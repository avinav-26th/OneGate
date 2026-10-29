import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_errors.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/date_formatter.dart';
import '../domain/visit_session.dart';
import '../domain/visitor.dart';
import '../domain/visitor_repository.dart';
import '../domain/visitor_status.dart';
import 'visitor_api_service.dart';

class VisitorRepositoryImpl implements VisitorRepository {
  final VisitorApiService apiService;
  static const String _storageKey = 'one_gate_persisted_visitors';
  static const String _pendingQueueKey = 'one_gate_pending_sync_queue';

  List<Visitor>? _memoryCache;
  final Set<String> _inFlightOperations = {};
  final Map<String, int> _lastOperationTime = {};

  VisitorRepositoryImpl({required this.apiService});

  // initial seed records for fresh installs without connectivity
  List<Visitor> _initialSeed() {
    final now = DateTime.now();
    return [
      Visitor(
        id: 'VIS001',
        name: 'Rahul Sharma',
        mobile: '9876543210',
        email: 'rahul@example.com',
        visitorType: 'Customer',
        project: 'Project A',
        purpose: 'Site Visit',
        status: VisitorStatus.registered,
        createdAt: now,
      ),
      Visitor(
        id: 'VIS002',
        name: 'Priya Patel',
        mobile: '9812345678',
        email: 'priya.patel@gmail.com',
        visitorType: 'Vendor',
        project: 'Project B',
        purpose: 'Electrical Inspection',
        status: VisitorStatus.checkedIn,
        createdAt: now.subtract(const Duration(hours: 2)),
        checkInTime: now.subtract(const Duration(hours: 1, minutes: 45)),
      ),
      Visitor(
        id: 'VIS003',
        name: 'Amit Verma',
        mobile: '9898989898',
        email: 'amit.verma@corp.in',
        visitorType: 'Other',
        project: 'Project C',
        purpose: 'Architectural Review',
        status: VisitorStatus.checkedOut,
        createdAt: now.subtract(const Duration(hours: 4)),
        checkInTime: now.subtract(const Duration(hours: 3)),
        checkOutTime: now.subtract(const Duration(minutes: 30)),
      ),
    ];
  }

  // read cached visitors from local storage
  Future<List<Visitor>> _readLocal() async {
    if (_memoryCache != null) {
      return List<Visitor>.from(_memoryCache!);
    }
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      final initial = _initialSeed();
      return initial;
    }
    try {
      final decoded = json.decode(jsonString);
      if (decoded is List) {
        final parsed = decoded
            .map((item) => Visitor.fromJson(item as Map<String, dynamic>))
            .toList();
        _memoryCache = parsed;
        return List<Visitor>.from(parsed);
      }
    } catch (_) {}
    final fallback = _initialSeed();
    return fallback;
  }

  Future<void> _writeLocal(List<Visitor> visitors) async {
    _memoryCache = List<Visitor>.from(visitors);
    final prefs = await SharedPreferences.getInstance();
    final raw = visitors.map((v) => v.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(raw));
  }

  // pending mutations queue for offline synchronization
  Future<List<Map<String, dynamic>>> _readPendingQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingQueueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = json.decode(raw);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _enqueuePendingMutation(Map<String, dynamic> mutation) async {
    final list = await _readPendingQueue();
    list.add(mutation);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingQueueKey, json.encode(list));
  }

  Future<void> _clearPendingQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingQueueKey);
  }

  // auto purge soft deleted visitors older than 30 days
  @override
  Future<void> autoPurgeExpiredRecycleBin([Duration retention = const Duration(days: 30)]) async {
    final all = await _readLocal();
    final cutoff = DateTime.now().subtract(retention);
    final remaining = all.where((v) {
      if (!v.isDeleted) return true;
      if (v.deletedAt == null) return true;
      return v.deletedAt!.isAfter(cutoff);
    }).toList();
    if (remaining.length != all.length) {
      await _writeLocal(remaining);
    }
  }

  // replay queued mutations when connection is restored
  @override
  Future<void> syncPendingMutations() async {
    final queue = await _readPendingQueue();
    if (queue.isEmpty) return;
    final remaining = <Map<String, dynamic>>[];
    for (final task in queue) {
      try {
        final action = task['action']?.toString();
        final id = task['id']?.toString() ?? '';
        final payload = task['data'] is Map<String, dynamic>
            ? task['data'] as Map<String, dynamic>
            : <String, dynamic>{};

        if (action == 'create') {
          await apiService.createVisitor(payload);
        } else if (action == 'update') {
          await apiService.updateVisitor(id, payload);
        } else if (action == 'delete') {
          await apiService.deleteVisitor(id);
        } else if (action == 'status') {
          await apiService.patchVisitor(id, payload);
        }
      } catch (_) {
        remaining.add(task);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    if (remaining.isEmpty) {
      await _clearPendingQueue();
    } else {
      await prefs.setString(_pendingQueueKey, json.encode(remaining));
    }
  }

  // fetch visitors with offline-first cache strategy
  @override
  Future<List<Visitor>> getVisitors({bool forceRefresh = false}) async {
    await autoPurgeExpiredRecycleBin();
    final prefs = await SharedPreferences.getInstance();
    final hasStored = prefs.containsKey(_storageKey);

    if (!hasStored) {
      try {
        final remote = await apiService.getVisitors();
        final remoteParsed = remote.map((i) => Visitor.fromJson(i)).toList();
        await _writeLocal(remoteParsed);
        return remoteParsed;
      } catch (_) {
        final initial = _initialSeed();
        await _writeLocal(initial);
        return initial;
      }
    }

    final localList = await _readLocal();

    if (forceRefresh) {
      try {
        await syncPendingMutations();
        final remote = await apiService.getVisitors();
        final remoteParsed = remote.map((i) => Visitor.fromJson(i)).toList();
        final localDeleted = localList.where((v) => v.isDeleted).toList();
        final merged = [...remoteParsed, ...localDeleted]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        await _writeLocal(merged);
        return remoteParsed;
      } catch (_) {}
    }

    return localList.where((v) => !v.isDeleted).toList();
  }

  @override
  Future<List<Visitor>> getRecycleBinVisitors() async {
    final localList = await _readLocal();
    return localList.where((v) => v.isDeleted).toList()
      ..sort((a, b) => (b.deletedAt ?? b.createdAt).compareTo(a.deletedAt ?? a.createdAt));
  }

  // query single visitor by id or pass code
  @override
  Future<Visitor> getVisitorById(String id) async {
    final localList = await _readLocal();
    final normalized = id.trim().toLowerCase();
    final match = localList.where((v) =>
        v.id.toLowerCase() == normalized ||
        v.passCode.toLowerCase() == normalized);
    if (match.isNotEmpty) {
      return match.first;
    }
    try {
      final remote = await apiService.getVisitor(id);
      final visitor = Visitor.fromJson(remote);
      localList.insert(0, visitor);
      await _writeLocal(localList);
      return visitor;
    } catch (_) {}
    throw const Failure(AppErrors.visitorNotFound, statusCode: 404);
  }

  // create visitor with double submit guard and offline queue fallback
  @override
  Future<Visitor> createVisitor(Visitor visitor) async {
    final opKey = 'create_${visitor.name.trim().toLowerCase()}_${visitor.mobile.trim()}';
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (_inFlightOperations.contains(opKey)) {
      throw const Failure(AppErrors.registrationInProgress);
    }
    if (_lastOperationTime.containsKey(opKey) && (nowMs - _lastOperationTime[opKey]!) < 1000) {
      throw const Failure(AppErrors.duplicateRegistration);
    }
    _inFlightOperations.add(opKey);
    _lastOperationTime[opKey] = nowMs;
    try {
      Visitor created;
      try {
        final remote = await apiService.createVisitor(visitor.toJson(includeId: false));
        created = Visitor.fromJson(remote);
      } catch (_) {
        final generatedId = 'VIS${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        created = visitor.copyWith(id: generatedId);
        await _enqueuePendingMutation({
          'action': 'create',
          'id': created.id,
          'data': created.toJson(includeId: false),
        });
      }

      final localList = await _readLocal();
      localList.insert(0, created);
      await _writeLocal(localList);
      return created;
    } finally {
      _inFlightOperations.remove(opKey);
    }
  }

  @override
  Future<Visitor> updateVisitor(Visitor visitor) async {
    Visitor updated = visitor;
    try {
      final remote = await apiService.updateVisitor(visitor.id, visitor.toJson());
      updated = Visitor.fromJson(remote);
    } catch (_) {
      await _enqueuePendingMutation({
        'action': 'update',
        'id': visitor.id,
        'data': visitor.toJson(),
      });
    }

    final localList = await _readLocal();
    final idx = localList.indexWhere((v) => v.id == visitor.id);
    if (idx != -1) {
      localList[idx] = updated;
      await _writeLocal(localList);
    }
    return updated;
  }

  @override
  Future<void> softDeleteVisitor(String id) async {
    final localList = await _readLocal();
    final idx = localList.indexWhere((v) => v.id.trim().toLowerCase() == id.trim().toLowerCase());
    if (idx != -1) {
      final updated = localList[idx].copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
      );
      localList[idx] = updated;
      await _writeLocal(localList);
    }
  }

  @override
  Future<void> deleteVisitor(String id) => softDeleteVisitor(id);

  @override
  Future<void> restoreVisitor(String id) async {
    final localList = await _readLocal();
    final idx = localList.indexWhere((v) => v.id.trim().toLowerCase() == id.trim().toLowerCase());
    if (idx != -1) {
      final updated = localList[idx].copyWith(
        isDeleted: false,
        clearDeletedAt: true,
      );
      localList[idx] = updated;
      await _writeLocal(localList);
    }
  }

  @override
  Future<void> hardDeleteVisitor(String id) async {
    try {
      await apiService.deleteVisitor(id);
    } catch (_) {
      await _enqueuePendingMutation({
        'action': 'delete',
        'id': id,
        'data': <String, dynamic>{},
      });
    }

    final localList = await _readLocal();
    localList.removeWhere((v) => v.id.trim().toLowerCase() == id.trim().toLowerCase());
    await _writeLocal(localList);
  }

  @override
  Future<void> emptyRecycleBin() async {
    final localList = await _readLocal();
    final deletedIds = localList.where((v) => v.isDeleted).map((v) => v.id).toList();
    localList.removeWhere((v) => v.isDeleted);
    await _writeLocal(localList);

    for (final id in deletedIds) {
      try {
        await apiService.deleteVisitor(id);
      } catch (_) {
        await _enqueuePendingMutation({
          'action': 'delete',
          'id': id,
          'data': <String, dynamic>{},
        });
      }
    }
  }

  // update gate status and append to visit history
  @override
  Future<Visitor> updateStatus(String id, VisitorStatus newStatus, DateTime timestamp) async {
    final opKey = 'status_${id.trim().toLowerCase()}_${newStatus.name}';
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (_inFlightOperations.contains(opKey)) {
      return getVisitorById(id);
    }
    if (_lastOperationTime.containsKey(opKey) && (nowMs - _lastOperationTime[opKey]!) < 1000) {
      return getVisitorById(id);
    }
    _inFlightOperations.add(opKey);
    _lastOperationTime[opKey] = nowMs;
    try {
      final current = await getVisitorById(id);
      final history = List<VisitSession>.from(current.visitHistory);

      if (newStatus == VisitorStatus.checkedIn) {
        history.add(VisitSession(
          id: 'SES-${history.length + 1}',
          checkInTime: timestamp,
          purpose: current.purpose,
          gateOrProject: current.project,
        ));
      } else if (newStatus == VisitorStatus.checkedOut) {
        if (history.isNotEmpty && history.last.checkOutTime == null) {
          history[history.length - 1] = history.last.copyWith(checkOutTime: timestamp);
        } else {
          history.add(VisitSession(
            id: 'SES-${history.length + 1}',
            checkInTime: current.checkInTime ?? timestamp,
            checkOutTime: timestamp,
            purpose: current.purpose,
            gateOrProject: current.project,
          ));
        }
      }

      final updated = newStatus == VisitorStatus.checkedIn
          ? current.copyWith(status: newStatus, checkInTime: timestamp, visitHistory: history)
          : current.copyWith(status: newStatus, checkOutTime: timestamp, visitHistory: history);

      final patchData = {
        'status': newStatus.toApiString(),
        if (newStatus == VisitorStatus.checkedIn)
          'check_in_time': DateFormatter.toIso(timestamp)
        else
          'check_out_time': DateFormatter.toIso(timestamp),
      };

      try {
        final remote = await apiService.patchVisitor(id, patchData);
        final remoteUpdated = Visitor.fromJson(remote).copyWith(visitHistory: history);
        final localList = await _readLocal();
        final idx = localList.indexWhere((v) => v.id == id);
        if (idx != -1) {
          localList[idx] = remoteUpdated;
          await _writeLocal(localList);
        }
        return remoteUpdated;
      } catch (_) {
        await _enqueuePendingMutation({
          'action': 'status',
          'id': id,
          'data': patchData,
        });
        final localList = await _readLocal();
        final idx = localList.indexWhere((v) => v.id == id);
        if (idx != -1) {
          localList[idx] = updated;
          await _writeLocal(localList);
        }
        return updated;
      }
    } finally {
      _inFlightOperations.remove(opKey);
    }
  }
}

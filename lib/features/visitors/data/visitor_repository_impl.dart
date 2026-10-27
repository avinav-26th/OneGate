import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/date_formatter.dart';
import '../domain/visitor.dart';
import '../domain/visitor_repository.dart';
import '../domain/visitor_status.dart';
import 'visitor_api_service.dart';

class VisitorRepositoryImpl implements VisitorRepository {
  final VisitorApiService apiService;
  static const String _storageKey = 'one_gate_persisted_visitors';

  VisitorRepositoryImpl({required this.apiService});

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

  Future<List<Visitor>> _loadLocalVisitors() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      final initial = _initialSeed();
      await _saveLocalVisitors(initial);
      return initial;
    }
    try {
      final decoded = json.decode(jsonString);
      if (decoded is List) {
        return decoded
            .map((item) => Visitor.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _initialSeed();
  }

  Future<void> _saveLocalVisitors(List<Visitor> visitors) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = visitors.map((v) => v.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(raw));
  }

  @override
  Future<List<Visitor>> getVisitors() async {
    try {
      final remoteList = await apiService.getVisitors();
      if (remoteList.isNotEmpty) {
        final visitors = remoteList.map((item) => Visitor.fromJson(item)).toList();
        await _saveLocalVisitors(visitors);
        return visitors;
      }
    } catch (_) {}

    return await _loadLocalVisitors();
  }

  @override
  Future<Visitor> getVisitorById(String id) async {
    try {
      final remoteMap = await apiService.getVisitor(id);
      final visitor = Visitor.fromJson(remoteMap);
      return visitor;
    } catch (_) {}

    final localList = await _loadLocalVisitors();
    final found = localList.where((v) => v.id.toLowerCase() == id.trim().toLowerCase());
    if (found.isNotEmpty) {
      return found.first;
    }
    throw const Failure('Visitor record not found', statusCode: 404);
  }

  @override
  Future<Visitor> createVisitor(Visitor visitor) async {
    Visitor created;
    try {
      final remote = await apiService.createVisitor(visitor.toJson(includeId: false));
      created = Visitor.fromJson(remote);
    } catch (_) {
      final generatedId = 'VIS${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      created = visitor.copyWith(id: generatedId);
    }

    final localList = await _loadLocalVisitors();
    localList.insert(0, created);
    await _saveLocalVisitors(localList);
    return created;
  }

  @override
  Future<Visitor> updateVisitor(Visitor visitor) async {
    Visitor updated;
    try {
      final remote = await apiService.updateVisitor(visitor.id, visitor.toJson());
      updated = Visitor.fromJson(remote);
    } catch (_) {
      updated = visitor;
    }

    final localList = await _loadLocalVisitors();
    final index = localList.indexWhere((v) => v.id == visitor.id);
    if (index != -1) {
      localList[index] = updated;
      await _saveLocalVisitors(localList);
    }
    return updated;
  }

  @override
  Future<void> deleteVisitor(String id) async {
    try {
      await apiService.deleteVisitor(id);
    } catch (_) {}

    final localList = await _loadLocalVisitors();
    localList.removeWhere((v) => v.id == id);
    await _saveLocalVisitors(localList);
  }

  @override
  Future<Visitor> updateStatus(String id, VisitorStatus newStatus, DateTime timestamp) async {
    final current = await getVisitorById(id);
    Visitor updated;
    if (newStatus == VisitorStatus.checkedIn) {
      updated = current.copyWith(
        status: newStatus,
        checkInTime: timestamp,
      );
    } else {
      updated = current.copyWith(
        status: newStatus,
        checkOutTime: timestamp,
      );
    }

    try {
      final patchData = {
        'status': newStatus.toApiString(),
        if (newStatus == VisitorStatus.checkedIn)
          'check_in_time': DateFormatter.toIso(timestamp)
        else
          'check_out_time': DateFormatter.toIso(timestamp),
      };
      final remote = await apiService.patchVisitor(id, patchData);
      updated = Visitor.fromJson(remote);
    } catch (_) {}

    final localList = await _loadLocalVisitors();
    final index = localList.indexWhere((v) => v.id == id);
    if (index != -1) {
      localList[index] = updated;
      await _saveLocalVisitors(localList);
    }
    return updated;
  }
}

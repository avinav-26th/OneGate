import 'package:flutter/foundation.dart';
import '../../../core/utils/date_formatter.dart';
import 'visit_session.dart';
import 'visitor_status.dart';

@immutable
class Visitor {
  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String visitorType;
  final String project;
  final String purpose;
  final VisitorStatus status;
  final DateTime createdAt;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final bool isDeleted;
  final DateTime? deletedAt;
  final List<VisitSession> visitHistory;

  const Visitor({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    required this.visitorType,
    required this.project,
    required this.purpose,
    required this.status,
    required this.createdAt,
    this.checkInTime,
    this.checkOutTime,
    this.isDeleted = false,
    this.deletedAt,
    this.visitHistory = const [],
  });

  String get passCode {
    final upper = id.toUpperCase();
    if (upper.startsWith('VIS')) {
      final suffix = upper.substring(3).replaceAll('-', '').replaceAll('_', '').trim();
      final numVal = int.tryParse(suffix);
      if (numVal != null) {
        return 'VIS${numVal.toString().padLeft(3, '0')}';
      }
      return upper;
    }
    final numVal = int.tryParse(id);
    if (numVal != null) {
      return 'VIS${numVal.toString().padLeft(3, '0')}';
    }
    return 'VIS-$id';
  }

  Visitor copyWith({
    String? id,
    String? name,
    String? mobile,
    String? email,
    String? visitorType,
    String? project,
    String? purpose,
    VisitorStatus? status,
    DateTime? createdAt,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    bool? isDeleted,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    List<VisitSession>? visitHistory,
  }) {
    return Visitor(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      visitorType: visitorType ?? this.visitorType,
      project: project ?? this.project,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      visitHistory: visitHistory ?? this.visitHistory,
    );
  }

  factory Visitor.fromJson(Map<String, dynamic> json) {
    final checkIn = DateFormatter.fromIso(
      (json['check_in_time'] ?? json['checkInTime'])?.toString(),
    );
    final checkOut = DateFormatter.fromIso(
      (json['check_out_time'] ?? json['checkOutTime'])?.toString(),
    );
    
    final historyList = <VisitSession>[];
    final historyRaw = json['visit_history'] ?? json['visitHistory'];
    if (historyRaw is List) {
      for (final item in historyRaw) {
        if (item is Map<String, dynamic>) {
          historyList.add(VisitSession.fromJson(item));
        }
      }
    }
    if (historyList.isEmpty && checkIn != null) {
      historyList.add(VisitSession(
        id: 'SES-1',
        checkInTime: checkIn,
        checkOutTime: checkOut,
        purpose: json['purpose']?.toString(),
        gateOrProject: json['project']?.toString(),
      ));
    }

    return Visitor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString(),
      visitorType: (json['visitor_type'] ?? json['visitorType'])?.toString() ?? 'Other',
      project: json['project']?.toString() ?? 'Project A',
      purpose: json['purpose']?.toString() ?? '',
      status: VisitorStatus.fromString(json['status']?.toString()),
      createdAt: DateFormatter.fromIso(
            (json['created_at'] ?? json['createdAt'])?.toString(),
          ) ??
          DateTime.now(),
      checkInTime: checkIn,
      checkOutTime: checkOut,
      isDeleted: json['is_deleted'] == true ||
          json['is_deleted'] == 'true' ||
          json['isDeleted'] == true ||
          json['isDeleted'] == 'true',
      deletedAt: DateFormatter.fromIso(
        (json['deleted_at'] ?? json['deletedAt'])?.toString(),
      ),
      visitHistory: historyList,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'name': name,
      'mobile': mobile,
      'email': email,
      'visitor_type': visitorType,
      'project': project,
      'purpose': purpose,
      'status': status.toApiString(),
      'created_at': DateFormatter.toIso(createdAt),
      'check_in_time': checkInTime != null ? DateFormatter.toIso(checkInTime!) : null,
      'check_out_time': checkOutTime != null ? DateFormatter.toIso(checkOutTime!) : null,
      'is_deleted': isDeleted,
      'deleted_at': deletedAt != null ? DateFormatter.toIso(deletedAt!) : null,
      'visit_history': visitHistory.map((s) => s.toJson()).toList(),
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Visitor && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

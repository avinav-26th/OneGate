import 'package:flutter/foundation.dart';
import '../../../core/utils/date_formatter.dart';
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
  });

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
    );
  }

  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString(),
      visitorType: json['visitor_type']?.toString() ?? 'Other',
      project: json['project']?.toString() ?? 'Project A',
      purpose: json['purpose']?.toString() ?? '',
      status: VisitorStatus.fromString(json['status']?.toString()),
      createdAt: DateFormatter.fromIso(json['created_at']?.toString()) ?? DateTime.now(),
      checkInTime: DateFormatter.fromIso(json['check_in_time']?.toString()),
      checkOutTime: DateFormatter.fromIso(json['check_out_time']?.toString()),
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

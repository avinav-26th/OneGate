import 'package:flutter/foundation.dart';
import '../../../core/utils/date_formatter.dart';

// single check in and check out session record
@immutable
class VisitSession {
  final String id;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String? purpose;
  final String? gateOrProject;

  const VisitSession({
    required this.id,
    required this.checkInTime,
    this.checkOutTime,
    this.purpose,
    this.gateOrProject,
  });

  bool get isCompleted => checkOutTime != null;

  // human readable duration between check in and check out
  String get durationText {
    final end = checkOutTime ?? DateTime.now();
    final diff = end.difference(checkInTime);
    if (diff.inMinutes < 1) {
      return '< 1 min';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} mins';
    } else {
      final hours = diff.inHours;
      final remainingMins = diff.inMinutes % 60;
      if (remainingMins == 0) {
        return '$hours hr${hours > 1 ? 's' : ''}';
      }
      return '$hours hr${hours > 1 ? 's' : ''} $remainingMins min';
    }
  }

  VisitSession copyWith({
    String? id,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? purpose,
    String? gateOrProject,
  }) {
    return VisitSession(
      id: id ?? this.id,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      purpose: purpose ?? this.purpose,
      gateOrProject: gateOrProject ?? this.gateOrProject,
    );
  }

  factory VisitSession.fromJson(Map<String, dynamic> json) {
    return VisitSession(
      id: json['id']?.toString() ?? 'SES-1',
      checkInTime: DateFormatter.fromIso(json['check_in_time']?.toString()) ?? DateTime.now(),
      checkOutTime: DateFormatter.fromIso(json['check_out_time']?.toString()),
      purpose: json['purpose']?.toString(),
      gateOrProject: json['gate_or_project']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'check_in_time': DateFormatter.toIso(checkInTime),
      'check_out_time': checkOutTime != null ? DateFormatter.toIso(checkOutTime!) : null,
      'purpose': purpose,
      'gate_or_project': gateOrProject,
    };
  }
}


import 'package:flutter/foundation.dart';
import '../../features/visitors/domain/visitor.dart';
import '../../features/visitors/domain/visitor_status.dart';
import '../utils/date_formatter.dart';

// static choices for dropdowns and chips
@immutable
class StaticTierData {
  static const List<String> projects = ['Project A', 'Project B', 'Project C'];
  static const List<String> visitorTypes = ['Customer', 'Vendor', 'Other'];
  static const List<String> commonPurposes = [
    'Site Visit',
    'Meeting',
    'Delivery',
    'Maintenance',
    'Interior Work',
    'Document Collection',
    'Personal',
  ];
}

class ComputedTierMetrics {
  final int totalCount;
  final int totalToday;
  final int currentlyIn;
  final int checkedOutToday;
  final int recycleBinCount;

  const ComputedTierMetrics({
    required this.totalCount,
    required this.totalToday,
    required this.currentlyIn,
    required this.checkedOutToday,
    required this.recycleBinCount,
  });

  // computes dashboard metrics from active visitors list
  factory ComputedTierMetrics.fromVisitors(List<Visitor> active, [List<Visitor> bin = const []]) {
    int today = 0;
    int inCount = 0;
    int outToday = 0;

    for (final v in active) {
      if (DateFormatter.isToday(v.createdAt)) {
        today++;
      }
      if (v.status == VisitorStatus.checkedIn) {
        inCount++;
      }
      if (v.status == VisitorStatus.checkedOut && DateFormatter.isToday(v.checkOutTime)) {
        outToday++;
      }
    }

    return ComputedTierMetrics(
      totalCount: active.length,
      totalToday: today,
      currentlyIn: inCount,
      checkedOutToday: outToday,
      recycleBinCount: bin.length,
    );
  }
}


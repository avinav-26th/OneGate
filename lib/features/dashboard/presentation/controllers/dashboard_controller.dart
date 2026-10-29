import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../visitors/domain/visitor_status.dart';
import '../../../visitors/presentation/controllers/visitor_list_controller.dart';

// metric data model for today's gate activity
class DashboardMetrics {
  final int totalToday;
  final int currentlyCheckedIn;
  final int checkedOutToday;

  const DashboardMetrics({
    required this.totalToday,
    required this.currentlyCheckedIn,
    required this.checkedOutToday,
  });

  const DashboardMetrics.zero()
      : totalToday = 0,
        currentlyCheckedIn = 0,
        checkedOutToday = 0;
}

// aggregates today's total, in, and out counts from active visitors
final dashboardMetricsProvider = Provider<AsyncValue<DashboardMetrics>>((ref) {
  final visitorsAsync = ref.watch(visitorListNotifierProvider);

  return visitorsAsync.whenData((visitors) {
    int totalToday = 0;
    int currentlyCheckedIn = 0;
    int checkedOutToday = 0;

    for (final visitor in visitors) {
      if (DateFormatter.isToday(visitor.createdAt)) {
        totalToday++;
      }
      if (visitor.status == VisitorStatus.checkedIn) {
        currentlyCheckedIn++;
      }
      if (DateFormatter.isToday(visitor.checkOutTime)) {
        checkedOutToday++;
      }
    }

    return DashboardMetrics(
      totalToday: totalToday,
      currentlyCheckedIn: currentlyCheckedIn,
      checkedOutToday: checkedOutToday,
    );
  });
});

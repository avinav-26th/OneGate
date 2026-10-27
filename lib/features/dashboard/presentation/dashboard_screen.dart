import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../visitors/presentation/controllers/visitor_list_controller.dart';
import '../../visitors/presentation/screens/visitor_details_screen.dart';
import 'controllers/dashboard_controller.dart';
import 'widgets/greeting_banner.dart';
import 'widgets/recent_visitor_tile.dart';
import 'widgets/today_metrics_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final visitorsAsync = ref.watch(recentVisitorsProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color(0xFFF4F7F8),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/onegate_logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OneGate',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF142B3B),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Sumadhura Real Estate',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF142B3B)),
            onPressed: () {
              ref.read(visitorListNotifierProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        backgroundColor: const Color(0xFF142B3B),
        color: const Color(0xFF38DCC0),
        onRefresh: () async {
          await ref.read(visitorListNotifierProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GreetingBanner(),
              const SizedBox(height: 20),
              const Text(
                'Today\'s Activity Metrics',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF142B3B),
                ),
              ),
              const SizedBox(height: 10),
              metricsAsync.when(
                data: (metrics) => TodayMetricsCard(
                  totalToday: metrics.totalToday,
                  currentlyCheckedIn: metrics.currentlyCheckedIn,
                  checkedOutToday: metrics.checkedOutToday,
                  onTapTotal: () {
                    ref.read(visitorQuickFilterProvider.notifier).state =
                        VisitorQuickFilter.totalToday;
                    widget.onNavigateTab?.call(2);
                  },
                  onTapCurrentlyIn: () {
                    ref.read(visitorQuickFilterProvider.notifier).state =
                        VisitorQuickFilter.currentlyIn;
                    widget.onNavigateTab?.call(2);
                  },
                  onTapCheckedOut: () {
                    ref.read(visitorQuickFilterProvider.notifier).state =
                        VisitorQuickFilter.checkedOutToday;
                    widget.onNavigateTab?.call(2);
                  },
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Failed to load metrics'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Visitors',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF142B3B),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(visitorQuickFilterProvider.notifier).state =
                          VisitorQuickFilter.all;
                      widget.onNavigateTab?.call(2);
                    },
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        color: Color(0xFF0E8B75),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              visitorsAsync.when(
                data: (visitors) {
                  if (visitors.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.people_outline, size: 36, color: Color(0xFF94A3B8)),
                          SizedBox(height: 8),
                          Text(
                            'No visitors recorded today',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visitors.length,
                    itemBuilder: (context, index) {
                      final visitor = visitors[index];
                      return RecentVisitorTile(
                        visitor: visitor,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => VisitorDetailsScreen(visitor: visitor),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Text('Error loading visitors: $error'),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

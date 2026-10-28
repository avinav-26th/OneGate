import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../visitors/presentation/controllers/visitor_list_controller.dart';
import '../../visitors/presentation/screens/visitor_details_screen.dart';
import '../../visitors/presentation/screens/visitor_form_screen.dart';
import 'controllers/dashboard_controller.dart';
import 'widgets/greeting_banner.dart';
import 'widgets/recent_visitor_tile.dart';
import 'widgets/today_metrics_card.dart';
import '../../../core/widgets/shimmer_loading.dart';

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
    final isDark = AppColors.isDark(context);

    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final visitorsAsync = ref.watch(recentVisitorsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.backgroundOf(context),
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
                Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryOf(context),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Sumadhura Real Estate',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_outlined,
              color: isDark ? AppColors.mintTeal : AppColors.navy,
            ),
            tooltip: ref.watch(themeModeProvider) == ThemeMode.dark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () {
              final current = ref.read(themeModeProvider);
              ref.read(themeModeProvider.notifier).state =
                  current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        color: isDark ? AppColors.mintTeal : AppColors.navy,
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
              Text(
                'Today\'s Activity Metrics',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryOf(context),
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
                loading: () => const TodayMetricsShimmer(),
                error: (error, stack) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Failed to load metrics'),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Quick Operations',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const VisitorFormScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.mintTeal : AppColors.navy,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_add_alt_1_rounded,
                              color: isDark ? AppColors.darkBackground : Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Register Visitor',
                              style: TextStyle(
                                color: isDark ? AppColors.darkBackground : Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => widget.onNavigateTab?.call(0),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceOf(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderOf(context)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              color: AppColors.textPrimaryOf(context),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Scan Pass',
                              style: TextStyle(
                                color: AppColors.textPrimaryOf(context),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  ref.read(visitorQuickFilterProvider.notifier).state = VisitorQuickFilter.all;
                  widget.onNavigateTab?.call(2);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderOf(context)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_alt_outlined, color: AppColors.textSecondaryOf(context), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'View All Registered Visitors',
                        style: TextStyle(
                          color: AppColors.textPrimaryOf(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Visitors',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(visitorQuickFilterProvider.notifier).state =
                          VisitorQuickFilter.all;
                      widget.onNavigateTab?.call(2);
                    },
                    child: Text(
                      'View all',
                      style: TextStyle(
                        color: isDark ? AppColors.mintTeal : const Color(0xFF0E8B75),
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
                        color: AppColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderOf(context)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.people_outline, size: 36, color: AppColors.textSecondaryOf(context)),
                          const SizedBox(height: 8),
                          Text(
                            'No visitors recorded today',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondaryOf(context),
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
                loading: () => const RecentVisitorListShimmer(count: 3),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../visitors/presentation/controllers/visitor_list_controller.dart';
import '../../visitors/presentation/screens/visitor_form_screen.dart';
import 'controllers/dashboard_controller.dart';
import 'widgets/dashboard_stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);

    return Scaffold(
      appBar: AppBar(
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
                const Text('OneGate'),
                Text(
                  'Sumadhura Real Estate',
                  style: TextStyle(
                    fontSize: 12,
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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(visitorListNotifierProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(visitorListNotifierProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Front Desk & Security',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Visitor Management Console',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage project visits, monitor gate entry/exit, and issue digital QR passes.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Today\'s Activity Metrics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              metricsAsync.when(
                data: (metrics) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DashboardStatCard(
                            title: 'Total Today',
                            count: metrics.totalToday,
                            icon: Icons.people_outline,
                            accentColor: const Color(0xFF3B82F6),
                            onTap: () => onNavigateTab?.call(1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DashboardStatCard(
                            title: 'Currently In',
                            count: metrics.currentlyCheckedIn,
                            icon: Icons.login_outlined,
                            accentColor: const Color(0xFF059669),
                            onTap: () {
                              ref.read(selectedStatusFilterProvider.notifier).state = null;
                              onNavigateTab?.call(1);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DashboardStatCard(
                      title: 'Checked Out Today',
                      count: metrics.checkedOutToday,
                      icon: Icons.logout_outlined,
                      accentColor: const Color(0xFF64748B),
                      onTap: () => onNavigateTab?.call(1),
                    ),
                  ],
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
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
              const SizedBox(height: 28),
              const Text(
                'Quick Operations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const VisitorFormScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('Register Visitor'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onNavigateTab?.call(2),
                      icon: const Icon(Icons.qr_code_scanner_outlined, size: 18),
                      label: const Text('Scan QR Code'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => onNavigateTab?.call(1),
                  icon: const Icon(Icons.format_list_bulleted_outlined, size: 18),
                  label: const Text('View All Registered Visitors'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

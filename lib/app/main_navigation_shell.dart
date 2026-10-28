import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/scanner/presentation/qr_scanner_screen.dart';
import '../features/visitors/presentation/screens/visitor_form_screen.dart';
import '../features/visitors/presentation/screens/visitor_list_screen.dart';
import 'widgets/smooth_curved_nav_bar.dart';

final mainNavigationIndexProvider = StateProvider<int>((ref) => 1);

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (ref.read(mainNavigationIndexProvider) == index) return;
    ref.read(mainNavigationIndexProvider.notifier).state = index;
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainNavigationIndexProvider);

    return PopScope(
      canPop: currentIndex == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentIndex != 1) {
          _onTabSelected(1);
        }
      },
      child: Scaffold(
        extendBody: true,
        body: PageView(
          controller: _pageController,
          physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
          onPageChanged: (index) {
            if (ref.read(mainNavigationIndexProvider) != index) {
              ref.read(mainNavigationIndexProvider.notifier).state = index;
            }
          },
          children: [
            QrScannerScreen(isActive: currentIndex == 0),
            DashboardScreen(onNavigateTab: _onTabSelected),
            const VisitorListScreen(),
          ],
        ),
        floatingActionButton: AnimatedBuilder(
          animation: _pageController,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: SizedBox(
              height: 42,
              child: Builder(
                builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final fabBg = isDark ? AppColors.mintTeal : AppColors.navy;
                  final fabFg = isDark ? AppColors.navy : Colors.white;

                  return FloatingActionButton.extended(
                    heroTag: 'onegate_shell_fab',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const VisitorFormScreen(),
                        ),
                      );
                    },
                    elevation: 3,
                    highlightElevation: 5,
                    extendedPadding: const EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: fabBg,
                    foregroundColor: fabFg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(21),
                    ),
                    icon: Icon(Icons.person_add_rounded, size: 18, color: fabFg),
                    label: Text(
                      AppStrings.newVisitor,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: fabFg,
                        letterSpacing: 0.2,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          builder: (context, child) {
            final page = (_pageController.hasClients && _pageController.position.hasContentDimensions)
                ? (_pageController.page ?? currentIndex.toDouble())
                : currentIndex.toDouble();

            final progress = page < 1.0 ? page.clamp(0.0, 1.0) : 1.0;
            if (progress <= 0.01) return const SizedBox.shrink();

            return Transform.scale(
              scale: progress,
              child: Opacity(
                opacity: progress,
                child: child,
              ),
            );
          },
        ),
        bottomNavigationBar: SmoothCurvedNavBar(
          pageController: _pageController,
          onTabSelected: _onTabSelected,
          items: const [
            SmoothCurvedNavItem(
              icon: Icons.qr_code_scanner_outlined,
              activeIcon: Icons.qr_code_scanner_rounded,
              label: AppStrings.scanGatePass,
            ),
            SmoothCurvedNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: AppStrings.dashboard,
            ),
            SmoothCurvedNavItem(
              icon: Icons.people_outline,
              activeIcon: Icons.people_alt_rounded,
              label: AppStrings.visitors,
            ),
          ],
        ),
      ),
    );
  }
}

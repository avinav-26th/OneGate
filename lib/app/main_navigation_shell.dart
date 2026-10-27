import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/scanner/presentation/qr_scanner_screen.dart';
import '../features/visitors/presentation/screens/visitor_form_screen.dart';
import '../features/visitors/presentation/screens/visitor_list_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 1;
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
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 1) {
          _onTabSelected(1);
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const ClampingScrollPhysics(),
          onPageChanged: (index) {
            if (_currentIndex != index) {
              setState(() => _currentIndex = index);
            }
          },
          children: [
            const QrScannerScreen(),
            DashboardScreen(onNavigateTab: _onTabSelected),
            const VisitorListScreen(),
          ],
        ),
        floatingActionButton: AnimatedScale(
          scale: _currentIndex == 0 ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            height: 42,
            child: FloatingActionButton.extended(
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
              backgroundColor: const Color(0xFF142B3B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(21),
              ),
              icon: const Icon(Icons.person_add_rounded, size: 18, color: Colors.white),
              label: const Text(
                'New Visitor',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: CurvedNavigationBar(
          index: _currentIndex,
          height: 65,
          color: Colors.white,
          buttonBackgroundColor: Colors.white,
          backgroundColor: _currentIndex == 0 ? Colors.black : const Color(0xFFF4F7F8),
          animationDuration: const Duration(milliseconds: 280),
          animationCurve: Curves.easeInOutCubic,
          onTap: _onTabSelected,
          items: [
            CurvedNavigationBarItem(
              child: Icon(
                _currentIndex == 0 ? Icons.qr_code_scanner_rounded : Icons.qr_code_scanner_outlined,
                size: 24,
                color: const Color(0xFF142B3B),
              ),
              label: 'Scan Pass',
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _currentIndex == 0 ? const Color(0xFF142B3B) : const Color(0xFF64748B),
              ),
            ),
            CurvedNavigationBarItem(
              child: Icon(
                _currentIndex == 1 ? Icons.home_rounded : Icons.home_outlined,
                size: 24,
                color: const Color(0xFF142B3B),
              ),
              label: 'Dashboard',
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _currentIndex == 1 ? const Color(0xFF142B3B) : const Color(0xFF64748B),
              ),
            ),
            CurvedNavigationBarItem(
              child: Icon(
                _currentIndex == 2 ? Icons.people_alt_rounded : Icons.people_outline,
                size: 24,
                color: const Color(0xFF142B3B),
              ),
              label: 'Visitors',
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _currentIndex == 2 ? const Color(0xFF142B3B) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

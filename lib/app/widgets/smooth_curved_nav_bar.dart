import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SmoothCurvedNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const SmoothCurvedNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class SmoothCurvedNavBar extends StatelessWidget {
  final PageController pageController;
  final ValueChanged<int> onTabSelected;
  final List<SmoothCurvedNavItem> items;

  const SmoothCurvedNavBar({
    super.key,
    required this.pageController,
    required this.onTabSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final count = items.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final circleColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final activeIconColor = isDark ? AppColors.mintTeal : AppColors.navy;
    final selectedTextColor = isDark ? AppColors.mintTeal : AppColors.navy;
    final unselectedTextColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final internalBottomPadding = bottomInset > 0 ? bottomInset : 8.0;
    final barHeight = 55.0 + internalBottomPadding;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemWidth = width / count;

        return AnimatedBuilder(
          animation: pageController,
          builder: (context, _) {
            final page = (pageController.hasClients && pageController.position.hasContentDimensions)
                ? (pageController.page ?? 1.0)
                : 1.0;

            final leftIndex = page.floor().clamp(0, count - 1);
            final rightIndex = page.ceil().clamp(0, count - 1);
            final fraction = (page - leftIndex).clamp(0.0, 1.0);
            final activeCenterX = (page + 0.5) * itemWidth;

            return SizedBox(
              height: barHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CurvedNavPainter(
                        activeCenterX: activeCenterX,
                        color: barColor,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -12,
                    left: activeCenterX - 24,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: circleColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: (1.0 - fraction).clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: 0.85 + 0.15 * (1.0 - fraction),
                                child: Icon(
                                  items[leftIndex].activeIcon,
                                  color: activeIconColor,
                                  size: 24,
                                ),
                              ),
                            ),
                            if (leftIndex != rightIndex)
                              Opacity(
                                opacity: fraction.clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: 0.85 + 0.15 * fraction,
                                  child: Icon(
                                    items[rightIndex].activeIcon,
                                    color: activeIconColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      children: List.generate(count, (index) {
                        final dist = (page - index).abs().clamp(0.0, 1.0);
                        final iconOpacity = (dist * 1.6).clamp(0.0, 1.0);
                        final isSelected = dist < 0.5;
                        final activeColor = Color.lerp(selectedTextColor, unselectedTextColor, dist)!;

                        return Expanded(
                          child: InkWell(
                            onTap: () => onTabSelected(index),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Opacity(
                                  opacity: iconOpacity,
                                  child: Icon(
                                    items[index].icon,
                                    color: activeColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  items[index].label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: activeColor,
                                  ),
                                ),
                                SizedBox(height: internalBottomPadding + 4),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CurvedNavPainter extends CustomPainter {
  final double activeCenterX;
  final Color color;
  final bool isDark;

  const _CurvedNavPainter({
    required this.activeCenterX,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final x = activeCenterX;
    const curveRadius = 34.0;
    const curveDepth = 26.0;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(x - curveRadius - 8, 0);

    path.cubicTo(
      x - curveRadius + 4,
      0,
      x - 22,
      curveDepth,
      x,
      curveDepth,
    );

    path.cubicTo(
      x + 22,
      curveDepth,
      x + curveRadius - 4,
      0,
      x + curveRadius + 8,
      0,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final topPath = Path();
    topPath.moveTo(0, 0);
    topPath.lineTo(x - curveRadius - 8, 0);
    topPath.cubicTo(
      x - curveRadius + 4,
      0,
      x - 22,
      curveDepth,
      x,
      curveDepth,
    );
    topPath.cubicTo(
      x + 22,
      curveDepth,
      x + curveRadius - 4,
      0,
      x + curveRadius + 8,
      0,
    );
    topPath.lineTo(size.width, 0);

    final ambientShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..style = PaintingStyle.fill;

    final keyShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.25 : 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(0, -3.5);
    canvas.drawPath(path, ambientShadowPaint);
    canvas.restore();

    canvas.save();
    canvas.translate(0, -1.2);
    canvas.drawPath(path, keyShadowPaint);
    canvas.restore();

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = isDark
          ? const Color(0xFF334155).withValues(alpha: 0.8)
          : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(topPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CurvedNavPainter oldDelegate) {
    return oldDelegate.activeCenterX != activeCenterX ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}

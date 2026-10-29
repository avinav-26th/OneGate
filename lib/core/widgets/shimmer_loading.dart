import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

// repeating animated gradient shader mask
class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// skeleton placeholder for today metrics card
class TodayMetricsShimmer extends StatelessWidget {
  const TodayMetricsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final dividerColor = AppColors.dividerOf(context);

    return ShimmerLoading(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  ShimmerBox(width: 44, height: 44, borderRadius: 12),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 130, height: 13, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(width: 50, height: 24, borderRadius: 6),
                      ],
                    ),
                  ),
                  ShimmerBox(
                    width: 14,
                    height: 14,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: dividerColor),
            IntrinsicHeight(
              child: Row(
                children: [
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          ShimmerBox(width: 44, height: 44, borderRadius: 12),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShimmerBox(width: 75, height: 13, borderRadius: 4),
                                SizedBox(height: 6),
                                ShimmerBox(width: 40, height: 24, borderRadius: 6),
                              ],
                            ),
                          ),
                          ShimmerBox(width: 14, height: 14, borderRadius: 4),
                        ],
                      ),
                    ),
                  ),
                  VerticalDivider(width: 1, color: dividerColor),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          ShimmerBox(width: 44, height: 44, borderRadius: 12),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShimmerBox(width: 75, height: 13, borderRadius: 4),
                                SizedBox(height: 6),
                                ShimmerBox(width: 40, height: 24, borderRadius: 6),
                              ],
                            ),
                          ),
                          ShimmerBox(width: 14, height: 14, borderRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecentVisitorTileShimmer extends StatelessWidget {
  const RecentVisitorTileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            ShimmerBox(width: 40, height: 40, borderRadius: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 120, height: 15, borderRadius: 4),
                  SizedBox(height: 6),
                  ShimmerBox(width: 160, height: 12, borderRadius: 4),
                ],
              ),
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ShimmerBox(width: 70, height: 22, borderRadius: 11),
                SizedBox(height: 6),
                ShimmerBox(width: 50, height: 11, borderRadius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// skeleton list for recent visitors
class RecentVisitorListShimmer extends StatelessWidget {
  final int count;

  const RecentVisitorListShimmer({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: List.generate(
          count,
          (_) => const RecentVisitorTileShimmer(),
        ),
      ),
    );
  }
}

class VisitorCardShimmer extends StatelessWidget {
  const VisitorCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final dividerColor = AppColors.dividerOf(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                ShimmerBox(width: 40, height: 40, borderRadius: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 140, height: 15, borderRadius: 4),
                      SizedBox(height: 6),
                      ShimmerBox(width: 90, height: 12, borderRadius: 4),
                    ],
                  ),
                ),
                ShimmerBox(width: 76, height: 22, borderRadius: 11),
              ],
            ),
            const SizedBox(height: 12),
            const ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
            const SizedBox(height: 6),
            const ShimmerBox(width: 200, height: 12, borderRadius: 4),
            const SizedBox(height: 12),
            Divider(height: 1, color: dividerColor),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 100, height: 12, borderRadius: 4),
                Row(
                  children: [
                    ShimmerBox(width: 28, height: 28, borderRadius: 14),
                    SizedBox(width: 8),
                    ShimmerBox(width: 28, height: 28, borderRadius: 14),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// full screen skeleton for visitor registry
class VisitorListShimmer extends StatelessWidget {
  final int count;

  const VisitorListShimmer({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 140, top: 8),
        itemCount: count,
        itemBuilder: (context, index) => const VisitorCardShimmer(),
      ),
    );
  }
}

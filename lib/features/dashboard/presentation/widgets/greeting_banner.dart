import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';

class GreetingBanner extends StatelessWidget {
  const GreetingBanner({super.key});

  // greeting text based on time of day
  String _getGreeting(int hour) {
    if (hour >= 5 && hour < 12) return 'Good morning!';
    if (hour >= 12 && hour < 17) return 'Good afternoon!';
    if (hour >= 17 && hour < 21) return 'Good evening!';
    return 'Good evening!';
  }

  Color _getBannerBg(BuildContext context, int hour) {
    final isDark = AppColors.isDark(context);
    if (isDark) {
      if (hour >= 5 && hour < 12) {
        return const Color(0xFF1E293B);
      } else if (hour >= 12 && hour < 17) {
        return const Color(0xFF222834);
      } else if (hour >= 17 && hour < 21) {
        return const Color(0xFF252233);
      } else {
        return const Color(0xFF16233B);
      }
    } else {
      if (hour >= 5 && hour < 12) {
        return const Color(0xFFEFF6FA);
      } else if (hour >= 12 && hour < 17) {
        return const Color(0xFFFEF9EE);
      } else if (hour >= 17 && hour < 21) {
        return const Color(0xFFFDF2F4);
      } else {
        return const Color(0xFFEEF2F7);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final bg = _getBannerBg(context, hour);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(hour),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryOf(context),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Here\'s today\'s visitor activity\nacross all projects.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryOf(context),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SvgPicture.asset(
            'assets/images/real_estate_illustration.svg',
            width: 110,
            height: 76,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/visitor_status.dart';

class StatusChip extends StatelessWidget {
  final VisitorStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    Color bg;
    Color fg;

    // resolve badge colors based on visitor status
    switch (status) {
      case VisitorStatus.registered:
        bg = isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7);
        fg = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
        break;
      case VisitorStatus.checkedIn:
        bg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.45) : const Color(0xFFD1FAE5);
        fg = isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
        break;
      case VisitorStatus.checkedOut:
        bg = isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F5F9);
        fg = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

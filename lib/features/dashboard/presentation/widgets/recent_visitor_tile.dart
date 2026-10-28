import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../visitors/domain/visitor.dart';
import '../../../visitors/presentation/widgets/status_chip.dart';

class RecentVisitorTile extends StatelessWidget {
  final Visitor visitor;
  final VoidCallback onTap;

  const RecentVisitorTile({
    super.key,
    required this.visitor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final timestamp = visitor.checkInTime ?? visitor.checkOutTime ?? visitor.createdAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE8EEF3),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  visitor.name.isNotEmpty ? visitor.name[0].toUpperCase() : 'V',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visitor.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${visitor.project}  •  ${visitor.visitorType}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryOf(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(status: visitor.status),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatter.formatTime(timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondaryOf(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

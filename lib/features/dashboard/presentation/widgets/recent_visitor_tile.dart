import 'package:flutter/material.dart';
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
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE8EEF3),
                child: Text(
                  visitor.name.isNotEmpty ? visitor.name[0].toUpperCase() : 'V',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF142B3B),
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF142B3B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${visitor.project}  •  ${visitor.visitorType}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
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
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
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


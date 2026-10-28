import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/date_formatter.dart';
import '../controllers/visitor_list_controller.dart';
import '../widgets/empty_state_widget.dart';

class RecycleBinScreen extends ConsumerStatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  ConsumerState<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends ConsumerState<RecycleBinScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recycleBinProvider.notifier).loadBin();
    });
  }

  int _daysRemaining(DateTime? deletedAt) {
    if (deletedAt == null) return 30;
    final diff = DateTime.now().difference(deletedAt).inDays;
    final rem = 30 - diff;
    return rem < 0 ? 0 : rem;
  }

  void _confirmEmptyBin(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Empty Recycle Bin?',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimaryOf(context)),
        ),
        content: Text(
          'All records in the recycle bin will be permanently erased. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondaryOf(context))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(recycleBinProvider.notifier).emptyBin();
              ref.read(visitorListNotifierProvider.notifier).refresh();
              AppSnackBar.info(context, 'Recycle bin cleared permanently');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Empty Permanently'),
          ),
        ],
      ),
    );
  }

  void _confirmPermanentDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Permanently Delete Record?',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimaryOf(context)),
        ),
        content: Text(
          'Are you sure you want to permanently delete $name? This action cannot be reversed.',
          style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondaryOf(context))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(recycleBinProvider.notifier).deletePermanently(id);
              ref.read(visitorListNotifierProvider.notifier).refresh();
              AppSnackBar.info(context, 'Permanently deleted $name');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final binAsync = ref.watch(recycleBinProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: Text(
          AppStrings.recycleBin,
          style: TextStyle(
            color: AppColors.textPrimaryOf(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.backgroundOf(context),
        leading: BackButton(color: AppColors.textPrimaryOf(context)),
        actions: [
          binAsync.maybeWhen(
            data: (items) => items.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.danger),
                    tooltip: 'Empty Bin',
                    onPressed: () => _confirmEmptyBin(context),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF78350F).withValues(alpha: 0.25)
                  : AppColors.warningLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFFB45309).withValues(alpha: 0.4)
                    : const Color(0xFFFDE68A),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Soft-deleted visitors are retained for 30 days before permanent auto-purge.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              color: isDark ? AppColors.mintTeal : AppColors.navy,
              onRefresh: () async {
                await ref.read(recycleBinProvider.notifier).loadBin();
              },
              child: binAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.mintTeal),
                ),
                error: (err, _) => Center(
                  child: Text('Error loading recycle bin: $err'),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.delete_outline_rounded,
                      title: 'Recycle Bin is Empty',
                      message: 'Deleted visitor records will appear here before permanent auto-removal.',
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final remaining = _daysRemaining(item.deletedAt);
                      return Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceOf(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderOf(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF334155) : AppColors.divider,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    item.name.isNotEmpty ? item.name[0].toUpperCase() : 'V',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimaryOf(context),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimaryOf(context),
                                        ),
                                      ),
                                      Text(
                                        '${item.project} • ${item.visitorType}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondaryOf(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
                                        : const Color(0xFFEFF6FA),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$remaining days left',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (item.deletedAt != null)
                              Text(
                                'Deleted: ${DateFormatter.formatDate(item.deletedAt!)} ${DateFormatter.formatTime(item.deletedAt!)}',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context)),
                              ),
                            Divider(height: 10, thickness: 0.8, color: AppColors.dividerOf(context)),
                            Padding(
                              padding: const EdgeInsets.only(top: 1, bottom: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      ref.read(recycleBinProvider.notifier).restore(item.id);
                                      ref.read(visitorListNotifierProvider.notifier).refresh();
                                      AppSnackBar.success(context, 'Restored ${item.name} to active registry');
                                    },
                                    icon: const Icon(Icons.restore_from_trash_rounded, size: 15),
                                    label: const Text('Restore', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.success,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                      minimumSize: const Size(0, 30),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _confirmPermanentDelete(context, item.id, item.name),
                                    icon: const Icon(Icons.delete_forever_rounded, size: 15),
                                    label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.danger,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                      minimumSize: const Size(0, 30),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

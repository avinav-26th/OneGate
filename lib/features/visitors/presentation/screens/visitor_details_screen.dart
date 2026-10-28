import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/visit_session.dart';
import '../../domain/visit_status_policy.dart';
import '../../domain/visitor.dart';
import '../../domain/visitor_status.dart';
import '../controllers/visitor_details_controller.dart';
import '../controllers/visitor_list_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/delete_dialog.dart';
import '../widgets/status_chip.dart';
import 'visitor_form_screen.dart';

class VisitorDetailsScreen extends ConsumerStatefulWidget {
  final Visitor visitor;

  const VisitorDetailsScreen({super.key, required this.visitor});

  @override
  ConsumerState<VisitorDetailsScreen> createState() => _VisitorDetailsScreenState();
}

class _VisitorDetailsScreenState extends ConsumerState<VisitorDetailsScreen>
    with SingleTickerProviderStateMixin {
  static const double _headerExpandedHeight = 232.0;
  static const double _headerCollapsedHeight = 80.0;

  late final AnimationController _headerController;
  late final Animation<double> _headerAnimation;
  bool _headerCollapsed = false;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _headerAnimation = _headerController.drive(
      CurveTween(curve: Curves.easeInOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(visitorDetailsNotifierProvider.notifier).setVisitor(widget.visitor);
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  void _setHeaderCollapsed(bool collapsed) {
    if (_headerCollapsed == collapsed) return;
    _headerCollapsed = collapsed;
    if (collapsed) {
      _headerController.forward();
    } else {
      _headerController.reverse();
    }
  }

  void _toggleHeader() => _setHeaderCollapsed(!_headerCollapsed);

  void _onHeaderDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -150) {
      _setHeaderCollapsed(true);
    } else if (velocity > 150) {
      _setHeaderCollapsed(false);
    }
  }

  bool _onContentScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;

    if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > 0) {
        _setHeaderCollapsed(true);
      } else if (delta < 0 && notification.metrics.pixels <= 0) {
        _setHeaderCollapsed(false);
      }
    } else if (notification is OverscrollNotification &&
        notification.dragDetails != null) {
      if (notification.overscroll > 0) {
        _setHeaderCollapsed(true);
      } else if (notification.overscroll < 0) {
        _setHeaderCollapsed(false);
      }
    }
    return false;
  }

  Future<void> _handleCheckIn(Visitor visitor) async {
    if (!VisitStatusPolicy.canCheckIn(visitor.status)) return;

    final success = await ref
        .read(visitorDetailsNotifierProvider.notifier)
        .checkIn(visitor.id);

    if (!mounted) return;

    if (success) {
      ref.read(visitorListNotifierProvider.notifier).refresh();
      AppSnackBar.success(context, 'Visitor checked in successfully');
    } else {
      AppSnackBar.error(context, 'Failed to check in visitor');
    }
  }

  Future<void> _handleCheckOut(Visitor visitor) async {
    if (!VisitStatusPolicy.canCheckOut(visitor.status)) return;

    final success = await ref
        .read(visitorDetailsNotifierProvider.notifier)
        .checkOut(visitor.id);

    if (!mounted) return;

    if (success) {
      ref.read(visitorListNotifierProvider.notifier).refresh();
      AppSnackBar.info(context, 'Visitor checked out successfully');
    } else {
      AppSnackBar.error(context, 'Failed to check out visitor');
    }
  }

  Future<void> _handleDelete(Visitor visitor) async {
    final confirmed = await DeleteDialog.show(
      context,
      visitorName: visitor.name,
      onConfirm: () {},
    );
    if (confirmed == true && mounted) {
      await ref
          .read(visitorListNotifierProvider.notifier)
          .softDeleteVisitor(visitor.id);
      if (mounted) {
        AppSnackBar.info(context, 'Moved ${visitor.name} to Recycle Bin');
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleEdit(Visitor visitor) async {
    final updated = await Navigator.of(context).push<Visitor>(
      MaterialPageRoute(
        builder: (_) => VisitorFormScreen(existingVisitor: visitor),
      ),
    );
    if (updated != null && mounted) {
      ref.read(visitorDetailsNotifierProvider.notifier).setVisitor(updated);
      ref.read(visitorListNotifierProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(visitorDetailsNotifierProvider);
    final visitor = detailsAsync.value ?? widget.visitor;
    final isLoading = detailsAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.backgroundOf(context),
        leading: BackButton(color: AppColors.textPrimaryOf(context)),
        title: Text(
          AppStrings.visitorDetails,
          style: TextStyle(
            color: AppColors.textPrimaryOf(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: AppColors.textPrimaryOf(context)),
            onPressed: () => _handleEdit(visitor),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () => _handleDelete(visitor),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundOf(context),
            border: Border(
              top: BorderSide(
                color: AppColors.borderOf(context),
                width: 0.8,
              ),
            ),
          ),
          child: _buildActionButtons(context, visitor, isLoading),
        ),
      ),

      body: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragEnd: _onHeaderDragEnd,
            child: AnimatedBuilder(
              animation: _headerAnimation,
              builder: (context, _) {
                final t = _headerAnimation.value;
                return _QrHeader(
                  visitor: visitor,
                  t: t,
                  height: lerpDouble(
                    _headerExpandedHeight,
                    _headerCollapsedHeight,
                    t,
                  )!,
                  onTap: _toggleHeader,
                );
              },
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onContentScroll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  children: [
                    _buildVisitorInfoCard(context, visitor),
                    const SizedBox(height: 16),
                    _buildVisitActivityTimeline(context, visitor),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorInfoCard(BuildContext context, Visitor visitor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visitor Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 14),
            _buildInfoRow(context, Icons.person_outline, 'Full Name', visitor.name),
            Divider(height: 20, color: AppColors.dividerOf(context)),
            _buildInfoRow(context, Icons.phone_outlined, 'Mobile Number', visitor.mobile),
            Divider(height: 20, color: AppColors.dividerOf(context)),
            _buildInfoRow(context, Icons.email_outlined, 'Email Address', visitor.email ?? 'Not provided'),
            Divider(height: 20, color: AppColors.dividerOf(context)),
            _buildInfoRow(context, Icons.apartment_outlined, 'Project', visitor.project),
            Divider(height: 20, color: AppColors.dividerOf(context)),
            _buildInfoRow(context, Icons.group_outlined, 'Visitor Type', visitor.visitorType),
            Divider(height: 20, color: AppColors.dividerOf(context)),
            _buildInfoRow(context, Icons.business_center_outlined, 'Purpose', visitor.purpose),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitActivityTimeline(BuildContext context, Visitor visitor) {
    final history = visitor.visitHistory;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Visit Activity Timeline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.chipOf(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderOf(context)),
                  ),
                  child: Text(
                    history.isEmpty
                        ? '1 Registration'
                        : '${history.length} Session${history.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildTimelineRow(
              context: context,
              icon: Icons.app_registration,
              title: 'Initial Registration',
              time: DateFormatter.formatDisplay(visitor.createdAt),
              isDone: true,
            ),
            if (history.isEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.chipOf(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Text(
                  'Awaiting initial gate check-in.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ),
            ] else ...[
              Divider(height: 24, color: AppColors.dividerOf(context)),
              ...history.reversed.map((session) => _buildSessionTile(context, session)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTile(BuildContext context, VisitSession session) {
    final isDark = AppColors.isDark(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.chipOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    session.isCompleted ? Icons.check_circle_outline : Icons.timelapse_rounded,
                    size: 15,
                    color: session.isCompleted ? AppColors.textSecondaryOf(context) : AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormatter.formatDate(session.checkInTime),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: session.isCompleted
                      ? (isDark ? AppColors.darkBorder : AppColors.borderSubtle.withValues(alpha: 0.3))
                      : (isDark ? AppColors.success.withValues(alpha: 0.25) : AppColors.successLight),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  session.durationText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: session.isCompleted
                        ? AppColors.textSecondaryOf(context)
                        : (isDark ? AppColors.mintTeal : AppColors.success),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTimelineRow(
            context: context,
            icon: Icons.login,
            title: 'Check-in Time',
            time: DateFormatter.formatTime(session.checkInTime),
            isDone: true,
          ),
          const SizedBox(height: 6),
          _buildTimelineRow(
            context: context,
            icon: Icons.logout,
            title: session.isCompleted ? 'Check-out Time' : 'Status',
            time: session.isCompleted
                ? DateFormatter.formatTime(session.checkOutTime!)
                : 'Currently Inside',
            isDone: session.isCompleted,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Visitor visitor, bool isLoading) {
    final isDark = AppColors.isDark(context);

    if (visitor.status == VisitorStatus.registered) {
      return SizedBox(
        width: double.infinity,
        child: CustomButton(
          text: AppStrings.recordCheckIn,
          icon: Icons.login,
          color: AppColors.success,
          isLoading: isLoading,
          onPressed: () => _handleCheckIn(visitor),
        ),
      );
    }

    if (visitor.status == VisitorStatus.checkedIn) {
      return SizedBox(
        width: double.infinity,
        child: CustomButton(
          text: AppStrings.recordCheckOut,
          icon: Icons.logout,
          color: isDark ? AppColors.mintTeal : AppColors.navy,
          textColor: isDark ? AppColors.darkBackground : Colors.white,
          isLoading: isLoading,
          onPressed: () => _handleCheckOut(visitor),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Start New Visit',
        icon: Icons.refresh_rounded,
        color: AppColors.success,
        isLoading: isLoading,
        onPressed: () => _handleCheckIn(visitor),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondaryOf(context)),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryOf(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String time,
    required bool isDone,
  }) {
    final isDark = AppColors.isDark(context);
    final color = isDone ? AppColors.textPrimaryOf(context) : AppColors.textSecondaryOf(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isDone
                ? (isDark ? AppColors.mintTeal.withValues(alpha: 0.15) : AppColors.mintTeal.withValues(alpha: 0.2))
                : AppColors.dividerOf(context),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 14,
            color: isDone ? (isDark ? AppColors.mintTeal : const Color(0xFF0E8B75)) : AppColors.textSecondaryOf(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _QrHeader extends StatelessWidget {
  final Visitor visitor;
  final double t;
  final double height;
  final VoidCallback onTap;

  const _QrHeader({
    required this.visitor,
    required this.t,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundOf(context),
        border: Border(
          bottom: BorderSide(
            color: t > 0.9 ? AppColors.borderOf(context).withValues(alpha: 0.5) : Colors.transparent,
            width: 0.8,
          ),
        ),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: lerpDouble(0, 1.2, t)!,
        child: InkWell(
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final cardHeight = constraints.maxHeight;

              final qrSize = lerpDouble(136.0, 42.0, t)!;
              final qrLeft = lerpDouble((width - 136.0) / 2, 12.0, t)!;
              final qrTop = lerpDouble(12.0, (cardHeight - 42.0) / 2, t)!;

              final expandedOpacity = (1.0 - (t / 0.35)).clamp(0.0, 1.0);
              final compactOpacity = ((t - 0.5) / 0.4).clamp(0.0, 1.0);
              final compactLeft = qrLeft + qrSize + 14.0;

              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: qrLeft,
                    top: qrTop,
                    width: qrSize,
                    height: qrSize,
                    child: Container(
                      padding: EdgeInsets.all(lerpDouble(6.0, 2.0, t)!),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(lerpDouble(14.0, 8.0, t)!),
                        border: Border.all(color: AppColors.borderOf(context)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: lerpDouble(6.0, 2.0, t)!,
                            offset: Offset(0, lerpDouble(2.0, 1.0, t)!),
                          ),
                        ],
                      ),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: QrImageView(
                          data: visitor.passCode,
                          version: QrVersions.auto,
                          size: 136,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.navy,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (expandedOpacity > 0.0)
                    Positioned(
                      top: lerpDouble(156.0, 90.0, t)!,
                      left: 16.0,
                      right: 16.0,
                      child: Opacity(
                        opacity: expandedOpacity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'PASS ID: ${visitor.passCode}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: AppColors.textPrimaryOf(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            StatusChip(status: visitor.status),
                          ],
                        ),
                      ),
                    ),
                  if (compactOpacity > 0.0)
                    Positioned(
                      left: compactLeft,
                      right: 12.0,
                      top: 0.0,
                      bottom: 0.0,
                      child: Opacity(
                        opacity: compactOpacity,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    visitor.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimaryOf(context),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'PASS: ${visitor.passCode}',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondaryOf(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusChip(status: visitor.status),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
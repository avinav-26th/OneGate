import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/visit_status_policy.dart';
import '../../domain/visitor.dart';
import '../../domain/visitor_status.dart';
import '../controllers/visitor_details_controller.dart';
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

class _VisitorDetailsScreenState extends ConsumerState<VisitorDetailsScreen> {
  late Visitor _visitor;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _visitor = widget.visitor;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(visitorDetailsNotifierProvider.notifier).setVisitor(_visitor);
    });
  }

  Future<void> _handleCheckIn() async {
    if (!VisitStatusPolicy.canCheckIn(_visitor.status)) return;

    setState(() => _isActionLoading = true);
    final success = await ref
        .read(visitorDetailsNotifierProvider.notifier)
        .checkIn(_visitor.id);

    if (!mounted) return;
    setState(() => _isActionLoading = false);

    if (success) {
      final updated = ref.read(visitorDetailsNotifierProvider).value;
      if (updated != null) {
        setState(() => _visitor = updated);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visitor checked in successfully'),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to check in visitor'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleCheckOut() async {
    if (!VisitStatusPolicy.canCheckOut(_visitor.status)) return;

    setState(() => _isActionLoading = true);
    final success = await ref
        .read(visitorDetailsNotifierProvider.notifier)
        .checkOut(_visitor.id);

    if (!mounted) return;
    setState(() => _isActionLoading = false);

    if (success) {
      final updated = ref.read(visitorDetailsNotifierProvider).value;
      if (updated != null) {
        setState(() => _visitor = updated);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visitor checked out successfully'),
          backgroundColor: Color(0xFF475569),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to check out visitor'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await DeleteDialog.show(
      context,
      visitorName: _visitor.name,
      onConfirm: () async {
        final success = await ref
            .read(visitorDetailsNotifierProvider.notifier)
            .delete(_visitor.id);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Visitor deleted successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop();
          }
        }
      },
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleEdit() async {
    final updated = await Navigator.of(context).push<Visitor>(
      MaterialPageRoute(
        builder: (_) => VisitorFormScreen(existingVisitor: _visitor),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _visitor = updated);
      ref.read(visitorDetailsNotifierProvider.notifier).setVisitor(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color(0xFFF4F7F8),
        title: const Text('Visitor Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _handleEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: _visitor.id,
                        version: QrVersions.auto,
                        size: 180,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF0F172A),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'PASS ID: ${_visitor.id}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    StatusChip(status: _visitor.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visitor Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.person_outline, 'Full Name', _visitor.name),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildInfoRow(Icons.phone_outlined, 'Mobile Number', _visitor.mobile),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildInfoRow(Icons.email_outlined, 'Email Address', _visitor.email ?? 'Not provided'),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildInfoRow(Icons.apartment_outlined, 'Project', _visitor.project),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildInfoRow(Icons.group_outlined, 'Visitor Type', _visitor.visitorType),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildInfoRow(Icons.business_center_outlined, 'Purpose', _visitor.purpose),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visit Activity Timeline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTimelineRow(
                      icon: Icons.app_registration,
                      title: 'Registered At',
                      time: DateFormatter.formatDisplay(_visitor.createdAt),
                      isDone: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTimelineRow(
                      icon: Icons.login,
                      title: 'Check-in Time',
                      time: DateFormatter.formatDisplay(_visitor.checkInTime),
                      isDone: _visitor.checkInTime != null,
                    ),
                    const SizedBox(height: 16),
                    _buildTimelineRow(
                      icon: Icons.logout,
                      title: 'Check-out Time',
                      time: DateFormatter.formatDisplay(_visitor.checkOutTime),
                      isDone: _visitor.checkOutTime != null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            _buildActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_visitor.status == VisitorStatus.registered) {
      return SizedBox(
        width: double.infinity,
        child: CustomButton(
          text: 'Record Check-In',
          icon: Icons.login,
          color: const Color(0xFF059669),
          isLoading: _isActionLoading,
          onPressed: _handleCheckIn,
        ),
      );
    }

    if (_visitor.status == VisitorStatus.checkedIn) {
      return SizedBox(
        width: double.infinity,
        child: CustomButton(
          text: 'Record Check-Out',
          icon: Icons.logout,
          color: const Color(0xFF142B3B),
          isLoading: _isActionLoading,
          onPressed: _handleCheckOut,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF64748B), size: 20),
          SizedBox(width: 8),
          Text(
            'Visit session completed. No further actions permitted.',
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineRow({
    required IconData icon,
    required String title,
    required String time,
    required bool isDone,
  }) {
    final color = isDone ? const Color(0xFF0F172A) : const Color(0xFF94A3B8);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDone
                ? const Color(0xFF4F46E5).withValues(alpha: 0.1)
                : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isDone ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(width: 12),
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

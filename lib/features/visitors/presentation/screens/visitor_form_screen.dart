import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_errors.dart';
import '../../../../core/data/data_orchestrator.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/visitor.dart';
import '../controllers/visitor_form_controller.dart';
import '../controllers/visitor_list_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'visitor_details_screen.dart';

// registration and edit form for visitor kyc details
class VisitorFormScreen extends ConsumerStatefulWidget {
  final Visitor? existingVisitor;

  const VisitorFormScreen({super.key, this.existingVisitor});

  @override
  ConsumerState<VisitorFormScreen> createState() => _VisitorFormScreenState();
}

class _VisitorFormScreenState extends ConsumerState<VisitorFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;
  late final TextEditingController _purposeController;
  late final TextEditingController _customTypeController;

  late String _selectedVisitorType;
  late String _selectedProject;

  bool get isEditing => widget.existingVisitor != null;

  @override
  void initState() {
    super.initState();
    final v = widget.existingVisitor;
    _nameController = TextEditingController(text: v?.name ?? '');
    _mobileController = TextEditingController(text: v?.mobile ?? '');
    _emailController = TextEditingController(text: v?.email ?? '');
    _purposeController = TextEditingController(text: v?.purpose ?? '');

    final existingType = v?.visitorType ?? 'Customer';
    if (existingType == 'Customer' || existingType == 'Vendor') {
      _selectedVisitorType = existingType;
      _customTypeController = TextEditingController();
    } else {
      _selectedVisitorType = 'Other';
      _customTypeController = TextEditingController(text: existingType == 'Other' ? '' : existingType);
    }

    _selectedProject = v?.project ?? AppConstants.projects.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _purposeController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  IconData _iconForVisitorType(String type) {
    switch (type.toLowerCase()) {
      case 'customer':
        return Icons.person_rounded;
      case 'vendor':
        return Icons.storefront_rounded;
      default:
        return Icons.work_outline_rounded;
    }
  }

  Color _colorForVisitorType(String type) {
    switch (type.toLowerCase()) {
      case 'customer':
        return const Color(0xFF0284C7);
      case 'vendor':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF64748B);
    }
  }

  // select visitor type from modal dialog
  void _showVisitorTypePopup() {
    final isDark = AppColors.isDark(context);

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surfaceOf(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Select Visitor Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ...['Customer', 'Vendor', 'Other'].map((type) {
                  final isSelected = _selectedVisitorType == type;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() => _selectedVisitorType = type);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.mintTeal.withValues(alpha: 0.15) : const Color(0xFFEFF6FA))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _iconForVisitorType(type),
                            size: 20,
                            color: _colorForVisitorType(type),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? (isDark ? AppColors.mintTeal : AppColors.navy)
                                    : AppColors.textPrimaryOf(context),
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_rounded, size: 20, color: AppColors.mintTeal),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProjectPopup(List<String> projects) {
    final isDark = AppColors.isDark(context);

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surfaceOf(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Select Destination Project',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ...projects.map((proj) {
                  final isSelected = _selectedProject == proj;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() => _selectedProject = proj);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.mintTeal.withValues(alpha: 0.15) : const Color(0xFFEFF6FA))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.apartment_rounded,
                            size: 20,
                            color: AppColors.textPrimaryOf(context),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              proj,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? (isDark ? AppColors.mintTeal : AppColors.navy)
                                    : AppColors.textPrimaryOf(context),
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_rounded, size: 20, color: AppColors.mintTeal),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // validate inputs and submit new or updated visitor
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final formNotifier = ref.read(visitorFormNotifierProvider.notifier);
    final effectiveType = _selectedVisitorType == 'Other'
        ? (_customTypeController.text.trim().isNotEmpty
            ? _customTypeController.text.trim()
            : 'Other')
        : _selectedVisitorType;

    Visitor? result;
    if (isEditing) {
      result = await formNotifier.updateVisitor(
        existing: widget.existingVisitor!,
        name: _nameController.text,
        mobile: _mobileController.text,
        email: _emailController.text,
        visitorType: effectiveType,
        project: _selectedProject,
        purpose: _purposeController.text,
      );
    } else {
      result = await formNotifier.registerVisitor(
        name: _nameController.text,
        mobile: _mobileController.text,
        email: _emailController.text,
        visitorType: effectiveType,
        project: _selectedProject,
        purpose: _purposeController.text,
      );
    }

    if (!mounted) return;

    if (result != null) {
      AppSnackBar.success(
        context,
        isEditing
            ? 'Visitor record updated successfully'
            : 'Visitor registered successfully! Pass ID: ${result.id}',
      );

      if (isEditing) {
        Navigator.of(context).pop(result);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VisitorDetailsScreen(visitor: result!),
          ),
        );
      }
    } else {
      AppSnackBar.error(
        context,
        isEditing
            ? AppErrors.updateFailed
            : AppErrors.registrationFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final availableProjects = ref.watch(availableProjectsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.backgroundOf(context),
        leading: BackButton(color: AppColors.textPrimaryOf(context)),
        title: Text(
          isEditing ? 'Edit Visitor' : 'Visitor Registration',
          style: TextStyle(
            color: AppColors.textPrimaryOf(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: _nameController,
                  label: 'Visitor Full Name *',
                  hint: 'e.g. Rahul Sharma',
                  prefixIcon: Icons.person_outline,
                  validator: Validators.validateName,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(60),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _mobileController,
                  label: 'Mobile Number (10 digits) *',
                  hint: 'e.g. 9876543210',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validateMobile,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address (Optional)',
                  hint: 'e.g. rahul@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(254),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Visitor Type *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _showVisitorTypePopup,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderOf(context)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _iconForVisitorType(_selectedVisitorType),
                          color: _colorForVisitorType(_selectedVisitorType),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedVisitorType,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selectedVisitorType == 'Other') ...[
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _customTypeController,
                    label: 'Specify Visitor Type *',
                    hint: 'e.g. Inspector, Contractor, Delivery Agent',
                    prefixIcon: Icons.edit_note_rounded,
                    validator: (v) => Validators.validateRequired(v, 'Visitor type details'),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(40),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Note: Custom category details are cached locally; cloud API sync for custom types will be enabled in a future release.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondaryOf(context),
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // destination project selection dropdown
                Text(
                  'Destination Project *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _showProjectPopup(availableProjects),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderOf(context)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.apartment_rounded,
                          color: AppColors.textPrimaryOf(context),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedProject,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _purposeController,
                  label: 'Purpose of Visit *',
                  hint: 'e.g. Site Visit, Electrical Inspection',
                  prefixIcon: Icons.business_center_outlined,
                  maxLines: 2,
                  validator: (v) => Validators.validateRequired(v, 'Purpose of visit'),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(250),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Frequently Used Purposes:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: 6),
                // quick select chips for common visit purposes
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: StaticTierData.commonPurposes.map((purpose) {
                    final isSelected = _purposeController.text.trim() == purpose;
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() {
                          _purposeController.text = purpose;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? AppColors.mintTeal.withValues(alpha: 0.2) : const Color(0xFF38DCC0).withValues(alpha: 0.18))
                              : AppColors.surfaceOf(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? (isDark ? AppColors.mintTeal : const Color(0xFF0E8B75))
                                : AppColors.borderOf(context),
                            width: isSelected ? 1.4 : 1,
                          ),
                        ),
                        child: Text(
                          purpose,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? AppColors.mintTeal : const Color(0xFF0E8B75))
                                : AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Cancel',
                        isOutlined: true,
                        color: isDark ? AppColors.darkBorder : AppColors.navy,
                        textColor: AppColors.textPrimaryOf(context),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: isEditing ? 'Update Visitor' : 'Register & Issue QR',
                        color: isDark ? AppColors.mintTeal : AppColors.navy,
                        textColor: isDark ? AppColors.darkBackground : Colors.white,
                        isLoading: ref.watch(visitorFormNotifierProvider).isLoading,
                        onPressed: _handleSubmit,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

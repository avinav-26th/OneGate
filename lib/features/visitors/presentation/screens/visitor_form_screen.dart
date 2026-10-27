import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/visitor.dart';
import '../controllers/visitor_form_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'visitor_details_screen.dart';

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

  late String _selectedVisitorType;
  late String _selectedProject;
  bool _isLoading = false;

  bool get isEditing => widget.existingVisitor != null;

  @override
  void initState() {
    super.initState();
    final v = widget.existingVisitor;
    _nameController = TextEditingController(text: v?.name ?? '');
    _mobileController = TextEditingController(text: v?.mobile ?? '');
    _emailController = TextEditingController(text: v?.email ?? '');
    _purposeController = TextEditingController(text: v?.purpose ?? '');

    _selectedVisitorType = v?.visitorType ?? AppConstants.visitorTypes.first;
    _selectedProject = v?.project ?? AppConstants.projects.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final formNotifier = ref.read(visitorFormNotifierProvider.notifier);

    Visitor? result;
    if (isEditing) {
      result = await formNotifier.updateVisitor(
        existing: widget.existingVisitor!,
        name: _nameController.text,
        mobile: _mobileController.text,
        email: _emailController.text,
        visitorType: _selectedVisitorType,
        project: _selectedProject,
        purpose: _purposeController.text,
      );
    } else {
      result = await formNotifier.registerVisitor(
        name: _nameController.text,
        mobile: _mobileController.text,
        email: _emailController.text,
        visitorType: _selectedVisitorType,
        project: _selectedProject,
        purpose: _purposeController.text,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Visitor record updated successfully'
                : 'Visitor registered successfully! Pass ID: ${result.id}',
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Failed to update visitor record'
                : 'Failed to register visitor',
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Visitor' : 'Visitor Registration'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.badge_outlined,
                          color: Color(0xFF0F172A),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing
                                  ? 'Updating ID: ${widget.existingVisitor!.id}'
                                  : 'New Visitor Pass',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEditing
                                  ? 'Modify details and synchronize changes with the registry.'
                                  : 'Enter visitor details to issue a digital gate entry pass.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: _nameController,
                  label: 'Visitor Full Name *',
                  hint: 'e.g. Rahul Sharma',
                  prefixIcon: Icons.person_outline,
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _mobileController,
                  label: 'Mobile Number (10 digits) *',
                  hint: 'e.g. 9876543210',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validateMobile,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address (Optional)',
                  hint: 'e.g. rahul@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Visitor Type *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedVisitorType,
                  items: AppConstants.visitorTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedVisitorType = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Destination Project *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedProject,
                  items: AppConstants.projects
                      .map((proj) => DropdownMenuItem(
                            value: proj,
                            child: Text(proj),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedProject = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _purposeController,
                  label: 'Purpose of Visit *',
                  hint: 'e.g. Site Visit, Electrical Inspection',
                  prefixIcon: Icons.business_center_outlined,
                  maxLines: 2,
                  validator: (v) => Validators.validateRequired(v, 'Purpose of visit'),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Cancel',
                        isOutlined: true,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: isEditing ? 'Update Visitor' : 'Register & Issue QR',
                        isLoading: _isLoading,
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

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class DeleteDialog extends StatelessWidget {
  final String visitorName;
  final VoidCallback onConfirm;

  const DeleteDialog({
    super.key,
    required this.visitorName,
    required this.onConfirm,
  });

  static Future<bool?> show(BuildContext context, {required String visitorName, required VoidCallback onConfirm}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => DeleteDialog(
        visitorName: visitorName,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Move to Recycle Bin?',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryOf(context),
        ),
      ),
      content: Text(
        'Are you sure you want to move "$visitorName" to the Recycle Bin? The record can be restored anytime within 30 days.',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondaryOf(context),
          height: 1.4,
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.textSecondaryOf(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
          ),
          child: const Text('Move to Bin'),
        ),
      ],
    );
  }
}

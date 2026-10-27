import 'package:flutter/material.dart';

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Delete Visitor',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ),
      content: Text(
        'Are you sure you want to delete the visitor record for "$visitorName"? This action cannot be undone.',
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF475569),
          height: 1.4,
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Color(0xFF64748B),
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
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

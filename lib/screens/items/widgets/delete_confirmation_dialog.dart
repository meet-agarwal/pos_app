// ============================================================
// delete_confirmation_dialog.dart
// ============================================================
// Confirmation dialog shown before any delete operation.
// Handles both single and bulk delete with appropriate messaging.
// ============================================================

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  /// Number of items being deleted.
  final int count;

  /// Optional name shown for single-item deletes.
  final String? itemName;

  const DeleteConfirmationDialog({
    super.key,
    required this.count,
    this.itemName,
  });

  /// Shows the dialog and returns true if confirmed.
  static Future<bool> show(
    BuildContext context, {
    required int count,
    String? itemName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteConfirmationDialog(
        count: count,
        itemName: itemName,
      ),
    );
    return result ?? false;
  }

  String get _title =>
      count == 1 ? 'Delete Item' : 'Delete $count Items';

  String get _message {
    if (count == 1 && itemName != null) {
      return 'Are you sure you want to permanently delete "$itemName"? '
          'This action cannot be undone.';
    }
    return 'Are you sure you want to permanently delete $count items? '
        'This action cannot be undone.';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: AppColors.error, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
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

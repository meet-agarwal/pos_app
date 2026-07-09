// ============================================================
// bulk_action_bar.dart
// ============================================================
// Toolbar that slides in when one or more rows are selected.
// Displays the selection count and bulk action buttons.
// ============================================================

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class BulkActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onDeleteSelected;
  final VoidCallback onClearSelection;

  const BulkActionBar({
    super.key,
    required this.selectedCount,
    required this.onDeleteSelected,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: Offset.zero,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          border: Border(
            bottom: BorderSide(color: AppColors.primary.withAlpha(80)),
          ),
        ),
        child: Row(
          children: [
            // Selection badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$selectedCount item${selectedCount == 1 ? '' : 's'} selected',
                style: AppTextStyles.badge,
              ),
            ),
            const SizedBox(width: 16),

            // Delete selected
            ElevatedButton.icon(
              onPressed: onDeleteSelected,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete Selected'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),

            // Clear selection
            OutlinedButton.icon(
              onPressed: onClearSelection,
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Clear Selection'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

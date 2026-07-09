// ============================================================
// upload_confirmation_dialog.dart
// ============================================================
// Shown BEFORE the file picker opens.
// Explains exactly what column format is required so the user
// prepares the spreadsheet correctly.
// ============================================================

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class UploadConfirmationDialog extends StatelessWidget {
  const UploadConfirmationDialog({super.key});

  /// Shows the dialog and returns true if the user confirms.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const UploadConfirmationDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.upload_file_outlined,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Upload Items Sheet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Rules list
              _RuleItem(
                icon: Icons.table_chart_outlined,
                text:
                    'Only the first worksheet in the Excel file will be imported.',
              ),
              _RuleItem(
                icon: Icons.view_column_outlined,
                text:
                    'The spreadsheet must contain all required columns in the exact order shown below.',
              ),
              _RuleItem(
                icon: Icons.spellcheck_outlined,
                text:
                    'Column headings must match exactly (case-sensitive).',
              ),
              _RuleItem(
                icon: Icons.update_outlined,
                text:
                    'Items with a matching code will be updated. New codes will be inserted.',
              ),
              _RuleItem(
                icon: Icons.warning_amber_outlined,
                text:
                    'Invalid rows will be skipped. A summary is shown after import.',
              ),

              // Required columns table
              const SizedBox(height: 20),
              const Text(
                'Required columns (in this order):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _buildColumnsTable(),

              const SizedBox(height: 28),

              // Action buttons
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
                    icon: const Icon(Icons.folder_open_outlined, size: 18),
                    label: const Text('Choose File'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumnsTable() {
    const headers = ['#', 'Column Name', 'Type', 'Required'];
    const rows = [
      ['1', 'code', 'Text', 'Yes'],
      ['2', 'name', 'Text', 'Yes'],
      ['3', 'unit', 'Text', 'Yes'],
      ['4', 'selling_price', 'Number ≥ 0', 'Yes'],
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.tableBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            decoration: const BoxDecoration(
              color: AppColors.tableHeaderBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: headers
                  .map((h) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Text(h,
                              style: AppTextStyles.tableHeader),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const Divider(height: 1),
          // Data rows
          for (int i = 0; i < rows.length; i++) ...[
            Container(
              color: i.isEven
                  ? AppColors.tableRowEven
                  : AppColors.tableRowOdd,
              child: Row(
                children: rows[i]
                    .map((cell) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 9),
                            child: Text(
                              cell,
                              style: cell == 'Yes'
                                  ? const TextStyle(
                                      color: AppColors.success,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)
                                  : AppTextStyles.tableCell
                                      .copyWith(
                                          fontFamily: i < 2 ||
                                                  rows[i].indexOf(cell) == 1
                                              ? 'monospace'
                                              : null),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            if (i < rows.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

// ── Individual rule line ──────────────────────────────────────

class _RuleItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RuleItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

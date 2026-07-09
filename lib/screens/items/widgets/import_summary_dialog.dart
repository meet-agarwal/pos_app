// ============================================================
// import_summary_dialog.dart
// ============================================================
// Shown after an Excel import finishes.
// Displays counts and, if there were failures, lists the errors.
// ============================================================

import 'package:flutter/material.dart';
import '../../../models/import_summary.dart';
import '../../../theme/app_theme.dart';

class ImportSummaryDialog extends StatelessWidget {
  final ImportSummary summary;

  const ImportSummaryDialog({super.key, required this.summary});

  static Future<void> show(
      BuildContext context, ImportSummary summary) {
    return showDialog(
      context: context,
      builder: (_) => ImportSummaryDialog(summary: summary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allFailed =
        summary.failed == summary.totalRows && summary.totalRows > 0;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: allFailed
                          ? AppColors.errorLight
                          : AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      allFailed
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: allFailed
                          ? AppColors.error
                          : AppColors.success,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    allFailed ? 'Import Failed' : 'Import Complete',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stat cards row
              Row(
                children: [
                  _StatCard(
                    label: 'Total Rows',
                    value: summary.totalRows,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Imported',
                    value: summary.imported,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Updated',
                    value: summary.updated,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Failed',
                    value: summary.failed,
                    color: summary.failed > 0
                        ? AppColors.error
                        : AppColors.textDisabled,
                  ),
                ],
              ),

              // Error list
              if (summary.hasErrors) ...[
                const SizedBox(height: 20),
                const Text(
                  'Skipped rows:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.error.withAlpha(60)),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      shrinkWrap: true,
                      itemCount: summary.errors.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 4),
                      itemBuilder: (_, i) => Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 14, color: AppColors.error),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              summary.errors[i],
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

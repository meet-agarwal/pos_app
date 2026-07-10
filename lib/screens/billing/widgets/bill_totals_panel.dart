// ============================================================
// bill_totals_panel.dart
// ============================================================
// Right-side summary card: Subtotal, Discount field, Total.
// Discount is a live ₹ text field — totals recompute instantly.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';

class BillTotalsPanel extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double total;
  final TextEditingController discountCtrl;

  const BillTotalsPanel({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.discountCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.tableHeaderBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Icon(Icons.summarize_outlined,
                    size: 15, color: AppColors.textSecondary),
                SizedBox(width: 6),
                Text('BILL SUMMARY', style: AppTextStyles.sectionLabel),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRow('Subtotal', _rupees(subtotal)),
                const SizedBox(height: 10),
                _buildDiscountRow(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1),
                ),
                _buildTotalRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountRow() {
    return Row(
      children: [
        const Text(
          'Discount',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 4),
        const Text(
          '(₹)',
          style: TextStyle(fontSize: 12, color: AppColors.textDisabled),
        ),
        const Spacer(),
        SizedBox(
          width: 110,
          child: TextField(
            controller: discountCtrl,
            textAlign: TextAlign.right,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: '₹ ',
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: const BorderSide(color: AppColors.tableBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: const BorderSide(color: AppColors.tableBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Total',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(70),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _rupees(total),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  String _rupees(double v) => '₹${v.toStringAsFixed(2)}';
}

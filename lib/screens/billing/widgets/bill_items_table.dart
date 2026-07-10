// ============================================================
// bill_items_table.dart
// ============================================================
// Editable table of items in the current bill.
// Each row shows English + Hindi name, unit, qty (editable),
// unit price, and line total, with a remove button.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../models/bill_state.dart';

class BillItemsTable extends StatelessWidget {
  final List<BillLineItem> items;

  /// Called with (rowIndex, newQuantity) when the user edits a qty.
  final void Function(int index, double qty) onQtyChanged;

  /// Called with rowIndex when the user taps the delete button.
  final ValueChanged<int> onRemove;

  const BillItemsTable({
    super.key,
    required this.items,
    required this.onQtyChanged,
    required this.onRemove,
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
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: items.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    itemBuilder: (_, i) => _BillRow(
                      // Stable key so the stateful row is never recycled
                      // when items are removed/reordered.
                      key: ValueKey(items[i].item.id ?? 'row_$i'),
                      lineItem: items[i],
                      rowIndex: i,
                      isEven: i.isEven,
                      onQtyChanged: (qty) => onQtyChanged(i, qty),
                      onRemove: () => onRemove(i),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.tableHeaderBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: const Row(
        children: [
          SizedBox(
              width: 32, child: Text('#', style: AppTextStyles.tableHeader)),
          Expanded(
              flex: 4,
              child: Text('Item', style: AppTextStyles.tableHeader)),
          SizedBox(
              width: 60,
              child: Text('Unit',
                  style: AppTextStyles.tableHeader,
                  textAlign: TextAlign.center)),
          SizedBox(
              width: 80,
              child: Text('Qty',
                  style: AppTextStyles.tableHeader,
                  textAlign: TextAlign.center)),
          SizedBox(
              width: 96,
              child: Text('Price',
                  style: AppTextStyles.tableHeader,
                  textAlign: TextAlign.right)),
          SizedBox(
              width: 96,
              child: Text('Total',
                  style: AppTextStyles.tableHeader,
                  textAlign: TextAlign.right)),
          SizedBox(width: 40), // delete column
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 52, color: AppColors.textDisabled),
          SizedBox(height: 14),
          Text(
            'No items added yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Search items above to add them to this bill',
            style:
                TextStyle(fontSize: 12, color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}

// ── Single editable row ───────────────────────────────────────

class _BillRow extends StatefulWidget {
  final BillLineItem lineItem;
  final int rowIndex;
  final bool isEven;
  final ValueChanged<double> onQtyChanged;
  final VoidCallback onRemove;

  const _BillRow({
    super.key,
    required this.lineItem,
    required this.rowIndex,
    required this.isEven,
    required this.onQtyChanged,
    required this.onRemove,
  });

  @override
  State<_BillRow> createState() => _BillRowState();
}

class _BillRowState extends State<_BillRow> {
  late final TextEditingController _qtyCtrl;
  late final FocusNode _qtyFocus;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: _fmtQty(widget.lineItem.quantity));

    _qtyFocus = FocusNode()
      ..addListener(() {
        if (_qtyFocus.hasFocus) {
          // Select all on focus for fast overwrite
          Future.microtask(() {
            _qtyCtrl.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _qtyCtrl.text.length,
            );
          });
        } else {
          // Commit on focus-out
          _commit(_qtyCtrl.text);
        }
      });
  }

  @override
  void didUpdateWidget(_BillRow old) {
    super.didUpdateWidget(old);
    // Keep the text field in sync when the parent recalculates
    // (e.g. after an external qty update) but don't stomp while focused.
    if (!_qtyFocus.hasFocus &&
        old.lineItem.quantity != widget.lineItem.quantity) {
      _qtyCtrl.text = _fmtQty(widget.lineItem.quantity);
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _qtyFocus.dispose();
    super.dispose();
  }

  String _fmtQty(double q) =>
      q == q.truncateToDouble() ? q.toInt().toString() : q.toString();

  void _commit(String text) {
    final q = double.tryParse(text.trim());
    if (q == null || q <= 0) {
      // Revert to last valid value
      _qtyCtrl.text = _fmtQty(widget.lineItem.quantity);
      return;
    }
    widget.onQtyChanged(q);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.lineItem.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovering
            ? AppColors.tableRowHover
            : (widget.isEven
                ? AppColors.tableRowEven
                : AppColors.tableRowOdd),
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Row number
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${widget.rowIndex + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textDisabled,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Item name (English + Hindi sub-label)
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.hindiName != null &&
                            item.hindiName!.isNotEmpty)
                          Text(
                            item.hindiName!,
                            style: GoogleFonts.notoSansDevanagari(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  // Unit
                  SizedBox(
                    width: 60,
                    child: Text(
                      item.unit,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Qty — inline editable
                  SizedBox(
                    width: 80,
                    child: Center(
                      child: SizedBox(
                        width: 62,
                        child: TextField(
                          controller: _qtyCtrl,
                          focusNode: _qtyFocus,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]')),
                          ],
                          onSubmitted: _commit,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                  color: AppColors.tableBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                  color: AppColors.tableBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Unit price
                  SizedBox(
                    width: 96,
                    child: Text(
                      '₹${item.sellingPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      textAlign: TextAlign.right,
                    ),
                  ),

                  // Line total
                  SizedBox(
                    width: 96,
                    child: Text(
                      '₹${widget.lineItem.lineTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),

                  // Delete
                  SizedBox(
                    width: 40,
                    child: _DeleteRowButton(onTap: widget.onRemove),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.tableBorder),
          ],
        ),
      ),
    );
  }
}

class _DeleteRowButton extends StatefulWidget {
  final VoidCallback onTap;
  const _DeleteRowButton({required this.onTap});

  @override
  State<_DeleteRowButton> createState() => _DeleteRowButtonState();
}

class _DeleteRowButtonState extends State<_DeleteRowButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _hovering
                ? AppColors.errorLight
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.delete_outline,
            size: 16,
            color: _hovering ? AppColors.error : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}

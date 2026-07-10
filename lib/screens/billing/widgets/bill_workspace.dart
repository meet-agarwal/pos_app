// ============================================================
// bill_workspace.dart
// ============================================================
// The full billing page for a single tab.
//
// Layout (tablet landscape):
//   ┌──────────────────────────────┐  ┌────────────────┐
//   │  CustomerSection             │  │                │
//   ├──────────────────────────────┤  │  BillTotals    │
//   │  ItemSearchField             │  │  Panel         │
//   ├──────────────────────────────┤  │                │
//   │                              │  │  ActionButtons │
//   │  BillItemsTable (scrollable) │  │                │
//   │                              │  └────────────────┘
//   └──────────────────────────────┘
//
// State is entirely local — IndexedStack keeps it alive when
// the user switches to another tab.
// ============================================================

import 'package:flutter/material.dart';

import '../../../models/item.dart';
import '../../../theme/app_theme.dart';
import '../models/bill_state.dart';
import 'action_buttons.dart';
import 'bill_items_table.dart';
import 'bill_totals_panel.dart';
import 'customer_section.dart';
import 'item_search_field.dart';

class BillWorkspace extends StatefulWidget {
  /// Full item catalogue loaded once by BillingScreen and shared
  /// across all tabs for zero-latency search.
  final List<Item> allItems;

  const BillWorkspace({super.key, required this.allItems});

  @override
  State<BillWorkspace> createState() => BillWorkspaceState();
}

class BillWorkspaceState extends State<BillWorkspace> {
  // ── Customer ──────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  // _linkedCustomer will be stored here when Save is implemented

  // ── Items ─────────────────────────────────────────────────
  final List<BillLineItem> _lineItems = [];

  // ── Discount ──────────────────────────────────────────────
  final _discountCtrl = TextEditingController();
  double _discount = 0.0;

  // ── Computed ─────────────────────────────────────────────
  double get _subtotal =>
      _lineItems.fold(0.0, (s, li) => s + li.lineTotal);
  double get _total =>
      (_subtotal - _discount).clamp(0.0, double.infinity);

  /// True if this bill contains any unsaved data.
  bool get hasChanges =>
      _lineItems.isNotEmpty ||
      _nameCtrl.text.isNotEmpty ||
      _mobileCtrl.text.isNotEmpty ||
      _discount > 0;

  // ── Lifecycle ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _discountCtrl.addListener(_onDiscountChanged);
  }

  @override
  void dispose() {
    _discountCtrl.removeListener(_onDiscountChanged);
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  // ── Handlers ─────────────────────────────────────────────

  void _onDiscountChanged() {
    final val = double.tryParse(_discountCtrl.text.trim()) ?? 0.0;
    final clamped = val < 0 ? 0.0 : val;
    if (clamped != _discount) setState(() => _discount = clamped);
  }

  void _addItem(Item item) {
    setState(() {
      // Increment quantity if item already present
      final idx = _lineItems.indexWhere((li) => li.item.id == item.id);
      if (idx >= 0) {
        _lineItems[idx].quantity += 1;
      } else {
        _lineItems.add(BillLineItem(item: item));
      }
    });
  }

  void _updateQty(int index, double qty) {
    if (qty <= 0) {
      _removeItem(index);
      return;
    }
    setState(() => _lineItems[index].quantity = qty);
  }

  void _removeItem(int index) {
    setState(() => _lineItems.removeAt(index));
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.contentBg,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Customer row ────────────────────────────────
            CustomerSection(
              nameCtrl: _nameCtrl,
              mobileCtrl: _mobileCtrl,
              onCustomerSelected: (_) {},
              // Customer reference will be used when Save is implemented
            ),
            const SizedBox(height: 10),

            // ── Item search ─────────────────────────────────
            ItemSearchField(
              allItems: widget.allItems,
              onItemSelected: _addItem,
            ),
            const SizedBox(height: 10),

            // ── Main content row ────────────────────────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Items table (takes most of the width)
                  Expanded(
                    flex: 3,
                    child: BillItemsTable(
                      items: _lineItems,
                      onQtyChanged: _updateQty,
                      onRemove: _removeItem,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Right panel: summary + buttons (fixed 296 px)
                  SizedBox(
                    width: 296,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BillTotalsPanel(
                          subtotal: _subtotal,
                          discount: _discount,
                          total: _total,
                          discountCtrl: _discountCtrl,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: AppColors.tableBorder),
                          ),
                          child: const ActionButtons(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

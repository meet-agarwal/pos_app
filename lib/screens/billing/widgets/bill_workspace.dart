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

import '../../../models/customer.dart';
import '../../../models/item.dart';
import '../../../services/billing_service.dart';
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

  /// Set when the user picks a record from the autocomplete dropdown.
  /// Cleared back to null if either field is manually edited afterward.
  Customer? _linkedCustomer;

  // ── Items ─────────────────────────────────────────────────
  final List<BillLineItem> _lineItems = [];

  // ── Discount ──────────────────────────────────────────────
  final _discountCtrl = TextEditingController();
  double _discount = 0.0;

  // ── Payment mode ──────────────────────────────────────────
  String _paymentMode = 'Cash';

  // ── Save state ────────────────────────────────────────────
  bool _isSaving = false;

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

  void _onCustomerSelected(Customer? c) {
    setState(() => _linkedCustomer = c);
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

  // ── Save ──────────────────────────────────────────────────

  /// Validates and persists the bill.
  /// [andPrint] = true when triggered from "Print & Save" (printing
  /// is a stub for now — will be implemented separately).
  Future<void> _saveBill({bool andPrint = false}) async {
    // Validation — must have at least one item
    if (_lineItems.isEmpty) {
      _showSnackBar(
        'Add at least one item before saving.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final invoiceNo = await BillingService.instance.saveBill(
        customerName: _nameCtrl.text,
        customerMobile: _mobileCtrl.text,
        lineItems: _lineItems,
        subtotal: _subtotal,
        discount: _discount,
        total: _total,
        paymentMode: _paymentMode,
        paidAmount: _total, // default: fully paid
      );

      if (!mounted) return;

      // TODO (future): trigger print if andPrint == true

      _showSnackBar('Invoice $invoiceNo saved successfully ✓');
      _resetWorkspace();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to save invoice: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Clears all fields to start a fresh bill.
  void _resetWorkspace() {
    setState(() {
      _lineItems.clear();
      _discount = 0.0;
      _paymentMode = 'Cash';
      _linkedCustomer = null;
    });
    _nameCtrl.clear();
    _mobileCtrl.clear();
    _discountCtrl.clear();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
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
              onCustomerSelected: _onCustomerSelected,
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
                          paymentMode: _paymentMode,
                          onPaymentModeChanged: (mode) =>
                              setState(() => _paymentMode = mode),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: AppColors.tableBorder),
                          ),
                          child: ActionButtons(
                            isSaving: _isSaving,
                            onSave: () => _saveBill(),
                            onSaveAndPrint: () => _saveBill(andPrint: true),
                          ),
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

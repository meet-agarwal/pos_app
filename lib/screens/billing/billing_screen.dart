// ============================================================
// billing_screen.dart
// ============================================================
// Root of the Billing module:
//   • Loads the full item catalogue once from ItemDao.
//   • Manages a list of open bills (tabs).
//   • Renders BillTabBar + IndexedStack<BillWorkspace>.
//
// IndexedStack keeps every workspace widget alive — switching
// tabs never destroys state (customer, items, discount, qty).
//
// Each workspace is keyed by its tab ID so Flutter can correctly
// track identity even when tabs are removed/reordered.
// ============================================================

import 'package:flutter/material.dart';

import '../../dao/item_dao.dart';
import '../../models/item.dart';
import '../../theme/app_theme.dart';
import 'models/bill_state.dart';
import 'widgets/bill_tab_bar.dart';
import 'widgets/bill_workspace.dart';

// ── Tab entry (immutable metadata) ───────────────────────────

class _BillTab {
  final int id;
  final String label;
  
  // Optional edit data
  final int? editInvoiceId;
  final String? editInvoiceNo;
  final String? initialCustomerName;
  final String? initialCustomerMobile;
  final double? initialDiscount;
  final String? initialPaymentMode;
  final List<BillLineItem>? initialLineItems;

  const _BillTab({
    required this.id,
    required this.label,
    this.editInvoiceId,
    this.editInvoiceNo,
    this.initialCustomerName,
    this.initialCustomerMobile,
    this.initialDiscount,
    this.initialPaymentMode,
    this.initialLineItems,
  });
}

// ── Screen ───────────────────────────────────────────────────

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => BillingScreenState();
}

class BillingScreenState extends State<BillingScreen> {
  // ── Tab state ─────────────────────────────────────────────
  List<_BillTab> _tabs = [];
  int _activeIndex = 0;
  int _nextId = 1; // monotonically increasing tab ID

  // ── Item catalogue ────────────────────────────────────────
  List<Item> _allItems = [];
  bool _itemsLoaded = false;

  // ── Lifecycle ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabs = [_BillTab(id: _nextId++, label: 'Bill 1')];
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await ItemDao.instance.getAllItems();
      if (mounted) {
        setState(() {
          _allItems = items;
          _itemsLoaded = true;
        });
      }
    } catch (_) {
      // Items simply won't be available for search; not fatal
      if (mounted) setState(() => _itemsLoaded = true);
    }
  }

  // ── Tab management ────────────────────────────────────────

  void _addTab() {
    setState(() {
      final id = _nextId++;
      _tabs = [..._tabs, _BillTab(id: id, label: 'Bill $id')];
      _activeIndex = _tabs.length - 1;
    });
  }

  void _closeTab(int index) {
    // Never close the last tab — just leave it (reset not implemented yet)
    if (_tabs.length == 1) return;

    setState(() {
      final updated = [..._tabs]..removeAt(index);
      _tabs = updated;

      // Keep active index in bounds
      if (_activeIndex >= _tabs.length) {
        _activeIndex = _tabs.length - 1;
      } else if (_activeIndex > index) {
        _activeIndex--;
      }
    });
  }

  void openEditTab({
    required int invoiceId,
    required String invoiceNo,
    String? customerName,
    String? customerMobile,
    required double discount,
    required String paymentMode,
    required List<BillLineItem> lineItems,
  }) {
    setState(() {
      final id = _nextId++;
      _tabs = [
        ..._tabs,
        _BillTab(
          id: id,
          label: 'Edit $invoiceNo',
          editInvoiceId: invoiceId,
          editInvoiceNo: invoiceNo,
          initialCustomerName: customerName,
          initialCustomerMobile: customerMobile,
          initialDiscount: discount,
          initialPaymentMode: paymentMode,
          initialLineItems: lineItems,
        ),
      ];
      _activeIndex = _tabs.length - 1;
    });
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const Divider(height: 1),
        BillTabBar(
          tabs: _tabs.map((t) => t.label).toList(),
          activeIndex: _activeIndex,
          onTabSelected: (i) => setState(() => _activeIndex = i),
          onTabClosed: _closeTab,
          onAddTab: _addTab,
        ),
        const Divider(height: 1),
        Expanded(
          child: !_itemsLoaded
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        'Loading items…',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : IndexedStack(
                  index: _activeIndex,
                  children: _tabs
                      .map(
                        (tab) => BillWorkspace(
                          key: ValueKey(tab.id),
                          allItems: _allItems,
                          editInvoiceId: tab.editInvoiceId,
                          editInvoiceNo: tab.editInvoiceNo,
                          initialCustomerName: tab.initialCustomerName,
                          initialCustomerMobile: tab.initialCustomerMobile,
                          initialDiscount: tab.initialDiscount,
                          initialPaymentMode: tab.initialPaymentMode,
                          initialLineItems: tab.initialLineItems,
                          onEditComplete: () {
                            final idx = _tabs.indexOf(tab);
                            if (idx >= 0) _closeTab(idx);
                          },
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final activeTab = _tabs.isNotEmpty ? _tabs[_activeIndex] : null;
    final title = (activeTab?.editInvoiceId != null) ? 'Edit Invoice' : 'Billing';

    return Container(
      height: 64,
      color: AppColors.screenHeaderBg,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.screenTitle),
          const Spacer(),
          // Show how many items are loaded (helpful for debugging)
          if (_itemsLoaded && _allItems.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_allItems.length} item${_allItems.length == 1 ? '' : 's'} loaded',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          if (_itemsLoaded && _allItems.isEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 13, color: AppColors.warning),
                  SizedBox(width: 4),
                  Text(
                    'No items — add items first',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// invoice_history_screen.dart
// ============================================================
// Features:
//   • Date-range filter (default = today) with quick chips
//   • Live search (invoice no. / customer name / mobile)
//   • Expandable rows with lazy-loaded line items
//   • Right-click (desktop) / long-press (touch) context menu
//       → Edit  (payment mode, discount, paid amount)
//       → Delete (with confirmation)
//       → Print  (stub)
//   • Total Sales footer
//   • Public `refresh()` method — called by AppShell on tab switch
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../dao/invoice_dao.dart';
import '../../database/db_constants.dart';
import '../../models/item.dart';
import '../../theme/app_theme.dart';
import '../billing/models/bill_state.dart';

// ── View model ───────────────────────────────────────────────

class _InvoiceRow {
  final int id;
  final String invoiceNo;
  final String? customerName;
  final String? customerMobile;
  final double subtotal;
  final double discount;
  final double total;
  final double paidAmount;
  final String paymentMode;
  final DateTime dateTime;
  List<Map<String, dynamic>>? items; // null = not yet loaded

  _InvoiceRow({
    required this.id,
    required this.invoiceNo,
    this.customerName,
    this.customerMobile,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paidAmount,
    required this.paymentMode,
    required this.dateTime,
  });

  factory _InvoiceRow.fromMap(Map<String, dynamic> m) {
    return _InvoiceRow(
      id: m[InvoiceColumns.id] as int,
      invoiceNo: m[InvoiceColumns.invoiceNo] as String,
      customerName: m['customer_name'] as String?,
      customerMobile: m['customer_mobile'] as String?,
      subtotal: (m[InvoiceColumns.subtotal] as num).toDouble(),
      discount: (m[InvoiceColumns.discount] as num).toDouble(),
      total: (m[InvoiceColumns.total] as num).toDouble(),
      paidAmount: (m[InvoiceColumns.paidAmount] as num).toDouble(),
      paymentMode: m[InvoiceColumns.paymentMode] as String,
      dateTime: DateTime.parse(m[InvoiceColumns.dateTime] as String),
    );
  }

  _InvoiceRow copyWith({
    String? paymentMode,
    double? discount,
    double? total,
    double? paidAmount,
  }) {
    return _InvoiceRow(
      id: id,
      invoiceNo: invoiceNo,
      customerName: customerName,
      customerMobile: customerMobile,
      subtotal: subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentMode: paymentMode ?? this.paymentMode,
      dateTime: dateTime,
    )..items = items;
  }

  String get displayName {
    final n = customerName?.trim() ?? '';
    final m = customerMobile?.trim() ?? '';
    if (n.isNotEmpty) return n;
    if (m.isNotEmpty) return m;
    return 'Walk-in';
  }

  bool get hasCustomer =>
      (customerName?.isNotEmpty ?? false) ||
      (customerMobile?.isNotEmpty ?? false);
}

// ── Edit result ───────────────────────────────────────────────

class _EditResult {
  final String paymentMode;
  final double discount;
  final double paidAmount;
  const _EditResult({
    required this.paymentMode,
    required this.discount,
    required this.paidAmount,
  });
}

// ── Screen ───────────────────────────────────────────────────

class InvoiceHistoryScreen extends StatefulWidget {
  final Function(
    int invoiceId,
    String invoiceNo,
    String? customerName,
    String? customerMobile,
    double discount,
    String paymentMode,
    List<BillLineItem> lineItems,
  )? onEditInvoice;

  const InvoiceHistoryScreen({
    super.key,
    this.onEditInvoice,
  });

  @override
  InvoiceHistoryScreenState createState() => InvoiceHistoryScreenState();
}

class InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  // ── State ─────────────────────────────────────────────────
  late DateTimeRange _dateRange;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;
  List<_InvoiceRow> _invoices = [];
  bool _loading = true;
  String? _error;
  final Set<int> _expanded = {};

  // ── Helpers ───────────────────────────────────────────────
  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  double get _totalSales =>
      _invoices.fold(0.0, (s, i) => s + i.total);

  String _rupees(double v) => '₹${v.toStringAsFixed(2)}';

  // ── Lifecycle ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final today = _today();
    _dateRange = DateTimeRange(start: today, end: today);
    _searchCtrl.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Public — called by AppShell on tab activation ─────────
  void refresh() => _load();

  // ── Data ──────────────────────────────────────────────────

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _searchQuery = _searchCtrl.text);
        _load();
      }
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _expanded.clear();
    });
    try {
      final rows = await InvoiceDao.instance.fetchByDateRange(
        _dateRange.start,
        _dateRange.end,
        search: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _invoices = rows.map(_InvoiceRow.fromMap).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _toggleExpand(int invoiceId) async {
    if (_expanded.contains(invoiceId)) {
      setState(() => _expanded.remove(invoiceId));
      return;
    }
    final inv = _invoices.firstWhere((i) => i.id == invoiceId);
    if (inv.items == null) {
      final items = await InvoiceDao.instance.fetchItemsForInvoice(invoiceId);
      if (mounted) {
        setState(() {
          inv.items = items;
          _expanded.add(invoiceId);
        });
      }
    } else {
      setState(() => _expanded.add(invoiceId));
    }
  }

  // ── Date range ────────────────────────────────────────────

  Future<void> _pickDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (result != null && mounted) {
      setState(() => _dateRange = result);
      _load();
    }
  }

  void _setQuick(DateTime start, DateTime end) {
    setState(() => _dateRange = DateTimeRange(start: start, end: end));
    _load();
  }

  // ── Context menu ──────────────────────────────────────────

  Future<void> _showContextMenu(
      Offset position, _InvoiceRow invoice) async {
    final size = MediaQuery.of(context).size;
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        size.width - position.dx,
        size.height - position.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 8,
      items: [
        _menuItem('edit', Icons.edit_outlined, 'Edit'),
        _menuItem('delete', Icons.delete_outline, 'Delete',
            color: AppColors.error),
        const PopupMenuDivider(height: 1),
        _menuItem('print', Icons.print_outlined, 'Print',
            color: AppColors.textSecondary),
      ],
    );
    if (!mounted) return;
    switch (result) {
      case 'edit':
        await _handleEdit(invoice);
      case 'delete':
        await _handleDelete(invoice);
      case 'print':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Print — coming soon')),
        );
    }
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label,
      {Color color = AppColors.textPrimary}) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color)),
        ],
      ),
    );
  }

  Future<void> _handleEdit(_InvoiceRow invoice) async {
    if (widget.onEditInvoice == null) return;
    
    // We need the items to populate the Edit screen
    List<Map<String, dynamic>> items = invoice.items ?? [];
    if (items.isEmpty) {
      items = await InvoiceDao.instance.fetchItemsForInvoice(invoice.id);
      if (mounted) {
        setState(() {
          invoice.items = items;
        });
      }
    }

    // Convert raw maps to BillLineItems using a fake/partial Item object
    // since we only really need id, name, unit, sellingPrice, etc.
    final lineItems = items.map((m) {
      return BillLineItem(
        item: Item(
          id: m[InvoiceItemColumns.itemId] as int,
          name: m[InvoiceItemColumns.itemName] as String,
          unit: m[InvoiceItemColumns.unit] as String,
          sellingPrice: (m[InvoiceItemColumns.unitPrice] as num).toDouble(),
        ),
      )..quantity = (m[InvoiceItemColumns.quantity] as num).toDouble();
    }).toList();

    widget.onEditInvoice!(
      invoice.id,
      invoice.invoiceNo,
      invoice.customerName,
      invoice.customerMobile,
      invoice.discount,
      invoice.paymentMode,
      lineItems,
    );
  }

  Future<void> _handleDelete(_InvoiceRow invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Invoice?',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
                children: [
                  const TextSpan(text: 'Invoice '),
                  TextSpan(
                    text: invoice.invoiceNo,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'monospace'),
                  ),
                  const TextSpan(
                      text:
                          ' and all its items will be permanently removed.\n\nThis action cannot be undone.'),
                ],
              ),
            ),
          ],
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await InvoiceDao.instance.deleteInvoice(invoice.id);
      if (!mounted) return;
      setState(() {
        _invoices.removeWhere((i) => i.id == invoice.id);
        _expanded.remove(invoice.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Invoice ${invoice.invoiceNo} deleted'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Delete failed: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const Divider(height: 1),
        _buildFilterBar(),
        const Divider(height: 1),
        Expanded(child: _buildBody()),
        const Divider(height: 1),
        _buildFooter(),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      height: 64,
      color: AppColors.screenHeaderBg,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Text('Invoice History', style: AppTextStyles.screenTitle),
          const Spacer(),
          if (!_loading && _error == null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_invoices.length} invoice${_invoices.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Filter bar ────────────────────────────────────────────

  Widget _buildFilterBar() {
    final today = _today();
    final yesterday = today.subtract(const Duration(days: 1));
    final startOfWeek =
        today.subtract(Duration(days: today.weekday - 1));
    final startOfMonth = DateTime(today.year, today.month, 1);

    String label;
    if (_dateRange.start == _dateRange.end) {
      if (_dateRange.start == today) {
        label = 'Today';
      } else if (_dateRange.start == yesterday) {
        label = 'Yesterday';
      } else {
        label = _fmtShort(_dateRange.start);
      }
    } else if (_dateRange.start == startOfWeek && _dateRange.end == today) {
      label = 'This Week';
    } else if (_dateRange.start == startOfMonth && _dateRange.end == today) {
      label = 'This Month';
    } else {
      label =
          '${_fmtShort(_dateRange.start)} – ${_fmtShort(_dateRange.end)}';
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Date range picker button
          _DateRangeButton(label: label, onTap: _pickDateRange),
          const SizedBox(width: 8),

          // Quick chips
          _QuickChip(
            label: 'Today',
            active: _dateRange.start == today && _dateRange.end == today,
            onTap: () => _setQuick(today, today),
          ),
          const SizedBox(width: 6),
          _QuickChip(
            label: 'This Week',
            active:
                _dateRange.start == startOfWeek && _dateRange.end == today,
            onTap: () => _setQuick(startOfWeek, today),
          ),
          const SizedBox(width: 6),
          _QuickChip(
            label: 'This Month',
            active:
                _dateRange.start == startOfMonth && _dateRange.end == today,
            onTap: () => _setQuick(startOfMonth, today),
          ),

          const Spacer(),

          // Search
          SizedBox(
            width: 260,
            height: 38,
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search invoice / customer…',
                prefixIcon: const Icon(Icons.search,
                    size: 16, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            size: 15, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                          _load();
                        },
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.tableBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.tableBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5)),
                filled: true,
                fillColor: AppColors.contentBg,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Refresh
          _IconBtn(
              icon: Icons.refresh_rounded, tooltip: 'Refresh', onTap: _load),
        ],
      ),
    );
  }

  String _fmtShort(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  // ── Body ──────────────────────────────────────────────────

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 12),
            Text('Loading invoices…',
                style:
                    TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Error: $_error',
                style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                  color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long_outlined,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('No invoices found',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results for "$_searchQuery"'
                  : 'No invoices in the selected date range',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ColoredBox(
      color: AppColors.contentBg,
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              itemCount: _invoices.length,
              itemBuilder: (_, i) {
                final inv = _invoices[i];
                return _InvoiceCardWithMenu(
                  invoice: inv,
                  isExpanded: _expanded.contains(inv.id),
                  onToggle: () => _toggleExpand(inv.id),
                  onContextMenu: (pos) => _showContextMenu(pos, inv),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: const Row(
        children: [
          SizedBox(width: 32),
          Expanded(flex: 3, child: Text('INVOICE NO.', style: AppTextStyles.tableHeader)),
          Expanded(flex: 3, child: Text('CUSTOMER', style: AppTextStyles.tableHeader)),
          Expanded(flex: 2, child: Text('TIME', style: AppTextStyles.tableHeader)),
          SizedBox(width: 90, child: Text('SUBTOTAL', style: AppTextStyles.tableHeader, textAlign: TextAlign.right)),
          SizedBox(width: 90, child: Text('DISCOUNT', style: AppTextStyles.tableHeader, textAlign: TextAlign.right)),
          SizedBox(width: 100, child: Text('TOTAL', style: AppTextStyles.tableHeader, textAlign: TextAlign.right)),
          SizedBox(width: 80, child: Text('MODE', style: AppTextStyles.tableHeader, textAlign: TextAlign.center)),
          SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.bar_chart_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Total Sales — ${_invoices.length} invoice${_invoices.length == 1 ? '' : 's'}',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withAlpha(60),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Text(
              _rupees(_totalSales),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Invoice card with context menu ───────────────────────────

class _InvoiceCardWithMenu extends StatelessWidget {
  final _InvoiceRow invoice;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<Offset> onContextMenu;

  const _InvoiceCardWithMenu({
    required this.invoice,
    required this.isExpanded,
    required this.onToggle,
    required this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Desktop: right-click
      onSecondaryTapUp: (d) => onContextMenu(d.globalPosition),
      // Touch: long press
      onLongPressStart: (d) => onContextMenu(d.globalPosition),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isExpanded ? AppColors.primary : AppColors.tableBorder,
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummaryRow(
              invoice: invoice,
              isExpanded: isExpanded,
              onToggle: onToggle,
            ),
            if (isExpanded) _ItemsExpansion(invoice: invoice),
          ],
        ),
      ),
    );
  }
}

// ── Summary row ───────────────────────────────────────────────

class _SummaryRow extends StatefulWidget {
  final _InvoiceRow invoice;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _SummaryRow({
    required this.invoice,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<_SummaryRow> createState() => _SummaryRowState();
}

class _SummaryRowState extends State<_SummaryRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final timeStr =
        '${inv.dateTime.hour.toString().padLeft(2, '0')}:'
        '${inv.dateTime.minute.toString().padLeft(2, '0')}';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: _hovering && !widget.isExpanded
                ? AppColors.tableRowHover
                : Colors.transparent,
            borderRadius: widget.isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(9))
                : BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              AnimatedRotation(
                duration: const Duration(milliseconds: 180),
                turns: widget.isExpanded ? 0.25 : 0,
                child: const Icon(Icons.chevron_right,
                    size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              // Invoice number
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Text(
                      inv.invoiceNo,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontFamily: 'monospace'),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: inv.invoiceNo));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Copied'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating),
                        );
                      },
                      child: const Icon(Icons.copy_outlined,
                          size: 12, color: AppColors.textDisabled),
                    ),
                  ],
                ),
              ),
              // Customer
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.person_outline,
                          size: 13, color: AppColors.primary),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        inv.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: inv.hasCustomer
                              ? AppColors.textPrimary
                              : AppColors.textDisabled,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Time
              Expanded(
                flex: 2,
                child: Text(timeStr,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ),
              // Subtotal
              SizedBox(
                width: 90,
                child: Text(
                  '₹${inv.subtotal.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary),
                ),
              ),
              // Discount
              SizedBox(
                width: 90,
                child: Text(
                  inv.discount > 0
                      ? '−₹${inv.discount.toStringAsFixed(2)}'
                      : '—',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: inv.discount > 0
                        ? AppColors.warning
                        : AppColors.textDisabled,
                    fontWeight: inv.discount > 0
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              // Total
              SizedBox(
                width: 100,
                child: Text(
                  '₹${inv.total.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
              ),
              // Mode chip
              SizedBox(
                width: 80,
                child: Center(child: _PaymentChip(mode: inv.paymentMode)),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Expanded items section ────────────────────────────────────

class _ItemsExpansion extends StatelessWidget {
  final _InvoiceRow invoice;
  const _ItemsExpansion({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final items = invoice.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        Container(
          color: AppColors.tableHeaderBg,
          padding:
              const EdgeInsets.symmetric(horizontal: 52, vertical: 7),
          child: const Row(
            children: [
              Expanded(flex: 4, child: Text('ITEM', style: AppTextStyles.tableHeader)),
              SizedBox(width: 60, child: Text('UNIT', style: AppTextStyles.tableHeader, textAlign: TextAlign.center)),
              SizedBox(width: 70, child: Text('QTY', style: AppTextStyles.tableHeader, textAlign: TextAlign.right)),
              SizedBox(width: 90, child: Text('UNIT PRICE', style: AppTextStyles.tableHeader, textAlign: TextAlign.right)),
              SizedBox(width: 100, child: Text('LINE TOTAL', style: AppTextStyles.tableHeader, textAlign: TextAlign.right)),
              SizedBox(width: 8),
            ],
          ),
        ),
        if (items == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          )
        else if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(14),
            child: Text('No items.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textDisabled),
                textAlign: TextAlign.center),
          )
        else
          ...items.asMap().entries.map((e) {
            final row = e.value;
            return _ItemRow(
              isEven: e.key.isEven,
              name: row[InvoiceItemColumns.itemName] as String,
              unit: row[InvoiceItemColumns.unit] as String,
              quantity:
                  (row[InvoiceItemColumns.quantity] as num).toDouble(),
              unitPrice:
                  (row[InvoiceItemColumns.unitPrice] as num).toDouble(),
              lineTotal:
                  (row[InvoiceItemColumns.total] as num).toDouble(),
            );
          }),
        _InvoiceTotalsBar(invoice: invoice),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final bool isEven;
  final String name;
  final String unit;
  final double quantity;
  final double unitPrice;
  final double lineTotal;

  const _ItemRow({
    required this.isEven,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isEven ? Colors.white : AppColors.tableRowOdd,
      padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 9),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(name, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 60, child: Text(unit, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          SizedBox(width: 70, child: Text(quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          SizedBox(width: 90, child: Text('₹${unitPrice.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          SizedBox(width: 100, child: Text('₹${lineTotal.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _InvoiceTotalsBar extends StatelessWidget {
  final _InvoiceRow invoice;
  const _InvoiceTotalsBar({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: AppColors.tableHeaderBg,
          borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(9))),
      padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (invoice.discount > 0) ...[
            Text('Subtotal: ₹${invoice.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(width: 16),
            Text('Discount: −₹${invoice.discount.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 16),
          ],
          Text('Total: ₹${invoice.total.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Edit invoice dialog ───────────────────────────────────────

class _EditInvoiceDialog extends StatefulWidget {
  final _InvoiceRow invoice;
  const _EditInvoiceDialog({required this.invoice});

  @override
  State<_EditInvoiceDialog> createState() => _EditInvoiceDialogState();
}

class _EditInvoiceDialogState extends State<_EditInvoiceDialog> {
  static const _modes = ['Cash', 'Card', 'Credit'];
  late String _paymentMode;
  late TextEditingController _discountCtrl;
  late TextEditingController _paidAmountCtrl;

  double get _currentDiscount =>
      double.tryParse(_discountCtrl.text.trim()) ?? 0.0;
  double get _newTotal =>
      (widget.invoice.subtotal - _currentDiscount).clamp(0.0, double.infinity);

  @override
  void initState() {
    super.initState();
    _paymentMode = widget.invoice.paymentMode;
    _discountCtrl = TextEditingController(
        text: widget.invoice.discount > 0
            ? widget.invoice.discount.toStringAsFixed(2)
            : '');
    _paidAmountCtrl = TextEditingController(
        text: widget.invoice.paidAmount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _paidAmountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit Invoice',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(widget.invoice.invoiceNo,
              style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: AppColors.primary)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info strip
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.tableHeaderBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.tableBorder),
                  ),
                  child: Row(
                    children: [
                      _InfoPill('Customer', widget.invoice.displayName),
                      const SizedBox(width: 16),
                      _InfoPill('Subtotal',
                          '₹${widget.invoice.subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Payment mode
                const Text('Payment Mode',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.6)),
                const SizedBox(height: 8),
                Row(
                  children: _modes.map((m) {
                    final sel = m == _paymentMode;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setDialogState(() => _paymentMode = m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 130),
                          margin: EdgeInsets.only(
                              right: m != _modes.last ? 6 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color:
                                sel ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.tableBorder,
                              width: sel ? 1.5 : 1,
                            ),
                          ),
                          child: Text(m,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : AppColors.textSecondary)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Discount
                const Text('Discount (₹)',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.6)),
                const SizedBox(height: 8),
                TextField(
                  controller: _discountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixText: '₹ ',
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),

                // Paid amount
                const Text('Paid Amount (₹)',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.6)),
                const SizedBox(height: 8),
                TextField(
                  controller: _paidAmountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixText: '₹ ',
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),

                // Calculated total preview
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('New Total',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                      Text(
                        '₹${_newTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
      actionsPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              _EditResult(
                paymentMode: _paymentMode,
                discount: _currentDiscount.clamp(0.0, double.infinity),
                paidAmount: double.tryParse(_paidAmountCtrl.text.trim()) ??
                    widget.invoice.paidAmount,
              ),
            );
          },
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  const _InfoPill(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

// ── Payment mode chip ─────────────────────────────────────────

class _PaymentChip extends StatelessWidget {
  final String mode;
  const _PaymentChip({required this.mode});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (mode) {
      'Cash' => (const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
      'Card' => (AppColors.primary, AppColors.primaryLight),
      'Credit' => (AppColors.warning, AppColors.warningLight),
      _ => (AppColors.textSecondary, AppColors.tableHeaderBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(mode,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3)),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────

class _DateRangeButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _DateRangeButton({required this.label, required this.onTap});

  @override
  State<_DateRangeButton> createState() => _DateRangeButtonState();
}

class _DateRangeButtonState extends State<_DateRangeButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovering ? AppColors.primary : AppColors.tableBorder,
              width: _hovering ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.date_range_outlined,
                  size: 14,
                  color: _hovering
                      ? AppColors.primary
                      : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(widget.label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _hovering
                          ? AppColors.primary
                          : AppColors.textSecondary)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down,
                  size: 16,
                  color: _hovering
                      ? AppColors.primary
                      : AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _QuickChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.tableHeaderBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: active ? AppColors.primary : AppColors.tableBorder),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    active ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _hovering
                  ? AppColors.primaryLight
                  : AppColors.tableHeaderBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _hovering
                      ? AppColors.primary
                      : AppColors.tableBorder),
            ),
            child: Icon(widget.icon,
                size: 17,
                color: _hovering
                    ? AppColors.primary
                    : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

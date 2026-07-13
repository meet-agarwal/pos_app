import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../dao/invoice_dao.dart';
import '../../database/db_constants.dart';
import '../../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _fromDateCtrl = TextEditingController();
  final _toDateCtrl = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  bool _isLoading = false;
  String? _error;

  final List<_ReportInvoiceData> _reportsData = [];
  double _totalSales = 0.0;

  // Pagination
  int _page = 0;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fromDateCtrl.text = _formatDateStr(_startDate);
    _toDateCtrl.text = _formatDateStr(_endDate);

    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _fromDateCtrl.dispose();
    _toDateCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDateStr(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  DateTime? _parseDateStr(String dateStr) {
    final parts = dateStr.trim().split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _page = 0;
      _hasMore = true;
      _reportsData.clear();
      _totalSales = 0.0;
    });

    try {
      // 1. Get total sales for the date range
      final total = await InvoiceDao.instance.getTotalSalesForDateRange(_startDate, _endDate);
      
      // 2. Fetch page 0
      final newInvoices = await _fetchPage(_page);

      if (mounted) {
        setState(() {
          _totalSales = total;
          _reportsData.addAll(newInvoices);
          _hasMore = newInvoices.length == _limit;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _page + 1;
      final newInvoices = await _fetchPage(nextPage);

      if (mounted) {
        setState(() {
          _page = nextPage;
          _reportsData.addAll(newInvoices);
          _hasMore = newInvoices.length == _limit;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<List<_ReportInvoiceData>> _fetchPage(int page) async {
    final offset = page * _limit;
    final invoiceRows = await InvoiceDao.instance.fetchReportsByDateRangePaginated(
      _startDate,
      _endDate,
      limit: _limit,
      offset: offset,
    );

    if (invoiceRows.isEmpty) return [];

    final invoiceIds = invoiceRows.map((r) => r[InvoiceColumns.id] as int).toList();
    final itemsRows = await InvoiceDao.instance.fetchItemsForInvoices(invoiceIds);

    // Group items by invoice_id
    final Map<int, List<Map<String, dynamic>>> itemsMap = {};
    for (final row in itemsRows) {
      final invId = row[InvoiceItemColumns.invoiceId] as int;
      itemsMap.putIfAbsent(invId, () => []).add(row);
    }

    // Map to _ReportInvoiceData
    return invoiceRows.map((row) {
      final id = row[InvoiceColumns.id] as int;
      return _ReportInvoiceData(
        invoiceNo: row[InvoiceColumns.invoiceNo] as String,
        discount: (row[InvoiceColumns.discount] as num).toDouble(),
        total: (row[InvoiceColumns.total] as num).toDouble(),
        items: itemsMap[id] ?? [],
      );
    }).toList();
  }

  void _applyFilter() {
    final start = _parseDateStr(_fromDateCtrl.text);
    final end = _parseDateStr(_toDateCtrl.text);

    if (start == null || end == null) {
      setState(() => _error = 'Invalid date format. Please use dd/mm/yyyy.');
      return;
    }

    if (end.isBefore(start)) {
      setState(() => _error = '"To Date" cannot be before "From Date".');
      return;
    }

    _startDate = start;
    _endDate = end;
    _loadInitialData();
  }

  // ── UI ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        _buildFilters(),
        const Divider(height: 1, color: AppColors.tableBorder),
        _buildUniversalHeader(),
        const Divider(height: 1, color: AppColors.tableBorder),
        Expanded(child: _buildTableBody()),
        const Divider(height: 1, color: AppColors.tableBorder),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      color: AppColors.screenHeaderBg,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerLeft,
      child: const Text('Sales Reports', style: AppTextStyles.screenTitle),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: AppColors.surfaceWhite,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateField('From Date', _fromDateCtrl),
          const SizedBox(width: 16),
          _buildDateField('To Date', _toDateCtrl),
          const SizedBox(width: 16),
          Container(
            margin: const EdgeInsets.only(top: 22),
            child: ElevatedButton(
              onPressed: _applyFilter,
              child: const Text('Filter Reports'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(width: 24),
            Container(
              margin: const EdgeInsets.only(top: 22),
              alignment: Alignment.centerLeft,
              child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            style: const TextStyle(fontSize: 14),
            keyboardType: TextInputType.datetime,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              hintText: 'dd/mm/yyyy',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUniversalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: AppColors.tableHeaderBg,
      child: const Row(
        children: [
          Expanded(flex: 2, child: _HeaderText('Invoice Number')),
          Expanded(flex: 3, child: _HeaderText('Item')),
          Expanded(flex: 1, child: _HeaderText('Qty', align: TextAlign.right)),
          Expanded(flex: 1, child: _HeaderText('Price', align: TextAlign.right)),
          Expanded(flex: 1, child: _HeaderText('Subtotal', align: TextAlign.right)),
          Expanded(flex: 1, child: _HeaderText('Discount', align: TextAlign.right)),
          Expanded(flex: 1, child: _HeaderText('Total', align: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildTableBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reportsData.isEmpty) {
      return const Center(
        child: Text('No invoices found for this date range.',
            style: TextStyle(color: AppColors.textDisabled, fontSize: 14)),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _reportsData.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _reportsData.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final data = _reportsData[index];
        return _buildReportRowGroup(data, index.isEven);
      },
    );
  }

  Widget _buildReportRowGroup(_ReportInvoiceData data, bool isEven) {
    return Container(
      color: isEven ? AppColors.tableRowEven : AppColors.tableRowOdd,
      child: Column(
        children: [
          // Invoice Summary Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.tableBorder, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: _BodyText(data.invoiceNo, isBold: true)),
                const Expanded(flex: 3, child: SizedBox()), // Item
                const Expanded(flex: 1, child: SizedBox()), // Qty
                const Expanded(flex: 1, child: SizedBox()), // Price
                const Expanded(flex: 1, child: SizedBox()), // Subtotal
                Expanded(flex: 1, child: _BodyText(data.discount.toStringAsFixed(2), align: TextAlign.right)), // Discount
                Expanded(flex: 1, child: _BodyText(data.total.toStringAsFixed(2), align: TextAlign.right, isBold: true)), // Total
              ],
            ),
          ),
          // Invoice Items Rows
          ...data.items.map((item) {
            final name = item[InvoiceItemColumns.itemName] as String;
            final qty = (item[InvoiceItemColumns.quantity] as num).toDouble();
            final price = (item[InvoiceItemColumns.unitPrice] as num).toDouble();
            final subtotal = (item[InvoiceItemColumns.total] as num).toDouble();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                children: [
                  const Expanded(flex: 2, child: SizedBox()), // Invoice Number
                  Expanded(flex: 3, child: Padding(
                    padding: const EdgeInsets.only(left: 16.0), // Indentation
                    child: _BodyText('- $name', color: AppColors.textSecondary),
                  )), // Item
                  Expanded(flex: 1, child: _BodyText(qty.toStringAsFixed(2), align: TextAlign.right, color: AppColors.textSecondary)), // Qty
                  Expanded(flex: 1, child: _BodyText(price.toStringAsFixed(2), align: TextAlign.right, color: AppColors.textSecondary)), // Price
                  Expanded(flex: 1, child: _BodyText(subtotal.toStringAsFixed(2), align: TextAlign.right, color: AppColors.textSecondary)), // Subtotal
                  const Expanded(flex: 1, child: SizedBox()), // Discount
                  const Expanded(flex: 1, child: SizedBox()), // Total
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('TOTAL SALES (Date Range)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          Text('₹ ${_totalSales.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _HeaderText(this.text, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        textAlign: align,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary));
  }
}

class _BodyText extends StatelessWidget {
  final String text;
  final TextAlign align;
  final bool isBold;
  final Color color;

  const _BodyText(
    this.text, {
    this.align = TextAlign.left,
    this.isBold = false,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Text(text,
        textAlign: align,
        style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: color));
  }
}

class _ReportInvoiceData {
  final String invoiceNo;
  final double discount;
  final double total;
  final List<Map<String, dynamic>> items;

  _ReportInvoiceData({
    required this.invoiceNo,
    required this.discount,
    required this.total,
    required this.items,
  });
}

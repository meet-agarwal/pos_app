// ============================================================
// customers_screen.dart
// ============================================================
// Features:
//   • Paginated table (20 per page) with customer count
//   • Live search by name or mobile (debounced)
//   • "Add Customer" button opens a creation dialog
//   • All form fields are optional
//   • Public `refresh()` method — called by AppShell on tab switch
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../../dao/customer_dao.dart';
import '../../models/customer.dart';
import '../../theme/app_theme.dart';

// ── Screen ───────────────────────────────────────────────────

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  CustomersScreenState createState() => CustomersScreenState();
}

class CustomersScreenState extends State<CustomersScreen> {
  static const _pageSize = 20;

  // ── State ─────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  int _page = 0;
  int _totalCount = 0;
  List<Customer> _customers = [];
  bool _loading = true;
  String? _error;

  // ── Computed ─────────────────────────────────────────────
  int get _totalPages => (_totalCount / _pageSize).ceil().clamp(1, 999999);
  bool get _hasPrev => _page > 0;
  bool get _hasNext => (_page + 1) < _totalPages;
  int get _startIdx => _page * _pageSize + 1;
  int get _endIdx => (_startIdx + _customers.length - 1).clamp(0, _totalCount);

  // ── Lifecycle ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadPage();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Public — called by AppShell on tab activation ─────────
  void refresh() => _loadPage(resetPage: true);

  // ── Data ──────────────────────────────────────────────────

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchCtrl.text;
          _page = 0;
        });
        _loadPage();
      }
    });
  }

  Future<void> _loadPage({bool resetPage = false}) async {
    if (!mounted) return;
    if (resetPage) setState(() => _page = 0);
    setState(() { _loading = true; _error = null; });
    try {
      final count = await CustomerDao.instance
          .getCustomerCount(search: _searchQuery);
      final customers = await CustomerDao.instance.getAllCustomers(
        page: _page,
        pageSize: _pageSize,
        search: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _totalCount = count;
          _customers = customers;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Navigation ────────────────────────────────────────────

  void _prevPage() {
    if (!_hasPrev) return;
    setState(() => _page--);
    _loadPage();
  }

  void _nextPage() {
    if (!_hasNext) return;
    setState(() => _page++);
    _loadPage();
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const Divider(height: 1),
        _buildSearchBar(),
        const Divider(height: 1),
        Expanded(child: _buildBody()),
        const Divider(height: 1),
        _buildPagination(),
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
          const Text('Customers', style: AppTextStyles.screenTitle),
          const SizedBox(width: 12),
          if (!_loading && _error == null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_totalCount customer${_totalCount == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          const Spacer(),
          // Add Customer button
          _AddButton(
            onTap: () async {
              final created = await showDialog<bool>(
                context: context,
                builder: (_) => const _AddCustomerDialog(),
              );
              if (created == true && mounted) _loadPage(resetPage: true);
            },
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by name or phone number…',
                  prefixIcon: const Icon(Icons.search,
                      size: 16, color: AppColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              size: 15, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _searchQuery = '';
                              _page = 0;
                            });
                            _loadPage();
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
          ),
          const SizedBox(width: 10),
          _IconBtn(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onTap: () => _loadPage(resetPage: true),
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 12),
            Text('Loading customers…',
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
            ElevatedButton(
                onPressed: _loadPage, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                  color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.people_outline,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('No customers found',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results for "$_searchQuery"'
                  : 'Add your first customer using the button above',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
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
              itemCount: _customers.length,
              itemBuilder: (_, i) => _CustomerRow(
                index: _startIdx + i,
                customer: _customers[i],
                isEven: i.isEven,
                onContextMenu: (pos) => _showContextMenu(pos, _customers[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: const Row(
        children: [
          SizedBox(
              width: 44,
              child: Text('#',
                  style: AppTextStyles.tableHeader,
                  textAlign: TextAlign.center)),
          Expanded(
              flex: 4,
              child: Text('NAME', style: AppTextStyles.tableHeader)),
          Expanded(
              flex: 3,
              child: Text('MOBILE', style: AppTextStyles.tableHeader)),
          SizedBox(
              width: 120,
              child: Text('OUTSTANDING DEBT',
                  style: AppTextStyles.tableHeader,
                  textAlign: TextAlign.right)),
          SizedBox(width: 16),
        ],
      ),
    );
  }

  // ── Pagination footer ─────────────────────────────────────

  Widget _buildPagination() {
    if (_loading || _error != null || _totalCount == 0) {
      return const SizedBox(height: 52);
    }

    return Container(
      height: 52,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            _customers.isEmpty
                ? 'No results'
                : 'Showing $_startIdx–$_endIdx of $_totalCount',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const Spacer(),
          // Prev
          _PaginationBtn(
            icon: Icons.chevron_left,
            enabled: _hasPrev,
            onTap: _prevPage,
          ),
          const SizedBox(width: 8),
          // Page indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Page ${_page + 1} of $_totalPages',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Next
          _PaginationBtn(
            icon: Icons.chevron_right,
            enabled: _hasNext,
            onTap: _nextPage,
          ),
        ],
      ),
    );
  }

  // ── Context Menu ──────────────────────────────────────────

  Future<void> _showContextMenu(Offset position, Customer customer) async {
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
        _menuItem('delete', Icons.delete_outline, 'Delete', color: AppColors.error),
      ],
    );
    if (!mounted) return;
    if (result == 'edit') {
      await _handleEdit(customer);
    } else if (result == 'delete') {
      await _handleDelete(customer);
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

  Future<void> _handleEdit(Customer customer) async {
    final edited = await showDialog<bool>(
      context: context,
      builder: (_) => _AddCustomerDialog(customer: customer),
    );
    if (edited == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Customer ${customer.name} updated'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      _loadPage();
    }
  }

  Future<void> _handleDelete(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Customer?',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to delete ${customer.name}? This action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      await CustomerDao.instance.deleteCustomer(customer.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Customer ${customer.name} deleted'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      _loadPage();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Delete failed: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ── Customer row ─────────────────────────────────────────────

class _CustomerRow extends StatefulWidget {
  final int index;
  final Customer customer;
  final bool isEven;
  final ValueChanged<Offset>? onContextMenu;

  const _CustomerRow({
    required this.index,
    required this.customer,
    required this.isEven,
    this.onContextMenu,
  });

  @override
  State<_CustomerRow> createState() => _CustomerRowState();
}

class _CustomerRowState extends State<_CustomerRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final hasDebt = (c.debt) > 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onSecondaryTapUp: (d) => widget.onContextMenu?.call(d.globalPosition),
        onLongPressStart: (d) => widget.onContextMenu?.call(d.globalPosition),
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.only(bottom: 3),
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
        decoration: BoxDecoration(
          color: _hovering
              ? AppColors.tableRowHover
              : widget.isEven
                  ? Colors.white
                  : AppColors.tableRowOdd,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.tableBorder),
        ),
        child: Row(
          children: [
            // Row index
            SizedBox(
              width: 44,
              child: Text(
                '${widget.index}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textDisabled),
              ),
            ),
            // Name
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _initial(c.name),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      c.name.isNotEmpty ? c.name : '—',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: c.name.isNotEmpty
                            ? AppColors.textPrimary
                            : AppColors.textDisabled,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Mobile
            Expanded(
              flex: 3,
              child: Text(
                c.mobile.isNotEmpty ? c.mobile : '—',
                style: TextStyle(
                  fontSize: 13,
                  color: c.mobile.isNotEmpty
                      ? AppColors.textPrimary
                      : AppColors.textDisabled,
                ),
              ),
            ),
            // Debt
            SizedBox(
              width: 120,
              child: Text(
                hasDebt ? '₹${c.debt.toStringAsFixed(2)}' : '—',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      hasDebt ? FontWeight.w600 : FontWeight.normal,
                  color: hasDebt
                      ? AppColors.warning
                      : AppColors.textDisabled,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
      ),
    );
  }

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }
}

// ── Add Customer dialog ───────────────────────────────────────

class _AddCustomerDialog extends StatefulWidget {
  final Customer? customer;

  const _AddCustomerDialog({this.customer});

  @override
  State<_AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<_AddCustomerDialog> {
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _debtCtrl = TextEditingController();
  bool _saving = false;
  String? _fieldError;

  bool get _isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameCtrl.text = widget.customer!.name;
      _mobileCtrl.text = widget.customer!.mobile;
      _debtCtrl.text = widget.customer!.debt > 0 ? widget.customer!.debt.toStringAsFixed(2) : '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _debtCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Soft validation — warn if both name and mobile are empty
    final name = _nameCtrl.text.trim();
    final mobile = _mobileCtrl.text.trim();
    if (name.isEmpty && mobile.isEmpty) {
      setState(() =>
          _fieldError = 'Please provide at least a name or phone number.');
      return;
    }
    if (mobile.isNotEmpty && mobile.length != 10) {
      setState(() =>
          _fieldError = 'Mobile number must be exactly 10 digits.');
      return;
    }
    setState(() { _saving = true; _fieldError = null; });
    try {
      final customer = Customer(
        id: widget.customer?.id,
        name: name,
        mobile: mobile,
        debt: double.tryParse(_debtCtrl.text.trim()) ?? 0.0,
      );
      if (_isEdit) {
        await CustomerDao.instance.updateCustomer(customer);
      } else {
        await CustomerDao.instance.insertCustomer(customer);
      }
      if (mounted) Navigator.pop(context, true);
    } on DatabaseException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _fieldError = 'Failed to save: ${e.toString()}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _fieldError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      title: Text(_isEdit ? 'Edit Customer' : 'Add New Customer',
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_fieldError != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withAlpha(80)),
                ),
                child: Text(_fieldError!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.error)),
              ),
              const SizedBox(height: 14),
            ],

            // Name
            _FieldLabel('Name', optional: true),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Customer name',
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.person_outline, size: 17),
              ),
            ),
            const SizedBox(height: 14),

            // Mobile
            _FieldLabel('Phone Number', optional: true),
            const SizedBox(height: 6),
            TextField(
              controller: _mobileCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. 9876543210',
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.phone_outlined, size: 17),
              ),
            ),
            const SizedBox(height: 14),

            // Opening debt
            _FieldLabel('Opening Debt (₹)', optional: true),
            const SizedBox(height: 6),
            TextField(
              controller: _debtCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: '0.00',
                isDense: true,
                prefixText: '₹ ',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      actionsPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(_isEdit ? 'Save Changes' : 'Add Customer'),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool optional;
  const _FieldLabel(this.text, {this.optional = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.6)),
        if (optional) ...[
          const SizedBox(width: 6),
          const Text('optional',
              style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textDisabled,
                  fontStyle: FontStyle.italic)),
        ],
      ],
    );
  }
}

// ── Shared helper widgets ─────────────────────────────────────

class _AddButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color:
                _hovering ? AppColors.primaryDark : AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                        color: AppColors.primary.withAlpha(70),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]
                : [],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text('Add Customer',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ),
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

class _PaginationBtn extends StatefulWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _PaginationBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  State<_PaginationBtn> createState() => _PaginationBtnState();
}

class _PaginationBtnState extends State<_PaginationBtn> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && _hovering;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? AppColors.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color:
                    active ? AppColors.primary : AppColors.tableBorder),
          ),
          child: Icon(widget.icon,
              size: 18,
              color: widget.enabled
                  ? active
                      ? AppColors.primary
                      : AppColors.textSecondary
                  : AppColors.textDisabled),
        ),
      ),
    );
  }
}

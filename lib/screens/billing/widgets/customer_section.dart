// ============================================================
// customer_section.dart
// ============================================================
// Customer Name + Mobile fields, each with an OverlayPortal
// autocomplete dropdown backed by CustomerDao.
// Selecting a suggestion auto-fills both fields.
// Both fields are optional — blank is perfectly valid.
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../dao/customer_dao.dart';
import '../../../models/customer.dart';
import '../../../theme/app_theme.dart';

class CustomerSection extends StatefulWidget {
  final TextEditingController nameCtrl;
  final TextEditingController mobileCtrl;

  /// Fired when a customer record is chosen from the dropdown.
  final ValueChanged<Customer?>? onCustomerSelected;

  const CustomerSection({
    super.key,
    required this.nameCtrl,
    required this.mobileCtrl,
    this.onCustomerSelected,
  });

  @override
  State<CustomerSection> createState() => _CustomerSectionState();
}

class _CustomerSectionState extends State<CustomerSection> {
  // ── Name field ────────────────────────────────────────────
  late final FocusNode _nameFocus;
  final _nameOverlay = OverlayPortalController();
  final _nameLink = LayerLink();
  final _nameKey = GlobalKey();
  List<Customer> _nameSuggestions = [];

  // ── Mobile field ──────────────────────────────────────────
  late final FocusNode _mobileFocus;
  final _mobileOverlay = OverlayPortalController();
  final _mobileLink = LayerLink();
  final _mobileKey = GlobalKey();
  List<Customer> _mobileSuggestions = [];

  Timer? _debounce;

  // ── Lifecycle ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _nameFocus = FocusNode()..addListener(_onNameFocusChange);
    _mobileFocus = FocusNode()..addListener(_onMobileFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameFocus
      ..removeListener(_onNameFocusChange)
      ..dispose();
    _mobileFocus
      ..removeListener(_onMobileFocusChange)
      ..dispose();
    super.dispose();
  }

  // ── Focus listeners ───────────────────────────────────────

  void _onNameFocusChange() {
    if (!_nameFocus.hasFocus) {
      Future.delayed(const Duration(milliseconds: 160), () {
        if (mounted && !_nameFocus.hasFocus && _nameOverlay.isShowing) {
          _nameOverlay.hide();
        }
      });
    }
  }

  void _onMobileFocusChange() {
    if (!_mobileFocus.hasFocus) {
      Future.delayed(const Duration(milliseconds: 160), () {
        if (mounted && !_mobileFocus.hasFocus && _mobileOverlay.isShowing) {
          _mobileOverlay.hide();
        }
      });
    }
  }

  // ── Search handlers ───────────────────────────────────────

  void _onNameChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      if (_nameOverlay.isShowing) _nameOverlay.hide();
      setState(() => _nameSuggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 220), () async {
      final results = await CustomerDao.instance.searchByName(query);
      if (!mounted) return;
      setState(() => _nameSuggestions = results);
      if (results.isNotEmpty) {
        if (!_nameOverlay.isShowing) _nameOverlay.show();
      } else {
        if (_nameOverlay.isShowing) _nameOverlay.hide();
      }
    });
  }

  void _onMobileChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      if (_mobileOverlay.isShowing) _mobileOverlay.hide();
      setState(() => _mobileSuggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 220), () async {
      final results = await CustomerDao.instance.searchByMobile(query);
      if (!mounted) return;
      setState(() => _mobileSuggestions = results);
      if (results.isNotEmpty) {
        if (!_mobileOverlay.isShowing) _mobileOverlay.show();
      } else {
        if (_mobileOverlay.isShowing) _mobileOverlay.hide();
      }
    });
  }

  void _selectCustomer(Customer c) {
    // Fill both fields
    widget.nameCtrl.text = c.name;
    widget.mobileCtrl.text = c.mobile;

    // Close both dropdowns
    if (_nameOverlay.isShowing) _nameOverlay.hide();
    if (_mobileOverlay.isShowing) _mobileOverlay.hide();
    setState(() {
      _nameSuggestions = [];
      _mobileSuggestions = [];
    });

    widget.onCustomerSelected?.call(c);
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.tableBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline,
              size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          const Text(
            'Customer',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          // Name field
          Expanded(child: _buildNameField()),
          const SizedBox(width: 12),
          // Mobile field
          Expanded(child: _buildMobileField()),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return OverlayPortal(
      controller: _nameOverlay,
      overlayChildBuilder: (_) => _buildOverlay(
        link: _nameLink,
        anchorKey: _nameKey,
        suggestions: _nameSuggestions,
      ),
      child: CompositedTransformTarget(
        link: _nameLink,
        child: TextField(
          key: _nameKey,
          controller: widget.nameCtrl,
          focusNode: _nameFocus,
          onChanged: _onNameChanged,
          decoration: const InputDecoration(
            hintText: 'Customer name (optional)',
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildMobileField() {
    return OverlayPortal(
      controller: _mobileOverlay,
      overlayChildBuilder: (_) => _buildOverlay(
        link: _mobileLink,
        anchorKey: _mobileKey,
        suggestions: _mobileSuggestions,
      ),
      child: CompositedTransformTarget(
        link: _mobileLink,
        child: TextField(
          key: _mobileKey,
          controller: widget.mobileCtrl,
          focusNode: _mobileFocus,
          onChanged: _onMobileChanged,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'Mobile number (optional)',
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildOverlay({
    required LayerLink link,
    required GlobalKey anchorKey,
    required List<Customer> suggestions,
  }) {
    double width = 320;
    final box =
        anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) width = box.size.width;

    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: link,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 6),
        showWhenUnlinked: false,
        child: SizedBox(
          width: width,
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(8),
            shadowColor: Colors.black.withAlpha(35),
            child: _CustomerList(
              customers: suggestions,
              onSelect: _selectCustomer,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Customer suggestion list ──────────────────────────────────

class _CustomerList extends StatelessWidget {
  final List<Customer> customers;
  final ValueChanged<Customer> onSelect;

  const _CustomerList({
    required this.customers,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.tableBorder),
      ),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: customers.length,
        itemBuilder: (_, i) => _CustomerTile(
          customer: customers[i],
          isEven: i.isEven,
          onTap: () => onSelect(customers[i]),
        ),
      ),
    );
  }
}

class _CustomerTile extends StatefulWidget {
  final Customer customer;
  final bool isEven;
  final VoidCallback onTap;

  const _CustomerTile({
    required this.customer,
    required this.isEven,
    required this.onTap,
  });

  @override
  State<_CustomerTile> createState() => _CustomerTileState();
}

class _CustomerTileState extends State<_CustomerTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          color: _hovering
              ? AppColors.tableRowHover
              : (widget.isEven ? Colors.white : AppColors.tableRowOdd),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person_outline,
                    size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.customer.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.customer.mobile,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}

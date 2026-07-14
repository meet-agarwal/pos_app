import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/item.dart';
import '../../../theme/app_theme.dart';
import 'item_search_field.dart';

class ItemEntryRow extends StatefulWidget {
  final List<Item> allItems;
  final void Function(Item item, double qty, double price) onAddItem;

  const ItemEntryRow({
    super.key,
    required this.allItems,
    required this.onAddItem,
  });

  @override
  State<ItemEntryRow> createState() => _ItemEntryRowState();
}

class _ItemEntryRowState extends State<ItemEntryRow> {
  Item? _selectedItem;

  final _searchCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  final _searchFocus = FocusNode();
  final _qtyFocus = FocusNode();
  final _priceFocus = FocusNode();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _priceCtrl.dispose();
    _searchFocus.dispose();
    _qtyFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  void _onItemSelected(Item item) {
    setState(() {
      _selectedItem = item;
      _searchCtrl.text = item.name; // Retain name
      _qtyCtrl.text = '1';
      _unitCtrl.text = item.unit;
      _priceCtrl.text = item.sellingPrice.toStringAsFixed(2);
    });
    // Move focus directly to Quantity field
    _qtyFocus.requestFocus();
    
    // Select all text in qty for quick override
    _qtyCtrl.selection = TextSelection(baseOffset: 0, extentOffset: _qtyCtrl.text.length);
  }

  void _submitItem() {
    if (_selectedItem == null) return;
    
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 1.0;
    final price = double.tryParse(_priceCtrl.text.trim()) ?? _selectedItem!.sellingPrice;
    
    if (qty > 0) {
      widget.onAddItem(_selectedItem!, qty, price);
    }
    
    // Reset state
    setState(() {
      _selectedItem = null;
    });
    _searchCtrl.clear();
    _qtyCtrl.clear();
    _unitCtrl.clear();
    _priceCtrl.clear();
    
    // Return focus to search for next item
    _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Item Search ──────────────────────────────
        Expanded(
          flex: 5,
          child: ItemSearchField(
            allItems: widget.allItems,
            onItemSelected: _onItemSelected,
            controller: _searchCtrl,
            focusNode: _searchFocus,
            clearOnSelect: false,
          ),
        ),
        const SizedBox(width: 8),

        // ── Quantity ─────────────────────────────────
        Expanded(
          flex: 1,
          child: TextField(
            controller: _qtyCtrl,
            focusNode: _qtyFocus,
            decoration: _inputDecoration('Qty'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            onSubmitted: (_) => _submitItem(),
          ),
        ),
        const SizedBox(width: 8),

        // ── Unit ─────────────────────────────────────
        Expanded(
          flex: 1,
          child: TextField(
            controller: _unitCtrl,
            readOnly: true,
            decoration: _inputDecoration('Unit').copyWith(
              fillColor: AppColors.contentBg, // visually indicate read-only
            ),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),

        // ── Price ────────────────────────────────────
        Expanded(
          flex: 2,
          child: TextField(
            controller: _priceCtrl,
            focusNode: _priceFocus,
            decoration: _inputDecoration('Price'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            onSubmitted: (_) => _submitItem(),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.tableBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.tableBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}

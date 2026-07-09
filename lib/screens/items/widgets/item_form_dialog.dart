// ============================================================
// item_form_dialog.dart
// ============================================================
// Reusable dialog for both Add and Edit item operations.
// When [item] is null → Add mode.
// When [item] is non-null → Edit mode (pre-filled fields).
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/item.dart';
import '../../../theme/app_theme.dart';

class ItemFormDialog extends StatefulWidget {
  /// Null = Add mode, non-null = Edit mode.
  final Item? item;

  const ItemFormDialog({super.key, this.item});

  /// Opens the dialog and returns the submitted [Item], or null if cancelled.
  static Future<Item?> show(BuildContext context, {Item? item}) {
    return showDialog<Item>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ItemFormDialog(item: item),
    );
  }

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _hindiNameCtrl;
  late final TextEditingController _groupNameCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _priceCtrl;

  bool get _isEditMode => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _codeCtrl      = TextEditingController(text: item?.code ?? '');
    _nameCtrl      = TextEditingController(text: item?.name ?? '');
    _hindiNameCtrl = TextEditingController(text: item?.hindiName ?? '');
    _groupNameCtrl = TextEditingController(text: item?.groupName ?? '');
    _unitCtrl      = TextEditingController(text: item?.unit ?? '');
    _priceCtrl     = TextEditingController(
        text: item != null ? item.sellingPrice.toStringAsFixed(2) : '');
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _hindiNameCtrl.dispose();
    _groupNameCtrl.dispose();
    _unitCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final item = Item(
      id:           widget.item?.id,
      code:         _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
      name:         _nameCtrl.text.trim(),
      hindiName:    _hindiNameCtrl.text.trim().isEmpty ? null : _hindiNameCtrl.text.trim(),
      groupName:    _groupNameCtrl.text.trim().isEmpty ? null : _groupNameCtrl.text.trim(),
      unit:         _unitCtrl.text.trim(),
      sellingPrice: double.parse(_priceCtrl.text.trim()),
    );
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isEditMode
                            ? Icons.edit_outlined
                            : Icons.add_box_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      _isEditMode ? 'Edit Item' : 'Add Item',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Code field (read-only in edit mode to prevent PK conflicts)
                _buildLabel('Item Code *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _codeCtrl,
                  readOnly: _isEditMode,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'e.g. A001',
                    filled: true,
                    fillColor: _isEditMode
                        ? AppColors.tableHeaderBg
                        : Colors.white,
                    suffixIcon: _isEditMode
                        ? const Tooltip(
                            message: 'Code cannot be changed after creation',
                            child: Icon(Icons.lock_outline,
                                size: 16, color: AppColors.textDisabled),
                          )
                        : null,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Item code is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Name field
                _buildLabel('Item Name *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. Basmati Rice 1kg'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Item name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Hindi Name + Group Name (both optional) — side by side
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Hindi Name (optional)'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _hindiNameCtrl,
                            decoration: const InputDecoration(
                              hintText: 'e.g. बासमती चावल',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Group (optional)'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _groupNameCtrl,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Grains, Dairy…',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),


                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Unit *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _unitCtrl,
                            decoration: const InputDecoration(
                                hintText: 'kg / pcs / bag'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Unit is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Selling Price *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}')),
                            ],
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              prefixText: '₹ ',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Price is required';
                              }
                              final price = double.tryParse(v.trim());
                              if (price == null || price < 0) {
                                return 'Enter a valid price';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: Icon(
                        _isEditMode ? Icons.save_outlined : Icons.add,
                        size: 18,
                      ),
                      label: Text(_isEditMode ? 'Save Changes' : 'Add Item'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      );
}

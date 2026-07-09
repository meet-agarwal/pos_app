// ============================================================
// invoice_item.dart
// ============================================================
// PURPOSE: Dart representation of one row in the `invoice_items`
//          table (the line-item detail of each invoice).
//
// WHY we copy item_name / unit into this table:
//   If you later edit or delete an item from the catalogue, the
//   historical invoice should still show the original name/unit.
//   This is standard denormalisation for billing systems.
// ============================================================

import '../database/db_constants.dart';

class InvoiceItem {
  final int? id;
  final int invoiceId;   // FK → invoices.id
  final int itemId;      // FK → items.id
  final String itemName; // snapshot at the time of sale
  final String unit;     // snapshot at the time of sale
  final double quantity;
  final double unitPrice;
  final double total;    // quantity * unitPrice (stored for quick reads)

  const InvoiceItem({
    this.id,
    required this.invoiceId,
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  // ── Serialisation ────────────────────────────────────────

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      InvoiceItemColumns.invoiceId: invoiceId,
      InvoiceItemColumns.itemId: itemId,
      InvoiceItemColumns.itemName: itemName,
      InvoiceItemColumns.unit: unit,
      InvoiceItemColumns.quantity: quantity,
      InvoiceItemColumns.unitPrice: unitPrice,
      InvoiceItemColumns.total: total,
    };
    if (id != null) map[InvoiceItemColumns.id] = id;
    return map;
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map[InvoiceItemColumns.id] as int?,
      invoiceId: map[InvoiceItemColumns.invoiceId] as int,
      itemId: map[InvoiceItemColumns.itemId] as int,
      itemName: map[InvoiceItemColumns.itemName] as String,
      unit: map[InvoiceItemColumns.unit] as String,
      quantity: (map[InvoiceItemColumns.quantity] as num).toDouble(),
      unitPrice: (map[InvoiceItemColumns.unitPrice] as num).toDouble(),
      total: (map[InvoiceItemColumns.total] as num).toDouble(),
    );
  }

  // ── Utility ──────────────────────────────────────────────

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    int? itemId,
    String? itemName,
    String? unit,
    double? quantity,
    double? unitPrice,
    double? total,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
    );
  }

  @override
  String toString() =>
      'InvoiceItem(id: $id, invoiceId: $invoiceId, itemName: $itemName, '
      'quantity: $quantity, unitPrice: $unitPrice, total: $total)';
}

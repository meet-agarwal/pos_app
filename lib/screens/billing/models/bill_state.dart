// ============================================================
// bill_state.dart
// ============================================================
// Per-tab data model used inside BillWorkspace.
// ============================================================

import '../../../models/item.dart';

/// A single line in a bill — wraps an [Item] with a mutable [quantity] and [price].
class BillLineItem {
  final Item item;
  double quantity;
  double price;

  BillLineItem({
    required this.item,
    this.quantity = 1.0,
    double? price,
  }) : price = price ?? item.sellingPrice;

  /// Total price for this line: price × quantity.
  double get lineTotal => price * quantity;
}

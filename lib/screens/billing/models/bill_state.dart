// ============================================================
// bill_state.dart
// ============================================================
// Per-tab data model used inside BillWorkspace.
// ============================================================

import '../../../models/item.dart';

/// A single line in a bill — wraps an [Item] with a mutable [quantity].
class BillLineItem {
  final Item item;
  double quantity;

  BillLineItem({required this.item, this.quantity = 1.0});

  /// Total price for this line: sellingPrice × quantity.
  double get lineTotal => item.sellingPrice * quantity;
}

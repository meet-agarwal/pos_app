// ============================================================
// customer.dart
// ============================================================
// PURPOSE: Dart representation of one row in the `customers` table.
// ============================================================

import '../database/db_constants.dart';

class Customer {
  final int? id;
  final String name;
  final String mobile;
  final double debt; // outstanding balance owed by the customer

  const Customer({
    this.id,
    required this.name,
    required this.mobile,
    this.debt = 0.0,
  });

  // ── Serialisation ────────────────────────────────────────

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      CustomerColumns.name: name,
      CustomerColumns.mobile: mobile,
      CustomerColumns.debt: debt,
    };
    if (id != null) map[CustomerColumns.id] = id;
    return map;
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map[CustomerColumns.id] as int?,
      name: map[CustomerColumns.name] as String,
      mobile: map[CustomerColumns.mobile] as String,
      debt: (map[CustomerColumns.debt] as num).toDouble(),
    );
  }

  // ── Utility ──────────────────────────────────────────────

  Customer copyWith({
    int? id,
    String? name,
    String? mobile,
    double? debt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      debt: debt ?? this.debt,
    );
  }

  @override
  String toString() =>
      'Customer(id: $id, name: $name, mobile: $mobile, debt: $debt)';
}

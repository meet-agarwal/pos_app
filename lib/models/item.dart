// ============================================================
// item.dart
// ============================================================
// PURPOSE: Dart representation of one row in the `items` table.
//
// PATTERN: Plain Data Class (no business logic here).
//   • toMap()   → converts the object into a Map<String,dynamic>
//                 that SQLite's insert/update methods accept.
//   • fromMap() → factory constructor that builds an Item from a
//                 Map<String,dynamic> returned by a SQLite query.
// ============================================================

import '../database/db_constants.dart';

class Item {
  final int? id;          // nullable: null before the row is inserted
  final String code;
  final String name;
  final String unit;
  final double sellingPrice;

  const Item({
    this.id,
    required this.code,
    required this.name,
    required this.unit,
    required this.sellingPrice,
  });

  // ── Serialisation ────────────────────────────────────────

  /// Converts this [Item] to a map suitable for SQLite operations.
  /// We omit [id] when it is null so that SQLite auto-generates it.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      ItemColumns.code: code,
      ItemColumns.name: name,
      ItemColumns.unit: unit,
      ItemColumns.sellingPrice: sellingPrice,
    };
    if (id != null) map[ItemColumns.id] = id;
    return map;
  }

  /// Builds an [Item] from a SQLite row map.
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map[ItemColumns.id] as int?,
      code: map[ItemColumns.code] as String,
      name: map[ItemColumns.name] as String,
      unit: map[ItemColumns.unit] as String,
      sellingPrice: (map[ItemColumns.sellingPrice] as num).toDouble(),
    );
  }

  // ── Utility ──────────────────────────────────────────────

  /// Returns a copy of this item with selected fields replaced.
  Item copyWith({
    int? id,
    String? code,
    String? name,
    String? unit,
    double? sellingPrice,
  }) {
    return Item(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      sellingPrice: sellingPrice ?? this.sellingPrice,
    );
  }

  @override
  String toString() =>
      'Item(id: $id, code: $code, name: $name, unit: $unit, sellingPrice: $sellingPrice)';
}

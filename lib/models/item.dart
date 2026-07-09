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
  final int? id;
  final String? code;       // optional — can be null or empty
  final String name;
  final String? hindiName;  // optional
  final String? groupName;  // optional
  final String unit;
  final double sellingPrice;

  const Item({
    this.id,
    this.code,
    required this.name,
    this.hindiName,
    this.groupName,
    required this.unit,
    required this.sellingPrice,
  });

  // ── Serialisation ────────────────────────────────────────

  /// Converts this [Item] to a map suitable for SQLite operations.
  /// Null / empty optional fields are stored as SQL NULL.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      ItemColumns.name: name,
      ItemColumns.unit: unit,
      ItemColumns.sellingPrice: sellingPrice,
      // Optional fields — stored as NULL when empty/null
      ItemColumns.code:      (code?.trim().isEmpty ?? true) ? null : code!.trim(),
      ItemColumns.hindiName: (hindiName?.trim().isEmpty ?? true) ? null : hindiName!.trim(),
      ItemColumns.groupName: (groupName?.trim().isEmpty ?? true) ? null : groupName!.trim(),
    };
    if (id != null) map[ItemColumns.id] = id;
    return map;
  }

  /// Builds an [Item] from a SQLite row map.
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id:           map[ItemColumns.id] as int?,
      code:         map[ItemColumns.code] as String?,
      name:         map[ItemColumns.name] as String,
      hindiName:    map[ItemColumns.hindiName] as String?,
      groupName:    map[ItemColumns.groupName] as String?,
      unit:         map[ItemColumns.unit] as String,
      sellingPrice: (map[ItemColumns.sellingPrice] as num).toDouble(),
    );
  }

  // ── Utility ──────────────────────────────────────────────

  Item copyWith({
    int? id,
    String? code,
    String? name,
    String? hindiName,
    String? groupName,
    String? unit,
    double? sellingPrice,
  }) {
    return Item(
      id:           id ?? this.id,
      code:         code ?? this.code,
      name:         name ?? this.name,
      hindiName:    hindiName ?? this.hindiName,
      groupName:    groupName ?? this.groupName,
      unit:         unit ?? this.unit,
      sellingPrice: sellingPrice ?? this.sellingPrice,
    );
  }

  @override
  String toString() =>
      'Item(id: $id, code: $code, name: $name, hindiName: $hindiName, '
      'groupName: $groupName, unit: $unit, sellingPrice: $sellingPrice)';
}


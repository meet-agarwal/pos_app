// ============================================================
// item_dao.dart  (Data Access Object)
// ============================================================
// Single Responsibility: every SQL statement that touches the
// `items` table lives here and ONLY here.
//
// Other parts of the app call these methods; they never write
// SQL directly.
// ============================================================

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../database/db_constants.dart';
import '../models/import_summary.dart';
import '../models/item.dart';

class ItemDao {
  ItemDao._();
  static final ItemDao instance = ItemDao._();

  /// Shortcut to get the open database.
  Future<Database> get _db async => DatabaseHelper.instance.database;

  // ── CREATE ────────────────────────────────────────────────

  /// Inserts [item] and returns the auto-generated row id.
  /// Throws a [DatabaseException] if the item code already exists.
  Future<int> insertItem(Item item) async {
    final db = await _db;
    return db.insert(
      TableNames.items,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // ── READ ──────────────────────────────────────────────────

  /// Returns every item, ordered alphabetically by name.
  Future<List<Item>> getAllItems() async {
    final db = await _db;
    final rows = await db.query(
      TableNames.items,
      orderBy: '${ItemColumns.name} ASC',
    );
    return rows.map(Item.fromMap).toList();
  }

  /// Returns the item whose code matches [code], or null.
  Future<Item?> getItemByCode(String code) async {
    final db = await _db;
    final rows = await db.query(
      TableNames.items,
      where: '${ItemColumns.code} = ?',
      whereArgs: [code],
      limit: 1,
    );
    return rows.isEmpty ? null : Item.fromMap(rows.first);
  }

  // ── UPDATE ────────────────────────────────────────────────

  /// Updates the item matching [item.id].
  /// Returns the number of rows affected (should be 1).
  Future<int> updateItem(Item item) async {
    assert(item.id != null, 'updateItem called without an id');
    final db = await _db;
    return db.update(
      TableNames.items,
      item.toMap(),
      where: '${ItemColumns.id} = ?',
      whereArgs: [item.id],
    );
  }

  // ── DELETE ────────────────────────────────────────────────

  /// Deletes the item with [id].
  Future<int> deleteItem(int id) async {
    final db = await _db;
    return db.delete(
      TableNames.items,
      where: '${ItemColumns.id} = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all items whose ids are in [ids].
  /// Returns the total number of deleted rows.
  Future<int> deleteItems(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final db = await _db;
    final placeholders = List.filled(ids.length, '?').join(', ');
    return db.delete(
      TableNames.items,
      where: '${ItemColumns.id} IN ($placeholders)',
      whereArgs: ids,
    );
  }

  // ── BULK IMPORT ───────────────────────────────────────────

  /// Processes a list of raw string maps parsed from an Excel file.
  ///
  /// Each map must have keys matching [ItemColumns] constants.
  /// For each row:
  ///   • If the item code already exists  → UPDATE the existing row.
  ///   • Otherwise                        → INSERT a new row.
  ///   • If validation fails              → skip and record the error.
  ///
  /// Returns an [ImportSummary] describing the outcome of every row.
  Future<ImportSummary> bulkImport(
      List<Map<String, String>> rawRows) async {
    int imported = 0;
    int updated = 0;
    int failed = 0;
    final errors = <String>[];

    final db = await _db;

    for (int i = 0; i < rawRows.length; i++) {
      final rowNum = i + 2; // +2 because row 1 is the header
      final raw = rawRows[i];

      try {
        // ── Field extraction & trim ──────────────────────
        final code      = (raw[ItemColumns.code] ?? '').trim();       // optional
        final name      = (raw[ItemColumns.name] ?? '').trim();
        final hindiName = (raw[ItemColumns.hindiName] ?? '').trim();  // optional
        final groupName = (raw[ItemColumns.groupName] ?? '').trim();  // optional
        final unit      = (raw[ItemColumns.unit] ?? '').trim();
        final priceRaw  = (raw[ItemColumns.sellingPrice] ?? '').trim();

        // ── Validation (only required fields) ────────────
        if (name.isEmpty) {
          errors.add('Row $rowNum: Item name is empty — skipped');
          failed++;
          continue;
        }
        if (unit.isEmpty) {
          errors.add('Row $rowNum: Unit is empty — skipped');
          failed++;
          continue;
        }
        final price = double.tryParse(priceRaw);
        if (price == null || price < 0) {
          errors.add(
              'Row $rowNum: Invalid selling_price "$priceRaw" — skipped');
          failed++;
          continue;
        }

        // ── Build the field map ───────────────────────────
        final fields = <String, dynamic>{
          ItemColumns.name:         name,
          ItemColumns.hindiName:    hindiName.isEmpty ? null : hindiName,
          ItemColumns.groupName:    groupName.isEmpty ? null : groupName,
          ItemColumns.unit:         unit,
          ItemColumns.sellingPrice: price,
          // Only store code when it is non-empty
          if (code.isNotEmpty) ItemColumns.code: code,
        };

        // ── Insert or Update ─────────────────────────────
        // When a code is provided, check if it already exists → update.
        // When no code is provided, always insert as a new row.
        if (code.isNotEmpty) {
          final existing = await db.query(
            TableNames.items,
            columns: [ItemColumns.id],
            where: '${ItemColumns.code} = ?',
            whereArgs: [code],
            limit: 1,
          );

          if (existing.isNotEmpty) {
            final existingId = existing.first[ItemColumns.id] as int;
            await db.update(
              TableNames.items,
              fields,
              where: '${ItemColumns.id} = ?',
              whereArgs: [existingId],
            );
            updated++;
            continue;
          }
        }

        // New row (no code, or code not found)
        await db.insert(TableNames.items, fields);
        imported++;
      } catch (e) {
        errors.add('Row $rowNum: Unexpected error — $e');
        failed++;
      }
    }

    return ImportSummary(
      totalRows: rawRows.length,
      imported: imported,
      updated: updated,
      failed: failed,
      errors: errors,
    );
  }
}

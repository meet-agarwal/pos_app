// ============================================================
// invoice_item_dao.dart  (Data Access Object)
// ============================================================
// Single Responsibility: every SQL statement that touches the
// `invoice_items` table lives here and ONLY here.
// ============================================================

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../database/db_constants.dart';
import '../models/invoice_item.dart';

class InvoiceItemDao {
  InvoiceItemDao._();
  static final InvoiceItemDao instance = InvoiceItemDao._();

  Future<Database> get _db async => DatabaseHelper.instance.database;

  // ── CREATE ────────────────────────────────────────────────

  /// Inserts all [items] in bulk.
  ///
  /// An optional [db] handle can be passed so this runs inside an
  /// existing transaction (called from BillingService).
  Future<void> insertInvoiceItems(
    List<InvoiceItem> items, {
    DatabaseExecutor? db,
  }) async {
    if (items.isEmpty) return;
    final database = db ?? await _db;
    final batch = database.batch();
    for (final item in items) {
      batch.insert(
        TableNames.invoiceItems,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }
    await batch.commit(noResult: true);
  }
}

// ============================================================
// invoice_dao.dart  (Data Access Object)
// ============================================================
// Single Responsibility: every SQL statement that touches the
// `invoices` table lives here and ONLY here.
// ============================================================

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../database/db_constants.dart';
import '../models/invoice.dart';

class InvoiceDao {
  InvoiceDao._();
  static final InvoiceDao instance = InvoiceDao._();

  Future<Database> get _db async => DatabaseHelper.instance.database;

  // ── CREATE ────────────────────────────────────────────────

  /// Inserts [invoice] and returns the auto-generated row id.
  Future<int> insertInvoice(Invoice invoice, {DatabaseExecutor? db}) async {
    final database = db ?? await _db;
    return database.insert(
      TableNames.invoices,
      invoice.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // ── INVOICE NUMBER GENERATION ─────────────────────────────

  /// Generates a human-readable, date-scoped invoice number.
  ///
  /// Format: `INV/YYMMDD/NNN`
  ///   • `YYMMDD`  — today's date (e.g. 260710 for 10 Jul 2026)
  ///   • `NNN`     — daily sequence starting at 001, incrementing per invoice
  ///
  /// Examples: INV/260710/001 → INV/260710/002 → INV/260711/001
  ///
  /// An optional [db] handle can be provided to run inside a transaction.
  Future<String> generateInvoiceNo({DatabaseExecutor? db}) async {
    final database = db ?? await _db;

    final now = DateTime.now();
    // YYMMDD — zero-padded
    final datePart =
        '${(now.year % 100).toString().padLeft(2, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';

    // Prefix used in the LIKE query (e.g. "INV/260710/")
    final prefix = 'INV/$datePart/';

    // Count how many invoices already exist for today
    final result = await database.rawQuery(
      'SELECT COUNT(*) as cnt FROM ${TableNames.invoices} '
      'WHERE ${InvoiceColumns.invoiceNo} LIKE ?',
      ['$prefix%'],
    );

    final count = (result.first['cnt'] as int?) ?? 0;
    final seq = (count + 1).toString().padLeft(3, '0');

    return '$prefix$seq';
  }

  // ── READ — DATE RANGE ────────────────────────────────────

  /// Returns invoices within [start]..[end] (inclusive) joined with customer.
  /// Optionally filtered by [search] on invoice_no, customer name or mobile.
  Future<List<Map<String, dynamic>>> fetchByDateRange(
    DateTime start,
    DateTime end, {
    String search = '',
  }) async {
    final db = await _db;
    final startStr = _fmtDate(start);
    final endStr = _fmtDate(end);
    final q = search.trim().toLowerCase();

    final rows = await db.rawQuery(
      '''
      SELECT
        i.${InvoiceColumns.id},
        i.${InvoiceColumns.invoiceNo},
        i.${InvoiceColumns.customerId},
        i.${InvoiceColumns.dateTime},
        i.${InvoiceColumns.subtotal},
        i.${InvoiceColumns.discount},
        i.${InvoiceColumns.total},
        i.${InvoiceColumns.paymentMode},
        i.${InvoiceColumns.paidAmount},
        c.${CustomerColumns.name}   AS customer_name,
        c.${CustomerColumns.mobile} AS customer_mobile
      FROM ${TableNames.invoices} i
      LEFT JOIN ${TableNames.customers} c
        ON i.${InvoiceColumns.customerId} = c.${CustomerColumns.id}
      WHERE date(i.${InvoiceColumns.dateTime}) >= ?
        AND date(i.${InvoiceColumns.dateTime}) <= ?
        ${q.isEmpty ? '' : "AND (LOWER(i.${InvoiceColumns.invoiceNo}) LIKE ? OR LOWER(COALESCE(c.${CustomerColumns.name},'')) LIKE ? OR LOWER(COALESCE(c.${CustomerColumns.mobile},'')) LIKE ?)"}
      ORDER BY i.${InvoiceColumns.id} DESC
      ''',
      [
        startStr,
        endStr,
        if (q.isNotEmpty) '%$q%',
        if (q.isNotEmpty) '%$q%',
        if (q.isNotEmpty) '%$q%',
      ],
    );
    return rows;
  }

  /// Returns all invoice_items rows for [invoiceId].
  Future<List<Map<String, dynamic>>> fetchItemsForInvoice(
      int invoiceId) async {
    final db = await _db;
    return db.query(
      TableNames.invoiceItems,
      where: '${InvoiceItemColumns.invoiceId} = ?',
      whereArgs: [invoiceId],
      orderBy: InvoiceItemColumns.id,
    );
  }

  // ── UPDATE ────────────────────────────────────────────────

  /// Patches payment_mode, discount, total (recalculated), and paid_amount.
  Future<void> updateInvoice({
    required int id,
    required String paymentMode,
    required double discount,
    required double subtotal,
    required double paidAmount,
  }) async {
    final total = (subtotal - discount).clamp(0.0, double.infinity);
    final db = await _db;
    await db.update(
      TableNames.invoices,
      {
        InvoiceColumns.paymentMode: paymentMode,
        InvoiceColumns.discount: discount,
        InvoiceColumns.total: total,
        InvoiceColumns.paidAmount: paidAmount,
      },
      where: '${InvoiceColumns.id} = ?',
      whereArgs: [id],
    );
  }

  // ── DELETE ────────────────────────────────────────────────

  /// Deletes the invoice and all its line items inside a single transaction.
  Future<void> deleteInvoice(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        TableNames.invoiceItems,
        where: '${InvoiceItemColumns.invoiceId} = ?',
        whereArgs: [id],
      );
      await txn.delete(
        TableNames.invoices,
        where: '${InvoiceColumns.id} = ?',
        whereArgs: [id],
      );
    });
  }

  // ── Helpers ───────────────────────────────────────────────

  /// Formats [d] as `YYYY-MM-DD` for SQLite `date()` comparisons.
  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

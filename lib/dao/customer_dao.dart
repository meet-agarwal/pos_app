// ============================================================
// customer_dao.dart  (Data Access Object)
// ============================================================
// Single Responsibility: every SQL statement that touches the
// `customers` table lives here and ONLY here.
// ============================================================

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../database/db_constants.dart';
import '../models/customer.dart';

class CustomerDao {
  CustomerDao._();
  static final CustomerDao instance = CustomerDao._();

  Future<Database> get _db async => DatabaseHelper.instance.database;

  // ── SEARCH ───────────────────────────────────────────────

  /// Returns customers whose name contains [query] (case-insensitive).
  /// Returns an empty list when [query] is blank or no rows match.
  Future<List<Customer>> searchByName(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final db = await _db;
    final rows = await db.query(
      TableNames.customers,
      where: 'LOWER(${CustomerColumns.name}) LIKE ?',
      whereArgs: ['%${q.toLowerCase()}%'],
      orderBy: CustomerColumns.name,
      limit: 8,
    );
    return rows.map(Customer.fromMap).toList();
  }

  /// Returns customers whose mobile number contains [query].
  /// Returns an empty list when [query] is blank or no rows match.
  Future<List<Customer>> searchByMobile(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final db = await _db;
    final rows = await db.query(
      TableNames.customers,
      where: '${CustomerColumns.mobile} LIKE ?',
      whereArgs: ['%$q%'],
      orderBy: CustomerColumns.mobile,
      limit: 8,
    );
    return rows.map(Customer.fromMap).toList();
  }

  // ── INSERT / FETCH ───────────────────────────────────────

  /// Resolves the customer to link to an invoice.
  ///
  /// Rules:
  ///   • Both [name] and [mobile] blank → returns `null` (anonymous walk-in).
  ///   • [mobile] provided (name optional) → if a row with that mobile already
  ///     exists, returns its id; otherwise inserts a new row and returns the id.
  ///   • [name] provided without mobile → always inserts a new row (no de-dup
  ///     key available) and returns the new id.
  Future<int?> insertOrFetchCustomer({
    required String name,
    required String mobile,
  }) async {
    final n = name.trim();
    final m = mobile.trim();

    // Anonymous walk-in — no customer record needed
    if (n.isEmpty && m.isEmpty) return null;

    final db = await _db;

    // If a mobile is provided, try to find an existing record first
    if (m.isNotEmpty) {
      final existing = await db.query(
        TableNames.customers,
        columns: [CustomerColumns.id],
        where: '${CustomerColumns.mobile} = ?',
        whereArgs: [m],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return existing.first[CustomerColumns.id] as int;
      }
    }

    // Insert a new customer row
    final id = await db.insert(
      TableNames.customers,
      {
        CustomerColumns.name: n,
        CustomerColumns.mobile: m,
        CustomerColumns.debt: 0.0,
      },
    );
    return id;
  }
}

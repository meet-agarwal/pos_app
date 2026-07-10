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
}

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

    // If a mobile is provided, it's the primary identifier. Try to find an existing record first.
    if (m.isNotEmpty) {
      final existing = await db.query(
        TableNames.customers,
        columns: [CustomerColumns.id, CustomerColumns.name],
        where: '${CustomerColumns.mobile} = ?',
        whereArgs: [m],
        limit: 1,
      );
      
      if (existing.isNotEmpty) {
        final existingId = existing.first[CustomerColumns.id] as int;
        final existingName = existing.first[CustomerColumns.name] as String?;
        
        // If the user provided a name and it differs from the existing name, update it.
        if (n.isNotEmpty && n != existingName) {
          await db.update(
            TableNames.customers,
            {CustomerColumns.name: n},
            where: '${CustomerColumns.id} = ?',
            whereArgs: [existingId],
          );
        }
        
        return existingId;
      }
    }

    // Insert a new customer row (either mobile not found, or only name provided)
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

  // ── PAGINATED READ ────────────────────────────────────────

  /// Returns one page of customers, optionally filtered by [search]
  /// (matches name or mobile, case-insensitive).
  Future<List<Customer>> getAllCustomers({
    int page = 0,
    int pageSize = 20,
    String search = '',
  }) async {
    final db = await _db;
    final q = search.trim().toLowerCase();
    String where = '';
    List<dynamic> args = [];
    if (q.isNotEmpty) {
      where =
          'WHERE LOWER(${CustomerColumns.name}) LIKE ? OR ${CustomerColumns.mobile} LIKE ?';
      args = ['%$q%', '%$q%'];
    }
    final rows = await db.rawQuery(
      'SELECT * FROM ${TableNames.customers} $where '
      'ORDER BY ${CustomerColumns.name} ASC '
      'LIMIT ? OFFSET ?',
      [...args, pageSize, page * pageSize],
    );
    return rows.map(Customer.fromMap).toList();
  }

  /// Returns the total count of customers matching [search].
  Future<int> getCustomerCount({String search = ''}) async {
    final db = await _db;
    final q = search.trim().toLowerCase();
    String where = '';
    List<dynamic> args = [];
    if (q.isNotEmpty) {
      where =
          'WHERE LOWER(${CustomerColumns.name}) LIKE ? OR ${CustomerColumns.mobile} LIKE ?';
      args = ['%$q%', '%$q%'];
    }
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM ${TableNames.customers} $where',
      args,
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  /// Inserts a new customer and returns the auto-generated row id.
  Future<int> insertCustomer(Customer customer) async {
    final db = await _db;
    return db.insert(
      TableNames.customers,
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Updates an existing customer.
  Future<void> updateCustomer(Customer customer) async {
    if (customer.id == null) return;
    final db = await _db;
    await db.update(
      TableNames.customers,
      customer.toMap(),
      where: '${CustomerColumns.id} = ?',
      whereArgs: [customer.id],
    );
  }

  /// Deletes a customer by their ID.
  Future<void> deleteCustomer(int id) async {
    final db = await _db;
    await db.delete(
      TableNames.customers,
      where: '${CustomerColumns.id} = ?',
      whereArgs: [id],
    );
  }

  /// Fetches a single customer by their ID. Returns null if not found.
  Future<Customer?> getCustomerById(int id) async {
    final db = await _db;
    final rows = await db.query(
      TableNames.customers,
      where: '${CustomerColumns.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return Customer.fromMap(rows.first);
    }
    return null;
  }
}

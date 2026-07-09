// ============================================================
// database_helper.dart
// ============================================================
// PURPOSE: Single Responsibility — open the database, create /
//          upgrade the schema, and expose the raw Database object.
//
// PATTERN: Singleton
//   Only ONE connection to the database file should ever exist at
//   a time.  The singleton pattern guarantees this: the first call
//   to DatabaseHelper.instance opens the file; every subsequent
//   call returns the already-open connection.
//
// USAGE:
//   final db = await DatabaseHelper.instance.database;
//   await db.insert(TableNames.items, item.toMap(), ...);
// ============================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'db_constants.dart';

class DatabaseHelper {
  // ── Singleton boilerplate ────────────────────────────────

  /// The one and only instance.
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  /// Private constructor — prevents `DatabaseHelper()` from outside.
  DatabaseHelper._privateConstructor();

  /// Cached database connection.  Null until the first call to [database].
  Database? _db;

  // ── Public accessor ──────────────────────────────────────

  /// Returns the open database, initialising it on first call.
  Future<Database> get database async {
    // Return existing connection if already open
    if (_db != null) return _db!;

    // Otherwise open (or create) the database file
    _db = await _initDatabase();
    return _db!;
  }

  // ── Initialisation ───────────────────────────────────────

  /// Resolves the database file path and opens it.
  Future<Database> _initDatabase() async {
    // getDatabasesPath() returns the platform-appropriate directory
    // (e.g. /data/data/<app>/databases/ on Android)
    final dbPath = await getDatabasesPath();

    // join() safely combines path segments across all OSes
    final path = join(dbPath, kDatabaseName);

    return await openDatabase(
      path,
      version: kDatabaseVersion,
      onCreate: _onCreate,     // called when the file doesn't exist yet
      onUpgrade: _onUpgrade,   // called when kDatabaseVersion is bumped
      // Enable foreign key enforcement (OFF by default in SQLite)
      onConfigure: _onConfigure,
    );
  }

  // ── Schema configuration ─────────────────────────────────

  /// Runs once per database connection to enable PRAGMA settings.
  Future<void> _onConfigure(Database db) async {
    // Foreign keys are disabled by default in SQLite — this line enables them
    // so that invalid customer_id / invoice_id values are rejected.
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Called when the database file is first created.
  /// Creates all four tables in dependency order (parent tables first).
  Future<void> _onCreate(Database db, int version) async {
    await _createItemsTable(db);
    await _createCustomersTable(db);
    await _createInvoicesTable(db);
    await _createInvoiceItemsTable(db);
  }

  /// Called when [kDatabaseVersion] is increased.
  /// Add ALTER TABLE statements here when you change the schema later.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Example for a future migration from v1 → v2:
    // if (oldVersion < 2) {
    //   await db.execute(
    //     'ALTER TABLE ${TableNames.items} ADD COLUMN barcode TEXT',
    //   );
    // }
  }

  // ── Table creation helpers ───────────────────────────────
  // Each table gets its own private method so that _onCreate stays clean
  // and individual tables are easy to find and modify.

  /// Creates the `items` table.
  Future<void> _createItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${TableNames.items} (
        ${ItemColumns.id}           INTEGER PRIMARY KEY AUTOINCREMENT,
        ${ItemColumns.code}         TEXT    NOT NULL UNIQUE,
        ${ItemColumns.name}         TEXT    NOT NULL,
        ${ItemColumns.unit}         TEXT    NOT NULL,
        ${ItemColumns.sellingPrice} REAL    NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Creates the `customers` table.
  Future<void> _createCustomersTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${TableNames.customers} (
        ${CustomerColumns.id}     INTEGER PRIMARY KEY AUTOINCREMENT,
        ${CustomerColumns.name}   TEXT    NOT NULL,
        ${CustomerColumns.mobile} TEXT    NOT NULL,
        ${CustomerColumns.debt}   REAL    NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Creates the `invoices` table.
  Future<void> _createInvoicesTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${TableNames.invoices} (
        ${InvoiceColumns.id}          INTEGER PRIMARY KEY AUTOINCREMENT,
        ${InvoiceColumns.invoiceNo}   TEXT    NOT NULL UNIQUE,
        ${InvoiceColumns.customerId}  INTEGER NOT NULL,
        ${InvoiceColumns.dateTime}    TEXT    NOT NULL,
        ${InvoiceColumns.subtotal}    REAL    NOT NULL DEFAULT 0,
        ${InvoiceColumns.discount}    REAL    NOT NULL DEFAULT 0,
        ${InvoiceColumns.total}       REAL    NOT NULL DEFAULT 0,
        ${InvoiceColumns.paymentMode} TEXT    NOT NULL,
        ${InvoiceColumns.paidAmount}  REAL    NOT NULL DEFAULT 0,
        FOREIGN KEY (${InvoiceColumns.customerId})
          REFERENCES ${TableNames.customers} (${CustomerColumns.id})
      )
    ''');
  }

  /// Creates the `invoice_items` table.
  Future<void> _createInvoiceItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${TableNames.invoiceItems} (
        ${InvoiceItemColumns.id}        INTEGER PRIMARY KEY AUTOINCREMENT,
        ${InvoiceItemColumns.invoiceId} INTEGER NOT NULL,
        ${InvoiceItemColumns.itemId}    INTEGER NOT NULL,
        ${InvoiceItemColumns.itemName}  TEXT    NOT NULL,
        ${InvoiceItemColumns.unit}      TEXT    NOT NULL,
        ${InvoiceItemColumns.quantity}  REAL    NOT NULL DEFAULT 1,
        ${InvoiceItemColumns.unitPrice} REAL    NOT NULL DEFAULT 0,
        ${InvoiceItemColumns.total}     REAL    NOT NULL DEFAULT 0,
        FOREIGN KEY (${InvoiceItemColumns.invoiceId})
          REFERENCES ${TableNames.invoices} (${InvoiceColumns.id}),
        FOREIGN KEY (${InvoiceItemColumns.itemId})
          REFERENCES ${TableNames.items} (${ItemColumns.id})
      )
    ''');
  }

  // ── Utility ──────────────────────────────────────────────

  /// Closes the database connection.
  /// Call this only when the app is fully shutting down.
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}

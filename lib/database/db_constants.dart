// ============================================================
// db_constants.dart
// ============================================================
// PURPOSE: Single source of truth for every table name and
//          column name used in the SQLite database.
//
// WHY:     Using bare strings like 'customer_id' scattered across
//          the codebase causes silent bugs (typo = runtime crash).
//          Centralising them here means:
//            • A typo is caught by the Dart analyser.
//            • Renaming a column = change ONE constant, not 50 strings.
// ============================================================

/// The SQLite database file name.
const String kDatabaseName = 'pos_database.db';

/// Current schema version.  Bump this when you add/alter tables.
const int kDatabaseVersion = 1;

// ── Table Names ─────────────────────────────────────────────

class TableNames {
  TableNames._(); // prevent instantiation – pure namespace

  static const String items = 'items';
  static const String customers = 'customers';
  static const String invoices = 'invoices';
  static const String invoiceItems = 'invoice_items';
}

// ── Column Names: Items ─────────────────────────────────────

class ItemColumns {
  ItemColumns._();

  static const String id = 'id';
  static const String code = 'code';
  static const String name = 'name';
  static const String unit = 'unit';
  static const String sellingPrice = 'selling_price';
}

// ── Column Names: Customers ─────────────────────────────────

class CustomerColumns {
  CustomerColumns._();

  static const String id = 'id';
  static const String name = 'name';
  static const String mobile = 'mobile';
  static const String debt = 'debt';
}

// ── Column Names: Invoices ───────────────────────────────────

class InvoiceColumns {
  InvoiceColumns._();

  static const String id = 'id';
  static const String invoiceNo = 'invoice_no';
  static const String customerId = 'customer_id';
  static const String dateTime = 'date_time';
  static const String subtotal = 'subtotal';
  static const String discount = 'discount';
  static const String total = 'total';
  static const String paymentMode = 'payment_mode';
  static const String paidAmount = 'paid_amount';
}

// ── Column Names: Invoice Items ──────────────────────────────

class InvoiceItemColumns {
  InvoiceItemColumns._();

  static const String id = 'id';
  static const String invoiceId = 'invoice_id';
  static const String itemId = 'item_id';
  static const String itemName = 'item_name';
  static const String unit = 'unit';
  static const String quantity = 'quantity';
  static const String unitPrice = 'unit_price';
  static const String total = 'total';
}

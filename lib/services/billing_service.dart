// ============================================================
// billing_service.dart
// ============================================================
// PURPOSE: Orchestrates the full "save bill" workflow in the
//          correct dependency order:
//
//   1. insertOrFetchCustomer  → int? customerId
//   2. generateInvoiceNo      → String invoiceNo
//   3. db.transaction:
//      a. insertInvoice(customerId, invoiceNo, ...)  → invoiceId
//      b. insertInvoiceItems(invoiceId, lineItems)
//
// Steps 3a and 3b run inside a single SQLite transaction so that
// a partial failure (e.g. item insert error) rolls back the
// invoice row too, keeping the database consistent.
//
// USAGE:
//   final invoiceNo = await BillingService.instance.saveBill(...);
// ============================================================

import 'package:sqflite/sqflite.dart';

import '../dao/customer_dao.dart';
import '../dao/invoice_dao.dart';
import '../dao/invoice_item_dao.dart';
import '../database/database_helper.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../screens/billing/models/bill_state.dart';

class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  // ── Save Bill ─────────────────────────────────────────────

  /// Persists a complete bill and returns the human-readable invoice number.
  ///
  /// Parameters:
  ///   [customerName]   — from the customer name field (may be empty).
  ///   [customerMobile] — from the mobile field (may be empty).
  ///   [lineItems]      — the cart items; must be non-empty.
  ///   [subtotal]       — sum of all line totals before discount.
  ///   [discount]       — discount amount (≥ 0).
  ///   [total]          — subtotal − discount (clamped to 0).
  ///   [paymentMode]    — e.g. 'Cash', 'Card', 'Credit'.
  ///   [paidAmount]     — amount actually paid now.
  ///
  /// Throws [ArgumentError] if [lineItems] is empty.
  /// Throws [DatabaseException] on any DB error (caller should catch).
  Future<String> saveBill({
    required String customerName,
    required String customerMobile,
    required List<BillLineItem> lineItems,
    required double subtotal,
    required double discount,
    required double total,
    required String paymentMode,
    required double paidAmount,
  }) async {
    if (lineItems.isEmpty) {
      throw ArgumentError('Cannot save a bill with no items.');
    }

    // ── Step 1: resolve customer ──────────────────────────
    final int? customerId = await CustomerDao.instance.insertOrFetchCustomer(
      name: customerName,
      mobile: customerMobile,
    );

    // ── Step 2 + 3: invoice number + atomic insert ────────
    final db = await DatabaseHelper.instance.database;

    // Generate the invoice number BEFORE the transaction so the
    // LIKE query runs on the live table (not inside an uncommitted tx).
    final invoiceNo = await InvoiceDao.instance.generateInvoiceNo(db: db);

    String savedInvoiceNo = invoiceNo;

    await db.transaction((txn) async {
      // 3a — Insert invoice
      final invoice = Invoice(
        invoiceNo: invoiceNo,
        customerId: customerId,
        dateTime: DateTime.now(),
        subtotal: subtotal,
        discount: discount,
        total: total,
        paymentMode: paymentMode,
        paidAmount: paidAmount,
      );

      final invoiceId = await InvoiceDao.instance.insertInvoice(
        invoice,
        db: txn,
      );

      // 3b — Build InvoiceItem list with the real invoiceId
      final invoiceItems = lineItems.map((li) {
        return InvoiceItem(
          invoiceId: invoiceId,
          itemId: li.item.id!,
          itemName: li.item.name,
          unit: li.item.unit,
          quantity: li.quantity,
          unitPrice: li.item.sellingPrice,
          total: li.lineTotal,
        );
      }).toList();

      // 3c — Bulk insert items
      await InvoiceItemDao.instance.insertInvoiceItems(
        invoiceItems,
        db: txn,
      );
    });

    return savedInvoiceNo;
  }

  // ── Update Bill ───────────────────────────────────────────

  /// Updates an existing bill in place, keeping its invoiceId and invoiceNo.
  /// 
  /// Deletes existing invoice_items and bulk inserts the new ones to handle
  /// additions/removals/modifications easily.
  Future<void> updateFullBill({
    required int invoiceId,
    required String customerName,
    required String customerMobile,
    required List<BillLineItem> lineItems,
    required double subtotal,
    required double discount,
    required double total,
    required String paymentMode,
    required double paidAmount,
  }) async {
    if (lineItems.isEmpty) {
      throw ArgumentError('Cannot save a bill with no items.');
    }

    // ── Step 1: resolve customer ──────────────────────────
    final int? customerId = await CustomerDao.instance.insertOrFetchCustomer(
      name: customerName,
      mobile: customerMobile,
    );

    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      // 1. Update invoice row
      await txn.update(
        'invoices',
        {
          'customer_id': customerId,
          'subtotal': subtotal,
          'discount': discount,
          'total': total,
          'payment_mode': paymentMode,
          'paid_amount': paidAmount,
        },
        where: 'id = ?',
        whereArgs: [invoiceId],
      );

      // 2. Delete all existing items
      await txn.delete(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );

      // 3. Insert new items
      final invoiceItems = lineItems.map((li) {
        return InvoiceItem(
          invoiceId: invoiceId,
          itemId: li.item.id!,
          itemName: li.item.name,
          unit: li.item.unit,
          quantity: li.quantity,
          unitPrice: li.item.sellingPrice,
          total: li.lineTotal,
        );
      }).toList();

      await InvoiceItemDao.instance.insertInvoiceItems(
        invoiceItems,
        db: txn,
      );
    });
  }

}

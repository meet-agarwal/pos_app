// ============================================================
// invoice.dart
// ============================================================
// PURPOSE: Dart representation of one row in the `invoices` table.
//
// NOTE on dateTime: We store it as an ISO-8601 string in SQLite
// (SQLite has no native DateTime type) and parse it back on read.
// ============================================================

import '../database/db_constants.dart';

class Invoice {
  final int? id;
  final String invoiceNo;
  final int? customerId;      // FK → customers.id  (null = anonymous walk-in)
  final DateTime dateTime;
  final double subtotal;
  final double discount;
  final double total;
  final String paymentMode;   // e.g. 'Cash', 'Card', 'Credit'
  final double paidAmount;

  const Invoice({
    this.id,
    required this.invoiceNo,
    this.customerId,
    required this.dateTime,
    required this.subtotal,
    this.discount = 0.0,
    required this.total,
    required this.paymentMode,
    required this.paidAmount,
  });

  // ── Serialisation ────────────────────────────────────────

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      InvoiceColumns.invoiceNo: invoiceNo,
      if (customerId != null) InvoiceColumns.customerId: customerId,
      // Store as ISO-8601 string for portability
      InvoiceColumns.dateTime: dateTime.toIso8601String(),
      InvoiceColumns.subtotal: subtotal,
      InvoiceColumns.discount: discount,
      InvoiceColumns.total: total,
      InvoiceColumns.paymentMode: paymentMode,
      InvoiceColumns.paidAmount: paidAmount,
    };
    if (id != null) map[InvoiceColumns.id] = id;
    return map;
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map[InvoiceColumns.id] as int?,
      invoiceNo: map[InvoiceColumns.invoiceNo] as String,
      customerId: map[InvoiceColumns.customerId] as int?,
      dateTime: DateTime.parse(map[InvoiceColumns.dateTime] as String),
      subtotal: (map[InvoiceColumns.subtotal] as num).toDouble(),
      discount: (map[InvoiceColumns.discount] as num).toDouble(),
      total: (map[InvoiceColumns.total] as num).toDouble(),
      paymentMode: map[InvoiceColumns.paymentMode] as String,
      paidAmount: (map[InvoiceColumns.paidAmount] as num).toDouble(),
    );
  }

  // ── Utility ──────────────────────────────────────────────

  // Sentinel so copyWith can distinguish "pass null" from "not provided".
  static const Object _sentinel = Object();

  Invoice copyWith({
    int? id,
    String? invoiceNo,
    Object? customerId = _sentinel,
    DateTime? dateTime,
    double? subtotal,
    double? discount,
    double? total,
    String? paymentMode,
    double? paidAmount,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      customerId: customerId == _sentinel
          ? this.customerId
          : customerId as int?,
      dateTime: dateTime ?? this.dateTime,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMode: paymentMode ?? this.paymentMode,
      paidAmount: paidAmount ?? this.paidAmount,
    );
  }

  @override
  String toString() =>
      'Invoice(id: $id, invoiceNo: $invoiceNo, customerId: $customerId, '
      'total: $total, paymentMode: $paymentMode)';
}


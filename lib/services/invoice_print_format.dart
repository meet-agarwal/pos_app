import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/invoice.dart';
import '../screens/billing/models/bill_state.dart';

class InvoicePrintFormat {
  InvoicePrintFormat._();

  static const _fontAsset = 'assets/fonts/NotoSansDevanagari-Regular.ttf';

  static Future<Uint8List> generateReceipt({
    required Invoice invoice,
    required List<BillLineItem> lineItems,
    String? customerName,
    String? customerMobile,
  }) async {
    final pdf = pw.Document();
    final style = pw.TextStyle(
      font: pw.Font.ttf(await rootBundle.load(_fontAsset)),
      fontSize: 8,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll57,
        margin: const pw.EdgeInsets.all(8),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Invoice No: ${invoice.invoiceNo}', style: style),
            pw.Text('Date: ${invoice.dateTime.toString().split('.')[0]}', style: style),
            if (customerName != null && customerName.isNotEmpty)
              pw.Text('Customer: $customerName', style: style),
            if (customerMobile != null && customerMobile.isNotEmpty)
              pw.Text('Mobile: $customerMobile', style: style),
            pw.SizedBox(height: 8),
            for (final line in lineItems) ...[
              pw.Text(_itemName(line), style: style),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${line.quantity.toStringAsFixed(2)} x ${line.item.sellingPrice.toStringAsFixed(2)}', style: style),
                  pw.Text((line.quantity * line.item.sellingPrice).toStringAsFixed(2), style: style),
                ],
              ),
              pw.SizedBox(height: 4),
            ],
            if (invoice.discount > 0)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Discount', style: style),
                  pw.Text('-${invoice.discount.toStringAsFixed(2)}', style: style),
                ],
              ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total', style: style),
                pw.Text(invoice.total.toStringAsFixed(2), style: style),
              ],
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static String _itemName(BillLineItem line) {
    final hindi = line.item.hindiName?.trim();
    return hindi != null && hindi.isNotEmpty ? '$hindi (${line.item.name})' : line.item.name;
  }
}

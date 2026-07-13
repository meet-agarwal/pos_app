import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/invoice.dart';
import '../screens/billing/models/bill_state.dart';

class InvoicePrintFormat {
  InvoicePrintFormat._();

  static Future<Uint8List> generateReceipt({
    required Invoice invoice,
    required List<BillLineItem> lineItems,
    String? customerName,
    String? customerMobile,
  }) async {
    final pdf = pw.Document();

    // Use NotoSansDevanagari to correctly render Hindi text
    final font = await PdfGoogleFonts.notoSansDevanagariRegular();

    // PdfPageFormat.roll57 is standard for 58mm thermal printers (approx 164 points width)
    final format = PdfPageFormat.roll57;

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(8), // Small margin for roll paper
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Invoice No: ${invoice.invoiceNo}', style: pw.TextStyle(font: font, fontSize: 8)),
              // Format date nicely
              pw.Text('Date: ${invoice.dateTime.toString().split('.')[0]}', style: pw.TextStyle(font: font, fontSize: 8)),
              if (customerName != null && customerName.isNotEmpty)
                pw.Text('Customer: $customerName', style: pw.TextStyle(font: font, fontSize: 8)),
              if (customerMobile != null && customerMobile.isNotEmpty)
                pw.Text('Mobile: $customerMobile', style: pw.TextStyle(font: font, fontSize: 8)),
              pw.SizedBox(height: 4),
              _buildSeparator(font),
              pw.SizedBox(height: 4),
              
              // Table Header
              pw.Row(
                children: [
                  pw.Expanded(flex: 1, child: pw.Text('#', style: pw.TextStyle(font: font, fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 4, child: pw.Text('Item', style: pw.TextStyle(font: font, fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text('Qty', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font, fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font, fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 3, child: pw.Text('Sub', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font, fontSize: 8, fontWeight: pw.FontWeight.bold))),
                ],
              ),
              pw.SizedBox(height: 4),
              _buildSeparator(font),
              pw.SizedBox(height: 4),
              
              // Items
              ...List.generate(lineItems.length, (index) {
                final item = lineItems[index];
                
                // Fallback to English name if Hindi name is empty
                final hindiName = (item.item.hindiName?.trim().isNotEmpty == true) ? item.item.hindiName! : item.item.name;
                final englishName = item.item.name;
                
                final qty = item.quantity;
                final price = item.item.sellingPrice;
                final subtotal = qty * price;
                
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Serial Number
                        pw.Expanded(flex: 1, child: pw.Text('${index + 1}', style: pw.TextStyle(font: font, fontSize: 8))),
                        // Item Name (Hindi first, then English in parentheses)
                        pw.Expanded(
                          flex: 11,
                          child: pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(text: hindiName, style: pw.TextStyle(font: font, fontSize: 8)),
                                pw.TextSpan(text: ' ($englishName)', style: pw.TextStyle(font: font, fontSize: 8)),
                              ],
                            ),
                            maxLines: 1, // Ensures it stays on one line
                            overflow: pw.TextOverflow.clip, // Truncates the English name if it overflows
                          ),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Expanded(flex: 5, child: pw.SizedBox()), // Empty space under Item Name
                        pw.Expanded(flex: 2, child: pw.Text(qty.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font, fontSize: 8))),
                        pw.Expanded(flex: 2, child: pw.Text(price.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font, fontSize: 8))),
                        pw.Expanded(flex: 3, child: pw.Text(subtotal.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font, fontSize: 8))),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                  ]
                );
              }),
              
              _buildSeparator(font),
              pw.SizedBox(height: 4),
              
              // Totals Section
              if (invoice.discount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount:', style: pw.TextStyle(font: font, fontSize: 8)),
                    pw.Text('-${invoice.discount.toStringAsFixed(2)}', style: pw.TextStyle(font: font, fontSize: 8)),
                  ]
                ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL:', style: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(invoice.total.toStringAsFixed(2), style: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ]
              ),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Text('Thank you!', style: pw.TextStyle(font: font, fontSize: 8)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSeparator(pw.Font font) {
    return pw.Text(
      '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',
      style: pw.TextStyle(font: font, fontSize: 8),
      maxLines: 1,
      overflow: pw.TextOverflow.clip,
    );
  }
}

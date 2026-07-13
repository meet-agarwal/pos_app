import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/invoice.dart';
import '../screens/billing/models/bill_state.dart';
import 'invoice_print_format.dart';

class PrinterService {
  PrinterService._();
  static final PrinterService instance = PrinterService._();

  static const String _defaultPrinterKey = 'default_printer_url';

  /// Lists all printers available on the current Windows system.
  Future<List<Printer>> getAvailablePrinters() async {
    return await Printing.listPrinters();
  }

  /// Returns the URL (unique identifier) of the default thermal printer, or null if none is set.
  Future<String?> getDefaultPrinterUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultPrinterKey);
  }

  /// Saves the URL of the default thermal printer.
  Future<void> setDefaultPrinterUrl(String printerUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultPrinterKey, printerUrl);
  }

  /// Clears the default printer.
  Future<void> clearDefaultPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_defaultPrinterKey);
  }

  /// Prints an invoice to the default printer.
  /// Generates the receipt layout internally using [InvoicePrintFormat].
  Future<void> printInvoice({
    required Invoice invoice,
    required List<BillLineItem> lineItems,
    String? customerName,
    String? customerMobile,
  }) async {
    final printerUrl = await getDefaultPrinterUrl();
    if (printerUrl == null || printerUrl.isEmpty) {
      throw Exception('No default thermal printer selected. Please select one in Settings.');
    }

    final printers = await getAvailablePrinters();
    Printer? selectedPrinter;
    for (final p in printers) {
      if (p.url == printerUrl) {
        selectedPrinter = p;
        break;
      }
    }

    if (selectedPrinter == null) {
      throw Exception('The saved default printer is not available. Please check your connection or re-select in Settings.');
    }

    // Generate the PDF receipt
    final pdfBytes = await InvoicePrintFormat.generateReceipt(
      invoice: invoice,
      lineItems: lineItems,
      customerName: customerName,
      customerMobile: customerMobile,
    );

    // Send it directly to the selected printer
    await Printing.directPrintPdf(
      printer: selectedPrinter,
      onLayout: (format) async => pdfBytes,
      name: 'Invoice_${invoice.invoiceNo}',
    );
  }
}

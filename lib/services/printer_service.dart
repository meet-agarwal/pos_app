import 'dart:convert';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/invoice.dart';
import '../screens/billing/models/bill_state.dart';
import 'invoice_print_format.dart';

/// A thermal printer the user picked in Settings (Bluetooth or USB).
class SavedPrinter {
  final PrinterType type;
  final String name;

  /// Bluetooth MAC address.
  final String? address;

  /// USB identifiers.
  final String? vendorId;
  final String? productId;

  const SavedPrinter({
    required this.type,
    required this.name,
    this.address,
    this.vendorId,
    this.productId,
  });

  bool get isBluetooth => type == PrinterType.bluetooth;

  bool isSameAs(SavedPrinter other) =>
      type == other.type &&
      address == other.address &&
      vendorId == other.vendorId &&
      productId == other.productId;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'name': name,
        'address': address,
        'vendorId': vendorId,
        'productId': productId,
      };

  factory SavedPrinter.fromJson(Map<String, dynamic> json) => SavedPrinter(
        type: PrinterType.values.byName(json['type'] as String),
        name: json['name'] as String,
        address: json['address'] as String?,
        vendorId: json['vendorId'] as String?,
        productId: json['productId'] as String?,
      );
}

class PrinterService {
  PrinterService._();
  static final PrinterService instance = PrinterService._();

  static const String _printerKey = 'default_printer';

  /// 58mm thermal printers print 384 dots across.
  static const int _paperWidthDots = 384;

  final PrinterManager _manager = PrinterManager.instance;

  // ── Discovery ─────────────────────────────────────────────

  /// Bluetooth printers already paired in Android's Bluetooth settings.
  /// The first call after install asks for Bluetooth permission and may
  /// return nothing — call it again once the permission is granted.
  Future<List<SavedPrinter>> listBluetoothPrinters() async {
    final printers = <SavedPrinter>[];
    await for (final d in _manager.discovery(type: PrinterType.bluetooth)) {
      printers.add(SavedPrinter(
        type: PrinterType.bluetooth,
        name: d.name,
        address: d.address,
      ));
    }
    return printers;
  }

  /// USB printers currently plugged into the tablet.
  Future<List<SavedPrinter>> listUsbPrinters() async {
    final printers = <SavedPrinter>[];
    await for (final d in _manager.discovery(type: PrinterType.usb)) {
      printers.add(SavedPrinter(
        type: PrinterType.usb,
        name: d.name,
        vendorId: d.vendorId,
        productId: d.productId,
      ));
    }
    return printers;
  }

  // ── Saved printer ─────────────────────────────────────────

  Future<SavedPrinter?> getSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_printerKey);
    if (raw == null) return null;
    try {
      return SavedPrinter.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> savePrinter(SavedPrinter printer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_printerKey, jsonEncode(printer.toJson()));
  }

  Future<void> clearSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_printerKey);
  }

  // ── Printing ──────────────────────────────────────────────

  /// Prints an invoice on the saved printer.
  Future<void> printInvoice({
    required Invoice invoice,
    required List<BillLineItem> lineItems,
    String? customerName,
    String? customerMobile,
  }) async {
    final printer = await getSavedPrinter();
    if (printer == null) {
      throw Exception('No printer selected. Please select one in Settings.');
    }

    final pdf = await InvoicePrintFormat.generateReceipt(
      invoice: invoice,
      lineItems: lineItems,
      customerName: customerName,
      customerMobile: customerMobile,
    );
    await _sendToPrinter(printer, await _escPosFromPdf(pdf));
  }

  /// Prints a few lines so the user can check the connection and Hindi.
  Future<void> printTestPage([SavedPrinter? printer]) async {
    printer ??= await getSavedPrinter();
    if (printer == null) {
      throw Exception('No printer selected. Please select one in Settings.');
    }

    final generator = Generator(PaperSize.mm58, await CapabilityProfile.load());
    final bytes = <int>[
      ...generator.reset(),
      ...generator.text('Test print', styles: const PosStyles(align: PosAlign.center, bold: true)),
      ...generator.text('Printer: ${printer.name}'),
      ...generator.text('Connection: ${printer.isBluetooth ? 'Bluetooth' : 'USB'}'),
      ...generator.cut(),
    ];
    await _sendToPrinter(printer, bytes);
  }

  /// Rasterises the receipt PDF to the printer's width and wraps it in
  /// ESC/POS commands. Printing the picture (not text) is what lets Hindi
  /// come out correctly on any printer.
  Future<List<int>> _escPosFromPdf(Uint8List pdfBytes) async {
    // Pick the resolution that makes the page exactly one printer-width wide.
    final dpi = _paperWidthDots * 72 / PdfPageFormat.roll57.width;

    final raster = await Printing.raster(pdfBytes, pages: [0], dpi: dpi).first;

    // Flatten onto white so transparent areas don't print black.
    final rgba = raster.pixels;
    final rgb = img.Image(width: raster.width, height: raster.height);
    for (var i = 0, p = 0; i < rgba.length; i += 4, p++) {
      final a = rgba[i + 3] / 255;
      int blend(int c) => (c * a + 255 * (1 - a)).round();
      rgb.setPixelRgb(
        p % raster.width,
        p ~/ raster.width,
        blend(rgba[i]),
        blend(rgba[i + 1]),
        blend(rgba[i + 2]),
      );
    }
    final image = rgb.width == _paperWidthDots
        ? rgb
        : img.copyResize(rgb, width: _paperWidthDots);

    final generator = Generator(PaperSize.mm58, await CapabilityProfile.load());
    return [
      ...generator.reset(),
      ...generator.imageRaster(image),
      ...generator.cut(),
    ];
  }

  Future<void> _sendToPrinter(SavedPrinter printer, List<int> bytes) async {
    final bool connected;
    if (printer.isBluetooth) {
      connected = await _manager.connect(
        type: PrinterType.bluetooth,
        model: BluetoothPrinterInput(
          name: printer.name,
          address: printer.address!,
        ),
      );
    } else {
      connected = await _manager.connect(
        type: PrinterType.usb,
        model: UsbPrinterInput(
          name: printer.name,
          vendorId: printer.vendorId,
          productId: printer.productId,
        ),
      );
    }
    if (!connected) {
      throw Exception(
        'Could not connect to "${printer.name}". Check it is switched on '
        'and ${printer.isBluetooth ? 'paired in Bluetooth settings' : 'plugged in'}.',
      );
    }

    final sent = await _manager.send(type: printer.type, bytes: bytes);
    if (!sent) {
      throw Exception('Could not send data to "${printer.name}".');
    }

    // Let the printer finish receiving before the link is dropped.
    if (printer.isBluetooth) {
      await Future<void>.delayed(const Duration(seconds: 1));
      await _manager.disconnect(type: PrinterType.bluetooth);
    }
  }
}

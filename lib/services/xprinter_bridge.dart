import 'dart:async';

import 'package:flutter/services.dart';

import 'printer_log.dart';

/// Talks to Xprinter's own Android SDK through the Kotlin bridge in
/// `XprinterBridge.kt`. It only moves bytes; the print data is built in Dart.
class XprinterBridge {
  XprinterBridge._();
  static final XprinterBridge instance = XprinterBridge._();

  static const MethodChannel _method = MethodChannel('pos_app/xprinter');
  static const EventChannel _events = EventChannel('pos_app/xprinter/events');

  StreamSubscription<dynamic>? _subscription;

  /// Starts copying everything the SDK reports into the printer log.
  void startLogging() {
    _subscription ??= _events.receiveBroadcastStream().listen(
      (dynamic raw) {
        final e = Map<dynamic, dynamic>.from(raw as Map);
        final info = e['info'] != null ? ' ${e['info']}' : '';
        final message = e['message'] != null ? ' (${e['message']})' : '';
        PrinterLog.instance.add('sdk', '${e['event']}$info$message');
      },
      onError: (Object error) => PrinterLog.instance.add('sdk', 'event error: $error'),
    );
  }

  /// Connects to a Bluetooth printer by MAC address, or a USB printer by its
  /// vendor/product ids. Completes when the SDK reports success or failure.
  Future<bool> connect({
    required String type,
    String? address,
    String? vendorId,
    String? productId,
  }) async {
    final ok = await _method.invokeMethod<bool>('connect', {
      'type': type,
      'address': address,
      'vendorId': vendorId,
      'productId': productId,
    });
    return ok ?? false;
  }

  /// Hands the bytes to the SDK. `connected` is false if the link dropped
  /// while the data was being sent.
  Future<({bool queued, bool connected})> send(Uint8List bytes, {int chunkSize = 1024}) async {
    final r = await _method.invokeMapMethod<String, dynamic>('send', {
      'bytes': bytes,
      'chunkSize': chunkSize,
    });
    return (
      queued: r?['queued'] == true,
      connected: r?['connected'] == true,
    );
  }

  Future<bool> isConnected() async =>
      await _method.invokeMethod<bool>('isConnected') ?? false;

  Future<void> disconnect() => _method.invokeMethod<void>('disconnect');
}

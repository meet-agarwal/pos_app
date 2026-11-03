import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A short, timestamped history of what the printer code did and what the
/// printer link reported. Kept on the device so it can be copied from Settings
/// and shared when printing misbehaves.
class PrinterLog extends ChangeNotifier {
  PrinterLog._();
  static final PrinterLog instance = PrinterLog._();

  static const String _key = 'printer_log';
  static const int _maxLines = 300;

  final List<String> _lines = [];

  List<String> get lines => List.unmodifiable(_lines);
  String get text => _lines.join('\n');

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _lines
      ..clear()
      ..addAll(prefs.getStringList(_key) ?? const []);
    notifyListeners();
  }

  void add(String source, String message) {
    final t = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.${t.millisecond.toString().padLeft(3, '0')}';
    _lines.add('$stamp [$source] $message');
    if (_lines.length > _maxLines) {
      _lines.removeRange(0, _lines.length - _maxLines);
    }
    notifyListeners();
    _save();
  }

  Future<void> clear() async {
    _lines.clear();
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _lines);
    } catch (_) {
      // Logging must never break printing.
    }
  }
}

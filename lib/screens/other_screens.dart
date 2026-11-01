import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'invoice_history/invoice_history_screen.dart';

export 'invoice_history/invoice_history_screen.dart';
export 'customers/customers_screen.dart';
export 'reports/reports_screen.dart';
import '../services/printer_service.dart';



class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SavedPrinter? _saved;
  List<SavedPrinter> _found = [];
  String? _foundLabel;
  bool _isSearching = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final saved = await PrinterService.instance.getSavedPrinter();
    if (mounted) setState(() => _saved = saved);
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _search({required bool bluetooth}) async {
    setState(() {
      _isSearching = true;
      _found = [];
      _foundLabel = bluetooth ? 'Paired Bluetooth printers' : 'USB printers';
    });
    try {
      final service = PrinterService.instance;
      final found = bluetooth
          ? await service.listBluetoothPrinters()
          : await service.listUsbPrinters();
      if (!mounted) return;
      setState(() => _found = found);
      if (found.isEmpty) {
        _showMessage(
          bluetooth
              ? 'No paired Bluetooth printers found. Pair the printer in '
                  'Android Bluetooth settings first. If you just allowed '
                  'Bluetooth access, search again.'
              : 'No USB printers found. Check the cable and the OTG adapter.',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) _showMessage('Search failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _select(SavedPrinter printer) async {
    await PrinterService.instance.savePrinter(printer);
    if (!mounted) return;
    setState(() => _saved = printer);
    _showMessage('${printer.name} saved as the receipt printer.');
  }

  Future<void> _remove() async {
    await PrinterService.instance.clearSavedPrinter();
    if (!mounted) return;
    setState(() => _saved = null);
    _showMessage('Printer removed.');
  }

  Future<void> _testPrint() async {
    setState(() => _isTesting = true);
    try {
      await PrinterService.instance.printTestPage();
      if (mounted) _showMessage('Test page sent to the printer.');
    } catch (e) {
      if (mounted) _showMessage('Test print failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 64,
          color: AppColors.screenHeaderBg,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.centerLeft,
          child: const Text('Settings', style: AppTextStyles.screenTitle),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Printer Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                'Receipts print on a 58mm thermal printer connected by Bluetooth or USB. '
                'Bluetooth printers must first be paired in Android Bluetooth settings.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              _buildSavedPrinter(),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isSearching ? null : () => _search(bluetooth: true),
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('Find Bluetooth printers'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSearching ? null : () => _search(bluetooth: false),
                    icon: const Icon(Icons.usb),
                    label: const Text('Find USB printers'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isSearching)
                const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
              else if (_foundLabel != null) ...[
                Text(_foundLabel!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                for (final printer in _found)
                  Card(
                    child: ListTile(
                      leading: Icon(printer.isBluetooth ? Icons.bluetooth : Icons.usb),
                      title: Text(printer.name),
                      subtitle: Text(printer.isBluetooth ? (printer.address ?? '') : 'USB'),
                      trailing: _saved != null && _saved!.isSameAs(printer)
                          ? const Icon(Icons.check_circle, color: AppColors.success)
                          : const Text('Select'),
                      onTap: () => _select(printer),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSavedPrinter() {
    final saved = _saved;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: saved == null
            ? const Text('No printer selected. Find a printer below and tap it.',
                style: TextStyle(color: AppColors.textSecondary))
            : Row(
                children: [
                  Icon(saved.isBluetooth ? Icons.bluetooth : Icons.usb, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(saved.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        Text(saved.isBluetooth ? 'Bluetooth' : 'USB',
                            style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testPrint,
                    icon: _isTesting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.print_outlined),
                    label: const Text('Test print'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(onPressed: _remove, child: const Text('Remove')),
                ],
              ),
      ),
    );
  }
}

// ── Shared placeholder body ───────────────────────────────────

class _PlaceholderContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _PlaceholderContent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 64,
          color: AppColors.screenHeaderBg,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.centerLeft,
          child: Text(title, style: AppTextStyles.screenTitle),
        ),
        const Divider(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 40, color: color),
                ),
                const SizedBox(height: 20),
                Text(title,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                const Text('Coming soon…',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textDisabled)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

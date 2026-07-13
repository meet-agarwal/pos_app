import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'invoice_history/invoice_history_screen.dart';

export 'invoice_history/invoice_history_screen.dart';
export 'customers/customers_screen.dart';
export 'reports/reports_screen.dart';
import 'package:printing/printing.dart';
import '../services/printer_service.dart';



class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Printer> _printers = [];
  String? _selectedPrinterUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    setState(() => _isLoading = true);
    try {
      final printers = await PrinterService.instance.getAvailablePrinters();
      final defaultUrl = await PrinterService.instance.getDefaultPrinterUrl();
      
      if (mounted) {
        setState(() {
          _printers = printers;
          _selectedPrinterUrl = defaultUrl;
          if (_selectedPrinterUrl != null && !_printers.any((p) => p.url == _selectedPrinterUrl)) {
            // If the saved printer no longer exists
            _selectedPrinterUrl = null;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading printers: $e')));
      }
    }
  }

  Future<void> _savePrinter() async {
    if (_selectedPrinterUrl == null) {
      await PrinterService.instance.clearDefaultPrinter();
    } else {
      await PrinterService.instance.setDefaultPrinterUrl(_selectedPrinterUrl!);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer settings saved successfully.'), backgroundColor: AppColors.success),
      );
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Printer Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                const Text('Select the default thermal printer for receipts (58mm width).', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Default Thermal Printer',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedPrinterUrl,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('None'),
                            ),
                            ..._printers.map((p) => DropdownMenuItem(
                                  value: p.url,
                                  child: Text(p.name),
                                )),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedPrinterUrl = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        height: 56, // matches Dropdown height roughly
                        child: ElevatedButton.icon(
                          onPressed: _savePrinter,
                          icon: const Icon(Icons.save),
                          label: const Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
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

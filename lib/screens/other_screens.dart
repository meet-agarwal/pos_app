import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class InvoiceHistoryScreen extends StatelessWidget {
  const InvoiceHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => _PlaceholderContent(
        icon: Icons.history_outlined,
        title: 'Invoice History',
        subtitle: 'Browse and search past invoices',
        color: const Color(0xFF7C4DFF),
      );
}

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});
  @override
  Widget build(BuildContext context) => _PlaceholderContent(
        icon: Icons.people_outline,
        title: 'Customers',
        subtitle: 'Manage your customer database',
        color: const Color(0xFF00BFA5),
      );
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) => _PlaceholderContent(
        icon: Icons.bar_chart_outlined,
        title: 'Reports',
        subtitle: 'Sales reports and analytics',
        color: const Color(0xFFFFA000),
      );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => _PlaceholderContent(
        icon: Icons.settings_outlined,
        title: 'Settings',
        subtitle: 'Configure your POS settings',
        color: const Color(0xFF546E7A),
      );
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

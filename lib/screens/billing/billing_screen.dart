import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Placeholder — full Billing screen will be built in the next step.
class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlaceholderScreen(
      icon: Icons.receipt_long_outlined,
      title: 'Billing',
      subtitle: 'Create invoices for your customers',
      color: const Color(0xFF2979FF),
    );
  }
}

/// Reusable placeholder used for screens not yet implemented.
class _PlaceholderScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _PlaceholderScreen({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Screen header bar
        Container(
          height: 64,
          color: AppColors.screenHeaderBg,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.centerLeft,
          child: Text(title, style: AppTextStyles.screenTitle),
        ),
        const Divider(),
        // Body
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
                        fontSize: 14, color: AppColors.textSecondary)),
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

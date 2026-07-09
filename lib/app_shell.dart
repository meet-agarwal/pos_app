// ============================================================
// app_shell.dart
// ============================================================
// The root layout of the application:
//   • Permanent [AppSidebar] on the left.
//   • [IndexedStack] on the right that holds all screens.
//     IndexedStack keeps every screen alive (state preserved)
//     when switching between nav items.
// ============================================================

import 'package:flutter/material.dart';

import 'screens/billing/billing_screen.dart';
import 'screens/items/items_screen.dart';
import 'screens/other_screens.dart';
import 'widgets/sidebar/app_sidebar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0; // 0 = Billing (default)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ─────────────────────────────────────────
          AppSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() => _selectedIndex = index);
            },
          ),

          // ── Main content ────────────────────────────────────
          // IndexedStack preserves state: the Items screen keeps
          // its loaded data and search state when you navigate away.
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                BillingScreen(),         // index 0
                ItemsScreen(),           // index 1
                InvoiceHistoryScreen(),  // index 2
                CustomersScreen(),       // index 3
                ReportsScreen(),         // index 4
                SettingsScreen(),        // index 5
              ],
            ),
          ),
        ],
      ),
    );
  }
}

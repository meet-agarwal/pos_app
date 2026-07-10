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

  final _invoiceHistoryKey = GlobalKey<InvoiceHistoryScreenState>();
  final _customersKey = GlobalKey<CustomersScreenState>();

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    if (index == 2) {
      _invoiceHistoryKey.currentState?.refresh();
    } else if (index == 3) {
      _customersKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ─────────────────────────────────────────
          AppSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: _onTabSelected,
          ),

          // ── Main content ────────────────────────────────────
          // IndexedStack preserves state: the Items screen keeps
          // its loaded data and search state when you navigate away.
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                const BillingScreen(),         // index 0
                const ItemsScreen(),           // index 1
                InvoiceHistoryScreen(key: _invoiceHistoryKey),  // index 2
                CustomersScreen(key: _customersKey),       // index 3
                const ReportsScreen(),         // index 4
                const SettingsScreen(),        // index 5
              ],
            ),
          ),
        ],
      ),
    );
  }
}


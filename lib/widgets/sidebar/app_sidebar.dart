// ============================================================
// app_sidebar.dart
// ============================================================
// Animated permanent sidebar.
//
// States:
//   Expanded  (240 px) → icon + label
//   Collapsed  (68 px) → icon only + tooltip on hover
//
// The sidebar manages its own expand/collapse toggle state.
// Navigation changes are reported to the parent via [onItemSelected].
// ============================================================

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// ── Navigation item descriptor (data only, no widget logic) ──

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ── Sidebar widget ────────────────────────────────────────────

class AppSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  bool _isExpanded = true;

  static const double _expandedWidth = 240.0;
  static const double _collapsedWidth = 68.0;
  static const Duration _dur = Duration(milliseconds: 260);
  static const Curve _curve = Curves.easeInOut;

  static const List<_NavItemData> _navItems = [
    _NavItemData(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'Billing',
    ),
    _NavItemData(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'Items',
    ),
    _NavItemData(
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
      label: 'Invoice History',
    ),
    _NavItemData(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Customers',
    ),
    _NavItemData(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      label: 'Reports',
    ),
    _NavItemData(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  void _toggle() => setState(() => _isExpanded = !_isExpanded);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: _isExpanded ? _expandedWidth : _collapsedWidth,
      duration: _dur,
      curve: _curve,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        // Subtle right border to separate from content
        border: Border(
          right: BorderSide(color: Color(0xFF1E2740), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLogo(),
          const Divider(color: AppColors.sidebarDivider, height: 1),
          const SizedBox(height: 8),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: [
                for (int i = 0; i < _navItems.length; i++)
                  _buildNavItem(i),
              ],
            ),
          ),

          const Divider(color: AppColors.sidebarDivider, height: 1),
          _buildToggle(),
        ],
      ),
    );
  }

  // ── Logo / Header ─────────────────────────────────────────

  Widget _buildLogo() {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            // Icon badge — always visible
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.sidebarItemSelected,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.point_of_sale,
                  color: Colors.white, size: 20),
            ),

            // Animated label
            ClipRect(
              child: AnimatedContainer(
                duration: _dur,
                curve: _curve,
                width: _isExpanded ? 160 : 0,
                child: AnimatedOpacity(
                  opacity: _isExpanded ? 1.0 : 0.0,
                  duration: _dur,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text(
                      'POS System',
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        color: AppColors.sidebarLogoText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Individual nav item ───────────────────────────────────

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = widget.selectedIndex == index;

    final icon = Icon(
      isSelected ? item.activeIcon : item.icon,
      color: isSelected
          ? AppColors.sidebarIconSelected
          : AppColors.sidebarIcon,
      size: 21,
    );

    final tile = AnimatedContainer(
      duration: _dur,
      curve: _curve,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.sidebarItemSelected
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: isSelected
              ? AppColors.sidebarItemSelected.withAlpha(230)
              : AppColors.sidebarItemHover,
          splashColor: AppColors.sidebarItemSelected.withAlpha(80),
          onTap: () => widget.onItemSelected(index),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _isExpanded ? 12 : 0,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment: _isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                icon,
                // Animated label
                ClipRect(
                  child: AnimatedContainer(
                    duration: _dur,
                    curve: _curve,
                    width: _isExpanded ? 160 : 0,
                    child: AnimatedOpacity(
                      opacity: _isExpanded ? 1.0 : 0.0,
                      duration: _dur,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.sidebarLabelSelected
                                : AppColors.sidebarLabel,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Wrap with Tooltip only in collapsed state
    if (_isExpanded) return tile;
    return Tooltip(
      message: item.label,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 400),
      child: tile,
    );
  }

  // ── Collapse / Expand toggle button ───────────────────────

  Widget _buildToggle() {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        hoverColor: AppColors.sidebarItemHover,
        onTap: _toggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            mainAxisAlignment: _isExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              AnimatedRotation(
                turns: _isExpanded ? 0 : 0.5,
                duration: _dur,
                curve: _curve,
                child: const Icon(
                  Icons.keyboard_double_arrow_left_rounded,
                  color: AppColors.sidebarToggleIcon,
                  size: 20,
                ),
              ),
              ClipRect(
                child: AnimatedContainer(
                  duration: _dur,
                  curve: _curve,
                  width: _isExpanded ? 120 : 0,
                  child: AnimatedOpacity(
                    opacity: _isExpanded ? 1.0 : 0.0,
                    duration: _dur,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Text(
                        'Collapse',
                        style: TextStyle(
                          color: AppColors.sidebarToggleIcon,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (_isExpanded) return button;
    return Tooltip(
      message: 'Expand sidebar',
      preferBelow: false,
      child: button,
    );
  }
}

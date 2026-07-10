// ============================================================
// bill_tab_bar.dart
// ============================================================
// Browser-style tab strip for switching between open bills.
// Shows "Bill N  ×" chips and a "+ New Bill" button.
// ============================================================

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class BillTabBar extends StatelessWidget {
  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int> onTabSelected;
  final ValueChanged<int> onTabClosed;
  final VoidCallback onAddTab;

  const BillTabBar({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onTabSelected,
    required this.onTabClosed,
    required this.onAddTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 8),
              itemCount: tabs.length,
              itemBuilder: (_, i) => _Tab(
                label: tabs[i],
                isActive: i == activeIndex,
                onTap: () => onTabSelected(i),
                onClose: () => onTabClosed(i),
              ),
            ),
          ),
          // Separator
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: AppColors.tableBorder,
          ),
          // New bill button
          _NewBillButton(onTap: onAddTab),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Single tab chip ───────────────────────────────────────────

class _Tab extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _Tab({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(right: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.primaryLight
                : (_hovering ? const Color(0xFFF5F7FB) : Colors.transparent),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border(
              bottom: BorderSide(
                color: widget.isActive ? AppColors.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_outlined,
                size: 13,
                color: widget.isActive
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isActive
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: widget.isActive
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              _CloseButton(
                isActive: widget.isActive,
                onTap: widget.onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;
  const _CloseButton({required this.isActive, required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: _hovering ? AppColors.error.withAlpha(26) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.close,
            size: 12,
            color: _hovering
                ? AppColors.error
                : (widget.isActive
                    ? AppColors.primary.withAlpha(160)
                    : AppColors.textDisabled),
          ),
        ),
      ),
    );
  }
}

// ── "+ New Bill" button ───────────────────────────────────────

class _NewBillButton extends StatefulWidget {
  final VoidCallback onTap;
  const _NewBillButton({required this.onTap});

  @override
  State<_NewBillButton> createState() => _NewBillButtonState();
}

class _NewBillButtonState extends State<_NewBillButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.primaryLight : Colors.transparent,
            border: Border.all(
              color: _hovering ? AppColors.primary : AppColors.tableBorder,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: 14,
                color: _hovering ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'New Bill',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _hovering ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

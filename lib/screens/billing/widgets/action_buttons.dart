// ============================================================
// action_buttons.dart
// ============================================================
// The three billing action buttons: Preview | Print & Save | Save.
// Visual-only for now — callbacks are left as TODO stubs.
// ============================================================

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Primary: Print & Save ────────────────────────
          _ActionButton(
            label: 'Print & Save',
            icon: Icons.print_outlined,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            onTap: () {}, // TODO: implement
          ),
          const SizedBox(height: 8),
          // ── Secondary row ────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _OutlineActionButton(
                  label: 'Preview',
                  icon: Icons.visibility_outlined,
                  onTap: () {}, // TODO: implement
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OutlineActionButton(
                  label: 'Save',
                  icon: Icons.save_outlined,
                  onTap: () {}, // TODO: implement
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Filled button ─────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _hovering
                ? widget.backgroundColor.withAlpha(220)
                : widget.backgroundColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: widget.backgroundColor.withAlpha(80),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 17, color: widget.foregroundColor),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Outlined button ───────────────────────────────────────────

class _OutlineActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _OutlineActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_OutlineActionButton> createState() => _OutlineActionButtonState();
}

class _OutlineActionButtonState extends State<_OutlineActionButton> {
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovering ? AppColors.primary : AppColors.tableBorder,
              width: _hovering ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: _hovering ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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

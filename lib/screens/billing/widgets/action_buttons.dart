// ============================================================
// action_buttons.dart
// ============================================================
// The three billing action buttons: Preview | Print & Save | Save.
// Callbacks and loading state are now wired — previously stubs.
// ============================================================

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class ActionButtons extends StatelessWidget {
  /// Called when the user taps "Save".
  final VoidCallback? onSave;

  /// Called when the user taps "Print & Save".
  final VoidCallback? onSaveAndPrint;

  /// When true the active button shows a loading indicator and
  /// all buttons are disabled to prevent double-taps.
  final bool isSaving;

  const ActionButtons({
    super.key,
    this.onSave,
    this.onSaveAndPrint,
    this.isSaving = false,
  });

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
            isLoading: isSaving,
            onTap: isSaving ? null : onSaveAndPrint,
          ),
          const SizedBox(height: 8),
          // ── Secondary row ────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _OutlineActionButton(
                  label: 'Preview',
                  icon: Icons.visibility_outlined,
                  onTap: isSaving ? null : () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OutlineActionButton(
                  label: 'Save',
                  icon: Icons.save_outlined,
                  isLoading: isSaving,
                  onTap: isSaving ? null : onSave,
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
  final bool isLoading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.isLoading = false,
    this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: disabled
                ? widget.backgroundColor.withAlpha(140)
                : _hovering
                    ? widget.backgroundColor.withAlpha(220)
                    : widget.backgroundColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovering && !disabled
                ? [
                    BoxShadow(
                      color: widget.backgroundColor.withAlpha(80),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: widget.isLoading
              ? const SizedBox(
                  height: 17,
                  child: Center(
                    child: SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon,
                        size: 17, color: widget.foregroundColor),
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
  final bool isLoading;
  final VoidCallback? onTap;

  const _OutlineActionButton({
    required this.label,
    required this.icon,
    this.isLoading = false,
    this.onTap,
  });

  @override
  State<_OutlineActionButton> createState() => _OutlineActionButtonState();
}

class _OutlineActionButtonState extends State<_OutlineActionButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _hovering && !disabled
                ? AppColors.primaryLight
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovering && !disabled
                  ? AppColors.primary
                  : AppColors.tableBorder,
              width: _hovering && !disabled ? 1.5 : 1,
            ),
          ),
          child: widget.isLoading
              ? SizedBox(
                  height: 15,
                  child: Center(
                    child: SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      size: 15,
                      color: _hovering && !disabled
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _hovering && !disabled
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

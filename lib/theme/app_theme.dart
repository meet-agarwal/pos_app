// ============================================================
// app_theme.dart
// ============================================================
// Single source of truth for all colours, typography and the
// MaterialApp ThemeData.  Import this file instead of hard-coding
// any colour values elsewhere.
// ============================================================

import 'package:flutter/material.dart';

// ── Colour Palette ───────────────────────────────────────────

class AppColors {
  AppColors._();

  // Sidebar
  static const Color sidebarBg = Color(0xFF151C2C);
  static const Color sidebarItemSelected = Color(0xFF2979FF);
  static const Color sidebarItemHover = Color(0xFF1E2740);
  static const Color sidebarIcon = Color(0xFF6B7A9F);
  static const Color sidebarIconSelected = Colors.white;
  static const Color sidebarLabel = Color(0xFF6B7A9F);
  static const Color sidebarLabelSelected = Colors.white;
  static const Color sidebarDivider = Color(0xFF1E2740);
  static const Color sidebarToggleIcon = Color(0xFF4A5578);
  static const Color sidebarLogoText = Colors.white;

  // Content area
  static const Color contentBg = Color(0xFFF0F4FA);
  static const Color surfaceWhite = Colors.white;
  static const Color screenHeaderBg = Colors.white;
  static const Color headerDivider = Color(0xFFE8EDF5);

  // Brand / Primary
  static const Color primary = Color(0xFF2979FF);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFFE3EEFF);

  // Status
  static const Color success = Color(0xFF43A047);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFFFA000);
  static const Color warningLight = Color(0xFFFFF8E1);

  // Table
  static const Color tableHeaderBg = Color(0xFFF5F7FB);
  static const Color tableRowEven = Colors.white;
  static const Color tableRowOdd = Color(0xFFFAFBFD);
  static const Color tableRowSelected = Color(0xFFE3EEFF);
  static const Color tableRowHover = Color(0xFFF0F5FF);
  static const Color tableBorder = Color(0xFFE4E9F2);
  static const Color tableHeaderText = Color(0xFF3D4F6E);

  // Text
  static const Color textPrimary = Color(0xFF1A2035);
  static const Color textSecondary = Color(0xFF5A6889);
  static const Color textDisabled = Color(0xFFB0BAD0);
  static const Color textOnPrimary = Colors.white;
}

// ── Text Styles ──────────────────────────────────────────────

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle screenTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.8,
  );

  static const TextStyle tableHeader = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.tableHeaderText,
    letterSpacing: 0.4,
  );

  static const TextStyle tableCell = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle tableCellMono = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    fontFamily: 'monospace',
  );

  static const TextStyle badge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

// ── Material ThemeData ───────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.contentBg,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.tableBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.tableBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          hintStyle: const TextStyle(
              color: AppColors.textDisabled, fontSize: 14),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return Colors.transparent;
          }),
          checkColor: WidgetStateProperty.all(Colors.white),
          side: const BorderSide(color: AppColors.tableBorder, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 12,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.tableBorder),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.tableBorder,
          thickness: 1,
          space: 0,
        ),
      );
}

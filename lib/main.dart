// ============================================================
// main.dart
// ============================================================
// Application entry point.
//
// Responsibilities:
//   1. Initialize the Flutter binding.
//   2. Initialize sqflite FFI for Windows/Linux/macOS.
//   3. Open (and create if new) the SQLite database.
//   4. Launch the app with [AppShell] as the root widget.
// ============================================================

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app_shell.dart';
import 'database/database_helper.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite works natively on Android & iOS.
  // On Windows / Linux / macOS it needs the FFI backend.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Open (and if necessary create) the SQLite database.
  // All four tables are created here on the first run.
  await DatabaseHelper.instance.database;

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const PosApp(),
    ),
  );
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS System',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: AppTheme.light,
      home: const AppShell(),
    );
  }
}

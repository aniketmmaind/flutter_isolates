import 'package:flutter/material.dart';

/// Design tokens for the app's "diagnostics console" look: a deep
/// navy instrument panel with two distinct trace colors — amber for
/// the UI thread, cyan for the background worker isolate — echoing
/// oscilloscope and telemetry displays. The two colors aren't
/// decorative: they're the same colors used to label the two threads
/// throughout the UI, so color always means the same thing.
abstract class AppPalette {
  static const Color bgDeep = Color(0xFF0A0F1C);
  static const Color bgPanel = Color(0xFF121B2E);
  static const Color bgPanelRaised = Color(0xFF1B2740);
  static const Color gridLine = Color(0xFF223452);
  static const Color traceUi = Color(0xFFFFC24B);
  static const Color traceWorker = Color(0xFF4FD8E8);
  static const Color textPrimary = Color(0xFFE8EEF9);
  static const Color textMuted = Color(0xFF7C8AA6);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF63E6A0);
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.traceWorker,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppPalette.traceWorker,
      secondary: AppPalette.traceUi,
      error: AppPalette.danger,
      surface: AppPalette.bgPanel,
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppPalette.bgDeep,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppPalette.textPrimary,
        displayColor: AppPalette.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.bgPanelRaised,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: AppPalette.textMuted),
        prefixStyle: const TextStyle(color: AppPalette.textMuted, fontFamily: 'monospace'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.gridLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.gridLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.traceWorker, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.traceWorker,
          foregroundColor: AppPalette.bgDeep,
          disabledBackgroundColor: AppPalette.bgPanelRaised,
          disabledForegroundColor: AppPalette.textMuted,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.6),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.danger,
          disabledForegroundColor: AppPalette.textMuted,
          side: const BorderSide(color: AppPalette.danger),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.6),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppPalette.bgPanelRaised,
        contentTextStyle: TextStyle(color: AppPalette.textPrimary),
      ),
    );
  }
}

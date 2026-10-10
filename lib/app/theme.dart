import 'package:flutter/material.dart';

import '../data/models/app_settings.dart';

/// Neutral grey themes. The monochrome variant keeps every role a true grey,
/// instead of Material's default purple tint.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeMode modeFor(AppThemeMode mode) => switch (mode) {
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.light => ThemeMode.light,
      };

  static ThemeData _build(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: Colors.grey,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
    );
    return ThemeData(
      colorScheme: colors,
      useMaterial3: true,
      scaffoldBackgroundColor: colors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surfaceContainer,
        foregroundColor: colors.onSurface,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surfaceContainer,
        selectedItemColor: colors.onSurface,
        unselectedItemColor: colors.onSurfaceVariant,
      ),
    );
  }
}

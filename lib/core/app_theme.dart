import 'package:flutter/material.dart';

class AppTheme {
  static const corporateBlue = Color(0xFF1F4E79);
  static const ink = Color(0xFF172033);
  static const mutedInk = Color(0xFF5F6B7A);
  static const page = Color(0xFFF4F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const line = Color(0xFFD7E0EA);
  static const teal = Color(0xFF0F766E);
  static const amber = Color(0xFF946200);

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: corporateBlue,
          brightness: Brightness.light,
        ).copyWith(
          primary: corporateBlue,
          secondary: teal,
          tertiary: amber,
          surface: surface,
          outline: line,
          outlineVariant: line,
          onSurface: ink,
          onSurfaceVariant: mutedInk,
        );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: page,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: line),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: line),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: ink,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          height: 1.22,
        ),
        titleMedium: TextStyle(
          color: ink,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          height: 1.3,
        ),
        titleSmall: TextStyle(
          color: ink,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          height: 1.35,
        ),
        bodyMedium: TextStyle(
          color: ink,
          fontSize: 14,
          letterSpacing: 0,
          height: 1.6,
        ),
        bodySmall: TextStyle(
          color: mutedInk,
          fontSize: 12,
          letterSpacing: 0,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          color: mutedInk,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        labelMedium: TextStyle(
          color: mutedInk,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        labelSmall: TextStyle(
          color: mutedInk,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
      visualDensity: VisualDensity.standard,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8EB8E5),
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0F141C),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF141A24),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}

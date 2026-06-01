import 'package:flutter/material.dart';

class AppTheme {
  static const sky = Color(0xFF18B7FF);
  static const skyDeep = Color(0xFF0077C8);
  static const yuzu = Color(0xFFFFD84D);
  static const mint = Color(0xFF27D3B5);
  static const coral = Color(0xFFFF7A6B);
  static const violet = Color(0xFF8B7CFF);
  static const ink = Color(0xFF123047);
  static const blueInk = Color(0xFF3F6F94);
  static const page = Color(0xFFF6FAFD);
  static const surface = Color(0xFFFFFFFF);
  static const line = Color(0xFFD9ECF6);

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: sky,
          brightness: Brightness.light,
        ).copyWith(
          primary: skyDeep,
          primaryContainer: const Color(0xFFE8F7FF),
          secondary: yuzu,
          secondaryContainer: const Color(0xFFEAF6FF),
          tertiary: mint,
          tertiaryContainer: const Color(0xFFD6FFF6),
          surface: surface,
          outline: line,
          outlineVariant: line,
          onPrimary: surface,
          onSecondary: ink,
          onSurface: ink,
          onSurfaceVariant: blueInk,
        );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: page,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8FDFF),
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: const Color(0x1F2D6F95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide.none,
        backgroundColor: const Color(0xFFE8F8FF),
      ),
      iconTheme: const IconThemeData(color: skyDeep),
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
          height: 1.62,
        ),
        bodySmall: TextStyle(
          color: blueInk,
          fontSize: 12,
          letterSpacing: 0,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          color: skyDeep,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        labelMedium: TextStyle(
          color: blueInk,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        labelSmall: TextStyle(
          color: blueInk,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
      visualDensity: VisualDensity.standard,
    );
  }
}

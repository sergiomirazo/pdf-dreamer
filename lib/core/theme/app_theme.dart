import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF7B2CBF);
  static const Color accent = Color(0xFFFF914D);
  static const Color highlightInk = Color(0x59FFC53D);

  static const Color pageBackground = Color(0xFFF8F7FB);
  static const Color surface = Colors.white;
  static const Color ink = Color(0xFF201A2E);
  static const Color mutedInk = Color(0xFF6B6476);
  static const Color border = Color(0xFFE8E1F2);

  static const Color darkPageBg = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkInk = Color(0xFFE8E6EF);
  static const Color darkMutedInk = Color(0xFF9E99A8);
  static const Color darkBorder = Color(0xFF38334A);

  static ThemeData light({Color accentColor = accent}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: accentColor,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: pageBackground,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: surface,
        foregroundColor: ink,
        surfaceTintColor: surface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: _onAccent(accentColor),
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: ink,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(
          color: ink,
          fontSize: 14,
          height: 1.45,
          letterSpacing: 0,
        ),
        labelLarge: TextStyle(
          color: ink,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }

  static ThemeData dark({Color accentColor = accent}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      secondary: accentColor,
      surface: darkSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: darkPageBg,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: darkSurface,
        foregroundColor: darkInk,
        surfaceTintColor: darkSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: _onAccent(accentColor),
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: darkInk,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: darkInk,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(
          color: darkInk,
          fontSize: 14,
          height: 1.45,
          letterSpacing: 0,
        ),
        labelLarge: TextStyle(
          color: darkInk,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }

  static Color _onAccent(Color color) =>
      ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? Colors.white
      : Colors.black;
}

import 'package:flutter/material.dart';

class ContraTheme {
  // Only allowed colours: the four brand colours + black & white.
  static const yellow = Color(0xFFF7C433);
  static const blue = Color(0xFF5186EC);
  static const green = Color(0xFF53A75B);
  static const red = Color(0xFFE75B49);

  static const ink = Colors.black;
  static const bg = Colors.white;
  static const card = Colors.white;

  // Black at low opacity is still "black", used for muted text.
  static const muted = Color(0x99000000);
  static const border = Colors.black;

  static const accent = blue;

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: accent,
        surface: card,
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 42,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: ink,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: ink,
        ),
      ),
    );
  }
}

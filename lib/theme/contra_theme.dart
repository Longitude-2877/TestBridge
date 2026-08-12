import 'package:flutter/material.dart';

class ContraTheme {
  static const bg = Color(0xFFF6F7FB);
  static const card = Colors.white;
  static const ink = Color(0xFF2B2B39);
  static const muted = Color(0xFF9AA0AE);
  static const teal = Color(0xFF0FB9B1);
  static const blue = Color(0xFF57A9FF);
  static const green = Color(0xFF2ECC71);
  static const red = Color(0xFFFF5B5B);
  static const yellow = Color(0xFFFFCB47);
  static const purple = Color(0xFF7C5CBF);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: teal,
        primary: teal,
        surface: card,
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

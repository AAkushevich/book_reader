import 'package:flutter/material.dart';

class ReaderThemeData {
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;

  const ReaderThemeData({
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
  });

  // ✅ 4 ТЕМЫ
  static const ReaderThemeData white = ReaderThemeData(
    backgroundColor: Colors.white,
    textColor: Color(0xFF1A1A1A),
    accentColor: Color(0xFF6C63FF),
  );

  static const ReaderThemeData sepia = ReaderThemeData(
    backgroundColor: Color(0xFFF4ECD8),
    textColor: Color(0xFF5B4636),
    accentColor: Color(0xFF8B7355),
  );

  static const ReaderThemeData dark = ReaderThemeData(
    backgroundColor: Color(0xFF2C2C2C),
    textColor: Color(0xFFE0E0E0),
    accentColor: Color(0xFF6C63FF),
  );

  static const ReaderThemeData black = ReaderThemeData(
    backgroundColor: Colors.black,
    textColor: Color(0xFFE0E0E0),
    accentColor: Color(0xFF6C63FF),
  );

  // Метод для получения темы по индексу
  static ReaderThemeData getByIndex(int index) {
    switch (index) {
      case 0:
        return white;
      case 1:
        return sepia;
      case 2:
        return dark;
      case 3:
        return black;
      default:
        return sepia;
    }
  }
}
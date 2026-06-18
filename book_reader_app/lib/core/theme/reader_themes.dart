import 'package:flutter/material.dart';

/// 3 готовые темы для читалки. Тебе не нужно ничего менять в цветах!
class ReaderThemeData {
  final Color backgroundColor; // Цвет фона страницы
  final Color textColor;       // Цвет текста
  final Color accentColor;     // Цвет кнопок и прогресса

  const ReaderThemeData({
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
  });

  /// ☀️ ДЕНЬ (Белый): Классический белый фон, но текст не чисто чёрный, 
  /// а тёмно-серый (#1A1A1A), чтобы не резало глаза.
  static const dayWhite = ReaderThemeData(
    backgroundColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF1A1A1A),
    accentColor: Color(0xFF2196F3),
  );

  /// 📜 ДЕНЬ (Сепия): Цвет старой бумаги. Самый щадящий для глаз при долгом чтении.
  static const daySepia = ReaderThemeData(
    backgroundColor: Color(0xFFF4ECD8),
    textColor: Color(0xFF5B4636),
    accentColor: Color(0xFF8D6E63),
  );

  /// 🌙 НОЧЬ: Чисто чёрный фон (экономит батарею на OLED), 
  /// но текст светло-серый (#A0A0A0), чтобы не было эффекта "светящегося пятна".
  static const nightOled = ReaderThemeData(
    backgroundColor: Color(0xFF000000),
    textColor: Color(0xFFA0A0A0),
    accentColor: Color(0xFF607D8B),
  );
}

class AppFonts {
  static const String ptSerif = 'PTSerif';
  static const String sourceSerif4 = 'SourceSerif4';
  static const String comfortaa = 'Comfortaa';
  

  static const List<String> available = [ptSerif, sourceSerif4, comfortaa];
}
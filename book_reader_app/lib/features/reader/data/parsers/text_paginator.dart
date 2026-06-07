import 'package:flutter/painting.dart';

class PaginatorConfig {
  final String text;
  final double fontSize;
  final String fontFamily;
  final double lineHeight;
  final double maxWidth;
  final double maxHeight;

  const PaginatorConfig({
    required this.text,
    required this.fontSize,
    required this.fontFamily,
    required this.lineHeight,
    required this.maxWidth,
    required this.maxHeight,
  });
}

/// Разбивает текст на страницы. 
/// Использует кооперативную многозадачность, чтобы не блокировать UI-поток.
Future<List<String>> paginateText(PaginatorConfig config) async {
  final paragraphs = config.text.split('\n');
  final pages = <String>[];
  final currentPage = StringBuffer();
  double currentHeight = 0.0;

  final textStyle = TextStyle(
    fontSize: config.fontSize,
    fontFamily: config.fontFamily,
    height: config.lineHeight,
  );

  final painter = TextPainter(textDirection: TextDirection.ltr);

  for (int i = 0; i < paragraphs.length; i++) {
    final para = paragraphs[i];
    final isBlank = para.trim().isEmpty;
    
    final blockHeight = isBlank 
        ? config.fontSize * config.lineHeight 
        : _measureHeight(painter, para, textStyle, config.maxWidth);

    if (currentHeight + blockHeight > config.maxHeight) {
      if (currentPage.isNotEmpty) {
        pages.add(currentPage.toString().trim());
        currentPage.clear();
        currentHeight = 0.0;
      }

      if (blockHeight > config.maxHeight) {
        final words = para.split(' ');
        for (final word in words) {
          final wHeight = _measureHeight(painter, word, textStyle, config.maxWidth);
          if (currentHeight + wHeight > config.maxHeight && currentPage.isNotEmpty) {
            pages.add(currentPage.toString().trim());
            currentPage.clear();
            currentHeight = 0.0;
          }
          currentPage.write('$word ');
          currentHeight += wHeight;
        }
      } else {
        currentPage.writeln(para);
        currentHeight += blockHeight;
      }
    } else {
      currentPage.writeln(para);
      currentHeight += blockHeight;
    }

    // ✅ КООПЕРАТИВНАЯ МНОГОЗАДАЧНОСТЬ:
    // Каждые 100 абзацев отдаём управление Event Loop на 1 кадр (~16 мс).
    // Это позволяет UI перерисовать индикатор загрузки, не прерывая общий процесс.
    if (i % 100 == 0) {
      await Future.delayed(Duration.zero);
    }
  }

  if (currentPage.isNotEmpty) {
    pages.add(currentPage.toString().trim());
  }

  return pages;
}

double _measureHeight(TextPainter painter, String text, TextStyle style, double maxWidth) {
  painter.text = TextSpan(text: text, style: style);
  painter.layout(maxWidth: maxWidth);
  return painter.height;
}
import 'package:flutter/material.dart';
import 'package:book_reader_app/features/reader/domain/entities/page_layout.dart';
import 'package:book_reader_app/features/reader/domain/entities/rendered_line.dart';

class PagePainter extends CustomPainter {
  final PageLayout page;
  final Color textColor;

  PagePainter(this.page, this.textColor);

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (final line in page.lines) {
      final availableWidth = size.width - line.offsetX;

      if (line.textAlign == TextAlign.justify && line.lineWidth > 0) {
        _drawJustifiedLine(canvas, tp, line, availableWidth);
      } else {
        tp.text = TextSpan(
          text: line.text,
          style: line.style.copyWith(color: textColor),
        );
        tp.textAlign = line.textAlign;
        tp.maxLines = 1;
        tp.layout(maxWidth: availableWidth);
        tp.paint(canvas, Offset(line.offsetX, line.offsetY));
      }
    }
  }

  void _drawJustifiedLine(
    Canvas canvas,
    TextPainter tp,
    RenderedLine line, // ✅ Явный тип вместо dynamic
    double availableWidth,
  ) {
    final words = line.text
        .split(' ')
        .where((String w) => w.isNotEmpty) // ✅ Явный тип String
        .toList();

    // Одно слово или пустая строка — рисуем как left
    if (words.length <= 1) {
      tp.text = TextSpan(
        text: line.text,
        style: line.style.copyWith(color: textColor),
      );
      tp.textAlign = TextAlign.left;
      tp.maxLines = 1;
      tp.layout(maxWidth: availableWidth);
      tp.paint(canvas, Offset(line.offsetX, line.offsetY));
      return;
    }

    // Измеряем ширину всех слов без пробелов
    double totalWordsWidth = 0;
    for (final word in words) {
      tp.text = TextSpan(
        text: word,
        style: line.style.copyWith(color: textColor),
      );
      tp.layout(maxWidth: double.infinity);
      totalWordsWidth += tp.width;
    }

    // Вычисляем ширину каждого пробела
    final spaceCount = words.length - 1;
    final spaceWidth =
        spaceCount > 0 ? (availableWidth - totalWordsWidth) / spaceCount : 0;

    // Рисуем каждое слово с вычисленным интервалом
    double currentX = line.offsetX;
    for (int i = 0; i < words.length; i++) {
      tp.text = TextSpan(
        text: words[i],
        style: line.style.copyWith(color: textColor),
      );
      tp.layout(maxWidth: double.infinity);
      tp.paint(canvas, Offset(currentX, line.offsetY));
      currentX += tp.width + spaceWidth;
    }
  }

  @override
  bool shouldRepaint(covariant PagePainter oldDelegate) =>
      oldDelegate.page != page || oldDelegate.textColor != textColor;
}
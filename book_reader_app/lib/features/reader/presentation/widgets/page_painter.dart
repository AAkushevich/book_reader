import 'package:flutter/material.dart';
import 'package:book_reader_app/features/reader/domain/entities/page_layout.dart';

class PagePainter extends CustomPainter {
  final PageLayout page;

  PagePainter(this.page);

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in page.lines) {
      final tp = TextPainter(
        text: TextSpan(text: line.text, style: line.style),
        textDirection: TextDirection.ltr,
        textAlign: line.textAlign,
      );
      tp.layout(maxWidth: line.lineWidth);
      tp.paint(canvas, Offset(line.offsetX, line.offsetY));
    }
  }

  @override
  bool shouldRepaint(covariant PagePainter oldDelegate) {
    return oldDelegate.page != page;
  }
}
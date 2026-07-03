import 'package:flutter/painting.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_block.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_content.dart';
import 'package:book_reader_app/features/reader/domain/entities/page_layout.dart';
import 'package:book_reader_app/features/reader/domain/entities/rendered_line.dart';

class PaginatorConfig {
  final double contentWidth;
  final double contentHeight;
  final TextStyle textStyle;
  final TextStyle titleStyle;
  final TextStyle epigraphStyle;
  final double firstLineIndent;
  final Hyphenator? hyphenator;

  const PaginatorConfig({
    required this.contentWidth,
    required this.contentHeight,
    required this.textStyle,
    required this.titleStyle,
    required this.epigraphStyle,
    this.firstLineIndent = 0,
    this.hyphenator,
  });
}

abstract class Hyphenator {
  int? hyphenate(String word);
}

class TextPaginator {
  Future<List<PageLayout>> paginate(
    List<BookBlock> blocks,
    List<Chapter> chapters,
    PaginatorConfig config,
  ) async {
    final sw = Stopwatch()..start();
    print('⏱️ Начало пагинации: ${blocks.length} блоков');
    // Запускаем синхронно, т.к. UI не зависнет (вызывается внутри AsyncValue.guard)
    final result = _paginateImpl(blocks, chapters, config);
    print('⏱️ Пагинация завершена за ${sw.elapsedMilliseconds} ms, страниц: ${result.length}');
    return result;
  }

  List<PageLayout> _paginateImpl(
    List<BookBlock> blocks,
    List<Chapter> chapters,
    PaginatorConfig config,
  ) {
    final pages = <PageLayout>[];
    var currentLines = <RenderedLine>[];
    double currentY = 0.0;
    int currentChapterIdx = 0;

    // Константная высота строки для обычного текста
    final double normalLineHeight = config.textStyle.fontSize! * (config.textStyle.height ?? 1.0);
    // Переиспользуемый TextPainter для измерения заголовков/эпиграфов/разбивки
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];

      while (currentChapterIdx < chapters.length - 1 &&
          chapters[currentChapterIdx + 1].blockIndex <= i) {
        currentChapterIdx++;
      }

      // --- ЗАГОЛОВОК ---
      if (block.type == BlockType.title) {
        if (currentY > 0) {
          pages.add(_createPage(currentLines, chapters, currentChapterIdx));
          currentLines = [];
          currentY = 0.0;
        }
        tp.text = TextSpan(text: block.text, style: config.titleStyle);
        tp.textAlign = TextAlign.center;
        tp.layout(maxWidth: config.contentWidth);
        final titleHeight = tp.height;
        final topSpacing = config.titleStyle.fontSize! * 0.5;
        currentY += topSpacing;
        if (currentY + titleHeight > config.contentHeight && currentLines.isNotEmpty) {
          pages.add(_createPage(currentLines, chapters, currentChapterIdx));
          currentLines = [];
          currentY = topSpacing;
        }
        currentLines.add(RenderedLine(
          text: block.text,
          style: config.titleStyle,
          offsetX: 0,
          offsetY: currentY,
          height: titleHeight,
          textAlign: TextAlign.center,
          lineWidth: config.contentWidth,
        ));
        currentY += titleHeight;
        currentY += config.titleStyle.fontSize! * 0.42;
        continue;
      }

      // --- ЭПИГРАФ ---
      if (block.type == BlockType.epigraph) {
        tp.text = TextSpan(text: block.text, style: config.epigraphStyle);
        tp.textAlign = TextAlign.center;
        tp.layout(maxWidth: config.contentWidth);
        if (currentY + tp.height > config.contentHeight) {
          pages.add(_createPage(currentLines, chapters, currentChapterIdx));
          currentLines = [];
          currentY = 0.0;
        }
        currentLines.add(RenderedLine(
          text: block.text,
          style: config.epigraphStyle,
          offsetX: 0,
          offsetY: currentY,
          height: tp.height,
          textAlign: TextAlign.center,
          lineWidth: config.contentWidth,
        ));
        currentY += tp.height;
        continue;
      }

      // --- ПУСТАЯ СТРОКА ---
      if (block.type == BlockType.emptyLine) {
        if (currentY + normalLineHeight > config.contentHeight) {
          pages.add(_createPage(currentLines, chapters, currentChapterIdx));
          currentLines = [];
          currentY = 0.0;
        }
        currentLines.add(RenderedLine(
          text: '',
          style: config.textStyle,
          offsetX: 0,
          offsetY: currentY,
          height: normalLineHeight,
          textAlign: TextAlign.left,
          lineWidth: config.contentWidth,
        ));
        currentY += normalLineHeight;
        continue;
      }

      // --- ПАРАГРАФ (быстрая разбивка) ---
      final lines = _splitParagraph(
        block.text,
        style: config.textStyle,
        maxWidth: config.contentWidth,
        firstLineIndent: config.firstLineIndent,
        painter: tp,
      );

      for (int j = 0; j < lines.length; j++) {
        final lineText = lines[j];
        final double indentX = (j == 0) ? config.firstLineIndent : 0;
        final double lineWidth = config.contentWidth - indentX;

        if (currentY + normalLineHeight > config.contentHeight) {
          pages.add(_createPage(currentLines, chapters, currentChapterIdx));
          currentLines = [];
          currentY = 0.0;
        }

        currentLines.add(RenderedLine(
          text: lineText,
          style: config.textStyle,
          offsetX: indentX,
          offsetY: currentY,
          height: normalLineHeight,
          textAlign: TextAlign.justify,
          lineWidth: lineWidth,
        ));
        currentY += normalLineHeight;
      }
    }

    if (currentLines.isNotEmpty) {
      pages.add(_createPage(currentLines, chapters, currentChapterIdx));
    }

    return pages;
  }

  PageLayout _createPage(List<RenderedLine> lines, List<Chapter> chapters, int chapterIdx) {
    return PageLayout(
      lines: lines.toList(),
      startBlockIndex: lines.isNotEmpty ? chapters[chapterIdx].blockIndex : 0,
      chapterIndex: chapterIdx,
    );
  }

  List<String> _splitParagraph(
    String text, {
    required TextStyle style,
    required double maxWidth,
    required double firstLineIndent,
    required TextPainter painter,
  }) {
    final lines = <String>[];
    if (text.isEmpty) return lines;

    int start = 0;
    // Первая строка с отступом
    if (firstLineIndent > 0) {
      final firstWidth = maxWidth - firstLineIndent;
      painter.text = TextSpan(text: text, style: style);
      painter.layout(maxWidth: firstWidth);
      final endOffset = painter.getPositionForOffset(Offset(firstWidth, 0)).offset;
      int end = endOffset.clamp(1, text.length);
      if (end < text.length && text[end] != ' ') {
        int lastSpace = text.lastIndexOf(' ', end);
        if (lastSpace > start) end = lastSpace;
      }
      lines.add(text.substring(start, end).trimRight());
      start = end;
      while (start < text.length && text[start] == ' ') start++;
    }

    if (start >= text.length) return lines;

    // Остальные строки: один layout и извлечение через LineMetrics
    painter.text = TextSpan(text: text.substring(start), style: style);
    painter.layout(maxWidth: maxWidth);
    final metrics = painter.computeLineMetrics();
    int offset = start;
    for (final m in metrics) {
      final endOffset = painter.getPositionForOffset(Offset(m.width, m.baseline)).offset;
      int end = offset + endOffset;
      if (end > text.length) end = text.length;
      if (end <= offset) break;
      String lineText = text.substring(offset, end);
      if (end < text.length && text[end] != ' ') {
        int lastSpace = lineText.lastIndexOf(' ');
        if (lastSpace > 0) {
          end = offset + lastSpace;
          lineText = text.substring(offset, end);
        }
      }
      if (lineText.trim().isNotEmpty) {
        lines.add(lineText.trimRight());
      }
      offset = end;
      while (offset < text.length && text[offset] == ' ') offset++;
    }
    if (offset < text.length) {
      lines.add(text.substring(offset).trimRight());
    }

    return lines;
  }
}
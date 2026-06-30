import 'package:book_reader_app/features/reader/domain/entities/book_content.dart';
import 'package:flutter/painting.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_block.dart';
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
    return _paginateImpl(blocks, chapters, config);
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

        final tp = TextPainter(
          text: TextSpan(text: block.text, style: config.titleStyle),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: config.contentWidth);

        final topSpacing = config.titleStyle.fontSize! * 0.5;
        if (currentY + topSpacing <= config.contentHeight) {
          currentY += topSpacing;
        }

        if (currentY + tp.height > config.contentHeight && currentLines.isNotEmpty) {
          pages.add(_createPage(currentLines, chapters, currentChapterIdx));
          currentLines = [];
          currentY = 0.0;
          currentY += topSpacing;
        }

        currentLines.add(RenderedLine(
          text: block.text,
          style: config.titleStyle,
          offsetX: 0,
          offsetY: currentY,
          height: tp.height,
          textAlign: TextAlign.center,
          lineWidth: config.contentWidth,
        ));
        currentY += tp.height;

        final bottomSpacing = config.titleStyle.fontSize! * 0.42;
        if (currentY + bottomSpacing <= config.contentHeight) {
          currentY += bottomSpacing;
        }
        continue;
      }

      // --- ЭПИГРАФ ---
      if (block.type == BlockType.epigraph) {
        final tp = TextPainter(
          text: TextSpan(text: block.text, style: config.epigraphStyle),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: config.contentWidth);

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
        final lineHeight = (config.textStyle.fontSize ?? 16) * (config.textStyle.height ?? 1.5);
        if (currentY + lineHeight > config.contentHeight) {
          pages.add(_createPage(currentLines, chapters, currentChapterIdx));
          currentLines = [];
          currentY = 0.0;
        }
        currentLines.add(RenderedLine(
          text: '',
          style: config.textStyle,
          offsetX: 0,
          offsetY: currentY,
          height: lineHeight,
          textAlign: TextAlign.left,
          lineWidth: config.contentWidth,
        ));
        currentY += lineHeight;
        continue;
      }

      // --- ПАРАГРАФ ---
      final paragraphLines = _layoutParagraph(
        block.text,
        style: config.textStyle,
        maxWidth: config.contentWidth,
        hyphenator: config.hyphenator,
        firstLineIndent: config.firstLineIndent,
      );

      for (int j = 0; j < paragraphLines.length; j++) {
        final lineText = paragraphLines[j];
        final double lineWidth = (j == 0) ? config.contentWidth - config.firstLineIndent : config.contentWidth;
        final tp = TextPainter(
          text: TextSpan(text: lineText, style: config.textStyle),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.justify,
        )..layout(maxWidth: lineWidth);
        final lineHeight = tp.height;

        if (currentY + lineHeight > config.contentHeight) {
          pages.add(_createPage(currentLines, chapters, currentChapterIdx));
          currentLines = [];
          currentY = 0.0;
        }

        double indentX = (j == 0) ? config.firstLineIndent : 0;
        currentLines.add(RenderedLine(
          text: lineText,
          style: config.textStyle,
          offsetX: indentX,
          offsetY: currentY,
          height: lineHeight,
          isHyphenated: lineText.endsWith('-') && block.text.isNotEmpty,
          textAlign: TextAlign.justify,
          lineWidth: lineWidth,
        ));
        currentY += lineHeight;
      }
    }

    if (currentLines.isNotEmpty) {
      pages.add(_createPage(currentLines, chapters, currentChapterIdx));
    }

    return pages;
  }

  PageLayout _createPage(List<RenderedLine> lines, List<Chapter> chapters, int chapterIdx) {
    return PageLayout(
      lines: List.unmodifiable(lines),
      startBlockIndex: lines.isNotEmpty ? chapters[chapterIdx].blockIndex : 0,
      chapterIndex: chapterIdx,
    );
  }

  List<String> _layoutParagraph(
    String text, {
    required TextStyle style,
    required double maxWidth,
    Hyphenator? hyphenator,
    double firstLineIndent = 0,
  }) {
    final lines = <String>[];
    if (text.isEmpty) return lines;

    int start = 0;
    double currentLineWidth = maxWidth - firstLineIndent;
    bool isFirst = true;

    while (start < text.length) {
      final tp = TextPainter(
        text: TextSpan(text: text.substring(start), style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: currentLineWidth);

      final endOffset = tp.getPositionForOffset(Offset(currentLineWidth, 0)).offset;
      if (endOffset <= 0) {
        lines.add(text.substring(start, start + 1));
        start += 1;
        currentLineWidth = maxWidth;
        isFirst = false;
        continue;
      }

      int end = start + endOffset;
      if (end > text.length) end = text.length;

      String line = text.substring(start, end);

      if (hyphenator != null && end < text.length) {
        final nextChar = text[end];
        if (![' ', '\t', '\n'].contains(nextChar)) {
          int lastSpace = line.lastIndexOf(' ');
          int breakPoint = lastSpace > 0 ? lastSpace + 1 : 0;
          String word = (breakPoint == 0) ? line : line.substring(breakPoint);
          final hyphenPos = hyphenator.hyphenate(word);
          if (hyphenPos != null && hyphenPos > 1 && hyphenPos < word.length - 1) {
            final candidate = line.substring(0, breakPoint) + word.substring(0, hyphenPos) + '-';
            final candidateTp = TextPainter(
              text: TextSpan(text: candidate, style: style),
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: currentLineWidth);
            if (candidateTp.width <= currentLineWidth) {
              lines.add(candidate.trimRight());
              start = start + breakPoint + hyphenPos;
              currentLineWidth = maxWidth;
              isFirst = false;
              continue;
            }
          }
        }
      }

      lines.add(line.trimRight());
      start = end;
      currentLineWidth = maxWidth;
      isFirst = false;
    }

    return lines;
  }
}
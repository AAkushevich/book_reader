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
    // ✅ Индекс первого блока на ТЕКУЩЕЙ странице
    int pageStartBlockIndex = 0;

    final double normalLineHeight =
        config.textStyle.fontSize! * (config.textStyle.height ?? 1.0);
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
          // ✅ Сохраняем предыдущую страницу с ЕЁ startBlockIndex
          pages.add(_createPage(currentLines, chapters, currentChapterIdx, pageStartBlockIndex));
          currentLines = [];
          currentY = 0.0;
        }
        // ✅ Новая страница начинается с этого блока (заголовка)
        pageStartBlockIndex = i;

        tp.text = TextSpan(text: block.text, style: config.titleStyle);
        tp.textAlign = TextAlign.center;
        tp.layout(maxWidth: config.contentWidth);
        final titleHeight = tp.height;
        final topSpacing = config.titleStyle.fontSize! * 0.5;
        currentY += topSpacing;
        if (currentY + titleHeight > config.contentHeight &&
            currentLines.isNotEmpty) {
          pages.add(_createPage(currentLines, chapters, currentChapterIdx, pageStartBlockIndex));
          currentLines = [];
          currentY = topSpacing;
          // Если заголовок не влез и ушёл на новую страницу,
          // pageStartBlockIndex остаётся = i (заголовок)
        }

        final titleCenterOffset = tp.width < config.contentWidth
            ? (config.contentWidth - tp.width) / 2
            : 0.0;

        currentLines.add(RenderedLine(
          text: block.text,
          style: config.titleStyle,
          offsetX: titleCenterOffset,
          offsetY: currentY,
          height: titleHeight,
          textAlign: TextAlign.left,
          lineWidth: config.contentWidth - titleCenterOffset,
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
          pages.add(_createPage(currentLines, chapters, currentChapterIdx, pageStartBlockIndex));
          currentLines = [];
          currentY = 0.0;
          // ✅ Новая страница начинается с эпиграфа
          pageStartBlockIndex = i;
        }

        final epiCenterOffset = tp.width < config.contentWidth
            ? (config.contentWidth - tp.width) / 2
            : 0.0;

        currentLines.add(RenderedLine(
          text: block.text,
          style: config.epigraphStyle,
          offsetX: epiCenterOffset,
          offsetY: currentY,
          height: tp.height,
          textAlign: TextAlign.left,
          lineWidth: config.contentWidth - epiCenterOffset,
        ));
        currentY += tp.height;
        continue;
      }

      // --- ПУСТАЯ СТРОКА ---
      if (block.type == BlockType.emptyLine) {
        if (currentY + normalLineHeight > config.contentHeight) {
          pages.add(_createPage(currentLines, chapters, currentChapterIdx, pageStartBlockIndex));
          currentLines = [];
          currentY = 0.0;
          pageStartBlockIndex = i;
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

      // --- ПАРАГРАФ ---
      String remainingText = block.text;
      bool isFirstLineOfBlock = true;

      while (remainingText.isNotEmpty) {
        final availableHeight = config.contentHeight - currentY;
        final currentMaxWidth = isFirstLineOfBlock
            ? config.contentWidth - config.firstLineIndent
            : config.contentWidth;

        tp.text = TextSpan(text: remainingText, style: config.textStyle);
        tp.layout(maxWidth: currentMaxWidth);

        final metrics = tp.computeLineMetrics();
        if (metrics.isEmpty) break;

        double pageAccumulatedHeight = 0;
        int linesOnThisPage = 0;

        for (int m = 0; m < metrics.length; m++) {
          final h = metrics[m].height;
          if (pageAccumulatedHeight + h > availableHeight) break;
          pageAccumulatedHeight += h;
          linesOnThisPage = m + 1;
        }

        if (linesOnThisPage == 0) {
          pages.add(_createPage(currentLines, chapters, currentChapterIdx, pageStartBlockIndex));
          currentLines = [];
          currentY = 0.0;
          // ✅ Новая страница начинается с этого параграфа
          pageStartBlockIndex = i;
          continue;
        }

        int consumedEnd = 0;
        for (int m = 0; m < linesOnThisPage; m++) {
          final metric = metrics[m];
          final lineStartPos = tp.getPositionForOffset(
            Offset(0, metric.baseline),
          );
          final boundary = tp.getLineBoundary(lineStartPos);

          int startOff = boundary.start;
          int endOff = boundary.end;

          if (m > 0 && startOff < consumedEnd) {
            startOff = consumedEnd;
          }

          String lineText =
              remainingText.substring(startOff, endOff).trimRight();

          final isLastOnPage = (m == linesOnThisPage - 1);
          final isEndOfParagraph = (endOff >= remainingText.length);

          if (isLastOnPage &&
              !isEndOfParagraph &&
              endOff < remainingText.length) {
            final charAtEnd = remainingText[endOff];
            if (charAtEnd != ' ' && charAtEnd != '\n') {
              final lastSpace = lineText.lastIndexOf(' ');
              if (lastSpace > 0) {
                endOff = startOff + lastSpace;
                lineText =
                    remainingText.substring(startOff, endOff).trimRight();
              } else if (config.hyphenator != null && lineText.length > 3) {
                final hp = config.hyphenator!.hyphenate(lineText);
                if (hp != null && hp > 1 && hp < lineText.length - 1) {
                  lineText = lineText.substring(0, hp) + '-';
                  endOff = startOff + hp;
                }
              }
            }
          }

          consumedEnd = endOff;

          final indentX = isFirstLineOfBlock ? config.firstLineIndent : 0.0;
          final actualHeight = metric.height;

          final bool isRealLastLine;
          if (isEndOfParagraph) {
            isRealLastLine = true;
          } else {
            final afterConsumed = consumedEnd < remainingText.length
                ? remainingText.substring(consumedEnd).trimLeft()
                : '';
            isRealLastLine = afterConsumed.isEmpty;
          }

          TextAlign textAlign;
          if (isRealLastLine) {
            final wordCount = lineText
                .trim()
                .split(RegExp(r'\s+'))
                .where((String w) => w.isNotEmpty)
                .length;
            textAlign = wordCount >= 4 ? TextAlign.justify : TextAlign.left;
          } else {
            textAlign = TextAlign.justify;
          }

          currentLines.add(RenderedLine(
            text: lineText,
            style: config.textStyle,
            offsetX: indentX,
            offsetY: currentY,
            height: actualHeight,
            textAlign: textAlign,
            lineWidth: currentMaxWidth,
          ));
          currentY += actualHeight;
          isFirstLineOfBlock = false;
        }

        if (consumedEnd <= 0) {
          remainingText = remainingText.substring(1);
        } else {
          remainingText = remainingText.substring(consumedEnd).trimLeft();
        }

        if (remainingText.isNotEmpty && currentY >= config.contentHeight) {
          pages.add(_createPage(currentLines, chapters, currentChapterIdx, pageStartBlockIndex));
          currentLines = [];
          currentY = 0.0;
          // ✅ Следующая страница продолжит тот же параграф
          // pageStartBlockIndex остаётся = i
        }
      }
    }

    if (currentLines.isNotEmpty) {
      pages.add(_createPage(currentLines, chapters, currentChapterIdx, pageStartBlockIndex));
    }

    return pages;
  }

  PageLayout _createPage(
    List<RenderedLine> lines,
    List<Chapter> chapters,
    int chapterIdx,
    int blockIndex,
  ) {
    return PageLayout(
      lines: lines.toList(),
      startBlockIndex: blockIndex,
      chapterIndex: chapterIdx,
    );
  }
}
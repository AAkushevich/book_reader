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

/// Контракт для движка переносов.
/// Возвращает список индексов, где можно разорвать слово.
/// Пример: "библиотека" → [2, 5, 8] → би-блио-те-ка
abstract class Hyphenator {
  List<int> breakPositions(String word);
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
          pages.add(_createPage(currentLines, chapters, currentChapterIdx, pageStartBlockIndex));
          currentLines = [];
          currentY = 0.0;
        }
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
      // Пре-процессинг: вставляем \u00AD в местах возможных переносов
      String remainingText = config.hyphenator != null
          ? _insertSoftHyphens(block.text, config.hyphenator!)
          : block.text;
      bool isFirstLineOfBlock = true;

      while (remainingText.isNotEmpty) {
        final availableHeight = config.contentHeight - currentY;

        // ═══════════════════════════════════════════════════════
        // СПЕЦИАЛЬНЫЙ СЛУЧАЙ: первая строка параграфа с отступом
        // Верстается отдельно на узкой ширине, остальные — на полной
        // ═══════════════════════════════════════════════════════
        if (isFirstLineOfBlock && config.firstLineIndent > 0) {
          final narrowWidth = config.contentWidth - config.firstLineIndent;

          tp.text = TextSpan(text: remainingText, style: config.textStyle);
          tp.layout(maxWidth: narrowWidth);
          final narrowMetrics = tp.computeLineMetrics();

          if (narrowMetrics.isEmpty) break;

          final firstMetric = narrowMetrics[0];

          // Не влезает по высоте — переносим параграф на новую страницу
          if (currentY + firstMetric.height > config.contentHeight) {
            if (currentLines.isEmpty) break; // защита от беск. цикла
            pages.add(_createPage(currentLines, chapters, currentChapterIdx, pageStartBlockIndex));
            currentLines = [];
            currentY = 0.0;
            pageStartBlockIndex = i;
            continue;
          }

          // Извлекаем только первую строку
          final firstBoundary = tp.getLineBoundary(
            tp.getPositionForOffset(Offset(0, firstMetric.baseline)),
          );
          final endOff = firstBoundary.end;

          String lineText = remainingText
              .substring(0, endOff)
              .trimRight()
              .replaceAll('\u00AD', '');

          final isEndOfParagraph = endOff >= remainingText.length;

          TextAlign textAlign;
          if (isEndOfParagraph) {
            final wordCount = lineText
                .trim()
                .split(RegExp(r'\s+'))
                .where((w) => w.isNotEmpty)
                .length;
            textAlign = wordCount >= 6 ? TextAlign.justify : TextAlign.left;
          } else {
            textAlign = TextAlign.justify;
          }

          currentLines.add(RenderedLine(
            text: lineText,
            style: config.textStyle,
            offsetX: config.firstLineIndent,
            offsetY: currentY,
            height: firstMetric.height,
            textAlign: textAlign,
            lineWidth: narrowWidth,
          ));
          currentY += firstMetric.height;

          // Сдвигаем текст, дальше — обычная обработка на полной ширине
          remainingText = remainingText.substring(endOff).trimLeft();
          isFirstLineOfBlock = false;
          continue;
        }

        // ═══════════════════════════════════════════════════════
        // ОБЫЧНАЯ ОБРАБОТКА (полная ширина)
        // ═══════════════════════════════════════════════════════
        final currentMaxWidth = config.contentWidth;

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
          lineText = lineText.replaceAll('\u00AD', '');

          final isLastOnPage = (m == linesOnThisPage - 1);
          final isEndOfParagraph = (endOff >= remainingText.length);

          bool wasShortened = false;

          if (isLastOnPage &&
              !isEndOfParagraph &&
              endOff < remainingText.length) {
            final charAtEnd = remainingText[endOff];
            if (charAtEnd != ' ' && charAtEnd != '\n') {
              final lastSpace = lineText.lastIndexOf(' ');
              if (lastSpace > 0) {
                endOff = startOff + lastSpace;
                lineText = remainingText
                    .substring(startOff, endOff)
                    .trimRight()
                    .replaceAll('\u00AD', '');
                wasShortened = true;
              }
            }
          }

          consumedEnd = endOff;

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
          if (wasShortened) {
            textAlign = TextAlign.left;
          } else if (isRealLastLine) {
            final wordCount = lineText
                .trim()
                .split(RegExp(r'\s+'))
                .where((String w) => w.isNotEmpty)
                .length;
            textAlign = wordCount >= 6 ? TextAlign.justify : TextAlign.left;
          } else {
            textAlign = TextAlign.justify;
          }

          currentLines.add(RenderedLine(
            text: lineText,
            style: config.textStyle,
            offsetX: 0,
            offsetY: currentY,
            height: actualHeight,
            textAlign: textAlign,
            lineWidth: currentMaxWidth,
          ));
          currentY += actualHeight;
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
        }
      }

      // Параграф полностью обработан — следующая страница со следующего блока
      pageStartBlockIndex = i + 1;
    }

    if (currentLines.isNotEmpty) {
      pages.add(_createPage(currentLines, chapters, currentChapterIdx, pageStartBlockIndex));
    }

    return pages;
  }

  /// Вставляет \u00AD между слогами, где можно перенести.
  /// Пунктуация в конце слова отделяется и не разрывается.
  static String _insertSoftHyphens(String text, Hyphenator h) {
    final buf = StringBuffer();
    final parts = text.split(' ');
    for (var i = 0; i < parts.length; i++) {
      final word = parts[i];
      if (word.isEmpty) {
        buf.write(' ');
        continue;
      }

      final m = RegExp(r'^(.+?)([.,!?;:…»]*)$').firstMatch(word);
      final core = m?.group(1) ?? word;
      final punct = m?.group(2) ?? '';

      final breaks = h.breakPositions(core);
      if (breaks.isEmpty) {
        buf.write(word);
      } else {
        var last = 0;
        for (final pos in breaks) {
          if (pos > last && pos < core.length) {
            buf.write(core.substring(last, pos));
            buf.write('\u00AD');
            last = pos;
          }
        }
        buf.write(core.substring(last));
        buf.write(punct);
      }
      if (i < parts.length - 1) buf.write(' ');
    }
    return buf.toString();
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
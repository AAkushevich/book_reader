import 'package:flutter/material.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_block.dart';
import 'package:book_reader_app/features/reader/domain/entities/text_line.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_content.dart';

class PaginatorConfig {
  final double fontSize;
  final String fontFamily;
  final double lineHeight;
  final double maxWidth;
  final double maxHeight;
  final TextScaler textScaler;
  
  const PaginatorConfig({
    required this.fontSize,
    required this.fontFamily,
    this.lineHeight = 1.5,
    required this.maxWidth,
    required this.maxHeight,
    this.textScaler = TextScaler.noScaling,
  });
}

class PaginationResult {
  final List<List<TextLine>> pages;
  final List<Chapter> chapters;
  
  const PaginationResult({
    required this.pages,
    required this.chapters,
  });
}

Future<PaginationResult> paginateBook(
  List<BookBlock> blocks, 
  List<Chapter> chapters,
  PaginatorConfig config
) async {
  final allPages = <List<TextLine>>[];
  var currentPage = <TextLine>[];
  double currentHeight = 0;
  
  final paragraphSpacing = config.fontSize * 0.15;
  const heightBuffer = 1.5;
  
  // Карта: индекс блока -> номер страницы, на которой он оказался
  final blockToPage = <int, int>{};

  for (int blockIdx = 0; blockIdx < blocks.length; blockIdx++) {
    final block = blocks[blockIdx];
    if (block.type == BlockType.emptyLine) continue;

    if (block.type == BlockType.title) {
      // Заголовок всегда начинает новую страницу
      if (currentPage.isNotEmpty) {
        allPages.add(currentPage);
        currentPage = [];
        currentHeight = 0;
      }
      
      // Запоминаем: этот блок (заголовок главы) находится на странице allPages.length
      blockToPage[blockIdx] = allPages.length;
      
      final titleSize = config.fontSize * 1.4;
      final painter = TextPainter(
        text: TextSpan(
          text: block.text,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            fontFamily: config.fontFamily,
            height: 1.3,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: config.textScaler, 
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: true,
          applyHeightToLastDescent: true,
        ),
      );
      painter.layout(maxWidth: config.maxWidth);
      
      final titleHeight = painter.height + heightBuffer;
      currentPage.add(TextLine(text: block.text, isTitle: true));
      currentHeight += titleHeight;
      
      if (currentHeight < config.maxHeight) {
        currentHeight += paragraphSpacing;
      }
      
      painter.dispose();
      continue;
    }

    if (block.type == BlockType.epigraph) {
      final epiSize = config.fontSize * 0.9;
      final painter = TextPainter(
        text: TextSpan(
          text: block.text,
          style: TextStyle(
            fontSize: epiSize,
            fontStyle: FontStyle.italic,
            fontFamily: config.fontFamily,
            height: 1.4,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: config.textScaler,
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: true,
          applyHeightToLastDescent: true,
        ),
      );
      painter.layout(maxWidth: config.maxWidth);
      
      final epiHeight = painter.height + heightBuffer;
      
      if (currentHeight + epiHeight > config.maxHeight && currentPage.isNotEmpty) {
        allPages.add(currentPage);
        currentPage = [];
        currentHeight = 0;
      }
      
      currentPage.add(TextLine(text: block.text, isEpigraph: true));
      currentHeight += epiHeight;
      painter.dispose();
      continue;
    }

    if (block.type == BlockType.paragraph) {
      String remainingText = block.text;
      bool isFirstLine = true;
      
      while (remainingText.isNotEmpty) {
        final painter = TextPainter(
          text: TextSpan(
            text: remainingText,
            style: TextStyle(
              fontSize: config.fontSize,
              fontFamily: config.fontFamily,
              height: config.lineHeight,
            ),
          ),
          textDirection: TextDirection.ltr,
          textScaler: config.textScaler, 
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: true,
            applyHeightToLastDescent: true,
          ),
        );
        painter.layout(maxWidth: config.maxWidth);
        
        final lineMetrics = painter.computeLineMetrics();
        
        if (lineMetrics.isEmpty) {
          remainingText = '';
          continue;
        }
        
        double accumulatedHeight = 0;
        int fittingLinesCount = 0;
        
        for (int i = 0; i < lineMetrics.length; i++) {
          final line = lineMetrics[i];
          final lineHeight = line.height + heightBuffer;
          
          if (currentHeight + accumulatedHeight + lineHeight > config.maxHeight) {
            break;
          }
          
          accumulatedHeight += lineHeight;
          fittingLinesCount = i + 1;
        }
        
        if (fittingLinesCount == 0) {
          fittingLinesCount = 1;
          accumulatedHeight = lineMetrics[0].height + heightBuffer;
        }
        
        if (fittingLinesCount >= lineMetrics.length) {
          final fittingText = isFirstLine
            ? '\u00A0\u00A0\u00A0\u00A0${remainingText.trimRight()}'
            : remainingText.trimRight();
          
          currentPage.add(TextLine(
            text: fittingText, 
            isFirstLineOfParagraph: isFirstLine,
          ));
          currentHeight += accumulatedHeight;
          remainingText = '';
          
          if (currentHeight < config.maxHeight) {
            currentHeight += paragraphSpacing;
          }
        } else {
          double lastLineBottom = 0;
          for (int i = 0; i < fittingLinesCount; i++) {
            lastLineBottom += lineMetrics[i].height;
          }
          
          final position = painter.getPositionForOffset(
            Offset(config.maxWidth / 2, lastLineBottom - 0.1)
          );
          int cutIndex = position.offset;
          
          if (cutIndex < remainingText.length && 
              remainingText[cutIndex] != ' ' && 
              remainingText[cutIndex] != '\n') {
            final lastSpace = remainingText.lastIndexOf(' ', cutIndex);
            if (lastSpace > 0) {
              cutIndex = lastSpace;
            }
          }
          
          if (cutIndex == 0) cutIndex = 1;
          if (cutIndex > remainingText.length) cutIndex = remainingText.length;
          
          final fittingText = isFirstLine
            ? '\u00A0\u00A0\u00A0\u00A0${remainingText.substring(0, cutIndex).trimRight()}'
            : remainingText.substring(0, cutIndex).trimRight();
          
          currentPage.add(TextLine(
            text: fittingText, 
            isFirstLineOfParagraph: isFirstLine,
          ));
          currentHeight += accumulatedHeight;
          remainingText = remainingText.substring(cutIndex).trimLeft();
          isFirstLine = false;
          
          if (currentHeight < config.maxHeight) {
            currentHeight += paragraphSpacing;
          }
          
          final remainingSpace = config.maxHeight - currentHeight;
          final preferredLineHeight = painter.preferredLineHeight + heightBuffer;
          
          if (remainingSpace < preferredLineHeight) {
            allPages.add(currentPage);
            currentPage = [];
            currentHeight = 0;
          }
        }
        
        painter.dispose();
      }
    }
  }

  if (currentPage.isNotEmpty) {
    allPages.add(currentPage);
  }

  // Сопоставляем главы с номерами страниц через карту blockToPage
  final updatedChapters = chapters.map((chapter) {
    return Chapter(
      title: chapter.title,
      startPageIndex: blockToPage[chapter.blockIndex] ?? 0,
      blockIndex: chapter.blockIndex,
    );
  }).toList();

  print('Пагинация завершена. Страниц: ${allPages.length}');
  print('Глав: ${updatedChapters.length}');
  
  // Для отладки — выводим первые 5 глав
  for (int i = 0; i < updatedChapters.length && i < 5; i++) {
    final ch = updatedChapters[i];
    print('  ${ch.title} -> страница ${ch.startPageIndex + 1}');
  }

  return PaginationResult(
    pages: allPages,
    chapters: updatedChapters,
  );
}
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:collection/collection.dart';
import 'package:book_reader_app/features/reader/data/parsers/book_parser.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_content.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_block.dart';

class EpubParser implements BookParser {
  @override
  Future<BookContent> parseBytes(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final blocks = <BookBlock>[];
    final chapters = <Chapter>[];

    for (final file in archive) {
      final fileName = file.name.toLowerCase();
      if (fileName.endsWith('.xhtml') || fileName.endsWith('.html')) {
        if (file.content != null) {
          final contentBytes = file.content as List<int>;
          final content = utf8.decode(contentBytes);
          
          try {
            final doc = XmlDocument.parse(content);
            final body = doc.findAllElements('body').firstOrNull;
            if (body != null) {
              _processHtmlBody(body, blocks, chapters);
            }
          } catch (e) {
            // Игнорируем невалидные XML
          }
        }
      }
    }

    return BookContent(blocks: blocks, chapters: chapters);
  }

  void _processHtmlBody(XmlElement body, List<BookBlock> blocks, List<Chapter> chapters) {
    for (final child in body.children) {
      if (child is XmlElement) {
        final tagName = child.name.local.toLowerCase();
        
        // Заголовки глав
        if (tagName == 'h1' || tagName == 'h2' || tagName == 'h3') {
          final title = child.innerText.trim();
          if (title.isNotEmpty) {
            blocks.add(BookBlock.emptyLine());
            blocks.add(BookBlock.title(title));
            blocks.add(BookBlock.emptyLine());
            
            chapters.add(Chapter(
              title: title,
              startPageIndex: 0,
              blockIndex: blocks.length - 2,
            ));
          }
        }
        // Параграфы
        else if (tagName == 'p') {
          final text = child.innerText.trim();
          if (text.isNotEmpty) {
            blocks.add(BookBlock.paragraph(text));
          }
        }
        // Цитаты
        else if (tagName == 'blockquote') {
          final text = child.innerText.trim();
          if (text.isNotEmpty) {
            blocks.add(BookBlock.emptyLine());
            blocks.add(BookBlock.epigraph(text));
            blocks.add(BookBlock.emptyLine());
          }
        }
      }
    }
  }
}
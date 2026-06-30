import 'package:xml/xml.dart';
import 'package:collection/collection.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_content.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_block.dart';

class Fb2XmlParser {
  static BookContent parse(String xmlContent) {
    final doc = XmlDocument.parse(xmlContent);
    final body = doc.findAllElements('body').firstOrNull;
    if (body == null) return BookContent(blocks: []);

    final blocks = <BookBlock>[];
    final chapters = <Chapter>[];
    
    for (final section in body.findAllElements('section')) {
      _processSection(section, blocks, chapters);
    }

    return BookContent(blocks: blocks, chapters: chapters);
  }

  static void _processSection(XmlElement section, List<BookBlock> blocks, List<Chapter> chapters) {
    for (final child in section.children) {
      if (child is XmlElement) {
        if (child.name.local == 'title') {
          final titleText = child.innerText.trim();
          if (titleText.isNotEmpty) {
            blocks.add(BookBlock.title(titleText));
            chapters.add(Chapter(
              title: titleText,
              startPageIndex: 0, // будет заполнено позже
              blockIndex: blocks.length - 1,
            ));
          }
        }
        else if (child.name.local == 'p') {
          final text = child.innerText.trim();
          if (text.isNotEmpty) {
            blocks.add(BookBlock.paragraph(text));
          }
        }
        else if (child.name.local == 'epigraph') {
          final text = child.innerText.trim();
          if (text.isNotEmpty) {
            blocks.add(BookBlock.epigraph(text));
          }
        }
        else if (child.name.local == 'empty-line') {
          blocks.add(BookBlock.emptyLine());
        }
        else if (child.name.local == 'section') {
          _processSection(child, blocks, chapters);
        }
      }
    }
  }
}
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
    
    // Начинаем обход с корневых секций
    for (final section in body.findAllElements('section')) {
      _processSection(section, blocks, chapters);
    }

    return BookContent(blocks: blocks, chapters: chapters);
  }

  static void _processSection(XmlElement section, List<BookBlock> blocks, List<Chapter> chapters) {
    for (final child in section.children) {
      if (child is XmlElement) {
        // 1. ЗАГОЛОВОК (Название главы, тома)
        if (child.name.local == 'title') {
          final titleText = child.innerText.trim();
          if (titleText.isNotEmpty) {
            // Добавляем пустую строку перед заголовком для красоты
            blocks.add(BookBlock.emptyLine());
            blocks.add(BookBlock.title(titleText));
            blocks.add(BookBlock.emptyLine());
            
            // Запоминаем главу для оглавления
            chapters.add(Chapter(
              title: titleText, 
              startPageIndex: 0, // Заполнится позже
              blockIndex: blocks.length - 2,
            ));
          }
        }
        // 2. ПАРАГРАФ (Обычный текст)
        else if (child.name.local == 'p') {
          final text = child.innerText.trim();
          if (text.isNotEmpty) {
            blocks.add(BookBlock.paragraph(text));
          }
        }
        // 3. ЭПИГРАФ
        else if (child.name.local == 'epigraph') {
          final text = child.innerText.trim();
          if (text.isNotEmpty) {
            blocks.add(BookBlock.emptyLine());
            blocks.add(BookBlock.epigraph(text));
            blocks.add(BookBlock.emptyLine());
          }
        }
        // 4. ПУСТАЯ СТРОКА
        else if (child.name.local == 'empty-line') {
          blocks.add(BookBlock.emptyLine());
        }
        // 5. ВЛОЖЕННАЯ СЕКЦИЯ (Глава внутри тома)
        else if (child.name.local == 'section') {
          _processSection(child, blocks, chapters);
        }
      }
    }
  }
}
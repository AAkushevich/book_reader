import 'package:xml/xml.dart';
import 'package:collection/collection.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_content.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_block.dart';

typedef ImageSize = ({int width, int height});

class Fb2XmlParser {
  static BookContent parse(
      String xmlContent, {
        Map<String, String> imagePaths = const {},
        Map<String, ImageSize> imageSizes = const {},
      }) {
    final doc = XmlDocument.parse(xmlContent);
    final body = doc.findAllElements('body').firstOrNull;
    if (body == null) return BookContent(blocks: []);

    final blocks = <BookBlock>[];
    final chapters = <Chapter>[];
    _walk(body, blocks, chapters, imagePaths, imageSizes);
    return BookContent(blocks: blocks, chapters: chapters);
  }

  static void _walk(
      XmlElement parent,
      List<BookBlock> blocks,
      List<Chapter> chapters,
      Map<String, String> imagePaths,
      Map<String, ImageSize> imageSizes,
      ) {
    for (final child in parent.children) {
      if (child is! XmlElement) continue;
      switch (child.name.local) {
        case 'title':
          final t = _normalize(child.innerText);
          if (t.isNotEmpty) {
            blocks.add(BookBlock.title(t));
            chapters.add(Chapter(
              title: t,
              startPageIndex: 0,
              blockIndex: blocks.length - 1,
            ));
          }
          break;
        case 'subtitle':
          final t = _normalize(child.innerText);
          if (t.isNotEmpty) blocks.add(BookBlock.title(t));
          break;
        case 'p':
          final t = _normalize(child.innerText);
          if (t.isNotEmpty) blocks.add(BookBlock.paragraph(t));
          break;
        case 'epigraph':
          final t = _normalize(child.innerText);
          if (t.isNotEmpty) blocks.add(BookBlock.epigraph(t));
          break;
        case 'empty-line':
          blocks.add(BookBlock.emptyLine());
          break;
        case 'image':
          final href = _getHref(child);
          if (href != null && href.startsWith('#')) {
            final id = href.substring(1);
            final path = imagePaths[id];
            if (path != null) {
              final size = imageSizes[id];
              blocks.add(BookBlock.image(
                path,
                width: size?.width,
                height: size?.height,
              ));
            }
          }
          break;
        case 'section':
        case 'body':
          _walk(child, blocks, chapters, imagePaths, imageSizes);
          break;
        default:
          _walk(child, blocks, chapters, imagePaths, imageSizes);
      }
    }
  }

  /// Приводит все типографские пробелы к обычному, убирает soft hyphen,
  /// схлопывает множественные пробелы, переводы строк внутри блока → пробел.
  static String _normalize(String s) {
    return s
        .replaceAll('\u00A0', ' ')   // NBSP — основной виновник «двойных»
        .replaceAll('\u2007', ' ')   // figure space
        .replaceAll('\u202F', ' ')   // narrow NBSP
        .replaceAll('\u2009', ' ')   // thin space
        .replaceAll('\u200A', ' ')   // hair space
        .replaceAll('\u2008', ' ')   // punctuation space
        .replaceAll('\u2006', ' ')
        .replaceAll('\u2005', ' ')
        .replaceAll('\u2004', ' ')
        .replaceAll('\u2003', ' ')   // em space
        .replaceAll('\u2002', ' ')   // en space
        .replaceAll('\u2001', ' ')
        .replaceAll('\u2000', ' ')
        .replaceAll('\u200B', '')    // zero-width space
        .replaceAll('\u00AD', '')    // soft hyphen
        .replaceAll('\t', ' ')
        .replaceAll(RegExp(r'[ ]*\n[ ]*'), ' ')  // переносы → пробел
        .replaceAll(RegExp(r' +'), ' ')          // схлопнуть множественные
        .trim();
  }

  static String? _getHref(XmlElement el) {
    const xlink = 'http://www.w3.org/1999/xlink';
    return el.getAttribute('href', namespace: xlink)
        ?? el.getAttribute('l:href')
        ?? el.getAttribute('href');
  }
}
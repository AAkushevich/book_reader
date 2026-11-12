import 'package:xml/xml.dart';
import 'package:collection/collection.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_content.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_block.dart';

/// Размеры картинки в пикселях.
typedef ImageSize = ({int width, int height});

class Fb2XmlParser {
  /// [imagePaths] — id binary → абсолютный путь к распакованному файлу.
  /// [imageSizes] — id binary → исходные размеры в px (нужны пагинатору).
  ///
  /// Оба аргумента опциональны: если их не передать, парсер работает
  /// как раньше и просто пропускает <image>.
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
          final t = child.innerText.trim();
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
          final t = child.innerText.trim();
          if (t.isNotEmpty) blocks.add(BookBlock.title(t));
          break;
        case 'p':
          final t = child.innerText.trim();
          if (t.isNotEmpty) blocks.add(BookBlock.paragraph(t));
          break;
        case 'epigraph':
          final t = child.innerText.trim();
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
            // если path == null (например, картинку не нашли в <binary>) —
            // молча пропускаем, не ломая текст
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

  /// В FB2 атрибут href лежит в XLink-неймспейсе, но в зависимости от
  /// того как парсер распознал namespace в конкретном файле, читается
  /// по-разному. Пробуем все три варианта.
  static String? _getHref(XmlElement el) {
    const xlink = 'http://www.w3.org/1999/xlink';
    return el.getAttribute('href', namespace: xlink)
        ?? el.getAttribute('l:href')
        ?? el.getAttribute('href');
  }
}
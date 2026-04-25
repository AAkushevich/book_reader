import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';
import 'package:book_reader_app/core/exceptions.dart';

/// Лёгкий DTO для передачи метаданных между изолятами
class BookMetadata {
  final String title;
  final String author;
  const BookMetadata({required this.title, required this.author});
}

/// Публичный API. Запускает парсинг в отдельном потоке (не блокирует UI)
Future<BookMetadata> extractMetadata(String filePath) async {
  try {
    return await Isolate.run(() => _parseSync(filePath));
  } on UnsupportedError catch (e) {
    // ✅ e.message может быть null → используем ?. и ??
    throw UnsupportedFileFormat(e.message?.split(': ').last ?? 'неизвестный формат');
  } on FileSystemException {
    throw FileReadError(filePath);
  } catch (e) {
    throw ParseError(e.toString());
  }
}

/// Чистая синхронная функция. Выполняется ТОЛЬКО внутри изолята
BookMetadata _parseSync(String path) {
  final ext = p.extension(path).toLowerCase().replaceFirst('.', '');
  return switch (ext) {
    'fb2'  => _parseFb2(path),
    'epub' => _parseEpub(path),
    _      => throw UnsupportedError('Format not supported'),
  };
}

BookMetadata _parseFb2(String path) {
  final content = File(path).readAsStringSync(encoding: utf8);
  final doc = XmlDocument.parse(content);
  final desc = doc.findAllElements('description').firstOrNull;

  final title = desc?.findAllElements('book-title').firstOrNull?.innerText.trim() ?? '';
  final authorEl = desc?.findAllElements('author').firstOrNull;
  final author = authorEl != null
      ? '${authorEl.findAllElements('first-name').firstOrNull?.innerText ?? ''} ${authorEl.findAllElements('last-name').firstOrNull?.innerText ?? ''}'.trim()
      : '';

  return BookMetadata(
    title: title.isEmpty ? 'Без названия' : title,
    author: author.isEmpty ? 'Неизвестный автор' : author,
  );
}

BookMetadata _parseEpub(String path) {
  final bytes = File(path).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);

  for (final f in archive) {
    if (f.name.contains('content.opf') || f.name.contains('package.opf')) {
      final content = utf8.decode(f.content as List<int>);
      final doc = XmlDocument.parse(content);
      final meta = doc.findAllElements('metadata').firstOrNull;
      if (meta != null) {
        final title = meta.findAllElements('dc:title').firstOrNull?.innerText.trim() ?? '';
        final author = meta.findAllElements('dc:creator').firstOrNull?.innerText.trim() ?? '';
        return BookMetadata(
          title: title.isEmpty ? 'Без названия' : title,
          author: author.isEmpty ? 'Неизвестный автор' : author,
        );
      }
    }
  }
  return const BookMetadata(title: 'Без названия', author: 'Неизвестный автор');
}
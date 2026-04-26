import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:collection/collection.dart'; // ✅ Для firstWhereOrNull
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';
import 'package:book_reader_app/core/exceptions.dart';

class BookMetadata {
  final String title;
  final String author;
  final Uint8List? coverImage;
  const BookMetadata({required this.title, required this.author, this.coverImage});
}

Future<BookMetadata> extractMetadata(String filePath) async {
  try {
    return await Isolate.run(() => _parseSync(filePath));
  } on UnsupportedError catch (e) {
    throw UnsupportedFileFormat(e.message?.split(': ').last ?? 'неизвестный формат');
  } on FileSystemException {
    throw FileReadError(filePath);
  } catch (e) {
    throw ParseError(e.toString());
  }
}

BookMetadata _parseSync(String path) {
  final ext = p.extension(path).toLowerCase().replaceFirst('.', '');
  return switch (ext) {
    'fb2'  => _parseFb2File(path),
    'zip'  => _parseFb2Zip(path),
    'epub' => _parseEpub(path),
    _      => throw UnsupportedError('Format not supported'),
  };
}

BookMetadata _parseFb2File(String path) {
  final content = File(path).readAsStringSync(encoding: utf8);
  return _parseFb2Content(content);
}

BookMetadata _parseFb2Zip(String path) {
  final bytes = File(path).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);
  final fb2Entry = archive.firstWhereOrNull(
    (f) => f.name.toLowerCase().endsWith('.fb2') && !f.name.endsWith('/'),
  );
  if (fb2Entry == null || fb2Entry.content == null) {
    throw FormatException('Архив не содержит .fb2 файл');
  }
  return _parseFb2Content(utf8.decode(fb2Entry.content as List<int>));
}

BookMetadata _parseFb2Content(String content) {
  final doc = XmlDocument.parse(content);
  final desc = doc.findAllElements('description').firstOrNull;

  final title = desc?.findAllElements('book-title').firstOrNull?.innerText.trim() ?? '';
  final authorEl = desc?.findAllElements('author').firstOrNull;
  final author = authorEl != null
      ? '${authorEl.findAllElements('first-name').firstOrNull?.innerText ?? ''} ${authorEl.findAllElements('last-name').firstOrNull?.innerText ?? ''}'.trim()
      : '';

  // ✅ Извлечение обложки для FB2 (безопасный поиск)
  Uint8List? coverImage;
  final coverPage = doc.findAllElements('coverpage').firstOrNull;
  final coverHref = coverPage?.findAllElements('image').firstOrNull?.getAttribute('href');
  
  if (coverHref != null) {
    final imageId = coverHref.replaceFirst('#', '');
    // ✅ Безопасный поиск вместо firstWhere + orElse: () => null
    final binary = doc.findAllElements('binary').firstWhereOrNull((el) => el.getAttribute('id') == imageId);
    
    if (binary != null) {
      final base64 = binary.innerText.replaceAll('\n', '').replaceAll('\r', '');
      try {
        coverImage = base64Decode(base64);
      } catch (_) {
        // Игнорируем ошибки декодирования
      }
    }
  }

  return BookMetadata(
    title: title.isEmpty ? 'Без названия' : title,
    author: author.isEmpty ? 'Неизвестный автор' : author,
    coverImage: coverImage,
  );
}

BookMetadata _parseEpub(String path) {
  final bytes = File(path).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);

  String? coverPath;
  String title = 'Без названия';
  String author = 'Неизвестный автор';

  // Поиск метаданных и пути к обложке
  for (final f in archive) {
    if (f.name.contains('content.opf') || f.name.contains('package.opf')) {
      final content = utf8.decode(f.content as List<int>);
      final doc = XmlDocument.parse(content);
      final meta = doc.findAllElements('metadata').firstOrNull;
      
      if (meta != null) {
        final t = meta.findAllElements('dc:title').firstOrNull?.innerText.trim();
        if (t?.isNotEmpty == true) title = t!;
        
        final a = meta.findAllElements('dc:creator').firstOrNull?.innerText.trim();
        if (a?.isNotEmpty == true) author = a!;

        // Поиск обложки: мета-тег name="cover"
        final coverMeta = meta.findAllElements('meta').firstWhereOrNull(
          (el) => el.getAttribute('name') == 'cover',
        );
        if (coverMeta != null) {
          coverPath = coverMeta.getAttribute('content');
        }
        
        // Альтернатива: properties="cover-image" в manifest
        if (coverPath == null) {
          final manifest = doc.findAllElements('manifest').firstOrNull;
          if (manifest != null) {
            final coverItem = manifest.findAllElements('item').firstWhereOrNull(
              (el) => (el.getAttribute('properties') ?? '').contains('cover-image'),
            );
            if (coverItem != null) coverPath = coverItem.getAttribute('href');
          }
        }
      }
      break;
    }
  }

  // ✅ Извлечение обложки по найденному пути
if (coverPath != null) {
  final coverFile = archive.firstWhereOrNull(
    // ✅ Добавлена проверка: используем ! только после гарантии, что coverPath != null
    (f) => f.name.endsWith(coverPath!) || f.name.contains('/$coverPath'),
  );
  if (coverFile != null && coverFile.content != null) {
    return BookMetadata(
      title: title,
      author: author,
      coverImage: Uint8List.fromList(coverFile.content as List<int>),
    );
  }
}

  return BookMetadata(title: title, author: author, coverImage: null);
}
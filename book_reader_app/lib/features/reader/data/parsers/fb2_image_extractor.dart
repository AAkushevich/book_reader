import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';  // для Uint8List
import 'package:book_reader_app/features/reader/data/parsers/fb2_xml_parser.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_content.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';

/// Размеры картинки в пикселях.
typedef ImageSize = ({int width, int height});

/// Извлекает <binary> из FB2, пишет на диск, читает размеры.
/// Работает на main isolate: instantiateImageCodec требует binding,
/// в background isolate упадёт. async + await → UI не блокируется.
class Fb2ImageExtractor {
  /// Шорткат для парсеров: взять xml + filePath → распаковать картинки
  /// в кэш + вернуть готовый BookContent.
  static Future<BookContent> extractAndParse(
    String xml,
    String filePath,
  ) async {
    final result = await _extractWithSizes(xml, filePath);
    return Fb2XmlParser.parse(
      xml,
      imagePaths: result.paths,
      imageSizes: result.sizes,
    );
  }

  static Future<({Map<String, String> paths, Map<String, ImageSize> sizes})>
  _extractWithSizes(String xmlContent, String filePath) async {
    final bookHash = filePath.hashCode.toRadixString(16);
    final docs = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${docs.path}/book_images/$bookHash');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    final doc = XmlDocument.parse(xmlContent);
    final paths = <String, String>{};
    final sizes = <String, ImageSize>{};

    for (final bin in doc.findAllElements('binary')) {
      final id = bin.getAttribute('id');
      if (id == null) continue;

      final ext = _extFor(bin.getAttribute('content-type') ?? 'image/jpeg');
      final b64 = bin.innerText.replaceAll(RegExp(r'\s+'), '');

      final Uint8List bytes;
      try {
        bytes = base64Decode(b64);
      } catch (_) {
        continue;
      }

      final path = '${imageDir.path}/$id.$ext';
      final file = File(path);

      // Файл уже есть от прошлой сессии — не перезаписываем
      if (!await file.exists()) {
        await file.writeAsBytes(bytes, flush: false);
      }
      paths[id] = path;

      // Размеры — только если формат декодируется Flutter'ом.
      // SVG упадёт здесь — это ок, пагинатор возьмёт дефолт.
      try {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        sizes[id] = (width: frame.image.width, height: frame.image.height);
        frame.image.dispose();
        codec.dispose();
      } catch (_) {
        // картинка на диске есть, размер неизвестен — рендер возьмёт 40% страницы
      }
    }

    return (paths: paths, sizes: sizes);
  }

  static String _extFor(String contentType) {
    final c = contentType.toLowerCase();
    if (c.contains('png')) return 'png';
    if (c.contains('gif')) return 'gif';
    if (c.contains('webp')) return 'webp';
    if (c.contains('svg')) return 'svg';
    return 'jpg';
  }
}

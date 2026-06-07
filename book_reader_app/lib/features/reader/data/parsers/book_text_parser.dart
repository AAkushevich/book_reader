import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';
import 'package:book_reader_app/core/exceptions.dart';

/// Публичный API. Извлекает чистый текст книги для последующей пагинации.
/// Выполняется в отдельном потоке, чтобы не блокировать UI.
Future<String> extractBookText(String filePath) async {
  try {
    return await Isolate.run(() => _extractTextSync(filePath));
  } on FileSystemException {
    throw FileReadError(filePath);
  } catch (e) {
    throw ParseError('Не удалось извлечь текст: $e');
  }
}

/// Синхронная логика парсинга. Вызывается ТОЛЬКО внутри изолята.
String _extractTextSync(String path) {
  final ext = p.extension(path).toLowerCase().replaceFirst('.', '');
  return switch (ext) {
    'fb2'  => _parseFb2(File(path).readAsStringSync(encoding: utf8)),
    'zip'  => _parseFb2Zip(path),
    'epub' => _parseEpub(path),
    _      => throw UnsupportedError('Format not supported'),
  };
}

/// Извлечение текста из FB2 внутри архива
String _parseFb2Zip(String path) {
  final bytes = File(path).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);
  
  final fb2File = archive.firstWhereOrNull(
    (f) => f.name.toLowerCase().endsWith('.fb2') && !f.name.endsWith('/'),
  );
  if (fb2File == null || fb2File.content == null) {
    throw FormatException('Архив не содержит файл .fb2');
  }
  return _parseFb2(utf8.decode(fb2File.content as List<int>));
}

/// Парсинг XML FB2. Сохраняет структуру абзацев для корректной пагинации.
String _parseFb2(String content) {
  final doc = XmlDocument.parse(content);
  final body = doc.findAllElements('body').firstOrNull;
  if (body == null) return '';

  final buffer = StringBuffer();
  _walkFb2Node(body, buffer);
  // Убираем лишние пустые строки, оставляем максимум 1
  return buffer.toString().replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

void _walkFb2Node(XmlNode node, StringBuffer buffer) {
  if (node is XmlElement) {
    // Блочные элементы требуют переноса строки
    final isBlock = [
      'p', 'title', 'subtitle', 'v', 'text-author', 'empty-line'
    ].contains(node.name.local);
    
    if (isBlock && buffer.isNotEmpty) buffer.writeln();

    for (final child in node.children) {
      _walkFb2Node(child, buffer);
    }

    if (isBlock) buffer.writeln();
  } else if (node is XmlText) {
    final text = node.value.trim();
    if (text.isNotEmpty) buffer.write(text);
  }
}

/// Извлечение текста из EPUB. Читает все XHTML файлы в порядке сортировки.
String _parseEpub(String path) {
  final bytes = File(path).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);

  final buffer = StringBuffer();
  // Фильтруем только контентные файлы
  final contentFiles = archive.where((f) =>
      !f.name.endsWith('/') && // ✅ Проверка на файл вместо isDirectory
      (f.name.endsWith('.xhtml') || f.name.endsWith('.html')) &&
      !f.name.contains('META-INF') &&
      !f.name.contains('nav'));

  // Сортируем по пути для сохранения примерного порядка глав
  final sortedFiles = contentFiles.toList()..sort((a, b) => a.name.compareTo(b.name));

  for (final file in sortedFiles) {
    if (file.content == null) continue;
    try {
      final content = utf8.decode(file.content as List<int>);
      final doc = XmlDocument.parse(content);
      final body = doc.findAllElements('body').firstOrNull;
      if (body != null) {
        buffer.writeln(_extractHtmlText(body));
        buffer.writeln(); // Разделитель между главами
      }
    } catch (_) {
      // Пропускаем битые или несодержательные файлы
    }
  }
  return buffer.toString().replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

/// Рекурсивное извлечение текста из HTML элементов
String _extractHtmlText(XmlElement element) {
  final buffer = StringBuffer();
  for (final child in element.children) {
    if (child is XmlText) {
      final text = child.value.trim();
      if (text.isNotEmpty) buffer.write('$text ');
    } else if (child is XmlElement) {
      buffer.write(_extractHtmlText(child));
      if (['p', 'h1', 'h2', 'h3', 'h4', 'title'].contains(child.name.local)) {
        buffer.writeln();
      }
    }
  }
  return buffer.toString();
}
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:book_reader_app/features/reader/data/parsers/book_parser.dart';

class EpubParser implements BookParser {
  @override
  Future<String> parseBytes(Uint8List bytes) async {

    final archive = ZipDecoder().decodeBytes(bytes);
    final buffer = StringBuffer();

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
              buffer.writeln(body.innerText);
            }
          } catch (e) {
            // Игнорируем файлы, которые не являются валидным XML, 
            // чтобы не ломать парсинг всей книги из-за одного служебного файла
          }
        }
      }
    }
    
    return buffer.toString().trim();
  }
}
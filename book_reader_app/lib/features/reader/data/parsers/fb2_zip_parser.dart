import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:book_reader_app/features/reader/data/parsers/book_parser.dart';
import 'package:book_reader_app/features/reader/data/parsers/fb2_xml_parser.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_content.dart';

class Fb2ZipParser implements BookParser {
  @override
  Future<BookContent> parseBytes(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    
    final fb2File = archive.firstWhereOrNull(
      (f) => f.name.toLowerCase().endsWith('.fb2') && !f.name.endsWith('/'),
    );
    
    if (fb2File == null || fb2File.content == null) {
      throw const FormatException('Архив не содержит валидный файл .fb2');
    }
    
    final contentBytes = fb2File.content as List<int>;
    final content = utf8.decode(contentBytes);
    
    return Fb2XmlParser.parse(content);
  }
}
import 'dart:convert';
import 'dart:typed_data';
import 'package:book_reader_app/features/reader/data/parsers/book_parser.dart';
import 'package:book_reader_app/features/reader/data/parsers/fb2_xml_parser.dart';

class Fb2Parser implements BookParser {
  @override
  Future<String> parseBytes(Uint8List bytes) async {
    final content = utf8.decode(bytes);
    
    return Fb2XmlParser.parse(content);
  }
}
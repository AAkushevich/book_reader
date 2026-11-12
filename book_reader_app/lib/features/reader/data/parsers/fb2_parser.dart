import 'dart:convert';
import 'dart:typed_data';
import 'package:book_reader_app/features/reader/data/parsers/book_parser.dart';
import 'package:book_reader_app/features/reader/data/parsers/fb2_image_extractor.dart';
import 'package:book_reader_app/features/reader/data/parsers/fb2_xml_parser.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_content.dart';

class Fb2Parser implements BookParser {
  @override
  Future<BookContent> parseBytes(Uint8List bytes, {String? filePath}) async {
    final xml = utf8.decode(bytes);

    if (filePath == null) {
      return Fb2XmlParser.parse(xml);
    }

    return Fb2ImageExtractor.extractAndParse(xml, filePath);
  }
}
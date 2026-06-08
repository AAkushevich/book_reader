import 'dart:typed_data';

abstract class BookParser {
  Future<String> parseBytes(Uint8List bytes);
}
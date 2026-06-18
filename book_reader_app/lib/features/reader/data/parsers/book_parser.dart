import 'dart:typed_data';
import 'package:book_reader_app/features/reader/domain/entities/book_content.dart';

abstract class BookParser {
  Future<BookContent> parseBytes(Uint8List bytes);
}
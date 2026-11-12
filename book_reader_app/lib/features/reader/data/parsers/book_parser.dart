import 'dart:typed_data';
import 'package:book_reader_app/features/reader/domain/entities/book_content.dart';

abstract class BookParser {
  /// [filePath] опционален — нужен парсерам, которые извлекают
  /// ресурсы (картинки) в кэш рядом с книгой. Остальные его игнорируют.
  Future<BookContent> parseBytes(Uint8List bytes, {String? filePath});
}
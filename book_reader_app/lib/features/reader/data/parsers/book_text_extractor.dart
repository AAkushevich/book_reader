import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:book_reader_app/core/exceptions.dart';
import 'package:book_reader_app/features/reader/data/parsers/book_parser.dart';
import 'package:book_reader_app/features/reader/data/parsers/fb2_parser.dart';
import 'package:book_reader_app/features/reader/data/parsers/fb2_zip_parser.dart';
import 'package:book_reader_app/features/reader/data/parsers/epub_parser.dart';

/// Сервис для извлечения текста из книг.
/// Инкапсулирует реестр парсеров и логику чтения файлов.
class BookTextExtractor {
  // Делаем карту финальной и приватной (_). 
  // Теперь это не "глобальная переменная", а защищённое внутреннее состояние класса.
  final Map<String, BookParser> _parsers = {
    'fb2': Fb2Parser(),
    'zip': Fb2ZipParser(),
    'epub': EpubParser(),
  };

  /// Извлекает текст из файла по указанному пути.
  Future<String> extract(String filePath) async {
    // 1. Получаем расширение
    final ext = p.extension(filePath).toLowerCase().replaceFirst('.', '');
    
    // 2. Находим парсер
    final parser = _parsers[ext];
    
    // 3. Валидация
    if (parser == null) {
      throw UnsupportedFileFormat(ext);
    }
    
    // 4. Чтение байтов (I/O)
    final Uint8List bytes = await File(filePath).readAsBytes();
    
    // 5. Делегирование парсинга (Бизнес-логика)
    return await parser.parseBytes(bytes);
  }
}
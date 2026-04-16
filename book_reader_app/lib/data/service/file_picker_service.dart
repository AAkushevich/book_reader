import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:logging/logging.dart';

/// Сервис для выбора файлов через системный файловый менеджер
class FilePickerService {
  final Logger _logger = Logger('FilePickerService');
  
  /// Открыть системный файловый менеджер для выбора ОДНОГО файла
  /// Возвращает выбранный файл или null если пользователь отменил
  Future<File?> pickSingleBook() async {
    try {
      _logger.info('Открываем системный файловый менеджер для выбора книги');
      
      // Открываем файловый менеджер с фильтром на FB2 и EPUB
      final result = await FilePicker.pickFiles(
        allowMultiple: false,  // Только один файл
        type: FileType.custom,
        allowedExtensions: ['fb2', 'epub'],
        dialogTitle: 'Выберите книгу для чтения',
      );
      
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        _logger.info('Выбран файл: $filePath');
        return File(filePath);
      }
      
      _logger.info('Пользователь отменил выбор файла');
      return null;
      
    } catch (e, stackTrace) {
      _logger.severe('Ошибка при выборе файла', e, stackTrace);
      return null;
    }
  }
  
  /// Открыть файловый менеджер для выбора НЕСКОЛЬКИХ файлов
  Future<List<File>> pickMultipleBooks() async {
    try {
      _logger.info('Открываем системный файловый менеджер для выбора нескольких книг');
      
      final result = await FilePicker.pickFiles(
        allowMultiple: true,   // Несколько файлов
        type: FileType.custom,
        allowedExtensions: ['fb2', 'epub'],
        dialogTitle: 'Выберите книги для добавления',
      );
      
      if (result != null) {
        final files = result.files
            .where((f) => f.path != null)
            .map((f) => File(f.path!))
            .toList();
        
        _logger.info('Выбрано файлов: ${files.length}');
        return files;
      }
      
      return [];
      
    } catch (e, stackTrace) {
      _logger.severe('Ошибка при выборе файлов', e, stackTrace);
      return [];
    }
  }
}
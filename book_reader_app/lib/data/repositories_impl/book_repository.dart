import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logging/logging.dart';
import '../models/book_model.dart';

/// Репозиторий для поиска книг на устройстве
/// SOLID: Single Responsibility - только поиск и получение книг
class BookRepositoryImpl {
  final Logger _logger = Logger('BookRepositoryImpl');
  
  // Разрешенные расширения файлов
  static const List<String> _supportedExtensions = ['fb2', 'epub'];
  
  // Минимальный размер файла (10 KB) - исключаем пустые файлы
  static const int _minFileSize = 10240;

  /// Поиск всех книг на устройстве
  /// Возвращает список книг или выбрасывает исключение
  Future<List<BookModel>> searchAllBooks() async {
    try {
      _logger.info('Начинаем поиск книг на устройстве');
      
      // Проверяем разрешения
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        throw Exception('Нет разрешения на чтение файлов');
      }
      
      // Получаем доступные директории
      final directories = await _getSearchDirectories();
      _logger.fine('Директории для поиска: ${directories.length}');
      
      final List<BookModel> books = [];
      
      // Сканируем каждую директорию
      for (final dir in directories) {
        if (!await dir.exists()) continue;
        
        await _scanDirectory(dir, books);
      }
      
      _logger.info('Поиск завершен. Найдено книг: ${books.length}');
      return books;
      
    } catch (e, stackTrace) {
      _logger.severe('Ошибка при поиске книг', e, stackTrace);
      throw Exception('Ошибка поиска книг: $e');
    }
  }
  
  /// Рекурсивное сканирование директории
  Future<void> _scanDirectory(Directory dir, List<BookModel> books) async {
    try {
      // Защита от слишком глубокой рекурсии
      final List<FileSystemEntity> entities;
      try {
        entities = await dir.list().toList();
      } catch (e) {
        _logger.warning('Не удалось прочитать директорию ${dir.path}: $e');
        return;
      }
      
      for (final entity in entities) {
        // Проверка на отмену (опционально - добавить CancelToken)
        
        if (entity is File) {
          final book = await _processFile(entity);
          if (book != null) {
            books.add(book);
          }
        } else if (entity is Directory) {
          // Избегаем системные директории
          if (_shouldSkipDirectory(entity.path)) continue;
          await _scanDirectory(entity, books);
        }
      }
    } catch (e) {
      _logger.warning('Ошибка сканирования ${dir.path}: $e');
    }
  }
  
  /// Обработка отдельного файла
  Future<BookModel?> _processFile(File file) async {
    try {
      final extension = file.path.split('.').last.toLowerCase();
      
      // Проверяем расширение
      if (!_supportedExtensions.contains(extension)) return null;
      
      // Проверяем размер
      final size = await file.length();
      if (size < _minFileSize) {
        _logger.fine('Файл слишком мал: ${file.path} ($size bytes)');
        return null;
      }
      
      // Проверяем, что файл читаемый
      if (!await file.exists()) return null;
      
      return BookModel.fromFile(file);
      
    } catch (e) {
      _logger.warning('Ошибка обработки файла ${file.path}: $e');
      return null;
    }
  }
  
  /// Проверка и запрос разрешений
  Future<bool> _checkPermissions() async {
    // Для Android 13+ (API 33+) используем новые разрешения
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      
      if (status.isDenied) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
      
      return status.isGranted;
    }
    
    // Для iOS разрешения запрашиваются автоматически
    return true;
  }
  
/// Получение директорий для поиска (для Android с полным доступом)
Future<List<Directory>> _getSearchDirectories() async {
  final directories = <Directory>[];
  
  if (Platform.isAndroid) {
    // Проверяем, есть ли полный доступ
    final hasFullAccess = await Permission.manageExternalStorage.status == PermissionStatus.granted;
    
    if (hasFullAccess) {
      // При полном доступе сканируем все доступные директории
      directories.addAll(await _getAllDirectories());
    } else {
      // Без полного доступа - только стандартные
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          directories.add(externalDir);
          
          final downloadsDir = Directory('${externalDir.path}/Download');
          if (await downloadsDir.exists()) {
            directories.add(downloadsDir);
          }
          
          final booksDir = Directory('${externalDir.path}/Books');
          if (await booksDir.exists()) {
            directories.add(booksDir);
          }
        }
      } catch (e) {
        _logger.warning('Ошибка доступа к хранилищу: $e');
      }
    }
    
    final appDir = await getApplicationDocumentsDirectory();
    directories.add(appDir);
  }
  
  return directories;
}

/// Получение всех возможных директорий (только при полном доступе)
Future<List<Directory>> _getAllDirectories() async {
  final List<Directory> dirs = [];
  
  // Основные пути на Android
  final List<String> paths = [
    '/storage/emulated/0/',           // Внутренняя память
    '/storage/emulated/0/Download',   // Загрузки
    '/storage/emulated/0/Documents',  // Документы
    '/storage/emulated/0/Books',      // Книги
    '/storage/emulated/0/DCIM',       // Изображения (могут быть книги)
    '/sdcard/',                        // Альтернативный путь к SD карте
    '/storage/sdcard0/',              // SD карта вариант 1
    '/storage/sdcard1/',              // SD карта вариант 2
  ];
  
  for (final path in paths) {
    final dir = Directory(path);
    if (await dir.exists()) {
      dirs.add(dir);
      _logger.fine('Добавлена директория для сканирования: $path');
    }
  }
  
  return dirs;
}
  
  /// Пропуск системных директорий
  bool _shouldSkipDirectory(String path) {
    final skipPatterns = [
      '/Android/data',
      '/Android/obb',
      'com.android',
      'cache',
      'temp',
      '.thumbnails',
      '.trash',
    ];
    
    return skipPatterns.any((pattern) => path.contains(pattern));
  }
}
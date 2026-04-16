import 'package:equatable/equatable.dart';
import 'dart:io';
/// Модель книги для работы в приложении
/// Следует принципу иммутабельности (Equatable для сравнения)
class BookModel extends Equatable {
  final String id;           // Уникальный ID (путь + имя файла)
  final String title;       // Название книги
  final String author;      // Автор
  final String filePath;    // Полный путь к файлу
  final String fileName;    // Имя файла
  final String extension;   // Расширение (fb2/epub)
  final int fileSize;       // Размер в байтах
  final DateTime modified;  // Дата последнего изменения
  final String? coverPath;  // Путь к обложке (опционально)

  const BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.filePath,
    required this.fileName,
    required this.extension,
    required this.fileSize,
    required this.modified,
    this.coverPath,
  });

  /// Фабричный метод для создания из файла
  factory BookModel.fromFile(File file) {
    final path = file.path;
    final name = path.split('/').last;
    final ext = name.split('.').last.toLowerCase();
    
    return BookModel(
      id: path, // Используем путь как ID
      title: _extractTitle(name), // Временное извлечение из имени
      author: 'Неизвестный автор', // Временное значение
      filePath: path,
      fileName: name,
      extension: ext,
      fileSize: file.lengthSync(),
      modified: file.lastModifiedSync(),
    );
  }

  /// Вспомогательный метод для извлечения названия из имени файла
  static String _extractTitle(String fileName) {
    // Удаляем расширение
    final nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'));
    // Заменяем подчеркивания и точки на пробелы
    return nameWithoutExt.replaceAll(RegExp(r'[_.]'), ' ');
  }

  @override
  List<Object?> get props => [id, title, author, filePath, modified];
}
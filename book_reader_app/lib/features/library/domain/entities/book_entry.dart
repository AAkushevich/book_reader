import 'package:equatable/equatable.dart';

/// Чистая доменная сущность книги. Не зависит от Flutter, БД или парсеров.
class BookEntry extends Equatable {
  final String id;
  final String title;
  final String author;
  final String filePath;
  final int fileSizeBytes;
  final String extension;
  final DateTime addedAt;

  const BookEntry({
    required this.id,
    required this.title,
    required this.author,
    required this.filePath,
    required this.fileSizeBytes,
    required this.extension,
    required this.addedAt,
  });

  /// Форматированный размер для UI
  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [id, title, author, filePath, fileSizeBytes, extension, addedAt];
}
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

  final DateTime? lastReadAt;      // null = книга ещё не открывалась
  final double readingProgress;    // 0.0 ... 1.0

  const BookEntry({
    required this.id,
    required this.title,
    required this.author,
    required this.filePath,
    required this.fileSizeBytes,
    required this.extension,
    required this.addedAt,
    this.lastReadAt,
    this.readingProgress = 0.0,
  });

  /// Форматированный размер для UI
  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get hasBeenRead => lastReadAt != null;

  int get progressPercent => (readingProgress * 100).round();

  BookEntry markAsReadNow({double? newProgress}) {
    return BookEntry(
      id: id,
      title: title,
      author: author,
      filePath: filePath,
      fileSizeBytes: fileSizeBytes,
      extension: extension,
      addedAt: addedAt,
      lastReadAt: DateTime.now(),
      readingProgress: newProgress ?? readingProgress,
    );
  }

  BookEntry withProgress(double newProgress) {
    return BookEntry(
      id: id,
      title: title,
      author: author,
      filePath: filePath,
      fileSizeBytes: fileSizeBytes,
      extension: extension,
      addedAt: addedAt,
      lastReadAt: lastReadAt,
      readingProgress: newProgress.clamp(0.0, 1.0),
    );
  }

  BookEntry copyWith({
    String? title,
    String? author,
    String? filePath,
    int? fileSizeBytes,
    String? extension,
    DateTime? addedAt,
    DateTime? lastReadAt,
    double? readingProgress,
  }) {
    return BookEntry(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      extension: extension ?? this.extension,
      addedAt: addedAt ?? this.addedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      readingProgress: readingProgress ?? this.readingProgress,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        filePath,
        fileSizeBytes,
        extension,
        addedAt,
        lastReadAt,
        readingProgress,
      ];
}
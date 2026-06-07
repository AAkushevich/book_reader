import 'package:book_reader_app/features/reader/domain/entities/reading_progress.dart';

/// Контракт репозитория читалки.
/// Отвечает ТОЛЬКО за хранение и извлечение прогресса чтения.
/// НЕ занимается парсингом файлов.
abstract class ReaderRepository {
  /// Загрузить сохранённый прогресс. Вернёт null, если книга открывается впервые.
  Future<ReadingProgress?> loadProgress(String bookId);

  /// Сохранить или полностью перезаписать прогресс.
  Future<void> saveProgress(ReadingProgress progress);

  /// Быстрое обновление только номера текущей страницы.
  Future<void> updatePage(String bookId, int pageIndex);

  /// Быстрое обновление только настроек отображения.
  Future<void> updateSettings(
    String bookId, {
    double? fontSize,
    String? fontFamily,
    bool? isDarkMode,
  });
}
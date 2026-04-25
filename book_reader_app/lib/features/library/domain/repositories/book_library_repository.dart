import 'package:book_reader_app/features/library/domain/entities/book_entry.dart';

/// Абстрактный контракт репозитория библиотеки.
/// Определяет, какие операции может выполнять слой данных.
/// Не содержит логики хранения, парсинга или UI.
abstract class BookLibraryRepository {
  /// Добавляет книгу: парсит метаданные → сохраняет в БД → возвращает сущность.
  Future<BookEntry> addBookFromPath(String filePath);

  /// Возвращает отсортированный список всех добавленных книг (новые сверху).
  Future<List<BookEntry>> getAllBooks();

  /// Удаляет книгу из списка (файл на диске остаётся нетронутым).
  Future<void> removeBook(String filePath);

  /// Полная очистка списка библиотеки.
  Future<void> clearLibrary();
}
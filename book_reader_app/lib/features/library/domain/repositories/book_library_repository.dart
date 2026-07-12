import 'package:book_reader_app/features/library/domain/entities/book_entry.dart';

/// Абстрактный контракт репозитория библиотеки.
/// Определяет, какие операции может выполнять слой данных.
/// Не содержит логики хранения, парсинга или UI.
abstract class BookLibraryRepository {
  Future<BookEntry> addBookFromPath(String filePath);
  Future<List<BookEntry>> getAllBooks();
  Future<void> removeBook(String filePath);
  Future<void> clearLibrary();
  Future<void> updateLastRead(String filePath);
  Future<void> updateProgress(String filePath, double progress);
}
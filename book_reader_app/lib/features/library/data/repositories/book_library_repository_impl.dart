import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:book_reader_app/core/exceptions.dart';
import 'package:book_reader_app/features/library/domain/entities/book_entry.dart';
import 'package:book_reader_app/features/library/domain/repositories/book_library_repository.dart';
import 'package:book_reader_app/features/library/data/datasources/sembast_storage.dart';
import 'package:book_reader_app/features/library/data/parsers/metadata_parser.dart';

/// Реализация контракта библиотеки.
/// Связывает парсер метаданных и хранилище, соблюдая границы домена.
class BookLibraryRepositoryImpl implements BookLibraryRepository {
  final SembastBookStorage _storage;

  BookLibraryRepositoryImpl(this._storage);

  @override
  Future<BookEntry> addBookFromPath(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const FileReadError('Файл не найден или недоступен');
    }

    final ext = p.extension(filePath).toLowerCase().replaceFirst('.', '');
    if (!['fb2', 'epub'].contains(ext)) {
      throw UnsupportedFileFormat(ext);
    }

    // 1. Извлекаем метаданные в изоляте (не блокирует UI)
    final metadata = await extractMetadata(filePath);

    // 2. Формируем доменную сущность
    final entry = BookEntry(
      id: filePath,
      title: metadata.title,
      author: metadata.author,
      filePath: filePath,
      fileSizeBytes: await file.length(),
      extension: ext,
      addedAt: DateTime.now(),
    );

    // 3. Сохраняем в БД
    await _storage.save(entry);
    return entry;
  }

  @override
  Future<List<BookEntry>> getAllBooks() => _storage.getAll();

  @override
  Future<void> removeBook(String filePath) => _storage.remove(filePath);

  @override
  Future<void> clearLibrary() => _storage.clear();
}
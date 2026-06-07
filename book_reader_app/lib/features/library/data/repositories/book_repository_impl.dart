import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast.dart'; // ✅ Добавлен импорт Sembast
import 'package:book_reader_app/core/exceptions.dart';
import 'package:book_reader_app/core/database/app_database.dart'; // ✅ Единая БД
import 'package:book_reader_app/features/library/domain/entities/book_entry.dart';
import 'package:book_reader_app/features/library/domain/repositories/book_library_repository.dart';
import 'package:book_reader_app/features/library/data/parsers/metadata_parser.dart';

class BookLibraryRepositoryImpl implements BookLibraryRepository {
  final AppDatabase _db;

  BookLibraryRepositoryImpl(this._db);

  @override
  Future<BookEntry> addBookFromPath(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const FileReadError('Файл не найден или недоступен');
    }

    final ext = p.extension(filePath).toLowerCase().replaceFirst('.', '');
    if (!['fb2', 'zip', 'epub'].contains(ext)) {
      throw UnsupportedFileFormat(ext);
    }

    final metadata = await extractMetadata(filePath);

    final entry = BookEntry(
      id: filePath,
      title: metadata.title,
      author: metadata.author,
      filePath: filePath,
      fileSizeBytes: await file.length(),
      extension: ext,
      addedAt: DateTime.now(),
    );

    await _db.books.record(entry.id).put(_db.db, _toJson(entry));
    return entry;
  }

  @override
  Future<List<BookEntry>> getAllBooks() async {
    final records = await _db.books.find(_db.db);
    return records.map((record) => _fromJson(record.value)).toList();
  }

  @override
  Future<void> removeBook(String filePath) async {
    await _db.books.record(filePath).delete(_db.db);
  }

  @override
  Future<void> clearLibrary() async {
    await _db.books.delete(_db.db);
  }

  // === Сериализация ===

  Map<String, dynamic> _toJson(BookEntry book) => {
    'id': book.id,
    'title': book.title,
    'author': book.author,
    'filePath': book.filePath,
    'fileSizeBytes': book.fileSizeBytes,
    'extension': book.extension,
    'addedAtMs': book.addedAt.millisecondsSinceEpoch,
  };

  BookEntry _fromJson(Map<String, dynamic> json) => BookEntry(
    id: json['id'] as String,
    title: json['title'] as String,
    author: json['author'] as String,
    filePath: json['filePath'] as String,
    fileSizeBytes: json['fileSizeBytes'] as int,
    extension: json['extension'] as String,
    addedAt: DateTime.fromMillisecondsSinceEpoch(json['addedAtMs'] as int),
  );
}
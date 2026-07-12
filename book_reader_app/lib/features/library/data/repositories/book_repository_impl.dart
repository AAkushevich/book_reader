import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast.dart';
import 'package:book_reader_app/core/exceptions.dart';
import 'package:book_reader_app/core/database/app_database.dart';
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
    final books = records.map((record) => _fromJson(record.value)).toList();
    
    // ✅ Сортировка: сначала прочитанные (по lastReadAt, новые сверху),
    // затем непрочитанные (по addedAt, новые сверху)
    books.sort((a, b) {
      if (a.hasBeenRead && b.hasBeenRead) {
        return b.lastReadAt!.compareTo(a.lastReadAt!);
      }
      if (a.hasBeenRead) return -1;
      if (b.hasBeenRead) return 1;
      return b.addedAt.compareTo(a.addedAt);
    });
    
    return books;
  }

  @override
  Future<void> removeBook(String filePath) async {
    await _db.books.record(filePath).delete(_db.db);
  }

  @override
  Future<void> clearLibrary() async {
    await _db.books.delete(_db.db);
  }

  // ✅ НОВЫЕ МЕТОДЫ: обновление времени чтения и прогресса
  
  @override
  Future<void> updateLastRead(String filePath) async {
    final record = _db.books.record(filePath);
    final json = await record.get(_db.db);
    if (json == null) return;
    
    final book = _fromJson(json);
    final updated = book.markAsReadNow();
    await record.put(_db.db, _toJson(updated));
  }

  @override
  Future<void> updateProgress(String filePath, double progress) async {
    final record = _db.books.record(filePath);
    final json = await record.get(_db.db);
    if (json == null) return;
    
    final book = _fromJson(json);
    final updated = book.withProgress(progress);
    await record.put(_db.db, _toJson(updated));
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
    // ✅ Новые поля
    'lastReadAtMs': book.lastReadAt?.millisecondsSinceEpoch,
    'readingProgress': book.readingProgress,
  };

  BookEntry _fromJson(Map<String, dynamic> json) => BookEntry(
    id: json['id'] as String,
    title: json['title'] as String,
    author: json['author'] as String,
    filePath: json['filePath'] as String,
    fileSizeBytes: json['fileSizeBytes'] as int,
    extension: json['extension'] as String,
    addedAt: DateTime.fromMillisecondsSinceEpoch(json['addedAtMs'] as int),
    // ✅ Обратная совместимость: если поля нет — null / 0.0
    lastReadAt: json['lastReadAtMs'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['lastReadAtMs'] as int)
        : null,
    readingProgress: (json['readingProgress'] as num?)?.toDouble() ?? 0.0,
  );
}
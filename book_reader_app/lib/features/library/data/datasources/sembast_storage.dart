import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:book_reader_app/features/library/domain/entities/book_entry.dart';

class SembastBookStorage {
  late final Database _db;
  final _store = stringMapStoreFactory.store('books');

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/book_library.db';
    _db = await databaseFactoryIo.openDatabase(dbPath);
  }

  Future<void> save(BookEntry book) async {
    await _store.record(book.id).put(_db, _toJson(book));
  }

  Future<List<BookEntry>> getAll() async {
    final records = await _store.find(_db);
    final books = records.map((r) => _fromJson(r.value)).toList();
    
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

  Future<void> remove(String filePath) async {
    // Удаляем файл обложки
    final record = _store.record(filePath);
    final json = await record.get(_db);
    if (json != null) {
      final book = _fromJson(json);
      if (book.coverImagePath != null) {
        final coverFile = File(book.coverImagePath!);
        if (await coverFile.exists()) {
          await coverFile.delete();
        }
      }
    }
    
    await record.delete(_db);
  }

  Future<void> clear() async {
    // Удаляем все файлы обложек
    try {
      final dir = await getApplicationDocumentsDirectory();
      final coverDir = Directory('${dir.path}/covers');
      if (await coverDir.exists()) {
        await coverDir.delete(recursive: true);
      }
    } catch (e) {
      // Игнорируем
    }
    
    await _store.delete(_db);
  }

  Map<String, dynamic> _toJson(BookEntry book) => {
    'id': book.id,
    'title': book.title,
    'author': book.author,
    'filePath': book.filePath,
    'fileSizeBytes': book.fileSizeBytes,
    'extension': book.extension,
    'addedAtMs': book.addedAt.millisecondsSinceEpoch,
    'lastReadAtMs': book.lastReadAt?.millisecondsSinceEpoch,
    'readingProgress': book.readingProgress,
    'coverImagePath': book.coverImagePath,
  };

  BookEntry _fromJson(Map<String, dynamic> json) => BookEntry(
    id: json['id'] as String,
    title: json['title'] as String,
    author: json['author'] as String,
    filePath: json['filePath'] as String,
    fileSizeBytes: json['fileSizeBytes'] as int,
    extension: json['extension'] as String,
    addedAt: DateTime.fromMillisecondsSinceEpoch(json['addedAtMs'] as int),
    lastReadAt: json['lastReadAtMs'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['lastReadAtMs'] as int)
        : null,
    readingProgress: (json['readingProgress'] as num?)?.toDouble() ?? 0.0,
    coverImagePath: json['coverImagePath'] as String?,
  );
}
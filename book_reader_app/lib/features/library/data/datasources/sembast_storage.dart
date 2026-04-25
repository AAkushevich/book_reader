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
    final records = await _store.find(_db, finder: Finder(sortOrders: [
      // ✅ ascending: false = сортировка по убыванию (новые записи сверху)
      SortOrder('addedAtMs', false),
    ]));
    return records.map((r) => _fromJson(r.value)).toList();
  }

  Future<void> remove(String filePath) async {
    await _store.record(filePath).delete(_db);
  }

  Future<void> clear() async {
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
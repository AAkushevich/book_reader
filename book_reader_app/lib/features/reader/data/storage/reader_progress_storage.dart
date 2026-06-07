import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:book_reader_app/features/reader/domain/entities/reading_progress.dart';

/// Низкоуровневый источник данных для прогресса чтения и настроек.
/// Использует ту же Sembast БД, что и библиотека книг.
class ReaderProgressStorage {
  late final Database _db;
  final _store = stringMapStoreFactory.store('reading_sessions');

  /// Инициализация. Вызывается один раз в main() (можно переиспользовать ту же БД)
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    // Используем тот же файл БД, чтобы не плодить соединения
    final dbPath = '${dir.path}/book_library.db';
    _db = await databaseFactoryIo.openDatabase(dbPath);
  }

  /// Загрузить сессию по ID книги. Вернёт null, если книга открывается впервые.
  Future<ReadingProgress?> loadSession(String bookId) async {
    final snapshot = await _store.record(bookId).get(_db);
    if (snapshot == null) return null;
    return _fromJson(snapshot as Map<String, dynamic>);
  }

  /// Сохранить или обновить полную сессию
  Future<void> saveSession(ReadingProgress session) async {
    await _store.record(session.bookId).put(_db, _toJson(session));
  }

  /// Удалить сессию (опционально, если пользователь удаляет книгу из библиотеки)
  Future<void> deleteSession(String bookId) async {
    await _store.record(bookId).delete(_db);
  }

  // === Ручная сериализация (совместима с архитетурой без генераторов) ===
  Map<String, dynamic> _toJson(ReadingProgress s) => {
    'bookId': s.bookId,
    'currentPageIndex': s.currentPageIndex,
    'fontSize': s.fontSize,
    'fontFamily': s.fontFamily,
    'isDarkMode': s.isDarkMode,
    'lastReadAtMs': s.lastReadAt.millisecondsSinceEpoch,
  };

  ReadingProgress _fromJson(Map<String, dynamic> json) => ReadingProgress(
    bookId: json['bookId'] as String,
    currentPageIndex: json['currentPageIndex'] as int? ?? 0,
    fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
    fontFamily: json['fontFamily'] as String? ?? 'sans-serif',
    isDarkMode: json['isDarkMode'] as bool? ?? false,
    lastReadAt: DateTime.fromMillisecondsSinceEpoch(
      json['lastReadAtMs'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    ),
  );
}
import 'package:sembast/sembast.dart';
import 'package:book_reader_app/core/database/app_database.dart';
import 'package:book_reader_app/features/reader/domain/entities/reading_progress.dart';
import 'package:book_reader_app/features/reader/domain/repositories/reader_repository.dart';

/// Реализация контракта читалки.
/// 
/// Отвечает ТОЛЬКО за сохранение и извлечение прогресса чтения из БД.
/// НЕ занимается парсингом файлов — это задача отдельного слоя (parsers).
class ReaderRepositoryImpl implements ReaderRepository {
  final AppDatabase _db;

  ReaderRepositoryImpl(this._db);

  @override
  Future<ReadingProgress?> loadProgress(String bookId) async {
    final snapshot = await _db.progress.record(bookId).get(_db.db);
    if (snapshot == null) return null;
    return _fromJson(snapshot);
  }

  @override
  Future<void> saveProgress(ReadingProgress progress) async {
    await _db.progress.record(progress.bookId).put(_db.db, _toJson(progress));
  }

  @override
  Future<void> updatePage(String bookId, int pageIndex) async {
    final existing = await loadProgress(bookId);
    final updated = (existing ?? ReadingProgress.initial(bookId)).updatePage(pageIndex);
    await saveProgress(updated);
  }

  @override
  Future<void> updateSettings(
    String bookId, {
    double? fontSize,
    String? fontFamily,
    bool? isDarkMode,
    double? lineHeight,
    double? paragraphSpacing,
  }) async {
    final existing = await loadProgress(bookId);
    final updated = (existing ?? ReadingProgress.initial(bookId)).updateSettings(
      fontSize: fontSize,
      fontFamily: fontFamily,
      isDarkMode: isDarkMode,
      lineHeight: lineHeight,
      paragraphSpacing: paragraphSpacing,
    );
    await saveProgress(updated);
  }

  // === Сериализация (внутренняя логика преобразования) ===

  Map<String, dynamic> _toJson(ReadingProgress s) => {
    'bookId': s.bookId,
    'currentPageIndex': s.currentPageIndex,
    'fontSize': s.fontSize,
    'fontFamily': s.fontFamily,
    'isDarkMode': s.isDarkMode,
    'lineHeight': s.lineHeight,
    'paragraphSpacing': s.paragraphSpacing,
    'lastReadAtMs': s.lastReadAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
  };
  ReadingProgress _fromJson(Map<String, dynamic> json) => ReadingProgress(
    bookId: json['bookId'] as String,
    currentPageIndex: json['currentPageIndex'] as int? ?? 0,
    fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
    fontFamily: json['fontFamily'] as String? ?? 'PTSerif',
    isDarkMode: json['isDarkMode'] as bool? ?? false,
    lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.5,
    paragraphSpacing: (json['paragraphSpacing'] as num?)?.toDouble() ?? 0.75,
    lastReadAt: json['lastReadAtMs'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['lastReadAtMs'] as int)
        : null, 
  );
}
import 'package:equatable/equatable.dart';

/// Сессия чтения: хранит прогресс и настройки для конкретной книги.
/// Не зависит от UI, БД, парсинга или Flutter.
class ReadingSession extends Equatable {
  final String bookId;           // Ссылка на книгу (путь к файлу)
  final int currentPageIndex;    // Текущая страница (0-based)
  final double fontSize;         // Размер шрифта
  final String fontFamily;       // Семейство шрифта
  final bool isDarkMode;         // Тема
  final DateTime lastReadAt;     // Время последнего открытия

  const ReadingSession({
    required this.bookId,
    this.currentPageIndex = 0,
    this.fontSize = 16.0,
    this.fontFamily = 'sans-serif',
    this.isDarkMode = false,
    required this.lastReadAt,
  });

  /// Создать сессию с настройками по умолчанию для новой книги
  factory ReadingSession.initial(String bookId) => ReadingSession(
    bookId: bookId,
    lastReadAt: DateTime.now(),
  );

  /// Обновить позицию чтения
  ReadingSession updateProgress(int pageIndex) => copyWith(
    currentPageIndex: pageIndex,
    lastReadAt: DateTime.now(),
  );

  /// Обновить настройки отображения
  ReadingSession updateSettings({double? fontSize, String? fontFamily, bool? isDarkMode}) => copyWith(
    fontSize: fontSize,
    fontFamily: fontFamily,
    isDarkMode: isDarkMode,
  );

  ReadingSession copyWith({
    int? currentPageIndex,
    double? fontSize,
    String? fontFamily,
    bool? isDarkMode,
    DateTime? lastReadAt,
  }) {
    return ReadingSession(
      bookId: bookId,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }

  @override
  List<Object?> get props => [
    bookId, currentPageIndex, fontSize, fontFamily, isDarkMode, lastReadAt,
  ];
}
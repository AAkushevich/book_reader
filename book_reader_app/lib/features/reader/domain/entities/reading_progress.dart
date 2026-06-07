import 'package:equatable/equatable.dart';

/// Сущность, хранящая прогресс и настройки чтения для конкретной книги.
/// Не зависит от UI, БД или Flutter.
class ReadingProgress extends Equatable {
  final String bookId;           // Ссылка на книгу (путь к файлу)
  final int currentPageIndex;    // Текущая страница (0-based)
  final double fontSize;         // Размер шрифта
  final String fontFamily;       // Семейство шрифта
  final bool isDarkMode;         // Тема
  final DateTime lastReadAt;     // Время последнего открытия

  const ReadingProgress({
    required this.bookId,
    this.currentPageIndex = 0,
    this.fontSize = 16.0,
    this.fontFamily = 'sans-serif',
    this.isDarkMode = false,
    required this.lastReadAt,
  });

  /// Создать прогресс с настройками по умолчанию для новой книги
  factory ReadingProgress.initial(String bookId) => ReadingProgress(
    bookId: bookId,
    lastReadAt: DateTime.now(),
  );

  /// Обновить позицию чтения
  ReadingProgress updatePage(int pageIndex) => copyWith(
    currentPageIndex: pageIndex,
    lastReadAt: DateTime.now(),
  );

  /// Обновить настройки отображения
  ReadingProgress updateSettings({double? fontSize, String? fontFamily, bool? isDarkMode}) => copyWith(
    fontSize: fontSize,
    fontFamily: fontFamily,
    isDarkMode: isDarkMode,
  );

  ReadingProgress copyWith({
    int? currentPageIndex,
    double? fontSize,
    String? fontFamily,
    bool? isDarkMode,
    DateTime? lastReadAt,
  }) {
    return ReadingProgress(
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
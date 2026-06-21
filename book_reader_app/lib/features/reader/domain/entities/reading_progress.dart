import 'package:equatable/equatable.dart';

class ReadingProgress extends Equatable {
  final String bookId;
  final int currentPageIndex;
  final double fontSize;
  final String fontFamily;
  final bool isDarkMode;
  final double lineHeight;
  final double paragraphSpacing;
  final int themeIndex;
  final int fontIndex; // ✅ 0=PTSerif, 1=SourceSerif4, 2=Comfortaa
  final DateTime? lastReadAt;

  const ReadingProgress({
    required this.bookId,
    this.currentPageIndex = 0,
    this.fontSize = 16.0,
    this.fontFamily = 'PTSerif',
    this.isDarkMode = false,
    this.lineHeight = 1.5,
    this.paragraphSpacing = 0.75,
    this.themeIndex = 1,
    this.fontIndex = 0,
    this.lastReadAt,
  });

  factory ReadingProgress.initial(String bookId) {
    return ReadingProgress(
      bookId: bookId,
      lastReadAt: DateTime.now(),
    );
  }

  ReadingProgress copyWith({
    String? bookId,
    int? currentPageIndex,
    double? fontSize,
    String? fontFamily,
    bool? isDarkMode,
    double? lineHeight,
    double? paragraphSpacing,
    int? themeIndex,
    int? fontIndex,
    DateTime? lastReadAt,
  }) {
    return ReadingProgress(
      bookId: bookId ?? this.bookId,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      lineHeight: lineHeight ?? this.lineHeight,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      themeIndex: themeIndex ?? this.themeIndex,
      fontIndex: fontIndex ?? this.fontIndex,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }

  ReadingProgress updatePage(int pageIndex) {
    return copyWith(
      currentPageIndex: pageIndex,
      lastReadAt: DateTime.now(),
    );
  }

  ReadingProgress updateSettings({
    double? fontSize,
    String? fontFamily,
    bool? isDarkMode,
    double? lineHeight,
    double? paragraphSpacing,
    int? themeIndex,
    int? fontIndex,
  }) {
    return copyWith(
      fontSize: fontSize,
      fontFamily: fontFamily,
      isDarkMode: isDarkMode,
      lineHeight: lineHeight,
      paragraphSpacing: paragraphSpacing,
      themeIndex: themeIndex,
      fontIndex: fontIndex,
      lastReadAt: DateTime.now(),
    );
  }

  static String getFontName(int index) {
    switch (index) {
      case 0:
        return 'PTSerif';
      case 1:
        return 'SourceSerif4';
      case 2:
        return 'Comfortaa';
      default:
        return 'PTSerif';
    }
  }

  @override
  List<Object?> get props => [
        bookId,
        currentPageIndex,
        fontSize,
        fontFamily,
        isDarkMode,
        lineHeight,
        paragraphSpacing,
        themeIndex,
        fontIndex,
        lastReadAt,
      ];
}
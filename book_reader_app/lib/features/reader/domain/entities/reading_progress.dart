class ReadingProgress {
  final String bookId;
  final int currentPageIndex;
  final double fontSize;
  final String fontFamily;
  final bool isDarkMode;
  final double lineHeight;
  final double paragraphSpacing;
  final DateTime? lastReadAt;

  const ReadingProgress({
    required this.bookId,
    this.currentPageIndex = 0,
    this.fontSize = 16.0,
    this.fontFamily = 'PTSerif',
    this.isDarkMode = false,
    this.lineHeight = 1.5,
    this.paragraphSpacing = 0.75,
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
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }

  ReadingProgress updateSettings({
    double? fontSize,
    String? fontFamily,
    bool? isDarkMode,
    double? lineHeight,
    double? paragraphSpacing,
  }) {
    return copyWith(
      fontSize: fontSize,
      fontFamily: fontFamily,
      isDarkMode: isDarkMode,
      lineHeight: lineHeight,
      paragraphSpacing: paragraphSpacing,
    );
  }

  ReadingProgress updatePage(int newPageIndex) {
    return copyWith(
      currentPageIndex: newPageIndex,
      lastReadAt: DateTime.now(),
    );
  }
}
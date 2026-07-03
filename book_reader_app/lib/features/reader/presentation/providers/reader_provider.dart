import 'package:book_reader_app/core/theme/reader_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:book_reader_app/core/database/app_database.dart';
import 'package:book_reader_app/features/reader/data/parsers/book_text_extractor.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_block.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_content.dart';
import 'package:book_reader_app/features/reader/domain/entities/page_layout.dart';
import 'package:book_reader_app/features/reader/domain/entities/reading_progress.dart';
import 'package:book_reader_app/features/reader/domain/repositories/reader_repository.dart';
import 'package:book_reader_app/features/reader/data/repositories/reader_repository_impl.dart';
import 'package:book_reader_app/features/reader/data/parsers/text_paginator.dart';

// ---------- Базовые провайдеры ----------
final appDatabaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError());

final readerRepositoryProvider = Provider<ReaderRepository>(
  (ref) => ReaderRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final bookTextExtractorProvider = Provider<BookTextExtractor>(
  (ref) => BookTextExtractor(),
);

class ContentSizeNotifier extends Notifier<Size> {
  @override
  Size build() => const Size(300, 600);
  void update(Size size) => state = size;
}

final contentSizeProvider = NotifierProvider<ContentSizeNotifier, Size>(
  ContentSizeNotifier.new,
);

// ---------- Состояние ридера ----------
class ReaderState {
  final List<BookBlock> blocks;
  final List<PageLayout> pages;
  final int currentPageIndex;
  final ReadingProgress? progress;
  final bool isReady;
  final bool showProgressAsPercent;
  final String bookTitle;
  final String bookAuthor;
  final List<Chapter> chapters;

  const ReaderState({
    this.blocks = const [],
    this.pages = const [],
    this.currentPageIndex = 0,
    this.progress,
    this.isReady = false,
    this.showProgressAsPercent = false,
    this.bookTitle = 'Неизвестная книга',
    this.bookAuthor = 'Автор неизвестен',
    this.chapters = const [],
  });

  ReaderState copyWith({
    List<BookBlock>? blocks,
    List<PageLayout>? pages,
    int? currentPageIndex,
    ReadingProgress? progress,
    bool? isReady,
    bool? showProgressAsPercent,
    String? bookTitle,
    String? bookAuthor,
    List<Chapter>? chapters,
  }) {
    return ReaderState(
      blocks: blocks ?? this.blocks,
      pages: pages ?? this.pages,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      progress: progress ?? this.progress,
      isReady: isReady ?? this.isReady,
      showProgressAsPercent: showProgressAsPercent ?? this.showProgressAsPercent,
      bookTitle: bookTitle ?? this.bookTitle,
      bookAuthor: bookAuthor ?? this.bookAuthor,
      chapters: chapters ?? this.chapters,
    );
  }
}

// ---------- Нотификатор ----------
final readerProvider = AsyncNotifierProvider<ReaderNotifier, ReaderState>(
  ReaderNotifier.new,
);

class ReaderNotifier extends AsyncNotifier<ReaderState> {
  late final ReaderRepository _repo;
  late final BookTextExtractor _extractor;

  @override
  Future<ReaderState> build() async {
    _repo = ref.watch(readerRepositoryProvider);
    _extractor = ref.watch(bookTextExtractorProvider);
    return const ReaderState();
  }

  Future<void> openBook(
    String filePath,
    String bookTitle,
    String bookAuthor,
    Size screenSize,
    TextScaler textScaler,
  ) async {
    final stopwatch = Stopwatch()..start();
    String finalTitle = bookTitle.isNotEmpty ? bookTitle : filePath.split('/').last.split('.').first;
    String finalAuthor = bookAuthor.isNotEmpty ? bookAuthor : 'Автор неизвестен';

    state = await AsyncValue.guard(() async {
      final t0 = stopwatch.elapsedMilliseconds;
      final existingProgress = await _repo.loadProgress(filePath);
      final progress = existingProgress ?? ReadingProgress.initial(filePath);
      print('⏱ Загрузка прогресса: ${stopwatch.elapsedMilliseconds - t0} ms');

      final t1 = stopwatch.elapsedMilliseconds;
      final bookContent = await _extractor.extract(progress.bookId);
      print('⏱ Парсинг книги: ${stopwatch.elapsedMilliseconds - t1} ms, блоков: ${bookContent.blocks.length}');

      if (bookContent.blocks.isEmpty) {
        throw FormatException('Файл не содержит читаемого текста');
      }

      final t2 = stopwatch.elapsedMilliseconds;
      final resultState = await _recalculatePages(
        bookContent.blocks,
        bookContent.chapters,
        progress,
        screenSize,
        bookTitle: finalTitle,
        bookAuthor: finalAuthor,
      );
      print('⏱ Пагинация: ${stopwatch.elapsedMilliseconds - t2} ms, страниц: ${resultState.pages.length}');
      print('⏱ ОБЩЕЕ ВРЕМЯ открытия книги: ${stopwatch.elapsedMilliseconds} ms');
      return resultState;
    });
  }

  Future<ReaderState> _recalculatePages(
    List<BookBlock> blocks,
    List<Chapter> chapters,
    ReadingProgress progress,
    Size screenSize, {
    String bookTitle = 'Неизвестная книга',
    String bookAuthor = 'Автор неизвестен',
  }) async {
    final contentWidth = screenSize.width - 40;
    final contentHeight = screenSize.height - 60 - 5;

    final theme = ReaderThemeData.getByIndex(progress.themeIndex);
    final textColor = theme.textColor;

    final baseStyle = TextStyle(
      fontSize: progress.fontSize,
      fontFamily: progress.fontFamily,
      height: progress.lineHeight,
      color: textColor,
      wordSpacing: 1.2,
    );

    final config = PaginatorConfig(
      contentWidth: contentWidth,
      contentHeight: contentHeight,
      textStyle: baseStyle,
      titleStyle: baseStyle.copyWith(
        fontSize: progress.fontSize * 1.4,
        fontWeight: FontWeight.bold,
        height: 1.3,
        wordSpacing: 0,
      ),
      epigraphStyle: baseStyle.copyWith(
        fontSize: progress.fontSize * 0.9,
        fontStyle: FontStyle.italic,
        height: 1.4,
        color: textColor.withOpacity(0.7),
      ),
      firstLineIndent: progress.fontSize * 1.5,
    );

    final paginator = TextPaginator();
    final pages = await paginator.paginate(blocks, chapters, config);
    final safeIndex = progress.currentPageIndex.clamp(0, pages.length - 1);

    print('📄 Пересчёт страниц: themeIndex=${progress.themeIndex}, fontSize=${progress.fontSize}, pages=${pages.length}');
    return ReaderState(
      blocks: blocks,
      pages: pages,
      currentPageIndex: safeIndex,
      progress: progress,
      isReady: true,
      bookTitle: bookTitle,
      bookAuthor: bookAuthor,
      chapters: chapters,
    );
  }

  // ---------- Методы управления ----------
  Future<void> goToPage(int index) async {
    final current = state.value;
    if (current == null || index < 0 || index >= current.pages.length) return;
    await _repo.updatePage(current.progress!.bookId, index);
    state = AsyncValue.data(current.copyWith(currentPageIndex: index));
  }

  Future<void> changeFontSize(double newFontSize, Size screenSize) async {
    final current = state.value;
    if (current == null) return;
    state = await AsyncValue.guard(() async {
      final updatedProgress = current.progress!.updateSettings(fontSize: newFontSize);
      await _repo.saveProgress(updatedProgress);
      return await _recalculatePages(
        current.blocks, current.chapters, updatedProgress, screenSize,
        bookTitle: current.bookTitle, bookAuthor: current.bookAuthor,
      );
    });
  }

  Future<void> changeLineHeight(double newLineHeight, Size screenSize) async {
    final current = state.value;
    if (current == null) return;
    state = await AsyncValue.guard(() async {
      final updatedProgress = current.progress!.updateSettings(lineHeight: newLineHeight);
      await _repo.saveProgress(updatedProgress);
      return await _recalculatePages(
        current.blocks, current.chapters, updatedProgress, screenSize,
        bookTitle: current.bookTitle, bookAuthor: current.bookAuthor,
      );
    });
  }

  Future<void> changeParagraphSpacing(double newSpacing, Size screenSize) async {
    final current = state.value;
    if (current == null) return;
    state = await AsyncValue.guard(() async {
      final updatedProgress = current.progress!.updateSettings(paragraphSpacing: newSpacing);
      await _repo.saveProgress(updatedProgress);
      return await _recalculatePages(
        current.blocks, current.chapters, updatedProgress, screenSize,
        bookTitle: current.bookTitle, bookAuthor: current.bookAuthor,
      );
    });
  }

  Future<void> changeTheme(int themeIndex, Size screenSize) async {
    final current = state.value;
    if (current == null) return;
    state = await AsyncValue.guard(() async {
      final updatedProgress = current.progress!.updateSettings(themeIndex: themeIndex);
      await _repo.saveProgress(updatedProgress);
      print('🔄 Пересчёт страниц после смены темы на индекс $themeIndex');
      return await _recalculatePages(
        current.blocks, current.chapters, updatedProgress, screenSize,
        bookTitle: current.bookTitle, bookAuthor: current.bookAuthor,
      );
    });
  }

  Future<void> changeFont(int fontIndex, Size screenSize) async {
    final current = state.value;
    if (current == null) return;
    state = await AsyncValue.guard(() async {
      final fontName = ReadingProgress.getFontName(fontIndex);
      final updatedProgress = current.progress!.updateSettings(
        fontIndex: fontIndex,
        fontFamily: fontName,
      );
      await _repo.saveProgress(updatedProgress);
      return await _recalculatePages(
        current.blocks, current.chapters, updatedProgress, screenSize,
        bookTitle: current.bookTitle, bookAuthor: current.bookAuthor,
      );
    });
  }

  Future<void> toggleTheme() async {
    final current = state.value;
    if (current == null) return;
    final size = ref.read(contentSizeProvider);
    if (size.width == 0 || size.height == 0) return;
    state = await AsyncValue.guard(() async {
      final updatedProgress = current.progress!.updateSettings(isDarkMode: !current.progress!.isDarkMode);
      await _repo.saveProgress(updatedProgress);
      print('🔄 Пересчёт страниц после toggleTheme');
      return await _recalculatePages(
        current.blocks, current.chapters, updatedProgress, size,
        bookTitle: current.bookTitle, bookAuthor: current.bookAuthor,
      );
    });
  }

  void toggleProgressFormat() {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(
      showProgressAsPercent: !current.showProgressAsPercent,
    ));
  }
}
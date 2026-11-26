import 'package:book_reader_app/core/theme/reader_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:book_reader_app/core/database/app_database.dart';
import 'package:book_reader_app/features/reader/data/parsers/book_text_extractor.dart';
import 'package:book_reader_app/features/reader/data/parsers/hyphenator_provider.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_block.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_content.dart';
import 'package:book_reader_app/features/reader/domain/entities/page_layout.dart';
import 'package:book_reader_app/features/reader/domain/entities/reading_progress.dart';
import 'package:book_reader_app/features/reader/domain/repositories/reader_repository.dart';
import 'package:book_reader_app/features/reader/data/repositories/reader_repository_impl.dart';
import 'package:book_reader_app/features/reader/data/parsers/text_paginator.dart';

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

final readerProvider = AsyncNotifierProvider<ReaderNotifier, ReaderState>(
  ReaderNotifier.new,
);

class ReaderNotifier extends AsyncNotifier<ReaderState> {
  late final ReaderRepository _repo;
  late final BookTextExtractor _extractor;

  // Scroll-aware flush
  bool _userScrolling = false;
  final List<PageLayout> _pendingPages = [];

  @override
  Future<ReaderState> build() async {
    _repo = ref.watch(readerRepositoryProvider);
    _extractor = ref.watch(bookTextExtractorProvider);
    return const ReaderState();
  }

  void setUserScrolling(bool value) {
    _userScrolling = value;
    if (!value && _pendingPages.isNotEmpty) {
      // Пользователь закончил скроллить — флашим всё накопленное
      final current = state.value;
      if (current != null) {
        state = AsyncValue.data(current.copyWith(
          pages: [...current.pages, ..._pendingPages],
          isReady: true,
        ));
        _pendingPages.clear();
      }
    }
  }

  Future<void> openBook(
      String filePath,
      String bookTitle,
      String bookAuthor,
      Size screenSize,
      TextScaler textScaler,
      ) async {
    final stopwatch = Stopwatch()..start();
    String finalTitle =
    bookTitle.isNotEmpty ? bookTitle : filePath.split('/').last.split('.').first;
    String finalAuthor = bookAuthor.isNotEmpty ? bookAuthor : 'Автор неизвестен';

    // сброс буферов при новой книге
    _userScrolling = false;
    _pendingPages.clear();

    state = const AsyncValue.loading();
    try {
      final t0 = stopwatch.elapsedMilliseconds;
      final existingProgress = await _repo.loadProgress(filePath);
      final progress = existingProgress ?? ReadingProgress.initial(filePath);
      print('⏱ Загрузка прогресса: ${stopwatch.elapsedMilliseconds - t0} ms');

      final t1 = stopwatch.elapsedMilliseconds;
      final bookContent = await _extractor.extract(progress.bookId);
      print('⏱ Парсинг книги: ${stopwatch.elapsedMilliseconds - t1} ms, блоков: ${bookContent.blocks.length}');

      if (bookContent.blocks.isEmpty) {
        state = AsyncValue.error(
          FormatException('Файл не содержит читаемого текста'),
          StackTrace.current,
        );
        return;
      }

      state = AsyncValue.data(ReaderState(
        blocks: bookContent.blocks,
        chapters: bookContent.chapters,
        progress: progress,
        isReady: false,
        bookTitle: finalTitle,
        bookAuthor: finalAuthor,
      ));

      final t2 = stopwatch.elapsedMilliseconds;
      final currentProgress = state.value?.progress ?? progress;

      final resultState = await _recalculatePages(
        bookContent.blocks,
        bookContent.chapters,
        currentProgress,
        screenSize,
        bookTitle: finalTitle,
        bookAuthor: finalAuthor,
        onProgress: (newPages) {
          final current = state.value;
          if (current == null) return;
          if (current.progress?.bookId != currentProgress.bookId) return;
          if (newPages.isEmpty) return;

          // Пока пользователь листает — копим, не дёргаем UI
          if (_userScrolling) {
            _pendingPages.addAll(newPages);
            return;
          }

          // Если пользователь далеко от края готового — тоже копим
          // (первые 50 ещё грузятся, ему хватает)
          final nearEdge = current.currentPageIndex + 20 >= current.pages.length;
          if (!nearEdge && current.pages.isNotEmpty) {
            _pendingPages.addAll(newPages);
            return;
          }

          // Пользователь близко к краю — флашим чтобы не «застрял»
          final newTotal = current.pages.length + _pendingPages.length + newPages.length;
          if (current.pages.length ~/ 100 != newTotal ~/ 100) {
            print('📄 onProgress: всего $newTotal страниц');
          }

          state = AsyncValue.data(current.copyWith(
            pages: [...current.pages, ..._pendingPages, ...newPages],
            isReady: true,
          ));
          _pendingPages.clear();
        },
      );

      print('⏱ Пагинация: ${stopwatch.elapsedMilliseconds - t2} ms, страниц: ${resultState.pages.length}');
      print('⏱ ОБЩЕЕ ВРЕМЯ открытия книги: ${stopwatch.elapsedMilliseconds} ms');

      state = AsyncValue.data(resultState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<ReaderState> _recalculatePages(
      List<BookBlock> blocks,
      List<Chapter> chapters,
      ReadingProgress progress,
      Size screenSize, {
        String bookTitle = 'Неизвестная книга',
        String bookAuthor = 'Автор неизвестен',
        void Function(List<PageLayout>)? onProgress,
      }) async {
    final contentWidth = screenSize.width - 40;
    final contentHeight = screenSize.height - 60 - 15;

    final theme = ReaderThemeData.getByIndex(progress.themeIndex);
    final textColor = theme.textColor;

    final baseStyle = TextStyle(
      fontSize: progress.fontSize,
      fontFamily: progress.fontFamily,
      height: progress.lineHeight,
      color: textColor,
    );

    final hyphenator = await HyphenatorProvider.instance();

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
      hyphenator: hyphenator,
    );

    final paginator = TextPaginator();
    final pages = await paginator.paginate(
      blocks, chapters, config,
      onProgress: onProgress,
    );
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

  Future<void> goToPage(int index) async {
    final current = state.value;
    if (current == null || index < 0 || index >= current.pages.length) return;

    await _repo.updatePage(current.progress!.bookId, index);

    final latest = state.value;
    if (latest == null) return;
    if (latest.progress?.bookId != current.progress?.bookId) return;

    state = AsyncValue.data(latest.copyWith(currentPageIndex: index));
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
    final updatedProgress = current.progress!.updateSettings(themeIndex: themeIndex);
    await _repo.saveProgress(updatedProgress);
    final latest = state.value;
    if (latest == null) return;
    if (latest.progress?.bookId != current.progress?.bookId) return;
    state = AsyncValue.data(latest.copyWith(progress: updatedProgress));
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
    final updatedProgress =
    current.progress!.updateSettings(isDarkMode: !current.progress!.isDarkMode);
    await _repo.saveProgress(updatedProgress);
    final latest = state.value;
    if (latest == null) return;
    if (latest.progress?.bookId != current.progress?.bookId) return;
    state = AsyncValue.data(latest.copyWith(progress: updatedProgress));
  }

  void toggleProgressFormat() {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(
      showProgressAsPercent: !current.showProgressAsPercent,
    ));
  }
}
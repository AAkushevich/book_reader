import 'package:book_reader_app/core/database/app_database.dart';
import 'package:book_reader_app/features/reader/data/parsers/book_text_extractor.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_block.dart';
import 'package:book_reader_app/features/reader/domain/entities/text_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:book_reader_app/features/reader/domain/entities/reading_progress.dart';
import 'package:book_reader_app/features/reader/domain/repositories/reader_repository.dart';
import 'package:book_reader_app/features/reader/data/repositories/reader_repository_impl.dart';
import 'package:book_reader_app/features/reader/data/parsers/text_paginator.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_content.dart'; 

final appDatabaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError());

final readerRepositoryProvider = Provider<ReaderRepository>(
  (ref) => ReaderRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final bookTextExtractorProvider = Provider<BookTextExtractor>(
  (ref) => BookTextExtractor(),
);

class ReaderState {
  final List<BookBlock> blocks;
  final List<List<TextLine>> pages;
  final int currentPageIndex;
  final ReadingProgress? progress;
  final bool isReady;
  final bool showProgressAsPercent;
  final String bookTitle;
  final String bookAuthor;
  final List<Chapter> chapters;
  final TextScaler textScaler; 

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
    this.textScaler = TextScaler.noScaling,
  });

  ReaderState copyWith({
    List<BookBlock>? blocks, 
    List<List<TextLine>>? pages,
    int? currentPageIndex,
    ReadingProgress? progress,
    bool? isReady,
    bool? showProgressAsPercent,
    String? bookTitle,
    String? bookAuthor,
    List<Chapter>? chapters,
    TextScaler? textScaler,
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
      textScaler: textScaler ?? this.textScaler,
    );
  }
}

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
    String finalTitle = bookTitle.isNotEmpty ? bookTitle : filePath.split('/').last.split('.').first;
    String finalAuthor = bookAuthor.isNotEmpty ? bookAuthor : 'Автор неизвестен';

    state = await AsyncValue.guard(() async {
      final existingProgress = await _repo.loadProgress(filePath);
      final progress = existingProgress ?? ReadingProgress.initial(filePath);
      
      final bookContent = await _extractor.extract(progress.bookId);
      if (bookContent.blocks.isEmpty) {
        throw FormatException('Файл не содержит читаемого текста');
      }

      final resultState = await _recalculatePages(
        bookContent.blocks, 
        bookContent.chapters,
        progress, 
        screenSize, 
        textScaler,
        bookTitle: finalTitle,
        bookAuthor: finalAuthor,
      );
      
      return resultState;
    });
  }

  Future<ReaderState> _recalculatePages(
    List<BookBlock> blocks, 
    List<Chapter> chapters,
    ReadingProgress progress, 
    Size screenSize,
    TextScaler textScaler, {
    String bookTitle = 'Неизвестная книга',
    String bookAuthor = 'Автор неизвестен',
  }) async {
    final config = PaginatorConfig(
      fontSize: progress.fontSize,
      fontFamily: progress.fontFamily,
      lineHeight: progress.lineHeight,
      maxWidth: screenSize.width - 40.0,
      maxHeight: screenSize.height - 96.0,
      textScaler: textScaler,
    );

    final result = await paginateBook(blocks, chapters, config);
    final safeIndex = progress.currentPageIndex.clamp(0, result.pages.length - 1);

    print('Блоков: ${blocks.length} | Страниц: ${result.pages.length}');
    print('Screen: ${screenSize.width}x${screenSize.height}');
    print('MaxHeight: ${config.maxHeight}');

    return ReaderState(
      blocks: blocks,
      pages: result.pages,
      currentPageIndex: safeIndex,
      progress: progress,
      isReady: true,
      textScaler: textScaler,
      bookTitle: bookTitle,
      bookAuthor: bookAuthor,
      chapters: result.chapters,
    );
  }

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
        current.blocks, 
        current.chapters,
        updatedProgress, 
        screenSize, 
        current.textScaler,
        bookTitle: current.bookTitle,
        bookAuthor: current.bookAuthor,
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
        current.blocks, 
        current.chapters,
        updatedProgress, 
        screenSize, 
        current.textScaler,
        bookTitle: current.bookTitle,
        bookAuthor: current.bookAuthor,
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
        current.blocks, 
        current.chapters,
        updatedProgress, 
        screenSize, 
        current.textScaler,
        bookTitle: current.bookTitle,
        bookAuthor: current.bookAuthor,
      );
    });
  }

  Future<void> changeTheme(int themeIndex, Size screenSize) async {
    final current = state.value;
    if (current == null) return;
    
    state = await AsyncValue.guard(() async {
      final updatedProgress = current.progress!.updateSettings(themeIndex: themeIndex);
      await _repo.saveProgress(updatedProgress);
      return current.copyWith(progress: updatedProgress);
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
        current.blocks, 
        current.chapters,
        updatedProgress, 
        screenSize, 
        current.textScaler,
        bookTitle: current.bookTitle,
        bookAuthor: current.bookAuthor,
      );
    });
  }

  Future<void> toggleTheme() async {
    final current = state.value;
    if (current == null) return;
    final updatedProgress = current.progress!.updateSettings(isDarkMode: !current.progress!.isDarkMode);
    await _repo.saveProgress(updatedProgress);
    state = AsyncValue.data(current.copyWith(progress: updatedProgress));
  }

  void toggleProgressFormat() {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(
      showProgressAsPercent: !current.showProgressAsPercent,
    ));
  }
}
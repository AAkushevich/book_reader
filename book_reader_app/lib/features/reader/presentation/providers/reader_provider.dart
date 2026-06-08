import 'package:book_reader_app/core/database/app_database.dart';
import 'package:book_reader_app/features/reader/data/parsers/book_text_extractor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class ReaderState {
  final String rawText;
  final List<String> pages;
  final int currentPageIndex;
  final ReadingProgress? progress;
  final bool isReady; 

  const ReaderState({
    this.rawText = '',
    this.pages = const [],
    this.currentPageIndex = 0,
    this.progress,
    this.isReady = false,
  });

  ReaderState copyWith({
    String? rawText,
    List<String>? pages,
    int? currentPageIndex,
    ReadingProgress? progress,
    bool? isReady,
  }) {
    return ReaderState(
      rawText: rawText ?? this.rawText,
      pages: pages ?? this.pages,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      progress: progress ?? this.progress,
      isReady: isReady ?? this.isReady,
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


  Future<void> openBook(String filePath, Size screenSize) async {

    state = await AsyncValue.guard(() async {
      final existingProgress = await _repo.loadProgress(filePath);
      final progress = existingProgress ?? ReadingProgress.initial(filePath);
      
      final rawText = await _extractor.extract(progress.bookId);
      
      if (rawText.trim().isEmpty) {
        throw FormatException('Файл не содержит читаемого текста');
      }

      return await _recalculatePages(rawText, progress, screenSize);
    });
  }

  Future<ReaderState> _recalculatePages(String text, ReadingProgress progress, Size screenSize) async {
    final config = PaginatorConfig(
      text: text,
      fontSize: progress.fontSize,
      fontFamily: progress.fontFamily,
      lineHeight: 1.5,
      maxWidth: screenSize.width - 32.0,
      maxHeight: screenSize.height - 140.0,
    );

    final pages = await paginateText(config);
    final safeIndex = progress.currentPageIndex.clamp(0, pages.length - 1);

    return ReaderState(
      rawText: text,
      pages: pages,
      currentPageIndex: safeIndex,
      progress: progress,
      isReady: true,
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
      
      return await _recalculatePages(current.rawText, updatedProgress, screenSize);
    });
  }

  Future<void> toggleTheme() async {
    final current = state.value;
    if (current == null) return;

    final updatedProgress = current.progress!.updateSettings(isDarkMode: !current.progress!.isDarkMode);
    await _repo.saveProgress(updatedProgress);

    state = AsyncValue.data(current.copyWith(progress: updatedProgress));
  }
}
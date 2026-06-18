import 'package:book_reader_app/features/reader/domain/entities/book_block.dart';

class BookContent {
  final List<BookBlock> blocks;
  final List<Chapter> chapters;

  const BookContent({
    required this.blocks,
    this.chapters = const [],
  });
}

class Chapter {
  final String title;
  final int startPageIndex;
  final int blockIndex;

  const Chapter({
    required this.title,
    required this.startPageIndex,
    required this.blockIndex,
  });
}
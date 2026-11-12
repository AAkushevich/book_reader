import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:book_reader_app/core/exceptions.dart';
import 'package:book_reader_app/features/library/domain/entities/book_entry.dart';
import 'package:book_reader_app/features/library/presentation/providers/book_library_provider.dart';
import 'package:book_reader_app/features/reader/presentation/pages/reader_screen.dart';
import 'package:book_reader_app/core/utils/time_ago.dart';

class BookLibraryPage extends ConsumerWidget {
  const BookLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBooks = ref.watch(bookLibraryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: asyncBooks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          error: error,
          onRetry: () => ref.invalidate(bookLibraryProvider),
        ),
        data: (books) {
          final sorted = List<BookEntry>.from(books)..sort((a, b) {
            if (a.hasBeenRead && b.hasBeenRead) {
              return b.lastReadAt!.compareTo(a.lastReadAt!);
            }
            if (a.hasBeenRead) return -1;
            if (b.hasBeenRead) return 1;
            return b.addedAt.compareTo(a.addedAt);
          });

          final recent = sorted.firstWhere(
            (b) => b.hasBeenRead,
            orElse: () => BookEntry(
              id: '',
              title: '',
              author: '',
              filePath: '',
              fileSizeBytes: 0,
              extension: '',
              addedAt: DateTime.now(),
            ),
          );

          final hasRecent = recent.filePath.isNotEmpty;
          final list = hasRecent
              ? sorted.where((b) => b.filePath != recent.filePath).toList()
              : sorted;

          return CustomScrollView(
            slivers: [
              if (hasRecent)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _RecentHeader(
                    book: recent,
                    minHeight: 160,
                    maxHeight: 260,
                    onContinue: () => _open(context, ref, recent),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        hasRecent ? 'Все книги' : 'Библиотека',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search_outlined, color: Colors.black54),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.sort, color: Colors.black54),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _BookCard(
                      book: list[i],
                      onTap: () => _open(context, ref, list[i]),
                      onDelete: () => _delete(context, ref, list[i]),
                    ),
                    childCount: list.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(bookLibraryProvider.notifier).pickAndAddBook(),
        backgroundColor: const Color(0xFFFF4081),
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref, BookEntry book) {
    ref.read(bookLibraryProvider.notifier).markAsRead(book.filePath);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          filePath: book.filePath,
          bookTitle: book.title,
          bookAuthor: book.author,
        ),
      ),
    );
  }

  void _delete(BuildContext context, WidgetRef ref, BookEntry book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить книгу?'),
        content: Text('«${book.title}» будет удалена из списка.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(bookLibraryProvider.notifier).removeBook(book.filePath);
              Navigator.pop(ctx);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

class _RecentHeader extends SliverPersistentHeaderDelegate {
  final BookEntry book;
  final double minHeight;
  final double maxHeight;
  final VoidCallback onContinue;

  _RecentHeader({
    required this.book,
    required this.minHeight,
    required this.maxHeight,
    required this.onContinue,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final ratio = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final currentHeight = maxExtent - shrinkOffset;
    final expandProgress = 1.0 - ratio;

    return SizedBox(
      height: maxExtent,
      width: double.infinity,
      child: ClipRect(
        child: SizedBox(
          height: currentHeight,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF5E62), Color(0xFFFF9966)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // ✅ Обложка: файл или заглушка
                  Positioned(
                    left: 16,
                    top: 16,
                    bottom: 16,
                    width: 110,
                    child: Opacity(
                      opacity: expandProgress,
                      child: Transform.scale(
                        scale: 0.7 + 0.3 * expandProgress,
                        alignment: Alignment.centerLeft,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildCoverImage(
                            book.coverImagePath,
                            width: 110,
                            height: double.infinity,
                            placeholderColor: Colors.white.withValues(alpha: 0.2),
                            placeholderIcon: Icons.book,
                            placeholderIconColor: Colors.white38,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16 + 126 * expandProgress,
                    right: 16,
                    top: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: (expandProgress * 2 - 1).clamp(0.0, 1.0),
                          child: Text(
                            formatTimeAgo(book.lastReadAt).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16 + 6 * expandProgress,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Opacity(
                          opacity: (expandProgress * 2 - 1).clamp(0.0, 1.0),
                          child: Text(
                            book.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${book.progressPercent}%',
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: book.readingProgress,
                                      backgroundColor: Colors.white24,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      minHeight: 3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: onContinue,
                              child: const Text(
                                'ПРОДОЛЖИТЬ >',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

class _BookCard extends StatelessWidget {
  final BookEntry book;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookCard({
    required this.book,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Обложка: файл или заглушка
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _buildCoverImage(
                book.coverImagePath,
                width: 60,
                height: 85,
                placeholderColor: Colors.grey[200],
                placeholderIcon: Icons.book,
                placeholderIconColor: Colors.grey,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    book.author,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${book.formattedSize} • .${book.extension.toUpperCase()}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[500]),
                  ),
                  if (book.hasBeenRead) ...[
                    const SizedBox(height: 4),
                    Text(
                      formatTimeAgo(book.lastReadAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                  if (book.readingProgress > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: book.readingProgress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                        minHeight: 2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ Общий виджет обложки: показывает файл или заглушку
Widget _buildCoverImage(
  String? coverImagePath, {
  required double width,
  required double height,
  required Color? placeholderColor,
  required IconData placeholderIcon,
  required Color placeholderIconColor,
}) {
  if (coverImagePath != null) {
    final file = File(coverImagePath);
    return Image.file(
      file,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: placeholderColor,
        child: Icon(placeholderIcon, color: placeholderIconColor, size: 24),
      ),
    );
  }
  return Container(
    width: width,
    height: height,
    color: placeholderColor,
    child: Icon(placeholderIcon, color: placeholderIconColor, size: 24),
  );
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final msg = switch (error) {
      AppException e => e.message,
      _ => 'Произошла ошибка',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(msg, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
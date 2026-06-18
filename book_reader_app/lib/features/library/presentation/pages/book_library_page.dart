import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:book_reader_app/core/exceptions.dart';
import 'package:book_reader_app/features/library/domain/entities/book_entry.dart';
import 'package:book_reader_app/features/library/presentation/providers/book_library_provider.dart';
import 'package:book_reader_app/features/reader/presentation/pages/reader_screen.dart';

class BookLibraryPage extends ConsumerWidget {
  const BookLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBooks = ref.watch(bookLibraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Моя библиотека'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить книгу',
            onPressed: () => ref.read(bookLibraryProvider.notifier).pickAndAddBook(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Очистить список',
            onPressed: asyncBooks.value?.isNotEmpty == true
                ? () => _showClearDialog(context, ref)
                : null,
          ),
        ],
      ),
      body: asyncBooks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          error: error,
          onRetry: () => ref.invalidate(bookLibraryProvider),
        ),
        data: (books) => books.isEmpty
            ? const _EmptyState()
            : _BookList(books: books),
      ),
    );
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистить библиотеку?'),
        content: const Text('Все книги будут удалены из списка.\nФайлы на устройстве останутся нетронутыми.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              ref.read(bookLibraryProvider.notifier).clearLibrary();
              Navigator.pop(ctx);
            },
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }
}

// ... (_EmptyState и _ErrorState без изменений) ...
class _EmptyState extends ConsumerWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_books, size: 80, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('Библиотека пуста', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Добавьте книги в формате FB2 или EPUB,\nнажав на кнопку выше',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final message = switch (error) {
      AppException e => e.message,
      _ => 'Произошла непредвиденная ошибка',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}

class _BookList extends StatelessWidget {
  final List<BookEntry> books;
  const _BookList({required this.books});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: books.length,
          itemBuilder: (context, index) => _BookTile(book: books[index], isWide: isWide),
        );
      },
    );
  }
}

class _BookTile extends ConsumerWidget {
  final BookEntry book;
  final bool isWide;
  const _BookTile({required this.book, required this.isWide});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _BookCover(book: book), 
        title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: isWide
            ? Row(children: [Expanded(child: Text(book.author, overflow: TextOverflow.ellipsis)), Text('${book.formattedSize} • .${book.extension}', style: Theme.of(context).textTheme.labelSmall)])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(book.author, overflow: TextOverflow.ellipsis), Text('${book.formattedSize} • .${book.extension}', style: Theme.of(context).textTheme.labelSmall)]),
        onLongPress: () => _showDeleteDialog(context, ref),
        onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReaderScreen(
                          filePath: book.filePath,
                          bookTitle: book.title,      
                          bookAuthor: book.author,    
                        ),
                      ),
                    ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить книгу?'),
        content: Text('«${book.title}» будет удалена из списка.\nФайл останется на устройстве.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
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

class _BookCover extends StatelessWidget {
  final BookEntry book;
  const _BookCover({required this.book});

  @override
  Widget build(BuildContext context) {
    // V1: обложка не сохраняется в БД, поэтому показываем заглушку
    // Для демонстрации можно раскомментировать код ниже, когда парсер вернёт coverImage
    /*
    if (book.coverImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(book.coverImage!, width: 48, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _Placeholder()),
      );
    }
    */
    return _Placeholder();
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.book, color: Theme.of(context).colorScheme.primary),
    );
  }
}
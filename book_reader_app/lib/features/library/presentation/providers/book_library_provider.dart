import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:book_reader_app/features/library/domain/entities/book_entry.dart';
import 'package:book_reader_app/features/library/domain/repositories/book_library_repository.dart';
import 'package:book_reader_app/features/library/data/repositories/book_repository_impl.dart';
import 'package:book_reader_app/features/reader/presentation/providers/reader_provider.dart';

part 'book_library_provider.g.dart';

@riverpod
BookLibraryRepository bookLibraryRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return BookLibraryRepositoryImpl(db);
}

@riverpod
class BookLibraryNotifier extends _$BookLibraryNotifier {
  late final BookLibraryRepository _repo;

  @override
  Future<List<BookEntry>> build() async {
    _repo = ref.watch(bookLibraryRepositoryProvider);
    return _repo.getAllBooks();
  }

  Future<void> pickAndAddBook() async {
    state = await AsyncValue.guard(() async {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['fb2', 'zip', 'epub'],
        dialogTitle: 'Выберите книгу',
      );

      final file = picked.firstOrNull; // or picked?.single, but single throws if >1
      if (file == null || file.path == null) {
        return await _repo.getAllBooks();
      }

      await _repo.addBookFromPath(file.path!);
      return await _repo.getAllBooks();
    });
  }

  Future<void> removeBook(String filePath) async {
    await _repo.removeBook(filePath);
    state = AsyncValue.data(await _repo.getAllBooks());
  }

  Future<void> clearLibrary() async {
    await _repo.clearLibrary();
    state = const AsyncValue.data([]);
  }

  // ✅ НОВЫЙ МЕТОД: отметить книгу как прочитанную (сейчас)
  Future<void> markAsRead(String filePath) async {
    await _repo.updateLastRead(filePath);
    
    final current = state.value;
    if (current == null) return;

    final updated = <BookEntry>[];
    for (final book in current) {
      if (book.filePath == filePath) {
        updated.add(book.markAsReadNow());
      } else {
        updated.add(book);
      }
    }

    updated.sort((a, b) {
      if (a.hasBeenRead && b.hasBeenRead) {
        return b.lastReadAt!.compareTo(a.lastReadAt!);
      }
      if (a.hasBeenRead) return -1;
      if (b.hasBeenRead) return 1;
      return b.addedAt.compareTo(a.addedAt);
    });

    state = AsyncValue.data(updated);
  }

  // ✅ НОВЫЙ МЕТОД: обновить прогресс чтения
  Future<void> updateProgress(String filePath, double progress) async {
    await _repo.updateProgress(filePath, progress);

    final current = state.value;
    if (current == null) return;

    final updated = current.map((book) {
      if (book.filePath == filePath) {
        return book.withProgress(progress);
      }
      return book;
    }).toList();

    state = AsyncValue.data(updated);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => _repo.getAllBooks());
  }
}
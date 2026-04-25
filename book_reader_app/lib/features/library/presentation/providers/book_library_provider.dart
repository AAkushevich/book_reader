import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:book_reader_app/core/exceptions.dart';
import 'package:book_reader_app/features/library/domain/entities/book_entry.dart';
import 'package:book_reader_app/features/library/domain/repositories/book_library_repository.dart';
import 'package:book_reader_app/features/library/data/repositories/book_library_repository_impl.dart';
import 'package:book_reader_app/features/library/data/datasources/sembast_storage.dart';

part 'book_library_provider.g.dart';

// Провайдер хранилища. Инициализацию БД (.init()) необходимо вызвать в main() до первого доступа
@riverpod
SembastBookStorage sembastStorage(Ref ref) => SembastBookStorage();

// Провайдер репозитория (автоматически внедряет зависимости)
@riverpod
BookLibraryRepository bookLibraryRepository(Ref ref) {
  final storage = ref.watch(sembastStorageProvider);
  return BookLibraryRepositoryImpl(storage);
}

// Асинхронный нотификер состояния библиотеки
@riverpod
class BookLibraryNotifier extends _$BookLibraryNotifier {
  late final BookLibraryRepository _repo;

  @override
  Future<List<BookEntry>> build() async {
    _repo = ref.watch(bookLibraryRepositoryProvider);
    return _repo.getAllBooks();
  }

  /// Выбрать файл через системный диалог и добавить в библиотеку
  Future<void> pickAndAddBook() async {
    state = const AsyncLoading();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['fb2', 'epub'],
        dialogTitle: 'Выберите книгу',
      );

      if (result == null || result.files.single.path == null) {
        // Пользователь отменил выбор → возвращаем текущее состояние
        state = AsyncValue.data(await _repo.getAllBooks());
        return;
      }

      await _repo.addBookFromPath(result.files.single.path!);
      final updated = await _repo.getAllBooks();
      state = AsyncValue.data(updated);
    } on AppException catch (e, st) {
      state = AsyncValue.error(e, st);
    } catch (e, st) {
      state = AsyncValue.error(ParseError(e.toString()), st);
    }
  }

  /// Удалить книгу из списка (файл на диске остаётся)
  Future<void> removeBook(String filePath) async {
    await _repo.removeBook(filePath);
    state = AsyncValue.data(await _repo.getAllBooks());
  }

  /// Очистить всю библиотеку
  Future<void> clearLibrary() async {
    await _repo.clearLibrary();
    state = const AsyncValue.data([]);
  }
}
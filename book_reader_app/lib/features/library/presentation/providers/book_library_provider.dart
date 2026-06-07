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
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['fb2', 'zip', 'epub'],
      dialogTitle: 'Выберите книгу',
    );
    if (result == null || result.files.single.path == null) {
      return await _repo.getAllBooks(); 
    }
    await _repo.addBookFromPath(result.files.single.path!);
  
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
}
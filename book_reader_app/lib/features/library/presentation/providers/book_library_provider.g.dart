// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_library_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bookLibraryRepository)
const bookLibraryRepositoryProvider = BookLibraryRepositoryProvider._();

final class BookLibraryRepositoryProvider
    extends
        $FunctionalProvider<
          BookLibraryRepository,
          BookLibraryRepository,
          BookLibraryRepository
        >
    with $Provider<BookLibraryRepository> {
  const BookLibraryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookLibraryRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookLibraryRepositoryHash();

  @$internal
  @override
  $ProviderElement<BookLibraryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BookLibraryRepository create(Ref ref) {
    return bookLibraryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BookLibraryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BookLibraryRepository>(value),
    );
  }
}

String _$bookLibraryRepositoryHash() =>
    r'f0286f85de94a85daffa9f50b7c2aa14de558071';

@ProviderFor(BookLibraryNotifier)
const bookLibraryProvider = BookLibraryNotifierProvider._();

final class BookLibraryNotifierProvider
    extends $AsyncNotifierProvider<BookLibraryNotifier, List<BookEntry>> {
  const BookLibraryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookLibraryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookLibraryNotifierHash();

  @$internal
  @override
  BookLibraryNotifier create() => BookLibraryNotifier();
}

String _$bookLibraryNotifierHash() =>
    r'cdfcac7183af031992b66f73128720d88c497fa9';

abstract class _$BookLibraryNotifier extends $AsyncNotifier<List<BookEntry>> {
  FutureOr<List<BookEntry>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<BookEntry>>, List<BookEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<BookEntry>>, List<BookEntry>>,
              AsyncValue<List<BookEntry>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

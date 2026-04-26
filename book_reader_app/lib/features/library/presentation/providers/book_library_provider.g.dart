// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_library_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sembastStorage)
const sembastStorageProvider = SembastStorageProvider._();

final class SembastStorageProvider
    extends
        $FunctionalProvider<
          SembastBookStorage,
          SembastBookStorage,
          SembastBookStorage
        >
    with $Provider<SembastBookStorage> {
  const SembastStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sembastStorageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sembastStorageHash();

  @$internal
  @override
  $ProviderElement<SembastBookStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SembastBookStorage create(Ref ref) {
    return sembastStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SembastBookStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SembastBookStorage>(value),
    );
  }
}

String _$sembastStorageHash() => r'50cf540c73b521d9bef8638fb81d46b4ccb53b61';

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
    r'ec461b8b8703d236896aca1d11915f98a52c84f3';

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

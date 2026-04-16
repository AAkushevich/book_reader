import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart'; // ВАЖНО: импорт enum
import 'package:book_reader_app/data/repositories_impl/book_repository.dart';
import 'package:book_reader_app/data/models/book_model.dart';
import 'package:book_reader_app/data/service/permission_service.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Модель найденной книги для UI
class FoundBook {
  final String path;
  final String name;
  final String title;
  final String author;
  final int sizeBytes;
  final String extension;
  
  FoundBook({
    required this.path,
    required this.name,
    required this.title,
    required this.author,
    required this.sizeBytes,
    required this.extension,
  });
  
  factory FoundBook.fromModel(BookModel model) {
    return FoundBook(
      path: model.filePath,
      name: model.fileName,
      title: model.title,
      author: model.author,
      sizeBytes: model.fileSize,
      extension: model.extension,
    );
  }
}

/// Состояние поиска
class SearchState {
  final bool isLoading;
  final List<FoundBook> results;
  final String? error;
  final int scannedFiles;
  final PermissionStatus permissionStatus;
  
  const SearchState({
    required this.isLoading,
    required this.results,
    this.error,
    this.scannedFiles = 0,
    this.permissionStatus = PermissionStatus.denied,
  });
  
  factory SearchState.initial() => const SearchState(
    isLoading: false, 
    results: [],
    error: null,
    scannedFiles: 0,
    permissionStatus: PermissionStatus.denied,
  );
  
  factory SearchState.loading() => const SearchState(
    isLoading: true, 
    results: [],
    error: null,
    scannedFiles: 0,
    permissionStatus: PermissionStatus.denied,
  );
  
  factory SearchState.data(List<FoundBook> results) => SearchState(
    isLoading: false, 
    results: results,
    error: null,
    scannedFiles: results.length,
    permissionStatus: PermissionStatus.granted,
  );
  
  factory SearchState.error(String message) => SearchState(
    isLoading: false, 
    results: [],
    error: message,
    scannedFiles: 0,
    permissionStatus: PermissionStatus.denied,
  );
  
  factory SearchState.noPermission(PermissionStatus status) => SearchState(
    isLoading: false,
    results: [],
    error: _getPermissionErrorMessage(status),
    scannedFiles: 0,
    permissionStatus: status,
  );
  
  static String _getPermissionErrorMessage(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.denied:
        return 'Доступ к файлам не предоставлен. Нажмите "Найти книги" снова.';
      case PermissionStatus.permanentlyDenied:
        return 'Доступ к файлам навсегда запрещен. Разрешите доступ в настройках.';
      case PermissionStatus.restricted:
        return 'Доступ к файлам ограничен системой';
      case PermissionStatus.limited:
        return 'Предоставлен ограниченный доступ к файлам';
      case PermissionStatus.granted:
        return '';
      case PermissionStatus.provisional:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
  
  SearchState copyWith({
    bool? isLoading,
    List<FoundBook>? results,
    String? error,
    int? scannedFiles,
    PermissionStatus? permissionStatus,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      error: error,
      scannedFiles: scannedFiles ?? this.scannedFiles,
      permissionStatus: permissionStatus ?? this.permissionStatus,
    );
  }
}

/// Контроллер поиска
class SearchController extends StateNotifier<SearchState> {
  final BookRepositoryImpl _repository;
  final PermissionService _permissionService;
  final Logger _logger = Logger('SearchController');
  
  CancelToken? _cancelToken;
  
  SearchController(this._repository, this._permissionService) : super(SearchState.initial());
  
  Future<List<FoundBook>> startSearch({BuildContext? context}) async {
    try {
      _logger.info('Запуск поиска книг');
      state = SearchState.loading();
      
      final hasPermission = await _checkAndRequestPermissions(context);
      
      if (!hasPermission) {
        final status = await _permissionService.getCurrentPermissionStatus();
        state = SearchState.noPermission(status);
        return [];
      }
      
      _cancelToken = CancelToken();
      final books = await _repository.searchAllBooks();
      _cancelToken?.throwIfCancelled();
      
      final foundBooks = books.map((book) => FoundBook.fromModel(book)).toList();
      state = SearchState.data(foundBooks);
      
      _logger.info('Поиск завершен. Найдено: ${foundBooks.length}');
      return foundBooks;
      
    } catch (e, stackTrace) {
      _logger.severe('Ошибка при поиске', e, stackTrace);
      state = SearchState.error('Ошибка поиска: $e');
      return [];
    } finally {
      _cancelToken = null;
    }
  }
  
  Future<bool> _checkAndRequestPermissions(BuildContext? context) async {
    try {
      final hasPermission = await _permissionService.checkPermissions();
      
      if (hasPermission) {
        _logger.info('Разрешения уже есть');
        return true;
      }
      
      if (context == null) {
        return await _permissionService.requestStoragePermission();
      }
      
      final shouldRequest = await _permissionService.showPermissionRationale(context);
      
      if (!shouldRequest) {
        return false;
      }
      
      final granted = await _permissionService.requestStoragePermission();
      
      if (!granted) {
        final status = await _permissionService.getCurrentPermissionStatus();
        if (status == PermissionStatus.permanentlyDenied && context.mounted) {
          _showOpenSettingsDialog(context);
        }
      }
      
      return granted;
      
    } catch (e) {
      _logger.severe('Ошибка при проверке разрешений', e);
      return false;
    }
  }
  
  void _showOpenSettingsDialog(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Доступ к файлам'),
          content: const Text(
            'Разрешение на доступ к файлам отклонено навсегда. '
            'Пожалуйста, предоставьте доступ в настройках приложения.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _permissionService.openAppSettings();
              },
              child: const Text('Открыть настройки'),
            ),
          ],
        ),
      );
    });
  }
  
  void cancelSearch() {
    _cancelToken?.cancel();
    _cancelToken = null;
    state = SearchState.initial();
  }
  
  void clearResults() {
    state = SearchState.initial();
  }
  
  Future<void> retryWithPermissions(BuildContext context) async {
    _logger.info('Повторный запрос разрешений');
    await startSearch(context: context);
  }
}

class CancelToken {
  bool _isCancelled = false;
  
  void cancel() {
    _isCancelled = true;
  }
  
  bool get isCancelled => _isCancelled;
  
  void throwIfCancelled() {
    if (_isCancelled) {
      throw Exception('Operation cancelled');
    }
  }
}

final permissionServiceProvider = Provider((ref) => PermissionService());
final bookRepositoryProvider = Provider((ref) => BookRepositoryImpl());
final searchControllerProvider = StateNotifierProvider<SearchController, SearchState>(
  (ref) {
    final repository = ref.read(bookRepositoryProvider);
    final permissionService = ref.read(permissionServiceProvider);
    return SearchController(repository, permissionService);
  },
);
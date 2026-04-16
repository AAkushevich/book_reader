import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:book_reader_app/data/service/file_picker_service.dart';
import '../controllers/search_controller.dart';

class FindBooksPage extends ConsumerStatefulWidget {
  const FindBooksPage({Key? key}) : super(key: key);

  @override
  ConsumerState<FindBooksPage> createState() => _FindBooksPageState();
}

class _FindBooksPageState extends ConsumerState<FindBooksPage> {
  final FilePickerService _filePickerService = FilePickerService();
  List<FoundBook> _selectedBooks = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);
    final notifier = ref.read(searchControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Books'),
        actions: [
          // Кнопка "Открыть файл" (как в Readera)
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _isLoading ? null : _openSingleFile,
            tooltip: 'Открыть файл',
          ),
          // Кнопка "Очистить"
          if (_selectedBooks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearBooks,
              tooltip: 'Очистить список',
            ),
        ],
      ),
      body: Column(
        children: [
          // Информационная карточка
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Нажмите на иконку папки вверху, чтобы выбрать книгу через файловый менеджер',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Кнопка быстрого действия
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _openSingleFile,
              icon: const Icon(Icons.add),
              label: const Text('Выбрать книгу'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Разделитель
          const Divider(height: 1),
          
          // Заголовок списка
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Выбранные книги (${_selectedBooks.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedBooks.isNotEmpty)
                  TextButton(
                    onPressed: _clearBooks,
                    child: const Text('Очистить все'),
                  ),
              ],
            ),
          ),
          
          // Список книг
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedBooks.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.library_books, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Нет выбранных книг',
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Нажмите кнопку "Выбрать книгу"',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _selectedBooks.length,
                        itemBuilder: (context, index) {
                          final book = _selectedBooks[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: _getExtensionIcon(book.extension),
                              title: Text(
                                book.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book.author,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatFileSize(book.sizeBytes),
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.read_more, color: Colors.blue),
                                    onPressed: () => _openBook(book),
                                    tooltip: 'Читать',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.grey),
                                    onPressed: () => _removeBook(index),
                                    tooltip: 'Удалить из списка',
                                  ),
                                ],
                              ),
                              onTap: () => _openBook(book),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  /// Открыть системный файловый менеджер для выбора ОДНОГО файла
  Future<void> _openSingleFile() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final file = await _filePickerService.pickSingleBook();
      
      if (file != null && mounted) {
        // Создаем модель книги из выбранного файла
        final book = FoundBook(
          path: file.path,
          name: file.path.split('/').last,
          title: _extractTitle(file.path),
          author: 'Неизвестный автор',
          sizeBytes: await file.length(),
          extension: file.path.split('.').last.toLowerCase(),
        );
        
        setState(() {
          _selectedBooks.add(book);
          _isLoading = false;
        });
        
        // Показываем уведомление
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Добавлена книга: ${book.title}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при выборе файла'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Открыть книгу для чтения
  void _openBook(FoundBook book) {
    // TODO: Перейти на страницу чтения книги
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Открытие книги: ${book.title}'),
        duration: const Duration(seconds: 1),
      ),
    );
    
    // Здесь позже будет:
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => BookReaderPage(book: book),
    //   ),
    // );
  }
  
  /// Удалить книгу из списка
  void _removeBook(int index) {
    setState(() {
      final removed = _selectedBooks.removeAt(index);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Удалена: ${removed.title}'),
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }
  
  /// Очистить весь список
  void _clearBooks() {
    setState(() {
      _selectedBooks.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Список очищен'),
        duration: Duration(seconds: 1),
      ),
    );
  }
  
  /// Извлечь название из пути файла
  String _extractTitle(String path) {
    final name = path.split('/').last;
    String withoutExt = name;
    
    if (name.toLowerCase().endsWith('.fb2')) {
      withoutExt = name.substring(0, name.length - 4);
    } else if (name.toLowerCase().endsWith('.epub')) {
      withoutExt = name.substring(0, name.length - 5);
    }
    
    // Заменяем подчеркивания и точки на пробелы
    return withoutExt.replaceAll(RegExp(r'[_.]'), ' ');
  }
  
  /// Форматирование размера файла
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// Иконка в зависимости от расширения
  Widget _getExtensionIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'fb2':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.description, color: Colors.blue),
        );
      case 'epub':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.menu_book, color: Colors.green),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.insert_drive_file, color: Colors.grey),
        );
    }
  }
}
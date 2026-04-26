/// Базовый класс для всех доменных исключений приложения.
/// Позволяет безопасно обрабатывать ошибки через pattern matching в UI/Provider.
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Пользователь отменил выбор файла
class FilePickerCancelled extends AppException {
  const FilePickerCancelled() : super('Выбор файла отменён');
}

/// Файл имеет неподдерживаемое расширение
class UnsupportedFileFormat extends AppException {
  const UnsupportedFileFormat(String ext) : super('Неподдерживаемый формат: .$ext');
}

/// Ошибка чтения с диска (нет доступа, файл удалён и т.д.)
class FileReadError extends AppException {
  const FileReadError(String path) : super('Не удалось прочитать файл: $path');
}

/// Ошибка парсинга структуры книги
class ParseError extends AppException {
  const ParseError(String message) : super('Ошибка парсинга метаданных: $message');
}
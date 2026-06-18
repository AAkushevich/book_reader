/// Типы блоков, которые могут быть в книге
enum BlockType {
  paragraph,   // Обычный абзац
  title,       // Заголовок (главы, тома)
  epigraph,    // Эпиграф
  emptyLine,   // Пустая строка (отступ)
  image,       // Картинка
}

/// Один смысловой блок текста
class BookBlock {
  final BlockType type;
  final String text; 
  
  /// Атрибуты для EPUB/FB2 (CSS-классы, ID ссылок и т.д.)
  /// Пример: {'class': 'epigraph', 'id': 'note1'}
  final Map<String, String>? attributes;

  const BookBlock({
    required this.type,
    required this.text,
    this.attributes,
  });

  factory BookBlock.paragraph(String text, {Map<String, String>? attrs}) => 
      BookBlock(type: BlockType.paragraph, text: text, attributes: attrs);
      
  factory BookBlock.title(String text, {Map<String, String>? attrs}) => 
      BookBlock(type: BlockType.title, text: text, attributes: attrs);
      
  factory BookBlock.epigraph(String text, {Map<String, String>? attrs}) => 
      BookBlock(type: BlockType.epigraph, text: text, attributes: attrs);
      
  factory BookBlock.emptyLine() => 
      BookBlock(type: BlockType.emptyLine, text: '');
}
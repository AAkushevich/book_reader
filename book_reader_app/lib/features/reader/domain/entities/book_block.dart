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
  final Map<String, String>? attributes;

  final String? imagePath;    // абсолютный путь к файлу на диске
  final int? imageWidth;      // исходные размеры (px) — нужны пагинатору
  final int? imageHeight;

  const BookBlock({
    required this.type,
    this.text = '',
    this.attributes,
    this.imagePath,
    this.imageWidth,
    this.imageHeight,
  });

  factory BookBlock.image(String path, {int? width, int? height}) => BookBlock(
    type: BlockType.image,
    imagePath: path,
    imageWidth: width,
    imageHeight: height,
  );

  factory BookBlock.paragraph(String text, {Map<String, String>? attrs}) => 
      BookBlock(type: BlockType.paragraph, text: text, attributes: attrs);
      
  factory BookBlock.title(String text, {Map<String, String>? attrs}) => 
      BookBlock(type: BlockType.title, text: text, attributes: attrs);
      
  factory BookBlock.epigraph(String text, {Map<String, String>? attrs}) => 
      BookBlock(type: BlockType.epigraph, text: text, attributes: attrs);
      
  factory BookBlock.emptyLine() => 
      BookBlock(type: BlockType.emptyLine, text: '');
}
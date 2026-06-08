import 'package:xml/xml.dart';

class Fb2XmlParser {
  
  /// Парсит FB2 XML-контент и извлекает из него текст с сохранением абзацев.
  static String parse(String xmlContent) {
    final doc = XmlDocument.parse(xmlContent);
    
    // Ищем первый тег <body>
    final body = doc.findAllElements('body').firstOrNull;
    if (body == null) return '';

    final buffer = StringBuffer();
    _walkFb2Node(body, buffer);
    
    // Убираем лишние пустые строки, оставляем максимум 1 (двойной перенос)
    return buffer.toString().replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  /// Рекурсивный обход узлов XML для извлечения текста.
  static void _walkFb2Node(XmlNode node, StringBuffer buffer) {
    for (final child in node.children) {
      if (child is XmlElement) {
        // Обработка параграфа
        if (child.name.local == 'p') {
          buffer.writeln(child.innerText);
        } 
        // Обработка пустой строки в FB2
        else if (child.name.local == 'empty-line') {
          buffer.writeln();
        } 
        else {
          _walkFb2Node(child, buffer);
        }
      } 
      else if (child is XmlText) {
        buffer.write(child.value);
      }
    }
  }
}
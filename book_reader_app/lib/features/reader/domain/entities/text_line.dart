/// Простая строка текста для отображения на странице
class TextLine {
  final String text;
  final bool isTitle;
  final bool isEpigraph;
  final bool isFirstLineOfParagraph;

  TextLine({
    required this.text,
    this.isTitle = false,
    this.isEpigraph = false,
    this.isFirstLineOfParagraph = false,
  });
}
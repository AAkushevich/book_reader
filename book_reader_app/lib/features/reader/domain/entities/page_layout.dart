import 'rendered_line.dart';

/// Готовая страница для отображения.
class PageLayout {
  final List<RenderedLine> lines;
  final int startBlockIndex; // индекс первого BookBlock на этой странице
  final int chapterIndex;    // индекс главы в списке chapters

  const PageLayout({
    required this.lines,
    required this.startBlockIndex,
    required this.chapterIndex,
  });
}
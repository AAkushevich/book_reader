import 'package:flutter/material.dart';
import 'package:book_reader_app/features/reader/domain/entities/book_content.dart';

class TableOfContentsScreen extends StatelessWidget {
  final String bookTitle;
  final String bookAuthor;
  final List<Chapter> chapters;
  final int currentPageIndex;
  final ValueChanged<int> onChapterTap;

  const TableOfContentsScreen({
    super.key,
    required this.bookTitle,
    required this.bookAuthor,
    required this.chapters,
    required this.currentPageIndex,
    required this.onChapterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Всегда тёмный фон
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6C63FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Оглавление',
          style: TextStyle(
            color: Color(0xFF6C63FF),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Название книги и автор
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bookAuthor,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  '1',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2A2A4A)),
          
          // Главы
          ...chapters.map((chapter) {
            final isCurrentChapter = chapter.startPageIndex == currentPageIndex;
            final isSubChapter = _isSubChapter(chapter.title);
            
            return GestureDetector(
              onTap: () => onChapterTap(chapter.startPageIndex),
              child: Container(
                padding: EdgeInsets.only(
                  left: isSubChapter ? 32 : 16,
                  right: 16,
                  top: 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  color: isCurrentChapter ? const Color(0xFF252547) : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        chapter.title,
                        style: TextStyle(
                          color: isCurrentChapter ? const Color(0xFF6C63FF) : Colors.white,
                          fontSize: 16,
                          fontWeight: isCurrentChapter ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    Text(
                      '${chapter.startPageIndex + 1}',
                      style: TextStyle(
                        color: isCurrentChapter ? const Color(0xFF6C63FF) : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _isSubChapter(String title) {
    final lowerTitle = title.toLowerCase();
    return lowerTitle.contains('глава') || 
           lowerTitle.contains('том') || 
           lowerTitle.contains('часть');
  }
}
class Book {
  final String id;
  final String title;
  final String? author;
  final int pages;

  Book({required this.id, required this.title, this.author, required this.pages});
}
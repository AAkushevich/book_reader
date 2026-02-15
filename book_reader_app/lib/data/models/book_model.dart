import '../../domain/entities/book.dart';

class BookModel {
  final String id;
  final String title;
  final String? author;
  final int pages;

  BookModel({required this.id, required this.title, this.author, required this.pages});

  factory BookModel.fromEntity(Book b) => BookModel(id: b.id, title: b.title, author: b.author, pages: b.pages);
  Book toEntity() => Book(id: id, title: title, author: author, pages: pages);


}

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'presentation/pages/books_page.dart';
// import 'presentation/pages/book_detail_page.dart';


// final routerProvider = Provider((ref) {
//   return GoRouter(
//     initialLocation: '/',
//     debugLogDiagnostics: true,
//     routes: [
//       GoRoute(
//         path: '/',
//         name: 'books',
//         builder: (context, state) => const BooksPage(),
//         routes: [
//           GoRoute(
//             path: 'book/:id',
//             name: 'bookDetail',
//             builder: (context, state) {
//               final id = state.params['id']!;
//               return BookDetailPage(bookId: id);
//             },
//           ),
//         ],
//       ),
//     ],
//   );
// });

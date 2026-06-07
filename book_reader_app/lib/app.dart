import 'package:flutter/material.dart';
import 'package:book_reader_app/features/library/presentation/pages/book_library_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const BookLibraryPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
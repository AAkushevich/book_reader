import 'package:flutter/material.dart';
import 'presentation/pages/findbookspage.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Finder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FindBooksPage(),
    );
  }
}
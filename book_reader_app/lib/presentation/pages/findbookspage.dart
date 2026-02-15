import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/search_controller.dart';

class FindBooksPage extends ConsumerWidget {
  const FindBooksPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Find Books')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
           
            final notifier = ref.read(searchControllerProvider.notifier);
            final found = await notifier.startSearch();
          
            if (found.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Книги не найдены')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Найдено ${found.length} файлов')),
              ); 
            }
          },
          child: searchState.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Найти книги'),
        ),
      ),
    );
  }
}

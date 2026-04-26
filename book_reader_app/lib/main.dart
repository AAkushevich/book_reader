import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:book_reader_app/app.dart';
import 'package:book_reader_app/features/library/data/datasources/sembast_storage.dart';
import 'package:book_reader_app/features/library/presentation/providers/book_library_provider.dart';

void main() async {
  // Обязательно перед любой асинхронной работой в main()
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Инициализируем БД ДО запуска UI
  final storage = SembastBookStorage();
  await storage.init();
  
  // 2. Внедряем готовое хранилище в DI-контейнер
  runApp(
    ProviderScope(
      overrides: [
        sembastStorageProvider.overrideWithValue(storage),
      ],
      child: const App(),
    ),
  );
}
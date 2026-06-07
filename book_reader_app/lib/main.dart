import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:book_reader_app/app.dart';
import 'package:book_reader_app/core/database/app_database.dart'; 
import 'package:book_reader_app/features/reader/presentation/providers/reader_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final appDb = AppDatabase();
  await appDb.init();
  
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(appDb),
      ],
      child: const App(),
    ),
  );
}
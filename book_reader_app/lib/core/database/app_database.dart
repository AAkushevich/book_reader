import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';


class AppDatabase {
  late final Database _db;
  
  static const String dbName = 'book_reader.db';
  
  final StoreRef<String, Map<String, dynamic>> books = 
      stringMapStoreFactory.store('books');
      
  final StoreRef<String, Map<String, dynamic>> progress = 
      stringMapStoreFactory.store('progress');

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _db = await databaseFactoryIo.openDatabase('${dir.path}/$dbName');
  }

  Database get db => _db;

  Future<void> close() => _db.close();
}
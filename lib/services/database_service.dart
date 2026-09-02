import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('avimetrics_pesagens.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS weighings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        galpao TEXT NOT NULL,
        gaiola TEXT NOT NULL,
        weight REAL NOT NULL,
        is_auto INTEGER NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertWeighing(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('weighings', row);
  }

  Future<List<Map<String, dynamic>>> getAllWeighings() async {
    final db = await database;
    return await db.query('weighings', orderBy: 'id DESC');
  }

  Future<int> clearAllWeighings() async {
    final db = await database;
    return await db.delete('weighings');
  }
}

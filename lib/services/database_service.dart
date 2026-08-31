import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/weighing_record.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('jjagro_balanca.db');
    return _database!;
  }

  Future<void> initDatabase() async {
    _database = await database;
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
      CREATE TABLE pesagens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        galpao TEXT NOT NULL,
        gaiola TEXT NOT NULL,
        peso REAL NOT NULL,
        data TEXT NOT NULL,
        hora TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        isAutoRecorded INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_galpao ON pesagens(galpao);');
  }

  Future<int> insertRecord(WeighingRecord record) async {
    final db = await database;
    return await db.insert('pesagens', record.toMap());
  }

  Future<List<WeighingRecord>> getAllRecords({String? galpao}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;

    if (galpao != null && galpao != 'Todos') {
      maps = await db.query(
        'pesagens',
        where: 'galpao = ?',
        whereArgs: [galpao],
        orderBy: 'timestamp DESC',
      );
    } else {
      maps = await db.query(
        'pesagens',
        orderBy: 'timestamp DESC',
      );
    }

    return List.generate(maps.length, (i) => WeighingRecord.fromMap(maps[i]));
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete('pesagens', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearRecords({String? galpao}) async {
    final db = await database;
    if (galpao != null && galpao != 'Todos') {
      return await db.delete('pesagens', where: 'galpao = ?', whereArgs: [galpao]);
    }
    return await db.delete('pesagens');
  }
}

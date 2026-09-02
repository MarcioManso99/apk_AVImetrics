import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/weighing_record.dart';

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

  // --- Métodos esperados pelo WeighingController ---

  Future<List<WeighingRecord>> getAllRecords({String? galpao}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;

    if (galpao != null && galpao.isNotEmpty) {
      maps = await db.query(
        'weighings',
        where: 'galpao = ?',
        whereArgs: [galpao],
        orderBy: 'id DESC',
      );
    } else {
      maps = await db.query('weighings', orderBy: 'id DESC');
    }

    return List.generate(maps.length, (i) => WeighingRecord.fromMap(maps[i]));
  }

  Future<int> insertRecord(dynamic record) async {
    final db = await database;
    if (record is Map<String, dynamic>) {
      return await db.insert('weighings', record);
    }
    try {
      return await db.insert('weighings', record.toMap());
    } catch (_) {
      return 0;
    }
  }

  Future<int> deleteRecord(dynamic id) async {
    final db = await database;
    return await db.delete(
      'weighings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearRecords({String? galpao}) async {
    final db = await database;
    if (galpao != null && galpao.isNotEmpty) {
      return await db.delete(
        'weighings',
        where: 'galpao = ?',
        whereArgs: [galpao],
      );
    }
    return await db.delete('weighings');
  }

  // --- Métodos esperados pelo SyncService ---

  Future<List<Map<String, dynamic>>> getAllWeighings() async {
    final db = await database;
    return await db.query('weighings', orderBy: 'id DESC');
  }

  Future<int> insertWeighing(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('weighings', row);
  }

  Future<int> clearAllWeighings() async {
    final db = await database;
    return await db.delete('weighings');
  }
}

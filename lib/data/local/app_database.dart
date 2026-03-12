import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'maize_guard.db';
  static const _dbVersion = 2;
  static const scansTable = 'scans';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbName);
    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createScansTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db
              .execute('ALTER TABLE $scansTable ADD COLUMN report_path TEXT');
          await db
              .execute('ALTER TABLE $scansTable ADD COLUMN model_version TEXT');
          await db
              .execute('ALTER TABLE $scansTable ADD COLUMN quality_score REAL');
          await db
              .execute('ALTER TABLE $scansTable ADD COLUMN disease_id TEXT');
          await db
              .execute('ALTER TABLE $scansTable ADD COLUMN farmer_notes TEXT');
          await db.execute(
            "UPDATE $scansTable SET model_version = COALESCE(model_version, 'legacy-model')",
          );
          await db.execute(
            "UPDATE $scansTable SET disease_id = lower(replace(predicted_label, '_', ' ')) WHERE disease_id IS NULL",
          );
        }
      },
    );
  }

  Future<void> _createScansTable(Database db) async {
    await db.execute('''
      CREATE TABLE $scansTable(
        id TEXT PRIMARY KEY,
        image_path TEXT NOT NULL,
        predicted_label TEXT NOT NULL,
        confidence REAL NOT NULL,
        timestamp TEXT NOT NULL,
        class_probabilities TEXT NOT NULL,
        report_path TEXT,
        model_version TEXT NOT NULL,
        quality_score REAL,
        disease_id TEXT NOT NULL,
        farmer_notes TEXT
      )
    ''');
  }
}

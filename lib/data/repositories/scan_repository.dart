import 'package:maize_leaf_prediction/data/local/app_database.dart';
import 'package:maize_leaf_prediction/data/models/scan_record.dart';
import 'package:sqflite/sqflite.dart';

class ScanRepository {
  ScanRepository(this._database);

  final AppDatabase _database;

  Future<void> insertScan(ScanRecord record) async {
    final db = await _database.database;
    await db.insert(
      AppDatabase.scansTable,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ScanRecord>> getAllScans() async {
    final db = await _database.database;
    final rows = await db.query(
      AppDatabase.scansTable,
      orderBy: 'timestamp DESC',
    );
    return rows.map(ScanRecord.fromMap).toList(growable: false);
  }

  Future<ScanRecord?> getScanById(String id) async {
    final db = await _database.database;
    final rows = await db.query(
      AppDatabase.scansTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ScanRecord.fromMap(rows.first);
  }

  Future<void> updateReportPath(String id, String reportPath) async {
    final db = await _database.database;
    await db.update(
      AppDatabase.scansTable,
      {'report_path': reportPath},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateFarmerNotes(String id, String notes) async {
    final db = await _database.database;
    await db.update(
      AppDatabase.scansTable,
      {'farmer_notes': notes},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteScan(String id) async {
    final db = await _database.database;
    await db.delete(AppDatabase.scansTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await _database.database;
    await db.delete(AppDatabase.scansTable);
  }
}

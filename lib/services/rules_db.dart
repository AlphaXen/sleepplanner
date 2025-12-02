import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/phone_rule_model.dart';

/// SQLite 헬퍼
class RulesDb {
  static final RulesDb instance = RulesDb._internal();
  RulesDb._internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'autoreply_rules.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE phone_rules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phone TEXT NOT NULL,
            message TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<PhoneRule>> getRules() async {
    final database = await db;
    final maps = await database.query('phone_rules', orderBy: 'id DESC');
    return maps.map((m) => PhoneRule.fromMap(m)).toList();
  }

  Future<int> insertRule(PhoneRule rule) async {
    final database = await db;
    return database.insert('phone_rules', rule.toMap());
  }

  Future<int> updateRule(PhoneRule rule) async {
    final database = await db;
    return database.update(
      'phone_rules',
      rule.toMap(),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  Future<int> deleteRule(int id) async {
    final database = await db;
    return database.delete(
      'phone_rules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}


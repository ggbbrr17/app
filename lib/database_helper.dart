import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('anthro_glyph.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE patients (
  id $idType,
  name $textType,
  gender TEXT,
  birthDate TEXT
)
''');

    await db.execute('''
CREATE TABLE measurements (
  id $idType,
  patient_id $intType,
  date $textType,
  age_months $intType,
  weight_kg $realType,
  height_cm $realType,
  bmi $realType,
  z_wfa $realType,
  z_hfa $realType,
  z_bmi $realType,
  diagnosis $textType,
  FOREIGN KEY (patient_id) REFERENCES patients (id)
)
''');

    await db.execute('''
CREATE TABLE sessions (
  id $idType,
  date $textType
)
''');

    await db.execute('''
CREATE TABLE chat_messages (
  id $idType,
  session_id INTEGER,
  role TEXT,
  text TEXT,
  type TEXT,
  data TEXT,
  isThought INTEGER,
  timestamp TEXT,
  FOREIGN KEY (session_id) REFERENCES sessions (id)
)
''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add tables if they don't exist
      await _createDB(db, newVersion);
    }
  }

  Future<int> createSession() async {
    final db = await instance.database;
    return await db.insert('sessions', {'date': DateTime.now().toIso8601String()});
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    final db = await instance.database;
    return await db.query('sessions', orderBy: 'date DESC');
  }

  Future<int> insertMessage(int sessionId, Map<String, dynamic> msg) async {
    final db = await instance.database;
    return await db.insert('chat_messages', {
      'session_id': sessionId,
      'role': msg['role'],
      'text': msg['text'] ?? "",
      'type': msg['type'],
      'data': msg['data'] != null ? jsonEncode(msg['data']) : null,
      'isThought': (msg['isThought'] ?? false) ? 1 : 0,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getSessionMessages(int sessionId) async {
    final db = await instance.database;
    return await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'id ASC',
    );
  }

  Future<void> clearCurrentSessionMessages(int sessionId) async {
    final db = await instance.database;
    await db.delete('chat_messages', where: 'session_id = ?', whereArgs: [sessionId]);
  }

  Future<int> insertPatient(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('patients', row);
  }

  Future<List<Map<String, dynamic>>> getAllPatients() async {
    final db = await instance.database;
    return await db.query('patients');
  }

  Future<int> insertMeasurement(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('measurements', row);
  }

  Future<List<Map<String, dynamic>>> getPatientMeasurements(int patientId) async {
    final db = await instance.database;
    return await db.query(
      'measurements',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'date ASC',
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

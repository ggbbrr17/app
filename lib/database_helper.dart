import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE patients (
  id $idType,
  name $textType,
  birthDate $textType,
  gender $textType
)
''');

    await db.execute('''
CREATE TABLE measurements (
  id $idType,
  patient_id INTEGER,
  date $textType,
  age_months $realType,
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

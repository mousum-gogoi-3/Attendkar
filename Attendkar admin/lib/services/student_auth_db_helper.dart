import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class StudentAuthDbHelper {
  static const _databaseName = "attendkar_student_auth.db";
  static const _databaseVersion = 2; // Incremented for roll_number

  StudentAuthDbHelper._privateConstructor();
  static final StudentAuthDbHelper instance = StudentAuthDbHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS student_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        roll_number TEXT NOT NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE student_accounts ADD COLUMN roll_number TEXT NOT NULL DEFAULT ""');
    }
  }

  Future<int> insertStudentAccount(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('student_accounts', row, conflictAlgorithm: ConflictAlgorithm.fail);
  }

  Future<Map<String, dynamic>?> authenticateStudent(String email, String password) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> res = await db.query(
      'student_accounts',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  Future<bool> doesAccountExist(String email) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> res = await db.query(
      'student_accounts',
      where: 'email = ?',
      whereArgs: [email],
    );
    return res.isNotEmpty;
  }

  Future<bool> doesRollNumberExist(String rollNumber) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> res = await db.query(
      'student_accounts',
      where: 'roll_number = ?',
      whereArgs: [rollNumber],
    );
    return res.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getAllAccounts() async {
    Database db = await instance.database;
    return await db.query('student_accounts', columns: ['id', 'email', 'roll_number']);
  }
}


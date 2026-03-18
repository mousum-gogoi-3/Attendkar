import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class FacultyDbHelper {
  static const _databaseName = "attendkar_faculty.db";
  static const _databaseVersion = 4;

  FacultyDbHelper._privateConstructor();
  static final FacultyDbHelper instance = FacultyDbHelper._privateConstructor();

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
    // Users table for faculty login
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT DEFAULT 'faculty'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS faculty_profile (
        faculty_id TEXT UNIQUE NOT NULL,
        user_id INTEGER NOT NULL,
        full_name TEXT NOT NULL,
        department TEXT NOT NULL,
        created_at TEXT,
        is_verified INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS classes (
        class_id INTEGER PRIMARY KEY AUTOINCREMENT,
        faculty_user_id INTEGER NOT NULL,
        subject_name TEXT NOT NULL,
        section TEXT NOT NULL,
        semester TEXT NOT NULL,
        department TEXT NOT NULL DEFAULT '',
        course TEXT NOT NULL DEFAULT '',
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance (
        attendance_id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL,
        student_user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS global_closures (
        date TEXT PRIMARY KEY,
        reason TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS class_closures (
        class_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        reason TEXT,
        PRIMARY KEY (class_id, date)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS class_students (
        student_id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        roll_no TEXT NOT NULL,
        department TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance_sessions (
        session_id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        start_time TEXT,
        end_time TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance_records (
        record_id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        UNIQUE(session_id, student_id)
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // For future upgrades or column additions
    try {
      if (oldVersion < 3) {
        await db.execute("ALTER TABLE faculty_profile ADD COLUMN is_verified INTEGER DEFAULT 0");
      }
    } catch (e) {
      // Column might already exist
    }

    try {
      await db.execute("ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'faculty'");
    } catch (e) {
      // Column might already exist
    }

    try {
      await db.execute("ALTER TABLE classes ADD COLUMN department TEXT NOT NULL DEFAULT ''");
    } catch (e) {
      // Column might already exist
    }

    try {
      if (oldVersion < 4) {
        await db.execute("ALTER TABLE classes ADD COLUMN course TEXT NOT NULL DEFAULT ''");
      }
    } catch (e) {
      // Column might already exist
    }

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS global_closures (
          date TEXT PRIMARY KEY,
          reason TEXT
        )
      ''');
    } catch (e) {
      // Logic failure
    }

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS class_closures (
          class_id INTEGER NOT NULL,
          date TEXT NOT NULL,
          reason TEXT,
          PRIMARY KEY (class_id, date)
        )
      ''');
    } catch (e) {
      // Logic failure
    }

    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS class_students (
          student_id INTEGER PRIMARY KEY AUTOINCREMENT,
          class_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          roll_no TEXT NOT NULL,
          department TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS attendance_sessions (
          session_id INTEGER PRIMARY KEY AUTOINCREMENT,
          class_id INTEGER NOT NULL,
          date TEXT NOT NULL,
          start_time TEXT,
          end_time TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS attendance_records (
          record_id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id INTEGER NOT NULL,
          student_id INTEGER NOT NULL,
          status TEXT NOT NULL,
          UNIQUE(session_id, student_id)
        )
      ''');
    }
  }

  // Helper method to insert user
  Future<int> insertUser(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('users', row, conflictAlgorithm: ConflictAlgorithm.fail);
  }

  Future<Map<String, dynamic>?> authenticateUser(String email, String password) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> res = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  Future<int> insertFacultyProfile(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('faculty_profile', row);
  }

  Future<Map<String, dynamic>?> getFacultyProfile(int userId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> res = await db.query(
      'faculty_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  Future<String> getNextFacultyId() async {
    Database db = await instance.database;
    var res = await db.rawQuery('SELECT COUNT(*) as count FROM faculty_profile');
    int count = Sqflite.firstIntValue(res) ?? 0;
    return 'FAC${(count + 1).toString().padLeft(3, '0')}';
  }

  Future<int> updateFacultyVerification(int userId, bool isVerified) async {
    Database db = await instance.database;
    return await db.update(
      'faculty_profile',
      {'is_verified': isVerified ? 1 : 0},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Class Methods
  Future<int> insertClass(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('classes', row);
  }

  Future<List<Map<String, dynamic>>> getFacultyClasses(int facultyUserId) async {
    Database db = await instance.database;
    return await db.query(
      'classes',
      where: 'faculty_user_id = ?',
      whereArgs: [facultyUserId],
      orderBy: 'created_at DESC'
    );
  }

  Future<Map<String, dynamic>?> getClassById(int classId) async {
    Database db = await instance.database;
    final res = await db.query(
      'classes',
      where: 'class_id = ?',
      whereArgs: [classId],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  // Attendance Methods
  Future<int> insertAttendance(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('attendance', row);
  }

  Future<void> insertAttendanceBatch(List<Map<String, dynamic>> rows) async {
    Database db = await instance.database;
    Batch batch = db.batch();
    for (var row in rows) {
      batch.insert('attendance', row);
    }
    await batch.commit(noResult: true);
  }

  Future<int> insertOrUpdateAttendance(Map<String, dynamic> row) async {
    Database db = await instance.database;
    final existing = await db.query(
      'attendance',
      where: 'class_id = ? AND student_user_id = ? AND date = ?',
      whereArgs: [row['class_id'], row['student_user_id'], row['date']],
    );
    if (existing.isNotEmpty) {
      return await db.update(
        'attendance',
        {'status': row['status']},
        where: 'attendance_id = ?',
        whereArgs: [existing.first['attendance_id']],
      );
    } else {
      return await db.insert('attendance', row);
    }
  }

  Future<int> updateAttendanceRecordById(int attendanceId, String newStudentId, String newStatus) async {
    Database db = await instance.database;
    return await db.update(
      'attendance',
      {
        'student_user_id': newStudentId,
        'status': newStatus,
      },
      where: 'attendance_id = ?',
      whereArgs: [attendanceId],
    );
  }

  Future<List<String>> getUniqueStudentsForClass(int classId) async {
    Database db = await instance.database;
    final res = await db.rawQuery(
      'SELECT DISTINCT student_user_id FROM attendance WHERE class_id = ?',
      [classId],
    );
    return res.map((e) => e['student_user_id'].toString()).toList();
  }

  Future<int> getTotalClassesHeld(int classId) async {
    Database db = await instance.database;
    final res = await db.rawQuery(
      '''
      SELECT COUNT(DISTINCT date) as count FROM attendance 
      WHERE class_id = ? 
      AND date NOT IN (SELECT date FROM global_closures)
      AND date NOT IN (SELECT date FROM class_closures WHERE class_id = ?)
      ''',
      [classId, classId],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getAttendanceForClassDate(int classId, String date) async {
    Database db = await instance.database;
    return await db.query(
      'attendance',
      where: 'class_id = ? AND date = ?',
      whereArgs: [classId, date],
    );
  }

  Future<List<Map<String, dynamic>>> getAllAttendanceForClass(int classId) async {
    Database db = await instance.database;
    return await db.query(
      'attendance',
      where: 'class_id = ?',
      whereArgs: [classId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllSavedAccounts() async {
    Database db = await instance.database;
    return await db.rawQuery('''
      SELECT u.user_id, u.email, p.full_name, p.faculty_id 
      FROM users u 
      LEFT JOIN faculty_profile p ON u.user_id = p.user_id
    ''');
  }

  // University Closures Methods
  Future<int> markUniversityClosed(String date, String reason) async {
    Database db = await instance.database;
    return await db.insert('global_closures', {'date': date, 'reason': reason}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> removeUniversityClosure(String date) async {
    Database db = await instance.database;
    return await db.delete('global_closures', where: 'date = ?', whereArgs: [date]);
  }

  Future<bool> isDateClosed(String date) async {
    Database db = await instance.database;
    final res = await db.query('global_closures', where: 'date = ?', whereArgs: [date]);
    return res.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getAllClosures() async {
    Database db = await instance.database;
    return await db.query('global_closures');
  }

  // Class Specific Closures Methods
  Future<int> markClassClosed(int classId, String date, String reason) async {
    Database db = await instance.database;
    return await db.insert('class_closures', {'class_id': classId, 'date': date, 'reason': reason}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> removeClassClosure(int classId, String date) async {
    Database db = await instance.database;
    return await db.delete('class_closures', where: 'class_id = ? AND date = ?', whereArgs: [classId, date]);
  }

  Future<bool> isClassDateClosed(int classId, String date) async {
    Database db = await instance.database;
    final res = await db.query('class_closures', where: 'class_id = ? AND date = ?', whereArgs: [classId, date]);
    return res.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getAllClassClosures(int classId) async {
    Database db = await instance.database;
    return await db.query('class_closures', where: 'class_id = ?', whereArgs: [classId]);
  }

  // --- NEW ARCHITECTURE METHODS ---

  // Class Students
  Future<int> insertClassStudent(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('class_students', row);
  }

  Future<void> insertClassStudentsBatch(List<Map<String, dynamic>> students) async {
    Database db = await instance.database;
    Batch batch = db.batch();
    for (var student in students) {
      batch.insert('class_students', student, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<int> updateClassStudent(int studentId, Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.update(
      'class_students',
      row,
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
  }

  Future<List<Map<String, dynamic>>> getStudentsForClassV2(int classId) async {
    Database db = await instance.database;
    return await db.query(
      'class_students',
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'roll_no ASC'
    );
  }

  Future<int> deleteClassStudent(int studentId) async {
    Database db = await instance.database;
    return await db.delete('class_students', where: 'student_id = ?', whereArgs: [studentId]);
  }

  // Attendance Sessions
  Future<int> insertAttendanceSession(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('attendance_sessions', row);
  }

  Future<List<Map<String, dynamic>>> getSessionsForClass(int classId) async {
    Database db = await instance.database;
    return await db.query(
      'attendance_sessions',
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'date DESC'
    );
  }

  Future<Map<String, dynamic>?> getSessionById(int sessionId) async {
    Database db = await instance.database;
    final res = await db.query(
      'attendance_sessions',
      where: 'session_id = ?',
      whereArgs: [sessionId]
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<int> deleteSession(int sessionId) async {
    Database db = await instance.database;
    await db.delete('attendance_records', where: 'session_id = ?', whereArgs: [sessionId]);
    return await db.delete('attendance_sessions', where: 'session_id = ?', whereArgs: [sessionId]);
  }

  // Attendance Records (V2)
  Future<void> replaceAttendanceRecordsForSession(int sessionId, List<Map<String, dynamic>> records) async {
    Database db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('attendance_records', where: 'session_id = ?', whereArgs: [sessionId]);
      for (var record in records) {
        await txn.insert('attendance_records', record);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getRecordsForSession(int sessionId) async {
    Database db = await instance.database;
    // Modified strictly to not join class_students as we will use CSV for metadata.
    return await db.rawQuery('''
      SELECT ar.* 
      FROM attendance_records ar
      WHERE ar.session_id = ?
    ''', [sessionId]);
  }

  Future<int> getTotalSessionsHeld(int classId) async {
    Database db = await instance.database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM attendance_sessions WHERE class_id = ?',
      [classId],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }
}


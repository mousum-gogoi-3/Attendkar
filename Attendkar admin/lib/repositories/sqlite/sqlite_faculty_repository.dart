import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../i_faculty_repository.dart';
import '../../models/faculty_profile.dart';

class SQLiteFacultyRepository implements IFacultyRepository {
  static const _databaseName = "attendkar_faculty.db";
  Database? _database;

  @override
  Future<void> init() async {
    if (_database != null) return;
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    
    // We are just *opening* the DB created by the main app, not creating tables.
    _database = await openDatabase(path);
  }

  @override
  Future<List<FacultyProfile>> getAllFaculty() async {
    final db = _database;
    if (db == null) throw Exception("Database not initialized");

    final result = await db.rawQuery('''
      SELECT u.user_id, u.email, p.full_name, p.department, p.is_verified, p.faculty_id
      FROM users u
      LEFT JOIN faculty_profile p ON u.user_id = p.user_id
      WHERE u.role = 'faculty'
    ''');
    
    return result.map((row) {
      return FacultyProfile(
        userId: row['user_id'] as int,
        fullName: row['full_name'] as String? ?? 'Unknown',
        department: row['department'] as String? ?? 'Unknown',
        facultyId: row['faculty_id'] as String? ?? 'UNKNOWN',
        email: row['email'] as String,
        isVerified: (row['is_verified'] as int? ?? 0) == 1,
      );
    }).toList();
  }

  @override
  Future<FacultyProfile?> getFacultyByEmail(String email) async {
    final db = _database;
    if (db == null) throw Exception("Database not initialized");

    final result = await db.rawQuery('''
      SELECT u.user_id, u.email, p.full_name, p.department, p.is_verified, p.faculty_id
      FROM users u
      LEFT JOIN faculty_profile p ON u.user_id = p.user_id
      WHERE u.role = 'faculty' AND u.email = ?
    ''', [email]);
    
    if (result.isEmpty) return null;
    final row = result.first;
    
    return FacultyProfile(
        userId: row['user_id'] as int,
        fullName: row['full_name'] as String? ?? 'Unknown',
        department: row['department'] as String? ?? 'Unknown',
        facultyId: row['faculty_id'] as String? ?? 'UNKNOWN',
        email: row['email'] as String,
        isVerified: (row['is_verified'] as int? ?? 0) == 1,
    );
  }

  @override
  Future<void> updateFacultyVerification(String email, bool isVerified) async {
    final db = _database;
    if (db == null) throw Exception("Database not initialized");

    // Get the user ID first
    final userResult = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (userResult.isEmpty) return;
    final userId = userResult.first['user_id'] as int;

    await db.update(
      'faculty_profile',
      {'is_verified': isVerified ? 1 : 0},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}

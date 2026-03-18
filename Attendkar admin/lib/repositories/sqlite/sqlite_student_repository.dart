import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../i_student_repository.dart';
import '../../models/student.dart';

class SQLiteStudentRepository implements IStudentRepository {
   static const _databaseName = "attendkar_student_auth.db";
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
  Future<List<Student>> getAllStudents() async {
     final db = _database;
     if (db == null) throw Exception("Database not initialized");

     final result = await db.query('student_accounts');
     return result.map((row) {
        // We only have email and roll_number in the auth DB currently. 
        // Name is usually in the class_students table in the faculty DB.
        // For admin purposes, showing what's in the auth DB.
        return Student(
          name: row['email'] as String, // Fallback
          rollNo: row['roll_number'] as String,
          department: 'Unknown',
          course: 'Unknown',
          semester: 'Unknown',
          section: 'Unknown',
        );
     }).toList();
  }

  @override
  Future<void> addStudent(Student student) async {
     final db = _database;
     if (db == null) throw Exception("Database not initialized");

     await db.insert('student_accounts', {
       'email': '\${student.rollNo}@student.edu', // Dummy email based on roll no
       'password': 'password123', // Default password
       'roll_number': student.rollNo,
     }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteStudent(String rollNo) async {
     final db = _database;
     if (db == null) throw Exception("Database not initialized");

     await db.delete('student_accounts', where: 'roll_number = ?', whereArgs: [rollNo]);
  }
}

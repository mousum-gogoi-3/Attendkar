import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'student_auth_db_helper.dart';
import 'student_data_service.dart';

class StudentAuthService {
  static const String _isStudentLoggedInKey = 'is_student_logged_in';
  static const String _studentEmailKey = 'student_email';
  static const String _studentRollNoKey = 'student_roll_no';

  static String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<bool> isStudentLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isStudentLoggedInKey) ?? false;
  }

  static Future<String?> getLoggedStudentEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_studentEmailKey);
  }

  static Future<String?> getLoggedStudentRollNo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_studentRollNoKey);
  }

  static Future<bool> registerStudent(String email, String password, String rollNumber) async {
    try {
      // 1. Verify that the Roll Number has been pre-registered by the Admin
      // We can use getStudentClasses which queries the Firestore 'students' collection securely.
      final classes = await StudentDataService.getStudentClasses(rollNumber);
      if (classes.isEmpty) {
        throw Exception("Roll number not registered by Admin.");
      }

      final dbHelper = StudentAuthDbHelper.instance;
      String hashedPassword = hashPassword(password);
      
      await dbHelper.insertStudentAccount({
        'email': email,
        'password': hashedPassword,
        'roll_number': rollNumber,
      });

      // Auto login after registration
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isStudentLoggedInKey, true);
      await prefs.setString(_studentEmailKey, email);
      await prefs.setString(_studentRollNoKey, rollNumber);

      return true;
    } catch (e) {
      if (e.toString().contains("Roll number not registered")) {
        rethrow;
      }
      return false; // likely duplicate email
    }
  }

  static Future<bool> loginStudent(String email, String password) async {
    final dbHelper = StudentAuthDbHelper.instance;
    String hashedPassword = hashPassword(password);

    final account = await dbHelper.authenticateStudent(email, hashedPassword);
    if (account != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isStudentLoggedInKey, true);
      await prefs.setString(_studentEmailKey, account['email'] as String);
      await prefs.setString(_studentRollNoKey, account['roll_number'] as String);
      return true;
    }
    return false;
  }

  static Future<void> loginWithSavedAccount(String email, String rollNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isStudentLoggedInKey, true);
    await prefs.setString(_studentEmailKey, email);
    await prefs.setString(_studentRollNoKey, rollNumber);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isStudentLoggedInKey);
    await prefs.remove(_studentEmailKey);
    await prefs.remove(_studentRollNoKey);
  }
}

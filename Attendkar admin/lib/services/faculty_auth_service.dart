import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'faculty_db_helper.dart';

class FacultyAuthService {
  static const String _facultyIdKey = 'faculty_id';
  static const String _userIdKey = 'faculty_user_id';
  static const String _isFacultyLoggedInKey = 'is_faculty_logged_in';

  // Hashing password
  static String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Check login state
  static Future<bool> isFacultyLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFacultyLoggedInKey) ?? false;
  }

  static Future<String?> getLoggedFacultyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_facultyIdKey);
  }

  static Future<int?> getLoggedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // Registration
  static Future<bool> registerFaculty({
    required String fullName,
    required String department,
    required String email,
    required String password,
  }) async {
    try {
      final dbHelper = FacultyDbHelper.instance;
      
      // Hash password
      String hashedPassword = hashPassword(password);

      // Insert into users
      int userId = await dbHelper.insertUser({
        'email': email,
        'password': hashedPassword,
        'role': 'faculty',
      });

      // Generate faculty ID
      String facultyId = await dbHelper.getNextFacultyId();

      // Insert into faculty_profile
      await dbHelper.insertFacultyProfile({
        'faculty_id': facultyId,
        'user_id': userId,
        'full_name': fullName,
        'department': department,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      // Typically duplicate email
      return false;
    }
  }

  // Login
  static Future<bool> loginFaculty(String email, String password) async {
    final dbHelper = FacultyDbHelper.instance;
    String hashedPassword = hashPassword(password);

    final user = await dbHelper.authenticateUser(email, hashedPassword);
    if (user != null && user['role'] == 'faculty') {
      final facultyProfile = await dbHelper.getFacultyProfile(user['user_id'] as int);
      
      if (facultyProfile != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isFacultyLoggedInKey, true);
        await prefs.setInt(_userIdKey, user['user_id'] as int);
        await prefs.setString(_facultyIdKey, facultyProfile['faculty_id'] as String);
        return true;
      }
    }
    return false;
  }

  // Quick Switch Login
  static Future<void> loginWithSavedAccount(int userId, String facultyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFacultyLoggedInKey, true);
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_facultyIdKey, facultyId);
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isFacultyLoggedInKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_facultyIdKey);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Manages student account credentials in Firestore (collection: student_accounts).
/// This replaces the old local SQLite approach so that credentials survive
/// app-data clears.
class StudentAuthDbHelper {
  StudentAuthDbHelper._privateConstructor();
  static final StudentAuthDbHelper instance = StudentAuthDbHelper._privateConstructor();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static bool _isAuthInitialized = false;

  /// Ensures we have Firestore read/write access via background admin sign-in.
  Future<void> _ensureAuth() async {
    if (_isAuthInitialized && _auth.currentUser != null) return;

    if (_auth.currentUser == null) {
      try {
        await _auth.signInWithEmailAndPassword(
          email: 'adminattendnahikarega@gmail.com',
          password: 'mainhoonadmin@#\$321',
        );
        _isAuthInitialized = true;
      } catch (_) {}
    } else {
      _isAuthInitialized = true;
    }
  }

  /// Saves a student account to Firestore.
  /// [row] must contain keys: 'email', 'password' (hashed), 'roll_number'.
  /// Uses roll_number as the document ID so one account per roll number.
  Future<void> insertStudentAccount(Map<String, dynamic> row) async {
    await _ensureAuth();

    final rollNumber = (row['roll_number'] as String).trim();
    final email = (row['email'] as String).trim().toLowerCase();

    // Check if an account with this email already exists
    final emailCheck = await _db
        .collection('student_accounts')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (emailCheck.docs.isNotEmpty) {
      throw Exception('An account with this email already exists.');
    }

    // Check if an account with this roll number already exists
    final rollCheck = await _db
        .collection('student_accounts')
        .doc(rollNumber)
        .get();

    if (rollCheck.exists) {
      throw Exception('An account with this roll number already exists.');
    }

    await _db.collection('student_accounts').doc(rollNumber).set({
      'email': email,
      'password': row['password'] as String,
      'roll_number': rollNumber,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Authenticates a student by email and hashed password.
  /// Returns the account data map if valid, null otherwise.
  Future<Map<String, dynamic>?> authenticateStudent(String email, String password) async {
    await _ensureAuth();

    final query = await _db
        .collection('student_accounts')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .where('password', isEqualTo: password)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.data();
    }
    return null;
  }

  /// Checks whether a student account with the given email exists.
  Future<bool> doesAccountExist(String email) async {
    await _ensureAuth();

    final query = await _db
        .collection('student_accounts')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }
}

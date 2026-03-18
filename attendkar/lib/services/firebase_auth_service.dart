import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles Firebase Authentication and initial faculty profile creation.
class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns the current Firebase Auth user, or null if not logged in.
  static User? get currentUser => _auth.currentUser;

  /// Returns true if a faculty user is currently signed in.
  static bool isFacultyLoggedIn() => _auth.currentUser != null;

  /// Registers a new faculty with Firebase Auth and saves their profile
  /// to Firestore under `faculties/{uid}`.
  ///
  /// Always returns true if the Auth account is created successfully,
  /// even if the Firestore profile write fails (it will be retried later).
  static Future<bool> registerFaculty({
    required String fullName,
    required String department,
    required String email,
    required String password,
  }) async {
    // Step 1: Create the Firebase Auth account. This is the critical step.
    // FirebaseAuthException is re-thrown so the UI can show the real error.
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Step 2: Save the faculty profile to Firestore. If this fails (e.g.,
    // due to security rules), the Auth account already exists so the user
    // can still log in. The profile write is best-effort here.
    final uid = credential.user!.uid;
    try {
      await _db.collection('faculties').doc(uid).set({
        'name': fullName,
        'email': email,
        'department': department,
        'isVerified': false,
        'assignedClassIds': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Firestore write failed — not critical, profile can be synced later.
      // Auth account was created successfully so we still return true.
    }

    return true;
  }

  /// Signs in a faculty member with email and password.
  /// Returns true on success, false on failure.
  static Future<bool> loginFaculty(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Ensures a Firestore profile document exists for the current user.
  /// Call this after login in case the profile write failed during registration.
  static Future<void> ensureFacultyProfile({
    required String fullName,
    required String department,
    required String email,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _db.collection('faculties').doc(uid).get();
      if (!doc.exists) {
        await _db.collection('faculties').doc(uid).set({
          'name': fullName,
          'email': email,
          'department': department,
          'isVerified': false,
          'assignedClassIds': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      // Ignore — profile sync can be retried on next login.
    }
  }

  /// Signs out the current user.
  static Future<void> logout() async {
    await _auth.signOut();
  }

  /// Returns the logged-in faculty's UID.
  static String? getLoggedFacultyUid() => _auth.currentUser?.uid;

  /// Returns the logged-in faculty's email.
  static String? getLoggedFacultyEmail() => _auth.currentUser?.email;

  /// Provides a stream of auth state changes (useful for reactive UI).
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
}

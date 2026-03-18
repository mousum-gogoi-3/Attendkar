import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/faculty_model.dart';
import '../models/class_model.dart';
import '../models/subject_model.dart';
import '../models/student_firestore_model.dart';
import '../models/attendance_session_model.dart';
import '../models/attendance_record_model.dart';

/// Central Firestore access layer for the Faculty App.
/// Faculty can READ classes/students and WRITE attendance sessions/records.
/// All structural data (classes, students) is written only by the Admin App.
class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Faculty ─────────────────────────────────────────────────────────────

  /// Fetches the faculty profile document for the given [uid].
  static Future<FacultyModel?> getFacultyProfile(String uid) async {
    try {
      final doc = await _db.collection('faculties').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return FacultyModel.fromFirestore(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  // ─── Classes ─────────────────────────────────────────────────────────────

  /// Returns all subjects assigned to the faculty identified by [facultyId].
  /// Queries the `subjects` collection where `facultyId == facultyId`.
  static Future<List<SubjectModel>> getAssignedSubjects(String facultyId) async {
    try {
      final snapshot = await _db
          .collection('subjects')
          .where('facultyId', isEqualTo: facultyId)
          .get();
      return snapshot.docs
          .map((doc) => SubjectModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns a single class by [classId].
  static Future<ClassModel?> getClassById(String classId) async {
    try {
      final doc = await _db.collection('classes').doc(classId).get();
      if (!doc.exists || doc.data() == null) return null;
      return ClassModel.fromFirestore(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  // ─── Students ────────────────────────────────────────────────────────────

  /// Returns all students belonging to [subjectId]. Read-only for Faculty App.
  static Future<List<StudentFirestoreModel>> getStudentsForSubject(
      String subjectId) async {
    try {
      final snapshot = await _db
          .collection('students')
          .where('subjectId', isEqualTo: subjectId)
          .get();
      final list = snapshot.docs
          .map((doc) =>
              StudentFirestoreModel.fromFirestore(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.rollNo.compareTo(b.rollNo));
      return list;
    } catch (_) {
      return [];
    }
  }

  // ─── Attendance Sessions ──────────────────────────────────────────────────

  /// Returns all attendance sessions for a subject, filtered to the given faculty.
  static Future<List<AttendanceSessionModel>> getSessionsForSubject(
      String subjectId, String facultyId) async {
    try {
      final snapshot = await _db
          .collection('attendance_sessions')
          .where('subjectId', isEqualTo: subjectId)
          .where('facultyId', isEqualTo: facultyId)
          .get();
      final list = snapshot.docs
          .map((doc) =>
              AttendanceSessionModel.fromFirestore(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Returns a single session by [sessionId].
  static Future<AttendanceSessionModel?> getSessionById(
      String sessionId) async {
    try {
      final doc =
          await _db.collection('attendance_sessions').doc(sessionId).get();
      if (!doc.exists || doc.data() == null) return null;
      return AttendanceSessionModel.fromFirestore(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  /// Creates a new attendance session. Returns the new document ID.
  static Future<String?> createAttendanceSession(
      AttendanceSessionModel session) async {
    try {
      final ref = await _db
          .collection('attendance_sessions')
          .add(session.toFirestore());
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  /// Deletes a session and all its attendance records atomically.
  static Future<void> deleteSession(String sessionId) async {
    try {
      final batch = _db.batch();

      // Delete all records for this session
      final records = await _db
          .collection('attendance_records')
          .where('sessionId', isEqualTo: sessionId)
          .get();
      for (final doc in records.docs) {
        batch.delete(doc.reference);
      }

      // Delete the session itself
      batch.delete(
          _db.collection('attendance_sessions').doc(sessionId));

      await batch.commit();
    } catch (_) {
      // Silently fail – let UI handle retry
    }
  }

  // ─── Attendance Records ───────────────────────────────────────────────────

  /// Returns all attendance records for a given session.
  static Future<List<AttendanceRecordModel>> getRecordsForSession(
      String sessionId) async {
    try {
      final snapshot = await _db
          .collection('attendance_records')
          .where('sessionId', isEqualTo: sessionId)
          .get();
      return snapshot.docs
          .map((doc) =>
              AttendanceRecordModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Replaces all attendance records for [sessionId] with [records].
  /// Uses a batched write for atomicity.
  static Future<bool> saveAttendanceRecords(
      String sessionId, List<AttendanceRecordModel> records) async {
    try {
      final batch = _db.batch();

      // Delete existing records for this session
      final existing = await _db
          .collection('attendance_records')
          .where('sessionId', isEqualTo: sessionId)
          .get();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }

      // Write new records
      for (final record in records) {
        final ref = _db.collection('attendance_records').doc();
        batch.set(ref, record.toFirestore());
      }

      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Analytics ───────────────────────────────────────────────────────────

  /// Returns the total number of sessions held for a subject by this faculty.
  static Future<int> getTotalSessionsHeld(
      String subjectId, String facultyId) async {
    try {
      final snapshot = await _db
          .collection('attendance_sessions')
          .where('subjectId', isEqualTo: subjectId)
          .where('facultyId', isEqualTo: facultyId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Returns a map of studentId → presentCount across all sessions for a subject.
  static Future<Map<String, int>> getAttendanceCountsForSubject(
      String subjectId, String facultyId) async {
    final sessions = await getSessionsForSubject(subjectId, facultyId);
    final Map<String, int> presentCount = {};
    for (final session in sessions) {
      final records = await getRecordsForSession(session.sessionId);
      for (final record in records) {
        if (record.isPresent) {
          presentCount[record.studentId] =
              (presentCount[record.studentId] ?? 0) + 1;
        }
      }
    }
    return presentCount;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/department_model.dart';
import '../models/faculty_model.dart';
import '../models/subject_model.dart';
import '../models/student_firestore_model.dart';
import '../models/attendance_session_model.dart';
import '../models/attendance_record_model.dart';

/// Admin-only Firestore service.
/// All write operations for structural data (departments, faculties, subjects,
/// students) are gated to the Admin Panel.
class AdminFirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Departments ──────────────────────────────────────────────────────────

  /// Live stream of all departments, ordered by name.
  static Stream<List<DepartmentModel>> streamDepartments() {
    return _db
        .collection('departments')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => DepartmentModel.fromFirestore(d.data(), d.id))
            .toList());
  }

  static Future<List<DepartmentModel>> getDepartments() async {
    try {
      final snap =
          await _db.collection('departments').orderBy('name').get();
      return snap.docs
          .map((d) => DepartmentModel.fromFirestore(d.data(), d.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<String?> createDepartment(String name, String program) async {
    final ref = await _db.collection('departments').add({
      'name': name.trim(),
      'program': program.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<bool> updateDepartment(
      String departmentId, String newName, String program) async {
    await _db.collection('departments').doc(departmentId).update({
      'name': newName.trim(),
      'program': program.trim(),
    });
    return true;
  }

  /// Deletes a department and all its associated faculties, subjects and students.
  static Future<bool> deleteDepartment(String departmentId) async {
    try {
      // Cascade: get all faculties in this department
      final faculties = await _db
          .collection('faculties')
          .where('department', isEqualTo: departmentId)
          .get();
      for (final faculty in faculties.docs) {
        await _deleteFacultyData(faculty.id);
      }
      await _db.collection('departments').doc(departmentId).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Faculty ──────────────────────────────────────────────────────────────

  /// Stream of faculties belonging to a given department ID.
  static Stream<List<FacultyModel>> streamFacultiesByDepartment(
      String departmentId) {
    return _db
        .collection('faculties')
        .where('department', isEqualTo: departmentId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => FacultyModel.fromFirestore(d.data(), d.id))
            .toList());
  }

  /// Creates a faculty account via Firebase Auth + writes Firestore profile.
  static Future<String?> createFaculty({
    required String name,
    required String email,
    required String password,
    required String departmentId,
    required String departmentName,
  }) async {
    try {
      // Create Firebase Auth account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;

      // Write Firestore profile
      await _db.collection('faculties').doc(uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'department': departmentId,
        'departmentName': departmentName,
        'isVerified': true, // Admin-created faculty are auto-verified
        'assignedClassIds': [],
        'createdAt': FieldValue.serverTimestamp(),
        'createdByAdmin': true,
      });

      // Sign back in as admin (creating faculty signs in as them)
      await _auth.signInWithEmailAndPassword(
        email: 'adminattendnahikarega@gmail.com',
        password: 'mainhoonadmin@#\$321',
      );

      return uid;
    } on FirebaseAuthException {
      // Re-sign in as admin even on failure
      try {
        await _auth.signInWithEmailAndPassword(
          email: 'adminattendnahikarega@gmail.com',
          password: 'mainhoonadmin@#\$321',
        );
      } catch (_) {}
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> updateFaculty(
      String facultyId, String name, String departmentId, String departmentName) async {
    try {
      await _db.collection('faculties').doc(facultyId).update({
        'name': name.trim(),
        'department': departmentId,
        'departmentName': departmentName,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteFaculty(String facultyId) async {
    try {
      await _deleteFacultyData(facultyId);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _deleteFacultyData(String facultyId) async {
    // Delete subjects assigned to this faculty
    final subjects = await _db
        .collection('subjects')
        .where('facultyId', isEqualTo: facultyId)
        .get();
    for (final subject in subjects.docs) {
      await _deleteSubjectData(subject.id);
    }
    // Delete classes assigned to this faculty (legacy)
    final classes = await _db
        .collection('classes')
        .where('facultyId', isEqualTo: facultyId)
        .get();
    final batch = _db.batch();
    for (final cls in classes.docs) {
      batch.delete(cls.reference);
    }
    batch.delete(_db.collection('faculties').doc(facultyId));
    await batch.commit();
  }

  // ─── Subjects ─────────────────────────────────────────────────────────────

  static Stream<List<SubjectModel>> streamSubjectsByFaculty(String facultyId) {
    return _db
        .collection('subjects')
        .where('facultyId', isEqualTo: facultyId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SubjectModel.fromFirestore(d.data(), d.id))
            .toList());
  }

  static Future<String?> createSubject({
    required String name,
    required String facultyId,
    required String departmentId,
    required String semester,
    required String courseCode,
  }) async {
    try {
      final ref = await _db.collection('subjects').add({
        'name': name.trim(),
        'facultyId': facultyId,
        'departmentId': departmentId,
        'semester': semester.trim(),
        'courseCode': courseCode.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> updateSubject(String subjectId, String name, String semester, String courseCode) async {
    try {
      await _db.collection('subjects').doc(subjectId).update({
        'name': name.trim(),
        'semester': semester.trim(),
        'courseCode': courseCode.trim(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteSubject(String subjectId) async {
    try {
      await _deleteSubjectData(subjectId);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _deleteSubjectData(String subjectId) async {
    final batch = _db.batch();
    // Delete students under subject
    final students = await _db
        .collection('students')
        .where('subjectId', isEqualTo: subjectId)
        .get();
    for (final s in students.docs) {
      batch.delete(s.reference);
    }
    // Delete attendance_sessions under subject
    final sessions = await _db
        .collection('attendance_sessions')
        .where('subjectId', isEqualTo: subjectId)
        .get();
    for (final sess in sessions.docs) {
      // Delete records for this session
      final records = await _db
          .collection('attendance_records')
          .where('sessionId', isEqualTo: sess.id)
          .get();
      for (final r in records.docs) {
        batch.delete(r.reference);
      }
      batch.delete(sess.reference);
    }
    batch.delete(_db.collection('subjects').doc(subjectId));
    await batch.commit();
  }

  // ─── Students ─────────────────────────────────────────────────────────────

  static Stream<List<StudentFirestoreModel>> streamStudentsBySubject(
      String subjectId) {
    return _db
        .collection('students')
        .where('subjectId', isEqualTo: subjectId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => StudentFirestoreModel.fromFirestore(d.data(), d.id))
              .toList();
          list.sort((a, b) => a.rollNo.compareTo(b.rollNo));
          return list;
        });
  }

  static Future<String?> createStudent({
    required String name,
    required String rollNo,
    required String department,
    required String section,
    required String subjectId,
    String semester = '',
    String classId = '',
  }) async {
    final ref = await _db.collection('students').add({
      'name': name.trim(),
      'rollNo': rollNo.trim(),
      'department': department.trim(),
      'section': section.trim(),
      'semester': semester.trim(),
      'subjectId': subjectId,
      'classId': classId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<bool> updateStudent(
      String studentId, String name, String rollNo, String section, String semester) async {
    try {
      await _db.collection('students').doc(studentId).update({
        'name': name.trim(),
        'rollNo': rollNo.trim(),
        'section': section.trim(),
        'semester': semester.trim(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteStudent(String studentId) async {
    try {
      await _db.collection('students').doc(studentId).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Batch-uploads a list of student maps (name, rollNo, department, section).
  /// Returns count of successfully created students.
  static Future<int> uploadStudents(
      List<Map<String, String>> students, String subjectId,
      {String classId = ''}) async {
    int count = 0;
    const batchSize = 400;
    for (int i = 0; i < students.length; i += batchSize) {
      final chunk = students.sublist(
          i, i + batchSize > students.length ? students.length : i + batchSize);
      final batch = _db.batch();
      for (final student in chunk) {
        final ref = _db.collection('students').doc();
        batch.set(ref, {
          'name': (student['name'] ?? '').trim(),
          'rollNo': (student['rollNo'] ?? '').trim(),
          'department': (student['department'] ?? '').trim(),
          'section': (student['section'] ?? '').trim(),
          'semester': (student['semester'] ?? '').trim(),
          'subjectId': subjectId,
          'classId': classId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        count++;
      }
      await batch.commit();
    }
    return count;
  }

  // ─── Attendance Sessions ──────────────────────────────────────────────────

  static Stream<List<AttendanceSessionModel>> streamSessionsBySubject(
      String subjectId) {
    return _db
        .collection('attendance_sessions')
        .where('subjectId', isEqualTo: subjectId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => AttendanceSessionModel.fromFirestore(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  static Future<bool> deleteSessionAdmin(String sessionId) async {
    try {
      final batch = _db.batch();
      final records = await _db
          .collection('attendance_records')
          .where('sessionId', isEqualTo: sessionId)
          .get();
      for (final r in records.docs) {
        batch.delete(r.reference);
      }
      batch.delete(_db.collection('attendance_sessions').doc(sessionId));
      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Attendance Records ───────────────────────────────────────────────────

  static Future<List<AttendanceRecordModel>> getRecordsForSession(
      String sessionId) async {
    try {
      final snap = await _db
          .collection('attendance_records')
          .where('sessionId', isEqualTo: sessionId)
          .get();
      return snap.docs
          .map((d) => AttendanceRecordModel.fromFirestore(d.data(), d.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Batch-fetches student documents and returns a map of studentId → StudentFirestoreModel.
  static Future<Map<String, StudentFirestoreModel>> getStudentsByIds(
      List<String> studentIds) async {
    if (studentIds.isEmpty) return {};
    try {
      final Map<String, StudentFirestoreModel> result = {};
      // Firestore 'whereIn' supports max 30 items per query; chunk if needed.
      const chunkSize = 30;
      for (int i = 0; i < studentIds.length; i += chunkSize) {
        final chunk = studentIds.sublist(
            i, i + chunkSize > studentIds.length ? studentIds.length : i + chunkSize);
        final snap = await _db
            .collection('students')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snap.docs) {
          result[doc.id] = StudentFirestoreModel.fromFirestore(doc.data(), doc.id);
        }
      }
      return result;
    } catch (e) {
      return {};
    }
  }

  static Future<bool> updateAttendanceRecord(
      String recordId, String status) async {
    try {
      await _db
          .collection('attendance_records')
          .doc(recordId)
          .update({'status': status});
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Student Lookup (for verification) ───────────────────────────────────

  /// Checks if a roll number exists in the students collection.
  /// Used by student signup verification.
  static Future<bool> rollNumberExists(String rollNo) async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInWithEmailAndPassword(
          email: 'adminattendnahikarega@gmail.com',
          password: 'mainhoonadmin@#\$321',
        );
      }
      
      final snap = await _db
          .collection('students')
          .where('rollNo', isEqualTo: rollNo.trim())
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Fetches a student by their roll number from the students collection.
  static Future<StudentFirestoreModel?> getStudentByRollNo(String rollNo) async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInWithEmailAndPassword(
          email: 'adminattendnahikarega@gmail.com',
          password: 'mainhoonadmin@#\$321',
        );
      }
      
      final snap = await _db
          .collection('students')
          .where('rollNo', isEqualTo: rollNo.trim())
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        return StudentFirestoreModel.fromFirestore(snap.docs.first.data(), snap.docs.first.id);
      }
      return null;
    } catch (e) {
      throw Exception('Firestore Error: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentDataService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static bool _isAuthInitialized = false;

  /// Ensures we have read access before querying.
  static Future<void> _ensureAuth() async {
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

  /// Fetches the profile details (Name, Roll No, Department, etc.) of a student.
  static Future<Map<String, dynamic>?> getStudentProfile(String rollNumber) async {
    await _ensureAuth();
    
    try {
      final studentQuery = await _db
          .collection('students')
          .where('rollNo', isEqualTo: rollNumber.trim())
          .limit(1)
          .get();

      if (studentQuery.docs.isNotEmpty) {
        return studentQuery.docs.first.data();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetches all classes a student is enrolled in by their Roll Number.
  static Future<List<Map<String, dynamic>>> getStudentClasses(String rollNumber) async {
    await _ensureAuth();
    
    // 1. Find the student doc(s) that match this roll number
    // Plural because a student might be enrolled in multiple subjects (each subject enrollment is currently a doc in 'students').
    final studentQuery = await _db
        .collection('students')
        .where('rollNo', isEqualTo: rollNumber.trim())
        .get();

    List<Map<String, dynamic>> classes = [];

    for (var doc in studentQuery.docs) {
      final data = doc.data();
      final subjectId = data['subjectId'] as String?;
      final section = data['section'] as String?;
      final semester = data['semester'] as String?;
      final department = data['department'] as String?;

      if (subjectId != null && subjectId.isNotEmpty) {
        // 2. Fetch subject details
        final subjectDoc = await _db.collection('subjects').doc(subjectId).get();
        if (subjectDoc.exists) {
          final subjectData = subjectDoc.data()!;
          final subjectName = subjectData['name'] as String? ?? 'Unknown Subject';
          final facultyId = subjectData['facultyId'] as String?;

          // 3. Fetch faculty name
          String facultyName = 'Unknown Faculty';
          if (facultyId != null && facultyId.isNotEmpty) {
            final facultyDoc = await _db.collection('faculties').doc(facultyId).get();
            if (facultyDoc.exists) {
              facultyName = facultyDoc.data()?['name'] as String? ?? 'Unknown Faculty';
            }
          }

          classes.add({
            'class_id': subjectId, // using subjectId as classId for Firestore structure
            'subject_name': subjectName,
            'section': section ?? '',
            'semester': semester ?? '',
            'department': department ?? '',
            'student_id': doc.id, // the unique document ID representing student's enrollment in this subject
            'faculty_name': facultyName,
            'created_at': (subjectData['createdAt'] as Timestamp?)?.toDate().millisecondsSinceEpoch ?? 0,
          });
        }
      }
    }

    // Sort by latest created subject
    classes.sort((a, b) => (b['created_at'] as int).compareTo(a['created_at'] as int));
    return classes;
  }

  /// Calculates total attendance stats for a specific student in a specific class.
  static Future<Map<String, dynamic>> getStudentAttendanceSummary(String subjectId, String rollNo) async {
    try {
      await _ensureAuth();
      
      // 1. Total sessions held for this class (subject)
      final sessionsQuery = await _db
          .collection('attendance_sessions')
          .where('subjectId', isEqualTo: subjectId)
          .get();
          
      int totalSessions = sessionsQuery.docs.length;

      // 2. Fetch all student document IDs for this rollNo (across potentially multiple subjects/sections, though we filter sessions down below)
      final studentDocsQuery = await _db
          .collection('students')
          .where('rollNo', isEqualTo: rollNo.trim())
          .get();

      if (studentDocsQuery.docs.isEmpty) {
        throw Exception("Student not found.");
      }

      // Collect all student document IDs mapping back to this rollNo
      final List<String> studentDocIds = studentDocsQuery.docs.map((d) => d.id).toList();

      // 3. Count presents: For this specific subject's sessions, count records matching any of the student doc IDs.
      // Easiest is to fetch records for the specific session IDs + student IDs.
      int presents = 0;
      if (sessionsQuery.docs.isNotEmpty) {
          final Set<String> sessionIds = sessionsQuery.docs.map((d) => d.id).toSet();
          
          // chunk studentDocIds to avoid Firestore limit
           for (var i = 0; i < studentDocIds.length; i += 10) {
             final chunk = studentDocIds.sublist(i, (i + 10 > studentDocIds.length) ? studentDocIds.length : i + 10);
              
             final presentQuery = await _db
                .collection('attendance_records')
                .where('studentId', whereIn: chunk)
                .where('status', isEqualTo: 'Present')
                .get();
                
             for (var record in presentQuery.docs) {
                if (sessionIds.contains(record.data()['sessionId'])) {
                    presents++;
                }
             }
           }
      }

      int absents = totalSessions - presents;

      // 4. Percentage
      double percentage = totalSessions > 0 ? (presents / totalSessions) * 100 : 0.0;

      return {
        'total_sessions': totalSessions,
        'present': presents,
        'absent': absents,
        'percentage': percentage,
      };
    } catch (_) {
      return {
        'total_sessions': 0,
        'present': 0,
        'absent': 0,
        'percentage': 0.0,
      };
    }
  }

  /// Fetches the discrete session list and whether the student was present or absent.
  static Future<List<Map<String, dynamic>>> getStudentAttendanceHistory(String subjectId, String rollNo) async {
    await _ensureAuth();
    
    try {
      // 1. Fetch all sessions for this subject
      final sessionsQuery = await _db
          .collection('attendance_sessions')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      // 2. Fetch all student document IDs for this rollNo
      final studentDocsQuery = await _db
          .collection('students')
          .where('rollNo', isEqualTo: rollNo.trim())
          .get();

      final List<String> studentDocIds = studentDocsQuery.docs.map((d) => d.id).toList();

      // 3. Fetch all records for this student's IDs
      final Map<String, String> recordsMap = {};
      
      if (studentDocIds.isNotEmpty) {
           for (var i = 0; i < studentDocIds.length; i += 10) {
             final chunk = studentDocIds.sublist(i, (i + 10 > studentDocIds.length) ? studentDocIds.length : i + 10);
            
             final recordsQuery = await _db
                .collection('attendance_records')
                .where('studentId', whereIn: chunk)
                .get();
                
             for (var doc in recordsQuery.docs) {
               final data = doc.data();
               // Overwrite if previously absent but present in another context, though there shouldn't be overlap per sessionId
               if (recordsMap[data['sessionId'] as String] != 'Present') {
                  recordsMap[data['sessionId'] as String] = data['status'] as String? ?? 'Absent';
               }
             }
           }
      }

    // 4. Assemble history list
    List<Map<String, dynamic>> history = [];
    for (var doc in sessionsQuery.docs) {
      final data = doc.data();
      final sessionId = doc.id;
      final date = data['date'] as String? ?? '';
      
      // We will assume "Absent" if no record visually exists yet, logical equivalent of a missed class
      final status = recordsMap[sessionId] ?? 'Absent'; 

      history.add({
        'session_id': sessionId,
        'date': date,
        'start_time': data['startTime'] as String? ?? '',
        'end_time': data['endTime'] as String? ?? '',
        'status': status,
      });
    }

      // We can sort them by date (descending) explicitly just in case index sorting was missed
      history.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
      return history;
    } catch (e) {
      return [];
    }
  }
}

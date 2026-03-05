import 'faculty_db_helper.dart';

class StudentDataService {
  /// Fetches all classes a student is enrolled in by their Roll Number.
  static Future<List<Map<String, dynamic>>> getStudentClasses(String rollNumber) async {
    final db = await FacultyDbHelper.instance.database;
    // We join classes, class_students, and faculty_profile to get a complete picture.
    return await db.rawQuery('''
      SELECT c.class_id, c.subject_name, c.section, c.semester, c.department, 
             cs.student_id, p.full_name as faculty_name
      FROM classes c
      JOIN class_students cs ON c.class_id = cs.class_id
      LEFT JOIN faculty_profile p ON c.faculty_user_id = p.user_id
      WHERE cs.roll_no = ?
      ORDER BY c.created_at DESC
    ''', [rollNumber]);
  }

  /// Calculates total attendance stats for a specific student in a specific class.
  static Future<Map<String, dynamic>> getStudentAttendanceSummary(int classId, int studentId) async {
    final db = await FacultyDbHelper.instance.database;
    
    // 1. Total sessions held for this class
    final totalSessionsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM attendance_sessions WHERE class_id = ?',
      [classId],
    );
    int totalSessions = (totalSessionsResult.first['count'] as int?) ?? 0;

    // 2. Total times the student was marked 'Present'
    final presentResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM attendance_records ar
      JOIN attendance_sessions s ON ar.session_id = s.session_id
      WHERE s.class_id = ? AND ar.student_id = ? AND ar.status = 'Present'
      ''',
      [classId, studentId],
    );
    int presents = (presentResult.first['count'] as int?) ?? 0;
    int absents = totalSessions - presents;

    // 3. Percentage
    double percentage = totalSessions > 0 ? (presents / totalSessions) * 100 : 0.0;

    return {
      'total_sessions': totalSessions,
      'present': presents,
      'absent': absents,
      'percentage': percentage,
    };
  }

  /// Fetches the discrete session list and whether the student was present or absent.
  static Future<List<Map<String, dynamic>>> getStudentAttendanceHistory(int classId, int studentId) async {
    final db = await FacultyDbHelper.instance.database;
    
    // Left join ensures we still see the session even if there's no record explicit row (defaulting to Absent logically)
    return await db.rawQuery('''
      SELECT s.session_id, s.date, s.start_time, s.end_time,
             COALESCE(ar.status, 'Absent') as status
      FROM attendance_sessions s
      LEFT JOIN attendance_records ar 
             ON s.session_id = ar.session_id AND ar.student_id = ?
      WHERE s.class_id = ?
      ORDER BY s.date DESC, s.start_time DESC
    ''', [studentId, classId]);
  }
}

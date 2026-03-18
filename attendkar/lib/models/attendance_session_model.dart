class AttendanceSessionModel {
  final String sessionId;
  final String classId;
  final String facultyId;
  final String date;
  final String startTime;
  final String endTime;
  final String subjectId; // Admin-panel subject linkage

  AttendanceSessionModel({
    required this.sessionId,
    required this.classId,
    required this.facultyId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.subjectId = '',
  });

  factory AttendanceSessionModel.fromFirestore(
      Map<String, dynamic> data, String id) {
    return AttendanceSessionModel(
      sessionId: id,
      classId: data['classId'] ?? '',
      facultyId: data['facultyId'] ?? '',
      date: data['date'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      subjectId: data['subjectId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'classId': classId,
      'subjectId': subjectId.isNotEmpty ? subjectId : classId,
      'facultyId': facultyId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}


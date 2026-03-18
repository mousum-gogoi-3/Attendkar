class AttendanceRecordModel {
  final String recordId;
  final String sessionId;
  final String studentId;
  final String status; // 'Present' or 'Absent'

  AttendanceRecordModel({
    required this.recordId,
    required this.sessionId,
    required this.studentId,
    required this.status,
  });

  bool get isPresent => status == 'Present';

  factory AttendanceRecordModel.fromFirestore(
      Map<String, dynamic> data, String id) {
    return AttendanceRecordModel(
      recordId: id,
      sessionId: data['sessionId'] ?? '',
      studentId: data['studentId'] ?? '',
      status: data['status'] ?? 'Absent',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'studentId': studentId,
      'status': status,
    };
  }
}

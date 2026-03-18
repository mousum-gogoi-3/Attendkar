class StudentFirestoreModel {
  final String studentId;
  final String name;
  final String rollNo;
  final String classId;
  final String department;
  final String section;
  final String semester;
  final String subjectId;

  StudentFirestoreModel({
    required this.studentId,
    required this.name,
    required this.rollNo,
    required this.classId,
    required this.department,
    this.section = '',
    this.semester = '',
    this.subjectId = '',
  });

  factory StudentFirestoreModel.fromFirestore(
      Map<String, dynamic> data, String id) {
    return StudentFirestoreModel(
      studentId: id,
      name: data['name'] ?? '',
      rollNo: data['rollNo'] ?? '',
      classId: data['classId'] ?? '',
      department: data['department'] ?? '',
      section: data['section'] ?? '',
      semester: data['semester'] ?? '',
      subjectId: data['subjectId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'rollNo': rollNo,
      'classId': classId,
      'department': department,
      'section': section,
      'semester': semester,
      'subjectId': subjectId,
    };
  }
}

class ClassModel {
  final String classId;
  final String className;
  final String subject;
  final String department;
  final String semester;
  final String section;
  final String facultyId;

  ClassModel({
    required this.classId,
    required this.className,
    required this.subject,
    required this.department,
    required this.semester,
    required this.section,
    required this.facultyId,
  });

  factory ClassModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ClassModel(
      classId: id,
      className: data['className'] ?? '',
      subject: data['subject'] ?? '',
      department: data['department'] ?? '',
      semester: data['semester'] ?? '',
      section: data['section'] ?? '',
      facultyId: data['facultyId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'className': className,
      'subject': subject,
      'department': department,
      'semester': semester,
      'section': section,
      'facultyId': facultyId,
    };
  }
}

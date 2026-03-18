class Student {
  final String name;
  final String rollNo;
  final String department;
  final String course;
  final String semester;
  final String section;

  Student({
    required this.name,
    required this.rollNo,
    required this.department,
    required this.course,
    required this.semester,
    required this.section,
  });

  factory Student.fromCsv(List<dynamic> csvRow) {
    return Student(
      name: csvRow[0]?.toString().trim() ?? '',
      rollNo: csvRow[1]?.toString().trim() ?? '',
      department: csvRow[2]?.toString().trim() ?? '',
      course: csvRow[3]?.toString().trim() ?? '',
      semester: csvRow[4]?.toString().trim() ?? '',
      section: csvRow.length > 5 ? csvRow[5]?.toString().trim() ?? '' : '',
    );
  }

  Map<String, dynamic> toMap(int classId) {
    return {
      'class_id': classId,
      'name': name,
      'roll_no': rollNo,
      'department': department,
    };
  }
}

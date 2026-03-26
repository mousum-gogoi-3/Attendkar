import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectModel {
  final String subjectId;
  final String name;
  final String facultyId;
  final String departmentId;
  final String semester;
  final String courseCode;
  final DateTime? createdAt;

  SubjectModel({
    required this.subjectId,
    required this.name,
    required this.facultyId,
    required this.departmentId,
    this.semester = '',
    this.courseCode = '',
    this.createdAt,
  });

  factory SubjectModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SubjectModel(
      subjectId: id,
      name: data['name'] ?? '',
      facultyId: data['facultyId'] ?? '',
      departmentId: data['departmentId'] ?? '',
      semester: data['semester'] ?? '',
      courseCode: data['courseCode'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'facultyId': facultyId,
      'departmentId': departmentId,
      'semester': semester,
      'courseCode': courseCode,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  SubjectModel copyWith({String? name, String? semester, String? courseCode}) {
    return SubjectModel(
      subjectId: subjectId,
      name: name ?? this.name,
      facultyId: facultyId,
      departmentId: departmentId,
      semester: semester ?? this.semester,
      courseCode: courseCode ?? this.courseCode,
      createdAt: createdAt,
    );
  }
}

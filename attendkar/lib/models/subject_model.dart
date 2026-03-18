import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectModel {
  final String subjectId;
  final String name;
  final String facultyId;
  final String departmentId;
  final DateTime? createdAt;

  SubjectModel({
    required this.subjectId,
    required this.name,
    required this.facultyId,
    required this.departmentId,
    this.createdAt,
  });

  factory SubjectModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SubjectModel(
      subjectId: id,
      name: data['name'] ?? '',
      facultyId: data['facultyId'] ?? '',
      departmentId: data['departmentId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'facultyId': facultyId,
      'departmentId': departmentId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  SubjectModel copyWith({String? name}) {
    return SubjectModel(
      subjectId: subjectId,
      name: name ?? this.name,
      facultyId: facultyId,
      departmentId: departmentId,
      createdAt: createdAt,
    );
  }
}

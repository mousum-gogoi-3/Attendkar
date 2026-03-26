import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentModel {
  final String departmentId;
  final String name;
  final String program;
  final DateTime? createdAt;

  DepartmentModel({
    required this.departmentId,
    required this.name,
    this.program = '',
    this.createdAt,
  });

  factory DepartmentModel.fromFirestore(
      Map<String, dynamic> data, String id) {
    return DepartmentModel(
      departmentId: id,
      name: data['name'] ?? '',
      program: data['program'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'program': program,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  DepartmentModel copyWith({String? name, String? program}) {
    return DepartmentModel(
      departmentId: departmentId,
      name: name ?? this.name,
      program: program ?? this.program,
      createdAt: createdAt,
    );
  }
}

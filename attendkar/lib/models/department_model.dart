import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentModel {
  final String departmentId;
  final String name;
  final DateTime? createdAt;

  DepartmentModel({
    required this.departmentId,
    required this.name,
    this.createdAt,
  });

  factory DepartmentModel.fromFirestore(
      Map<String, dynamic> data, String id) {
    return DepartmentModel(
      departmentId: id,
      name: data['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  DepartmentModel copyWith({String? name}) {
    return DepartmentModel(
      departmentId: departmentId,
      name: name ?? this.name,
      createdAt: createdAt,
    );
  }
}

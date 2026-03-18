class FacultyModel {
  final String facultyId; // Firebase Auth UID
  final String name;
  final String email;
  final String department;
  final bool isVerified;
  final List<String> assignedClassIds;

  FacultyModel({
    required this.facultyId,
    required this.name,
    required this.email,
    required this.department,
    this.isVerified = false,
    this.assignedClassIds = const [],
  });

  factory FacultyModel.fromFirestore(Map<String, dynamic> data, String id) {
    return FacultyModel(
      facultyId: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      department: data['department'] ?? '',
      isVerified: data['isVerified'] ?? false,
      assignedClassIds: List<String>.from(data['assignedClassIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'department': department,
      'isVerified': isVerified,
      'assignedClassIds': assignedClassIds,
    };
  }
}

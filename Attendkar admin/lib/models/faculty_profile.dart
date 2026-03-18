class FacultyProfile {
  final int userId;
  final String fullName;
  final String department;
  final String facultyId;
  final String email;
  final bool isVerified;

  FacultyProfile({
    required this.userId,
    required this.fullName,
    required this.department,
    required this.facultyId,
    required this.email,
    required this.isVerified,
  });

  factory FacultyProfile.fromMap(Map<String, dynamic> map, String email) {
    return FacultyProfile(
      userId: map['user_id'] as int,
      fullName: map['full_name'] as String? ?? '',
      department: map['department'] as String? ?? '',
      facultyId: map['faculty_id'] as String? ?? '',
      isVerified: (map['is_verified'] as int? ?? 0) == 1,
      email: email,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'department': department,
      'faculty_id': facultyId,
      'is_verified': isVerified ? 1 : 0,
      // email is in users table
    };
  }
}

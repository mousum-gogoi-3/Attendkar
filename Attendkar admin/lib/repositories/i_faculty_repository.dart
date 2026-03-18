import '../models/faculty_profile.dart';

abstract class IFacultyRepository {
  Future<void> init();
  Future<List<FacultyProfile>> getAllFaculty();
  Future<FacultyProfile?> getFacultyByEmail(String email);
  Future<void> updateFacultyVerification(String email, bool isVerified);
}

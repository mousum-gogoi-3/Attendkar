import '../models/student.dart';

abstract class IStudentRepository {
  Future<void> init();
  Future<List<Student>> getAllStudents();
  Future<void> addStudent(Student student);
  Future<void> deleteStudent(String rollNo);
}

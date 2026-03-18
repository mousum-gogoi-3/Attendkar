import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import '../models/student.dart';

class StudentCsvService {
  static List<Student>? _cachedStudents;

  /// Loads the students from the CSV file and caches them in memory.
  static Future<List<Student>> loadStudentsFromCSV() async {
    if (_cachedStudents != null) {
      return _cachedStudents!;
    }

    try {
      final String csvString = await rootBundle.loadString('assets/students.csv');
      final List<List<dynamic>> csvTable = CsvToListConverter().convert(csvString);
      
      final List<Student> students = [];
      final Set<String> seenRollNos = {};
      
      // Assuming row 0 is the header: Name, Roll No, Department, Course, Semester, Section
      for (int i = 1; i < csvTable.length; i++) {
        final row = csvTable[i];
        if (row.isEmpty || row[0] == null || row[0].toString().trim().isEmpty) continue;
        
        final student = Student.fromCsv(row);
        if (!seenRollNos.contains(student.rollNo)) {
          seenRollNos.add(student.rollNo);
          students.add(student);
        }
      }
      
      _cachedStudents = students;
      return students;
    } catch (e) {
      print("Error loading CSV: \$e");
      return [];
    }
  }

  /// Filters cached students by class parameters.
  static Future<List<Student>> filterStudentsByClass({
    required String department,
    required String course,
    required String semester,
    String? section,
  }) async {
    final students = await loadStudentsFromCSV();
    
    String cleanStr(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();

    final searchDept = cleanStr(department);
    final searchCourse = cleanStr(course);
    final searchSem = cleanStr(semester);
    final searchSec = cleanStr(section ?? '');

    return students.where((student) {
      final deptMatch = searchDept.isEmpty || cleanStr(student.department).contains(searchDept);
      final courseMatch = searchCourse.isEmpty || cleanStr(student.course).contains(searchCourse);
      final semMatch = searchSem.isEmpty || cleanStr(student.semester) == searchSem;
      
      bool secMatch = true;
      if (searchSec.isNotEmpty) {
        secMatch = cleanStr(student.section) == searchSec;
      }

      return deptMatch && courseMatch && semMatch && secMatch;
    }).toList();
  }

  /// Finds a specific student by their Roll No
  static Future<Student?> getStudentByRollNo(String rollNo) async {
    final students = await loadStudentsFromCSV();
    final searchRollNo = rollNo.trim().toLowerCase();

    try {
      return students.firstWhere((s) => s.rollNo.trim().toLowerCase() == searchRollNo);
    } catch (_) {
      return null; // firstWhere throws StateError if no element is found
    }
  }
}

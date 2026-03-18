import 'package:flutter/material.dart';
import '../repositories/i_student_repository.dart';
import '../repositories/sqlite/sqlite_student_repository.dart';
import '../models/student.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final IStudentRepository _studentRepository = SQLiteStudentRepository();
  List<Student> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
     setState(() => _isLoading = true);
     try {
       await _studentRepository.init();
       final students = await _studentRepository.getAllStudents();
       setState(() {
         _students = students;
       });
     } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading students: $e')));
       }
     } finally {
        if (mounted) {
           setState(() => _isLoading = false);
        }
     }
  }

  void _showAddStudentDialog() {
     final rollNoController = TextEditingController();
     
     showDialog(
       context: context,
       builder: (context) {
          return AlertDialog(
            title: const Text('Add Student to Registry'),
            content: TextField(
               controller: rollNoController,
               decoration: const InputDecoration(
                  labelText: 'Roll Number',
                  border: OutlineInputBorder(),
               ),
            ),
            actions: [
               TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
               ),
               ElevatedButton(
                  onPressed: () async {
                     final rollNo = rollNoController.text.trim();
                     if (rollNo.isEmpty) return;
                     
                     try {
                        final newStudent = Student(
                           name: 'Unknown',
                           rollNo: rollNo,
                           department: 'Unknown',
                           course: 'Unknown',
                           semester: 'Unknown',
                           section: 'Unknown',
                        );
                        await _studentRepository.addStudent(newStudent);
                        if (mounted) Navigator.pop(context);
                        _loadStudents();
                     } catch(e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                     }
                  },
                  child: const Text('Add'),
               )
            ],
          );
       }
     );
  }

  Future<void> _deleteStudent(String rollNo) async {
     final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
           title: const Text('Delete Student?'),
           content: Text('Are you sure you want to delete roll number $rollNo? This will only remove their login account.'),
           actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
           ]
        )
     );

     if (confirm == true) {
        try {
           await _studentRepository.deleteStudent(rollNo);
           _loadStudents();
        } catch (e) {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
         title: const Text('Student Registry'),
         backgroundColor: Colors.green,
         foregroundColor: Colors.white,
       ),
       body: _isLoading
         ? const Center(child: CircularProgressIndicator())
         : ListView.builder(
             itemCount: _students.length,
             itemBuilder: (context, index) {
                final student = _students[index];
                return ListTile(
                   leading: CircleAvatar(child: const Icon(Icons.person)),
                   title: Text(student.rollNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                   subtitle: Text(student.name),
                   trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteStudent(student.rollNo),
                   ),
                );
             },
           ),
       floatingActionButton: FloatingActionButton(
          onPressed: _showAddStudentDialog,
          backgroundColor: Colors.green,
          child: const Icon(Icons.add, color: Colors.white),
       ),
    );
  }
}

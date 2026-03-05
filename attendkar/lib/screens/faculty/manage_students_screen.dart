import 'package:flutter/material.dart';
import '../../services/faculty_db_helper.dart';

class ManageStudentsScreen extends StatefulWidget {
  final int classId;

  const ManageStudentsScreen({
    super.key,
    required this.classId,
  });

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final students = await FacultyDbHelper.instance.getStudentsForClassV2(widget.classId);
    if (mounted) {
      setState(() {
        _students = students;
        _isLoading = false;
      });
    }
  }

  void _showStudentDialog({Map<String, dynamic>? student}) {
    final isEditing = student != null;
    final nameCtrl = TextEditingController(text: student?['name']);
    final rollCtrl = TextEditingController(text: student?['roll_no']);
    final deptCtrl = TextEditingController(text: student?['department']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Student' : 'Add Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rollCtrl,
                decoration: const InputDecoration(labelText: 'Roll No', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: deptCtrl,
                decoration: const InputDecoration(labelText: 'Department (Optional)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final roll = rollCtrl.text.trim();
              if (name.isEmpty || roll.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Roll No are required')));
                return;
              }

              if (isEditing) {
                await FacultyDbHelper.instance.updateClassStudent(student!['student_id'], {
                  'name': name,
                  'roll_no': roll,
                  'department': deptCtrl.text.trim(),
                });
              } else {
                await FacultyDbHelper.instance.insertClassStudent({
                  'class_id': widget.classId,
                  'name': name,
                  'roll_no': roll,
                  'department': deptCtrl.text.trim(),
                });
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _loadStudents();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudent(int studentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student?'),
        content: const Text('Are you sure you want to remove this student from the class?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FacultyDbHelper.instance.deleteClassStudent(studentId);
      _loadStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Student',
            onPressed: () => _showStudentDialog(),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        'No students enrolled',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showStudentDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Student'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(student['name'][0].toUpperCase()),
                        ),
                        title: Text(student['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Roll No: ${student['roll_no']}' + (student['department'].toString().isNotEmpty ? ' • Dept: ${student['department']}' : '')),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showStudentDialog(student: student),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteStudent(student['student_id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/student_firestore_model.dart';

/// Read-only student list for an assigned class.
/// Faculty cannot add, edit, or delete students.
/// All student management is done by the Admin App.
class ManageStudentsScreen extends StatefulWidget {
  final String subjectId;
  final String className;

  const ManageStudentsScreen({
    super.key,
    required this.subjectId,
    required this.className,
  });

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  List<StudentFirestoreModel> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final students = await FirestoreService.getStudentsForSubject(widget.subjectId);
    if (mounted) {
      setState(() {
        _students = students;
        _isLoading = false;
      });
    }
  }

  List<StudentFirestoreModel> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    final q = _searchQuery.toLowerCase();
    return _students.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.rollNo.toLowerCase().contains(q);
    }).toList();
  }

  void _showStudentDetails(StudentFirestoreModel student) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.15),
              child: Text(
                student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: theme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(student.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(Icons.badge, 'Roll No', student.rollNo),
            _detailRow(Icons.domain, 'Department', student.department),
            if (student.section.isNotEmpty)
              _detailRow(Icons.group, 'Section', student.section),
            if (student.semester.isNotEmpty)
              _detailRow(Icons.school, 'Semester', student.semester),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredStudents;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Students', style: TextStyle(fontSize: 18)),
            Text(widget.className,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  color: theme.primaryColor.withOpacity(0.06),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16,
                          color: theme.primaryColor.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Student list is managed by the Admin. View only.',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.primaryColor.withOpacity(0.7)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search bar
                if (_students.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by name or roll number…',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (v) =>
                          setState(() => _searchQuery = v),
                    ),
                  ),

                Expanded(
                  child: _students.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 64,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.2)),
                              const SizedBox(height: 16),
                              Text(
                                'No students enrolled yet',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  'Students will appear here once added by the Admin.',
                                  style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.5)),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No students match "$_searchQuery"',
                                style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5)),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadStudents,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final student = filtered[index];
                                  return Card(
                                    margin:
                                        const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: theme.primaryColor
                                            .withOpacity(0.12),
                                        child: Text(
                                          student.name.isNotEmpty
                                              ? student.name[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                              color: theme.primaryColor,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      title: Text(student.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      subtitle: Text(
                                          'Roll No: ${student.rollNo}${student.department.isNotEmpty ? '  \u2022  ${student.department}' : ''}${student.section.isNotEmpty ? '  \u2022  Sec ${student.section}' : ''}${student.semester.isNotEmpty ? '  \u2022  Sem ${student.semester}' : ''}'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.info_outline,
                                            color: Colors.blue),
                                        onPressed: () =>
                                            _showStudentDetails(student),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),

                // Student count footer
                if (_students.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Text(
                      '${_students.length} student${_students.length == 1 ? '' : 's'} enrolled',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 13),
                    ),
                  ),
              ],
            ),
    );
  }
}

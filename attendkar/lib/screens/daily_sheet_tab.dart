import 'package:flutter/material.dart';
import '../services/student_auth_service.dart';
import '../services/student_data_service.dart';
import 'student/student_class_detail_screen.dart';

class DailySheetTab extends StatefulWidget {
  const DailySheetTab({super.key});

  @override
  State<DailySheetTab> createState() => _DailySheetTabState();
}

class _DailySheetTabState extends State<DailySheetTab> {
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = true;
  String? _rollNo;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    final rollNo = await StudentAuthService.getLoggedStudentRollNo();
    if (rollNo != null && rollNo.isNotEmpty) {
      final classes = await StudentDataService.getStudentClasses(rollNo);
      if (mounted) {
        setState(() {
          _rollNo = rollNo;
          _classes = classes;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _classes.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _classes.length,
              itemBuilder: (context, index) {
                final cls = _classes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      child: Icon(Icons.class_, color: theme.primaryColor),
                    ),
                    title: Text(cls['subject_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('Faculty: ${cls['faculty_name'] ?? 'Unknown'}\nSec: ${cls['section']} • Sem: ${cls['semester']}'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StudentClassDetailScreen(
                            classId: cls['class_id'],
                            subjectName: cls['subject_name'],
                            studentId: cls['student_id'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.school_outlined, size: 80, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            'No Classes Found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'You are not enrolled in any class yet.\nPlease contact your faculty.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

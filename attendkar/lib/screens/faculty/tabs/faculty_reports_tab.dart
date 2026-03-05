import 'package:flutter/material.dart';
import '../../../services/faculty_db_helper.dart';
import '../../../services/faculty_auth_service.dart';
import '../class_analytics_screen.dart';

class FacultyReportsTab extends StatefulWidget {
  const FacultyReportsTab({super.key});

  @override
  State<FacultyReportsTab> createState() => _FacultyReportsTabState();
}

class _FacultyReportsTabState extends State<FacultyReportsTab> {
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    final userId = await FacultyAuthService.getLoggedUserId();
    if (userId != null) {
      final classes = await FacultyDbHelper.instance.getFacultyClasses(userId);
      if (mounted) {
        setState(() {
          _classes = classes;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Reports'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _classes.isEmpty
              ? Center(
                  child: Text(
                    'No classes available for reports.',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _classes.length,
                  itemBuilder: (context, index) {
                    final cls = _classes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                          child: Icon(Icons.analytics, color: theme.primaryColor),
                        ),
                        title: Text(cls['subject_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Dept: ${cls['department']} • Sec: ${cls['section']} • Sem: ${cls['semester']}',
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ClassAnalyticsScreen(
                                classId: cls['class_id'],
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
}


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/faculty_db_helper.dart';
import '../../../services/faculty_auth_service.dart';
import '../create_class_screen.dart';
import '../class_dashboard_screen.dart';

class FacultyDashboardTab extends StatefulWidget {
  const FacultyDashboardTab({super.key});

  @override
  State<FacultyDashboardTab> createState() => _FacultyDashboardTabState();
}

class _FacultyDashboardTabState extends State<FacultyDashboardTab> {
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

  Future<void> _showUniversityClosureDialog(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    final formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
    final theme = Theme.of(context);
    final isClosed = await FacultyDbHelper.instance.isDateClosed(formattedDate);
    
    if (isClosed) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove Closure?'),
          content: Text('University is already marked closed on ${DateFormat('MMM dd, yyyy').format(pickedDate)}. Do you want to remove this?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                await FacultyDbHelper.instance.removeUniversityClosure(formattedDate);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Closure removed')));
              },
              child: const Text('Remove Closure'),
            ),
          ],
        ),
      );
    } else {
      final reasonCtrl = TextEditingController();
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Close University'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Date: ${DateFormat('MMM dd, yyyy').format(pickedDate)}') ,
              const SizedBox(height: 16),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reason (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await FacultyDbHelper.instance.markUniversityClosed(formattedDate, reasonCtrl.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('University marked closed')));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateClassScreen()),
              );
              _loadClasses(); // Refresh after returning
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _classes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.class_outlined, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                              const SizedBox(height: 16),
                              Text(
                                'No classes yet',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const CreateClassScreen()),
                                  );
                                  _loadClasses();
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Create Class'),
                              ),
                            ],
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                title: Text(
                                  cls['subject_name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Dept: ${cls['department']} • Sec: ${cls['section']} • Sem: ${cls['semester']}',
                                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                  ),
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ClassDashboardScreen(
                                          classId: cls['class_id'],
                                          subjectName: cls['subject_name'],
                                          section: cls['section'],
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                                    foregroundColor: theme.primaryColor,
                                    elevation: 0,
                                  ),
                                  child: const Text('Dashboard'),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../services/firebase_auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../models/subject_model.dart';
import '../../../widgets/custom_card.dart';
import '../class_analytics_screen.dart';

/// Reports Tab – shows faculty's assigned classes for analytics.
class FacultyReportsTab extends StatefulWidget {
  const FacultyReportsTab({super.key});

  @override
  State<FacultyReportsTab> createState() => _FacultyReportsTabState();
}

class _FacultyReportsTabState extends State<FacultyReportsTab> {
  List<SubjectModel> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    final uid = FirebaseAuthService.getLoggedFacultyUid();
    if (uid != null) {
      final subjects = await FirestoreService.getAssignedSubjects(uid);
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Reports')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? Center(
                  child: Text(
                    'No classes assigned yet.',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final sub = _subjects[index];
                    return CustomCard(
                      padding: EdgeInsets.zero,
                      color: theme.cardTheme.color,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                          child: Icon(Icons.analytics,
                              color: theme.primaryColor),
                        ),
                        title: Text(sub.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Tap to view Analytics',
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6)),
                          ),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ClassAnalyticsScreen(subjectModel: sub),
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

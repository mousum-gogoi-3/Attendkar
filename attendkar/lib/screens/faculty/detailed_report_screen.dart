import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/student_firestore_model.dart';

/// Detailed per-session attendance report for a class.
/// Uses Firestore as the data source.
class DetailedReportScreen extends StatefulWidget {
  final String classId;
  final String subjectName;
  final String section;

  const DetailedReportScreen({
    super.key,
    required this.classId,
    required this.subjectName,
    required this.section,
  });

  @override
  State<DetailedReportScreen> createState() => _DetailedReportScreenState();
}

class _DetailedReportScreenState extends State<DetailedReportScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _studentStats = [];
  int _totalSessions = 0;

  @override
  void initState() {
    super.initState();
    _loadDetailedReport();
  }

  Future<void> _loadDetailedReport() async {
    setState(() => _isLoading = true);

    final uid = FirebaseAuthService.getLoggedFacultyUid();
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final students = await FirestoreService.getStudentsForSubject(widget.classId);
    final sessions =
        await FirestoreService.getSessionsForSubject(widget.classId, uid);

    // Map studentId -> presentCount
    final Map<String, int> presentCounts = {};
    for (final session in sessions) {
      final records =
          await FirestoreService.getRecordsForSession(session.sessionId);
      for (final record in records) {
        if (record.isPresent) {
          presentCounts[record.studentId] =
              (presentCounts[record.studentId] ?? 0) + 1;
        }
      }
    }

    final int totalSessions = sessions.length;

    // Build stats per student
    final List<Map<String, dynamic>> stats = students.map((student) {
      final present = presentCounts[student.studentId] ?? 0;
      final absent = totalSessions - present;
      final percentage =
          totalSessions > 0 ? (present / totalSessions) * 100 : 0.0;
      return {
        'student': student,
        'present': present,
        'absent': absent < 0 ? 0 : absent,
        'total': totalSessions,
        'percentage': percentage,
      };
    }).toList();

    // Sort by roll number
    stats.sort((a, b) {
      final sa = a['student'] as StudentFirestoreModel;
      final sb = b['student'] as StudentFirestoreModel;
      return sa.rollNo.compareTo(sb.rollNo);
    });

    if (mounted) {
      setState(() {
        _studentStats = stats;
        _totalSessions = totalSessions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendance Report', style: TextStyle(fontSize: 16)),
            Text(
              '${widget.subjectName} (${widget.section})',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _studentStats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_outlined,
                          size: 64,
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        'No attendance records found',
                        style: TextStyle(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      color: theme.primaryColor.withOpacity(0.05),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Students: ${_studentStats.length}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Sessions: $_totalSessions',
                            style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _studentStats.length,
                        itemBuilder: (context, index) {
                          final stat = _studentStats[index];
                          final student =
                              stat['student'] as StudentFirestoreModel;
                          final percentage = stat['percentage'] as double;
                          final Color statusColor = percentage >= 75
                              ? Colors.green
                              : (percentage >= 60
                                  ? Colors.orange
                                  : Colors.red);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 54,
                                    height: 54,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CircularProgressIndicator(
                                          value: percentage / 100,
                                          backgroundColor:
                                              statusColor.withOpacity(0.2),
                                          color: statusColor,
                                          strokeWidth: 5,
                                        ),
                                        Center(
                                          child: Text(
                                            '${percentage.toInt()}%',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text('Roll: ${student.rollNo}',
                                                style: TextStyle(
                                                    color: theme
                                                        .colorScheme.onSurface
                                                        .withOpacity(0.6),
                                                    fontSize: 13)),
                                            const SizedBox(width: 12),
                                            Text(
                                                'P: ${stat['present']}  A: ${stat['absent']}',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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

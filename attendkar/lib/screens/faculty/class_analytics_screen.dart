import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/subject_model.dart';
import '../../models/student_firestore_model.dart';
import '../../models/attendance_session_model.dart';
import '../../widgets/custom_card.dart';

/// Attendance analytics for a specific assigned class.
class ClassAnalyticsScreen extends StatefulWidget {
  final SubjectModel subjectModel;

  const ClassAnalyticsScreen({
    super.key,
    required this.subjectModel,
  });

  @override
  State<ClassAnalyticsScreen> createState() => _ClassAnalyticsScreenState();
}

class _ClassAnalyticsScreenState extends State<ClassAnalyticsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;

  List<StudentFirestoreModel> _students = [];
  Map<String, int> _presentCounts = {};
  int _totalSessions = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    final uid = FirebaseAuthService.getLoggedFacultyUid();
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Load students
    final students =
        await FirestoreService.getStudentsForSubject(widget.subjectModel.subjectId);

    // Load sessions
    final allSessions = await FirestoreService.getSessionsForSubject(
        widget.subjectModel.subjectId, uid);

    // Apply date filter
    List<AttendanceSessionModel> filteredSessions = allSessions.where((s) {
      if (_startDate == null && _endDate == null) return true;
      final sessionDate = DateTime.parse(s.date);
      if (_startDate != null && _endDate != null) {
        return sessionDate.isAfter(
                _startDate!.subtract(const Duration(days: 1))) &&
            sessionDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }
      return true;
    }).toList();

    // Count present records per student
    final Map<String, int> presentCounts = {};
    for (final session in filteredSessions) {
      final records =
          await FirestoreService.getRecordsForSession(session.sessionId);
      for (final record in records) {
        if (record.isPresent) {
          presentCounts[record.studentId] =
              (presentCounts[record.studentId] ?? 0) + 1;
        }
      }
    }

    if (mounted) {
      setState(() {
        _students = students;
        _totalSessions = filteredSessions.length;
        _presentCounts = presentCounts;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAnalytics();
    }
  }

  void _clearFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    double classAverage = 0.0;
    if (_totalSessions > 0 && _students.isNotEmpty) {
      final totalPresents =
          _presentCounts.values.fold(0, (sum, c) => sum + c);
      classAverage = (totalPresents / (_totalSessions * _students.length)) * 100;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analytics', style: TextStyle(fontSize: 18)),
            Text(widget.subjectModel.name,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Filter by Date Range',
            onPressed: _selectDateRange,
          ),
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.orange),
              tooltip: 'Clear Filter',
              onPressed: _clearFilter,
            ),
        ],
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.primaryColor.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Sessions:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('$_totalSessions',
                        style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Class Average:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('${classAverage.toStringAsFixed(1)}%',
                        style: TextStyle(
                            color:
                                classAverage >= 75 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ],
                ),
                if (_startDate != null && _endDate != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Filtered: ${DateFormat('MMM dd').format(_startDate!)} – ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                    style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? const Center(child: Text('No students enrolled.'))
                    : ListView.builder(
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          final present =
                              _presentCounts[student.studentId] ?? 0;
                          final absent = _totalSessions - present;
                          final percentage = _totalSessions > 0
                              ? (present / _totalSessions) * 100
                              : 0.0;
                          final color = percentage >= 75
                              ? Colors.green
                              : (percentage >= 60
                                  ? Colors.orange
                                  : Colors.red);

                          return CustomCard(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CircularProgressIndicator(
                                        value: _totalSessions > 0
                                            ? present / _totalSessions
                                            : 0,
                                        strokeWidth: 6,
                                        backgroundColor:
                                            color.withOpacity(0.2),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                color),
                                      ),
                                      Center(
                                        child: Text(
                                          '${percentage.toStringAsFixed(0)}%',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: color),
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
                                      Text(student.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text(
                                          'Roll No: ${student.rollNo}',
                                          style: TextStyle(
                                              color: theme
                                                  .colorScheme.onSurface
                                                  .withOpacity(0.6))),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('$present P',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green)),
                                    const SizedBox(height: 4),
                                    Text('$absent A',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red)),
                                  ],
                                ),
                              ],
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

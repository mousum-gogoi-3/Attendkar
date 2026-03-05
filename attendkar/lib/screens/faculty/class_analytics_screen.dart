import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/faculty_db_helper.dart';

class ClassAnalyticsScreen extends StatefulWidget {
  final int classId;

  const ClassAnalyticsScreen({
    super.key,
    required this.classId,
  });

  @override
  State<ClassAnalyticsScreen> createState() => _ClassAnalyticsScreenState();
}

class _ClassAnalyticsScreenState extends State<ClassAnalyticsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;
  
  List<Map<String, dynamic>> _students = [];
  Map<int, int> _presentCounts = {};
  int _totalSessions = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    // Fetch all students for the class
    final students = await FacultyDbHelper.instance.getStudentsForClassV2(widget.classId);
    
    // Fetch sessions
    final allSessions = await FacultyDbHelper.instance.getSessionsForClass(widget.classId);
    
    // Apply date filter
    List<Map<String, dynamic>> filteredSessions = allSessions.where((session) {
      if (_startDate == null && _endDate == null) return true;
      DateTime sessionDate = DateTime.parse(session['date']);
      
      if (_startDate != null && _endDate != null) {
        return sessionDate.isAfter(_startDate!.subtract(const Duration(days: 1))) && 
               sessionDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }
      return true;
    }).toList();

    int totalSessions = filteredSessions.length;
    Map<int, int> presentCounts = {};
    
    if (totalSessions > 0) {
      for (var session in filteredSessions) {
        final records = await FacultyDbHelper.instance.getRecordsForSession(session['session_id']);
        for (var record in records) {
          if (record['status'] == 'Present') {
            final studentId = record['student_id'];
            presentCounts[studentId] = (presentCounts[studentId] ?? 0) + 1;
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _students = students;
        _totalSessions = totalSessions;
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

    // Calculate overall class average
    double classAverage = 0.0;
    if (_totalSessions > 0 && _students.isNotEmpty) {
      int totalPresents = _presentCounts.values.fold(0, (sum, count) => sum + count);
      classAverage = (totalPresents / (_totalSessions * _students.length)) * 100;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Filter by Date',
            onPressed: _selectDateRange,
          ),
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.red),
              tooltip: 'Clear Filter',
              onPressed: _clearFilter,
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.primaryColor.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Sessions Held:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('$_totalSessions', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Class Average:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${classAverage.toStringAsFixed(1)}%', style: TextStyle(color: classAverage >= 75 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                if (_startDate != null && _endDate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Filtered: ${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                    style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                  ),
                ]
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
                          final studentId = student['student_id'];
                          final present = _presentCounts[studentId] ?? 0;
                          final absent = _totalSessions - present;
                          final percentage = _totalSessions > 0 ? (present / _totalSessions) * 100 : 0.0;

                          // Color-code based on generally accepted safe attendance thresholds
                          final color = percentage >= 75 ? Colors.green : (percentage >= 60 ? Colors.orange : Colors.red);

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Percentage circle
                                  SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CircularProgressIndicator(
                                          value: _totalSessions > 0 ? present / _totalSessions : 0,
                                          strokeWidth: 6,
                                          backgroundColor: color.withOpacity(0.2),
                                          valueColor: AlwaysStoppedAnimation<Color>(color),
                                        ),
                                        Center(
                                          child: Text(
                                            '${percentage.toStringAsFixed(0)}%',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(student['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Text('Roll No: ${student['roll_no']}', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                                      ],
                                    ),
                                  ),
                                  // Stats
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('$present P', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                      const SizedBox(height: 4),
                                      Text('$absent A', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                    ],
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

import 'package:flutter/material.dart';
import '../../services/faculty_db_helper.dart';

class DetailedReportScreen extends StatefulWidget {
  final int classId;
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

  @override
  void initState() {
    super.initState();
    _loadDetailedReport();
  }

  Future<void> _loadDetailedReport() async {
    setState(() => _isLoading = true);
    final records = await FacultyDbHelper.instance.getAllAttendanceForClass(widget.classId);
    final totalUniqueDates = await FacultyDbHelper.instance.getTotalClassesHeld(widget.classId);
    final closures = await FacultyDbHelper.instance.getAllClosures();
    final classClosures = await FacultyDbHelper.instance.getAllClassClosures(widget.classId);
    Set<String> closedDates = closures.map((c) => c['date'] as String).toSet();
    Set<String> classClosedDates = classClosures.map((c) => c['date'] as String).toSet();

    // Grouping by student ID
    Map<String, Map<String, int>> statsMap = {};

    for (var record in records) {
      String date = record['date'];
      if (closedDates.contains(date) || classClosedDates.contains(date)) continue; // Ignore records on closed dates

      String studentId = record['student_user_id'].toString();
      String status = record['status'];

      if (!statsMap.containsKey(studentId)) {
        statsMap[studentId] = {'present': 0};
      }

      if (status == 'Present') {
        statsMap[studentId]!['present'] = statsMap[studentId]!['present']! + 1;
      }
    }

    List<Map<String, dynamic>> formattedStats = [];
    statsMap.forEach((studentId, stat) {
      int present = stat['present']!;
      int absent = totalUniqueDates - present;
      if (absent < 0) absent = 0; // Prevent negatives just in case
      
      double percentage = totalUniqueDates > 0 ? (present / totalUniqueDates) * 100 : 0.0;
      
      formattedStats.add({
        'student_id': studentId,
        'present': present,
        'absent': absent,
        'total': totalUniqueDates,
        'percentage': percentage,
      });
    });

    // Sort by roll number alphabetically/numerically
    formattedStats.sort((a, b) => a['student_id'].compareTo(b['student_id']));

    if (mounted) {
      setState(() {
        _studentStats = formattedStats;
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
            Text('${widget.subjectName} (${widget.section})', 
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)
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
                      Icon(Icons.analytics_outlined, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        'No attendance records found',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: theme.primaryColor.withOpacity(0.05),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Students: ${_studentStats.length}', 
                            style: const TextStyle(fontWeight: FontWeight.bold)
                          ),
                          Text('Overall Overview', 
                            style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)
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
                          final percentage = stat['percentage'] as double;
                          
                          Color statusColor = percentage >= 75 
                              ? Colors.green 
                              : (percentage >= 60 ? Colors.orange : Colors.red);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Circular Percentage Indicator
                                  SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CircularProgressIndicator(
                                          value: percentage / 100,
                                          backgroundColor: statusColor.withOpacity(0.2),
                                          color: statusColor,
                                          strokeWidth: 4,
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
                                  
                                  // Student Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Roll No / ID: ${stat['student_id']}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text('P: ${stat['present']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 12),
                                            Text('A: ${stat['absent']}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 12),
                                            Text('Total: ${stat['total']}', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
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

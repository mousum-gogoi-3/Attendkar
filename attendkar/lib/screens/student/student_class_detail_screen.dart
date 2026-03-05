import 'package:flutter/material.dart';
import '../../services/student_data_service.dart';

class StudentClassDetailScreen extends StatefulWidget {
  final int classId;
  final String subjectName;
  final int studentId;

  const StudentClassDetailScreen({
    super.key,
    required this.classId,
    required this.subjectName,
    required this.studentId,
  });

  @override
  State<StudentClassDetailScreen> createState() => _StudentClassDetailScreenState();
}

class _StudentClassDetailScreenState extends State<StudentClassDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final summary = await StudentDataService.getStudentAttendanceSummary(widget.classId, widget.studentId);
    final history = await StudentDataService.getStudentAttendanceHistory(widget.classId, widget.studentId);

    if (mounted) {
      setState(() {
        _summary = summary;
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.subjectName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final double percentage = _summary['percentage'] ?? 0.0;
    final color = percentage >= 75 ? Colors.green : (percentage >= 60 ? Colors.orange : Colors.red);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
      ),
      body: Column(
        children: [
          // SUMMARY SECTION
          Container(
            padding: const EdgeInsets.all(24.0),
            color: theme.primaryColor.withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Circular Progress
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: _summary['total_sessions'] > 0 
                            ? _summary['present'] / _summary['total_sessions'] 
                            : 0,
                        strokeWidth: 10,
                        backgroundColor: color.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                      Center(
                        child: Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: color),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Stats column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow('Total Classes:', '${_summary['total_sessions']}', Colors.black54),
                    const SizedBox(height: 8),
                    _buildStatRow('Present:', '${_summary['present']}', Colors.green),
                    const SizedBox(height: 8),
                    _buildStatRow('Absent:', '${_summary['absent']}', Colors.red),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // HISTORY SECTION
          Expanded(
            child: _history.isEmpty
                ? const Center(child: Text('No attendance records found.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final session = _history[index];
                      final isPresent = session['status'] == 'Present';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            isPresent ? Icons.check_circle : Icons.cancel,
                            color: isPresent ? Colors.green : Colors.red,
                          ),
                          title: Text(session['date'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${session['start_time']} - ${session['end_time']}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              session['status'],
                              style: TextStyle(
                                color: isPresent ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/faculty_db_helper.dart';

class TakeAttendanceScreen extends StatefulWidget {
  final int sessionId;
  final String date;
  final String startTime;
  final String endTime;

  const TakeAttendanceScreen({
    super.key,
    required this.sessionId,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  List<Map<String, dynamic>> _students = [];
  Map<int, bool> _attendanceStatus = {}; // student_id -> true (present) or false (absent)
  bool _isLoading = true;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
    _loadStudentsAndRecords();
  }

  void _checkLockStatus() {
    final sessionDate = DateTime.parse(widget.date);
    // Enforce 1-week rule
    if (DateTime.now().difference(sessionDate).inDays > 7) {
      _isLocked = true;
    }
  }

  Future<void> _loadStudentsAndRecords() async {
    setState(() => _isLoading = true);
    
    // Get class_id from session
    final session = await FacultyDbHelper.instance.getSessionById(widget.sessionId);
    if (session == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    
    final classId = session['class_id'];
    
    // Fetch all students for this class
    final allStudents = await FacultyDbHelper.instance.getStudentsForClassV2(classId);
    
    // Fetch existing records for this session
    final existingRecordsList = await FacultyDbHelper.instance.getRecordsForSession(widget.sessionId);
    
    final Map<int, bool> statusMap = {};
    for (var record in existingRecordsList) {
      statusMap[record['student_id']] = record['status'] == 'Present';
    }

    if (mounted) {
      setState(() {
        _students = allStudents;
        // Default to absent if no record exists yet
        for (var student in allStudents) {
          _attendanceStatus[student['student_id']] = statusMap[student['student_id']] ?? false;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAttendance() async {
    if (_isLocked) return;

    List<Map<String, dynamic>> records = [];
    _attendanceStatus.forEach((studentId, isPresent) {
      records.add({
        'session_id': widget.sessionId,
        'student_id': studentId,
        'status': isPresent ? 'Present' : 'Absent',
      });
    });

    setState(() => _isLoading = true);
    await FacultyDbHelper.instance.replaceAttendanceRecordsForSession(widget.sessionId, records);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance Saved Successfully!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(widget.date));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mark Attendance', style: TextStyle(fontSize: 16)),
            Text('$formattedDate • ${widget.startTime} - ${widget.endTime}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_isLocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.withOpacity(0.1),
              child: const Row(
                children: [
                  Icon(Icons.lock, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This session is locked because it is older than 1 week. Changes cannot be made.',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: theme.primaryColor.withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_students.length} Students', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  'Present: ${_attendanceStatus.values.where((v) => v).length}',
                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
                  ? const Center(child: Text('No students enrolled in this class.'))
                  : ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final studentId = student['student_id'];
                        final isPresent = _attendanceStatus[studentId] ?? false;

                        return CheckboxListTile(
                          value: isPresent,
                          onChanged: _isLocked ? null : (val) {
                            if (val != null) {
                              setState(() => _attendanceStatus[studentId] = val);
                            }
                          },
                          title: Text(student['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Roll No: ${student['roll_no']}'),
                          secondary: CircleAvatar(
                            backgroundColor: isPresent ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                            child: Icon(
                              isPresent ? Icons.check : Icons.close,
                              color: isPresent ? Colors.green : Colors.red,
                            ),
                          ),
                          activeColor: Colors.green,
                        );
                      },
                    ),
          ),
          
          if (!_isLocked && !_isLoading && _students.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Submit Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/student_firestore_model.dart';
import '../../models/attendance_record_model.dart';

/// Screen for marking student attendance within a session.
/// Faculty marks each student as Present or Absent, then submits.
class TakeAttendanceScreen extends StatefulWidget {
  final String sessionId;
  final String subjectId;
  final String date;
  final String startTime;
  final String endTime;

  const TakeAttendanceScreen({
    super.key,
    required this.sessionId,
    required this.subjectId,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  List<StudentFirestoreModel> _students = [];
  Map<String, bool> _attendanceStatus = {}; // studentId → present (true/false)
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
    _loadStudentsAndRecords();
  }

  void _checkLockStatus() {
    final sessionDate = DateTime.parse(widget.date);
    if (DateTime.now().difference(sessionDate).inDays > 7) {
      _isLocked = true;
    }
  }

  Future<void> _loadStudentsAndRecords() async {
    setState(() => _isLoading = true);

    // Load students from Firestore for this class
    final students =
        await FirestoreService.getStudentsForSubject(widget.subjectId);

    // Load existing attendance records for this session
    final records =
        await FirestoreService.getRecordsForSession(widget.sessionId);

    // Build status map from existing records
    final Map<String, bool> statusMap = {};
    for (final record in records) {
      statusMap[record.studentId] = record.isPresent;
    }

    if (mounted) {
      setState(() {
        _students = students;
        // Default new students to absent
        for (final student in students) {
          _attendanceStatus[student.studentId] =
              statusMap[student.studentId] ?? false;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAttendance() async {
    if (_isLocked || _isSaving) return;

    setState(() => _isSaving = true);

    final records = _attendanceStatus.entries.map((entry) {
      return AttendanceRecordModel(
        recordId: '',
        sessionId: widget.sessionId,
        studentId: entry.key,
        status: entry.value ? 'Present' : 'Absent',
      );
    }).toList();

    final success = await FirestoreService.saveAttendanceRecords(
        widget.sessionId, records);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save attendance. Check your connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _markAll(bool present) {
    setState(() {
      for (final student in _students) {
        _attendanceStatus[student.studentId] = present;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate =
        DateFormat('MMM dd, yyyy').format(DateTime.parse(widget.date));
    final presentCount =
        _attendanceStatus.values.where((v) => v).length;
    final totalCount = _students.length;

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // Gradient Header with summary
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20, right: 20, bottom: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                    : [const Color(0xFF667eea), const Color(0xFF764ba2)],
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(isDark ? 0.1 : 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mark Attendance',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('$formattedDate  •  ${widget.startTime} – ${widget.endTime}',
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Summary chips
                Row(
                  children: [
                    _summaryChip('$totalCount', 'Total', Colors.white.withOpacity(0.15), Colors.white),
                    const SizedBox(width: 8),
                    _summaryChip('$presentCount', 'Present', Colors.green.withOpacity(0.25), Colors.greenAccent),
                    const SizedBox(width: 8),
                    _summaryChip('${totalCount - presentCount}', 'Absent', Colors.red.withOpacity(0.25), Colors.redAccent),
                  ],
                ),
                if (!_isLocked && _students.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _actionChip('All Present', Icons.check_circle_outline, () => _markAll(true)),
                      const SizedBox(width: 8),
                      _actionChip('All Absent', Icons.cancel_outlined, () => _markAll(false)),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Lock banner
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
                      'Session locked – older than 7 days. No changes allowed.',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? const Center(
                        child: Text(
                            'No students in this class. Contact admin to add students.'))
                    : ListView.builder(
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          final isPresent =
                              _attendanceStatus[student.studentId] ?? false;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: InkWell(
                              onTap: _isLocked
                                  ? null
                                  : () {
                                      setState(() => _attendanceStatus[student.studentId] = !isPresent);
                                    },
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isPresent ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isPresent ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isPresent ? Colors.green : Colors.red,
                                      foregroundColor: Colors.white,
                                      child: Icon(isPresent ? Icons.check : Icons.close),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(student.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(height: 4),
                                          Text('Roll No: ${student.rollNo}',
                                              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Submit button
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
                  onPressed: _isSaving ? null : _submitAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Submit Attendance',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryChip(String value, String label, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white.withOpacity(0.8)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

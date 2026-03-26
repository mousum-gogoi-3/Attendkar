import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/subject_model.dart';
import '../../models/student_firestore_model.dart';
import '../../models/attendance_session_model.dart';
import '../../widgets/custom_card.dart';
import '../../services/report_export_service.dart';
import 'student_attendance_details_screen.dart';

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
  bool _isExporting = false;

  List<StudentFirestoreModel> _students = [];
  Map<String, int> _presentCounts = {};
  Map<String, List<Map<String, dynamic>>> _studentHistory = {};
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
    final Map<String, List<Map<String, dynamic>>> studentHistory = {};
    for (final student in students) {
      studentHistory[student.studentId] = [];
    }

    final Map<String, int> presentCounts = {};
    for (final session in filteredSessions) {
      final records =
          await FirestoreService.getRecordsForSession(session.sessionId);
          
      final Map<String, bool> sessionRecordMap = {};
      for (final record in records) {
        if (record.isPresent) {
          presentCounts[record.studentId] =
              (presentCounts[record.studentId] ?? 0) + 1;
        }
        sessionRecordMap[record.studentId] = record.isPresent;
      }
      
      for (final student in students) {
        studentHistory[student.studentId]?.add({
          'session': session,
          'isPresent': sessionRecordMap[student.studentId] ?? false,
        });
      }
    }

    if (mounted) {
      setState(() {
        _students = students;
        _totalSessions = filteredSessions.length;
        _presentCounts = presentCounts;
        _studentHistory = studentHistory;
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

  void _showDownloadOptions() {
    bool downloadAll = true;
    DateTime? tempStart = _startDate;
    DateTime? tempEnd = _endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Download Report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
                  RadioListTile<bool>(
                    title: const Text('All Details'),
                    value: true,
                    groupValue: downloadAll,
                    onChanged: (val) => setModalState(() => downloadAll = val!),
                  ),
                  RadioListTile<bool>(
                    title: const Text('Select Date Range'),
                    value: false,
                    groupValue: downloadAll,
                    onChanged: (val) => setModalState(() => downloadAll = val!),
                  ),
                  if (!downloadAll)
                    ListTile(
                      title: Text(tempStart != null && tempEnd != null 
                        ? '${DateFormat('MMM dd, yyyy').format(tempStart!)} - ${DateFormat('MMM dd, yyyy').format(tempEnd!)}'
                        : 'Tap to select dates'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: tempStart != null && tempEnd != null
                              ? DateTimeRange(start: tempStart!, end: tempEnd!)
                              : null,
                        );
                        if (picked != null) {
                          setModalState(() {
                            tempStart = picked.start;
                            tempEnd = picked.end;
                          });
                        }
                      },
                    ),
                  const SizedBox(height: 20),
                  const Text('Export Format', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('PDF'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red.shade900),
                          onPressed: () {
                            Navigator.pop(context);
                            _processExport(isPdf: true, isAll: downloadAll, start: tempStart, end: tempEnd);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.table_chart),
                          label: const Text('Excel'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100, foregroundColor: Colors.green.shade900),
                          onPressed: () {
                            Navigator.pop(context);
                            _processExport(isPdf: false, isAll: downloadAll, start: tempStart, end: tempEnd);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _processExport({
    required bool isPdf,
    required bool isAll,
    required DateTime? start,
    required DateTime? end,
  }) async {
    setState(() => _isExporting = true);

    try {
      final uid = FirebaseAuthService.getLoggedFacultyUid();
      if (uid == null) return;
      
      final allSessions = await FirestoreService.getSessionsForSubject(
          widget.subjectModel.subjectId, uid);
          
      List<AttendanceSessionModel> exportSessions = allSessions.where((s) {
        if (isAll) return true;
        if (start == null || end == null) return true;
        final sessionDate = DateTime.parse(s.date);
        return sessionDate.isAfter(start.subtract(const Duration(days: 1))) &&
               sessionDate.isBefore(end.add(const Duration(days: 1)));
      }).toList();

      final students = await FirestoreService.getStudentsForSubject(widget.subjectModel.subjectId);
      final Map<String, int> presentCounts = {};
      
      for (final session in exportSessions) {
        final records = await FirestoreService.getRecordsForSession(session.sessionId);
        for (final record in records) {
          if (record.isPresent) {
            presentCounts[record.studentId] = (presentCounts[record.studentId] ?? 0) + 1;
          }
        }
      }

      final List<Map<String, dynamic>> analyticsData = [];
      final int totalSessions = exportSessions.length;
      
      for (final student in students) {
        final present = presentCounts[student.studentId] ?? 0;
        final absent = totalSessions - present;
        final percentage = totalSessions > 0 ? (present / totalSessions) * 100 : 0.0;
        
        analyticsData.add({
          'student': student,
          'present': present,
          'absent': absent,
          'total': totalSessions,
          'percentage': percentage,
        });
      }

      String program = '';
      if (widget.subjectModel.departmentId.isNotEmpty) {
        final dept = await FirestoreService.getDepartmentById(widget.subjectModel.departmentId);
        if (dept != null) {
          program = dept['program'] ?? '';
        }
      }

      if (isPdf) {
        await ReportExportService.exportToPdf(
          programName: program.isNotEmpty ? program : 'BTECH',
          subject: widget.subjectModel,
          startDate: isAll ? null : start,
          endDate: isAll ? null : end,
          analyticsData: analyticsData,
        );
      } else {
        await ReportExportService.exportToExcel(
          programName: program.isNotEmpty ? program : 'BTECH',
          subject: widget.subjectModel,
          startDate: isAll ? null : start,
          endDate: isAll ? null : end,
          analyticsData: analyticsData,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export generated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
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

    return Stack(
      children: [
        Scaffold(
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
                icon: const Icon(Icons.download),
                tooltip: 'Download Report',
                onPressed: _showDownloadOptions,
              ),
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

                              return GestureDetector(
                                onTap: () {
                                  final stat = {
                                    'student': student,
                                    'present': present,
                                    'absent': absent,
                                    'total': _totalSessions,
                                    'percentage': percentage,
                                    'history': _studentHistory[student.studentId] ?? [],
                                  };
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StudentAttendanceDetailsScreen(stat: stat),
                                    ),
                                  );
                                },
                                child: CustomCard(
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
                               ),
                               );
                             },
                           ),
               ),
            ],
          ),
        ),
        if (_isExporting)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Generating Report...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

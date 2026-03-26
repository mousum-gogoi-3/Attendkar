import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/student_firestore_model.dart';
import '../../models/attendance_session_model.dart';
import '../../models/subject_model.dart';
import '../../services/report_export_service.dart';

class StudentAttendanceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> stat;

  const StudentAttendanceDetailsScreen({super.key, required this.stat});

  @override
  State<StudentAttendanceDetailsScreen> createState() =>
      _StudentAttendanceDetailsScreenState();
}

class _StudentAttendanceDetailsScreenState
    extends State<StudentAttendanceDetailsScreen> {
  DateTime? _filterStart;
  DateTime? _filterEnd;
  bool _isExporting = false;

  List<Map<String, dynamic>> get _allHistory =>
      List<Map<String, dynamic>>.from(widget.stat['history'] ?? []);

  List<Map<String, dynamic>> get _filteredHistory {
    final history = _allHistory;
    if (_filterStart == null && _filterEnd == null) return history;

    return history.where((item) {
      final session = item['session'];
      final date = DateTime.tryParse(session.date);
      if (date == null) return false;
      if (_filterStart != null && date.isBefore(_filterStart!)) return false;
      if (_filterEnd != null &&
          date.isAfter(_filterEnd!.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Groups history items by "MMMM yyyy" (e.g. "March 2026") and sorts
  /// months descending, records within each month descending.
  Map<String, List<Map<String, dynamic>>> _groupByMonth(
      List<Map<String, dynamic>> history) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final item in history) {
      final session = item['session'];
      final date = DateTime.tryParse(session.date);
      if (date == null) continue;
      final key = DateFormat('MMMM yyyy').format(date);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }

    // Sort records inside each month descending
    for (final list in grouped.values) {
      list.sort((a, b) {
        final dA = DateTime.tryParse(a['session'].date) ?? DateTime(1970);
        final dB = DateTime.tryParse(b['session'].date) ?? DateTime(1970);
        return dB.compareTo(dA);
      });
    }

    // Return sorted by month descending
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final dA = DateFormat('MMMM yyyy').parse(a);
        final dB = DateFormat('MMMM yyyy').parse(b);
        return dB.compareTo(dA);
      });

    return {for (final k in sortedKeys) k: grouped[k]!};
  }

  int _countPresent(List<Map<String, dynamic>> items) =>
      items.where((i) => i['isPresent'] == true).length;

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _filterStart != null && _filterEnd != null
          ? DateTimeRange(start: _filterStart!, end: _filterEnd!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _filterStart = picked.start;
        _filterEnd = picked.end;
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _filterStart = null;
      _filterEnd = null;
    });
  }

  void _showDownloadOptions() {
    bool downloadAll = true;
    DateTime? tempStart = _filterStart;
    DateTime? tempEnd = _filterEnd;

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
      final student = widget.stat['student'] as StudentFirestoreModel;
      final subject = widget.stat['subject'] as SubjectModel;
      final program = widget.stat['program'] as String;

      final exportHistory = _allHistory.where((item) {
        if (isAll) return true;
        if (start == null || end == null) return true;
        final sessionDate = DateTime.parse(item['session'].date);
        return sessionDate.isAfter(start.subtract(const Duration(days: 1))) &&
               sessionDate.isBefore(end.add(const Duration(days: 1)));
      }).toList();

      if (isPdf) {
        await ReportExportService.exportStudentHistoryToPdf(
          programName: program.isNotEmpty ? program : 'BTECH',
          subject: subject,
          student: student,
          startDate: isAll ? null : start,
          endDate: isAll ? null : end,
          history: exportHistory,
        );
      } else {
        await ReportExportService.exportStudentHistoryToExcel(
          programName: program.isNotEmpty ? program : 'BTECH',
          subject: subject,
          student: student,
          startDate: isAll ? null : start,
          endDate: isAll ? null : end,
          history: exportHistory,
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
    final student = widget.stat['student'] as StudentFirestoreModel;
    final theme = Theme.of(context);

    final filtered = _filteredHistory;
    final grouped = _groupByMonth(filtered);

    final totalFiltered = filtered.length;
    final presentFiltered = _countPresent(filtered);
    final absentFiltered = totalFiltered - presentFiltered;
    final percentageFiltered =
        totalFiltered > 0 ? (presentFiltered / totalFiltered) * 100 : 0.0;

    final bool isFiltered = _filterStart != null || _filterEnd != null;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Student Attendance Details',
                style: TextStyle(fontSize: 16)),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Download Report',
                onPressed: _showDownloadOptions,
              ),
          IconButton(
            icon: Icon(isFiltered
                ? Icons.filter_alt
                : Icons.filter_alt_outlined),
            tooltip: 'Filter by Date Range',
            onPressed: _pickDateRange,
          ),
          if (isFiltered)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.orange),
              tooltip: 'Clear Filter',
              onPressed: _clearFilter,
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Student Info Header ──
          Container(
            padding: const EdgeInsets.all(20),
            color: theme.scaffoldBackgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Roll No: ${student.rollNo}',
                        style: TextStyle(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 16)),
                    Text(
                      '${percentageFiltered.toInt()}% Attendance',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: percentageFiltered >= 75
                            ? Colors.green
                            : (percentageFiltered >= 60
                                ? Colors.orange
                                : Colors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: $totalFiltered | Present: $presentFiltered | Absent: $absentFiltered',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (isFiltered) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.date_range,
                            size: 16, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text(
                          '${DateFormat('MMM dd, yyyy').format(_filterStart!)} – ${DateFormat('MMM dd, yyyy').format(_filterEnd!)}',
                          style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Monthly Grouped List ──
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No attendance records found.',
                        style: TextStyle(fontSize: 15)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: grouped.length,
                    itemBuilder: (context, sectionIndex) {
                      final monthKey = grouped.keys.elementAt(sectionIndex);
                      final items = grouped[monthKey]!;
                      final monthPresent = _countPresent(items);
                      final monthAbsent = items.length - monthPresent;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (sectionIndex > 0) const SizedBox(height: 16),
                          // ── Month Header ──
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  monthKey,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Row(
                                  children: [
                                    _StatChip(
                                        label: 'P',
                                        value: '$monthPresent',
                                        color: Colors.green),
                                    const SizedBox(width: 8),
                                    _StatChip(
                                        label: 'A',
                                        value: '$monthAbsent',
                                        color: Colors.red),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // ── Attendance Table ──
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: theme.dividerColor.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Column(
                                children: [
                                  // Table header
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.04),
                                    child: const Row(
                                      children: [
                                        Expanded(
                                            flex: 3,
                                            child: Text('Date',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 13))),
                                        Expanded(
                                            flex: 3,
                                            child: Text('Time',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 13))),
                                        Expanded(
                                            flex: 2,
                                            child: Text('Status',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 13))),
                                      ],
                                    ),
                                  ),
                                  // Table rows
                                  ...items.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final item = entry.value;
                                    final session = item['session'];
                                    final isPresent =
                                        item['isPresent'] as bool;
                                    final date =
                                        DateTime.parse(session.date);
                                    final dateStr =
                                        DateFormat('dd MMM, E').format(date);

                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: idx % 2 == 0
                                            ? Colors.transparent
                                            : theme.colorScheme.onSurface
                                                .withOpacity(0.02),
                                        border: Border(
                                          top: BorderSide(
                                              color: theme.dividerColor
                                                  .withOpacity(0.15)),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Text(dateStr,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                                '${session.startTime} - ${session.endTime}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(
                                                            0.6))),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Center(
                                              child: Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 10,
                                                    vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isPresent
                                                      ? Colors.green
                                                          .withOpacity(0.1)
                                                      : Colors.red
                                                          .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8),
                                                ),
                                                child: Text(
                                                  isPresent
                                                      ? 'Present'
                                                      : 'Absent',
                                                  textAlign:
                                                      TextAlign.center,
                                                  style: TextStyle(
                                                    color: isPresent
                                                        ? Colors.green
                                                        : Colors.red,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ],
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$value $label',
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/student_data_service.dart';
import '../../widgets/custom_card.dart';

class StudentClassDetailScreen extends StatefulWidget {
  final String classId;
  final String subjectName;
  final String rollNo;

  const StudentClassDetailScreen({
    super.key,
    required this.classId,
    required this.subjectName,
    required this.rollNo,
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
    
    final summary = await StudentDataService.getStudentAttendanceSummary(widget.classId, widget.rollNo);
    final history = await StudentDataService.getStudentAttendanceHistory(widget.classId, widget.rollNo);

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
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.subjectName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final double percentage = _summary['percentage'] ?? 0.0;
    final color = percentage >= 75 ? Colors.green : (percentage >= 60 ? Colors.orange : Colors.red);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient Header with stats
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 24, right: 24, bottom: 28,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1A1A2E), const Color(0xFF0F3460)]
                      : [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00B4DB).withOpacity(isDark ? 0.1 : 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button row
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
                        child: Text(
                          widget.subjectName,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats row
                  Row(
                    children: [
                      // Large percentage ring
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: _summary['total_sessions'] > 0 
                                  ? _summary['present'] / _summary['total_sessions'] 
                                  : 0,
                              strokeWidth: 8,
                              backgroundColor: Colors.white.withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                            Center(
                              child: Text(
                                '${percentage.toStringAsFixed(0)}%',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Stats chips
                      Expanded(
                        child: Column(
                          children: [
                            _statChip('Total', '${_summary['total_sessions']}', Colors.white.withOpacity(0.15), Colors.white),
                            const SizedBox(height: 8),
                            _statChip('Present', '${_summary['present']}', Colors.green.withOpacity(0.25), Colors.greenAccent),
                            const SizedBox(height: 8),
                            _statChip('Absent', '${_summary['absent']}', Colors.red.withOpacity(0.25), Colors.redAccent),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          ),

          // Section title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'Attendance History',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // History list
          if (_history.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No attendance records found.')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final session = _history[index];
                    final isPresent = session['status'] == 'Present';
                    final statusColor = isPresent ? Colors.green : Colors.red;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        elevation: isDark ? 0 : 1,
                        shadowColor: statusColor.withOpacity(0.1),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border(left: BorderSide(color: statusColor, width: 4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isPresent ? Icons.check_rounded : Icons.close_rounded,
                                  color: statusColor, size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(session['date'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text('${session['start_time']} - ${session['end_time']}',
                                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  session['status'],
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: (80 * index).ms, duration: 350.ms).slideX(begin: 0.04);
                  },
                  childCount: _history.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 13)),
          Text(value, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/subject_model.dart';
import '../../models/attendance_session_model.dart';
import '../../models/attendance_record_model.dart';
import '../../models/student_firestore_model.dart';
import '../../services/admin_firestore_service.dart';

class AdminAttendanceScreen extends StatelessWidget {
  final SubjectModel subject;

  const AdminAttendanceScreen({super.key, required this.subject});

  void _confirmDeleteSession(BuildContext context, String sessionId, String date) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Session'),
        content: Text('Delete attendance session for $date?\nAll records will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await AdminFirestoreService.deleteSessionAdmin(sessionId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17)),
            Text(subject.name, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A3E) : const Color(0xFF1971C2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<AttendanceSessionModel>>(
        stream: AdminFirestoreService.streamSessionsBySubject(subject.subjectId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snap.data ?? [];
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy_outlined,
                      size: 72,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text('No attendance sessions yet',
                      style: GoogleFonts.outfit(
                          fontSize: 17, fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                  const SizedBox(height: 8),
                  Text('Faculty marks attendance from their panel',
                      style: GoogleFonts.outfit(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3))),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final session = sessions[i];
              return _SessionTile(
                session: session,
                onDelete: () => _confirmDeleteSession(context, session.sessionId, session.date),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Session Tile (expandable) ─────────────────────────────────────────────

class _SessionTile extends StatefulWidget {
  final AttendanceSessionModel session;
  final VoidCallback onDelete;

  const _SessionTile({required this.session, required this.onDelete});

  @override
  State<_SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<_SessionTile> {
  bool _expanded = false;
  bool _loading = false;
  List<AttendanceRecordModel> _records = [];
  Map<String, StudentFirestoreModel> _studentMap = {};

  Future<void> _load() async {
    if (_records.isNotEmpty) return;
    setState(() => _loading = true);
    final records = await AdminFirestoreService.getRecordsForSession(
        widget.session.sessionId);
    final studentIds = records.map((r) => r.studentId).toList();
    final studentMap = await AdminFirestoreService.getStudentsByIds(studentIds);
    setState(() {
      _records = records;
      _studentMap = studentMap;
      _loading = false;
    });
  }

  Future<void> _toggle(AttendanceRecordModel record) async {
    final newStatus = record.isPresent ? 'Absent' : 'Present';
    await AdminFirestoreService.updateAttendanceRecord(record.recordId, newStatus);
    setState(() {
      final idx = _records.indexWhere((r) => r.recordId == record.recordId);
      if (idx != -1) {
        _records[idx] = AttendanceRecordModel(
          recordId: record.recordId,
          sessionId: record.sessionId,
          studentId: record.studentId,
          status: newStatus,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          // Session header
          InkWell(
            borderRadius: BorderRadius.vertical(
                top: const Radius.circular(16),
                bottom: _expanded
                    ? Radius.zero
                    : const Radius.circular(16)),
            onTap: () async {
              setState(() => _expanded = !_expanded);
              if (_expanded) await _load();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1971C2).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_today_rounded,
                        color: Color(0xFF1971C2), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.session.date,
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: theme.colorScheme.onSurface)),
                        Text(
                            '${widget.session.startTime} – ${widget.session.endTime}',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 20),
                    onPressed: widget.onDelete,
                    tooltip: 'Delete session',
                  ),
                  Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                ],
              ),
            ),
          ),

          // Expanded records
          if (_expanded) ...[
            const Divider(height: 1),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )
            else if (_records.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No records found',
                    style: GoogleFonts.outfit(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
              )
            else
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _records.length,
                itemBuilder: (context, i) {
                  final record = _records[i];
                  final isPresent = record.isPresent;
                  final student = _studentMap[record.studentId];
                  final studentName = student?.name ?? 'Unknown Student';
                  final rollNo = student?.rollNo ?? record.studentId;
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: isPresent
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.red.withValues(alpha: 0.12),
                      child: Icon(
                        isPresent ? Icons.check_rounded : Icons.close_rounded,
                        color: isPresent ? Colors.green : Colors.red,
                        size: 18,
                      ),
                    ),
                    title: Text(studentName,
                        style: GoogleFonts.outfit(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text('Roll No: $rollNo',
                        style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5))),
                    trailing: Switch.adaptive(
                      value: isPresent,
                      activeColor: Colors.green,
                      onChanged: (_) => _toggle(record),
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}

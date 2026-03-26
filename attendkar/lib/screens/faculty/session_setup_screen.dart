import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/subject_model.dart';
import '../../models/attendance_session_model.dart';
import 'take_attendance_screen.dart';

class SessionSetupScreen extends StatefulWidget {
  final SubjectModel subjectModel;

  const SessionSetupScreen({
    super.key,
    required this.subjectModel,
  });

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  List<AttendanceSessionModel> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    final uid = FirebaseAuthService.getLoggedFacultyUid();
    if (uid != null) {
      final sessions = await FirestoreService.getSessionsForSubject(
          widget.subjectModel.subjectId, uid);
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createNewSession() async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime =
        TimeOfDay(hour: (startTime.hour + 1) % 24, minute: startTime.minute);

    final theme = Theme.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('New Session', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogOptionTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: DateFormat('MMM dd, yyyy').format(selectedDate),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setStateDialog(() => selectedDate = date);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DialogOptionTile(
                        icon: Icons.access_time_rounded,
                        label: 'From',
                        value: startTime.format(context),
                        onTap: () async {
                          final time = await showTimePicker(context: context, initialTime: startTime);
                          if (time != null) {
                            setStateDialog(() {
                              startTime = time;
                              endTime = TimeOfDay(hour: (startTime.hour + 1) % 24, minute: startTime.minute);
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DialogOptionTile(
                        icon: Icons.access_time_filled_rounded,
                        label: 'To',
                        value: endTime.format(context),
                        onTap: () async {
                          final time = await showTimePicker(context: context, initialTime: endTime);
                          if (time != null) setStateDialog(() => endTime = time);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );

    if (result != true) return;

    final uid = FirebaseAuthService.getLoggedFacultyUid();
    if (uid == null) return;

    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    final startStr = startTime.format(context);
    final endStr = endTime.format(context);

    // Prevent duplicate sessions with same date and time
    final sessionExists = _sessions.any((s) => s.date == formattedDate && s.startTime == startStr);
    if (sessionExists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A session already exists for this date and time.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    final session = AttendanceSessionModel(
      sessionId: '',
      classId: widget.subjectModel.subjectId,
      subjectId: widget.subjectModel.subjectId,
      facultyId: uid,
      date: formattedDate,
      startTime: startStr,
      endTime: endStr,
    );

    final newSessionId = await FirestoreService.createAttendanceSession(session);

    if (!mounted) return;

    if (newSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create session. Try again.')),
      );
      return;
    }

    await _loadSessions();

    if (!mounted) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => TakeAttendanceScreen(
              sessionId: newSessionId,
              subjectId: widget.subjectModel.subjectId,
              date: formattedDate,
              startTime: startStr,
              endTime: endStr,
            ),
          ),
        )
        .then((_) => _loadSessions());
  }

  Future<void> _deleteSession(String sessionId) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Session?'),
        content: const Text('This will permanently delete the session and all its records.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirestoreService.deleteSession(sessionId);
      _loadSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient Header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 20, right: 20, bottom: 24,
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
                            const Text('Sessions', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(widget.subjectModel.name,
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_note_rounded, size: 14, color: Colors.white.withOpacity(0.8)),
                        const SizedBox(width: 6),
                        Text('${_sessions.length} Sessions', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          ),

          // Content
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_sessions.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.event_note_rounded, size: 64, color: const Color(0xFF667eea).withOpacity(0.4)),
                    ),
                    const SizedBox(height: 24),
                    Text('No Sessions Yet', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Create your first attendance session', style: TextStyle(color: Colors.grey.shade500)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _createNewSession,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final session = _sessions[index];
                    final sessionDate = DateTime.parse(session.date);
                    final isLocked = DateTime.now().difference(sessionDate).inDays > 7;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        elevation: isDark ? 0 : 2,
                        shadowColor: Colors.black.withOpacity(0.06),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(
                                  builder: (_) => TakeAttendanceScreen(
                                    sessionId: session.sessionId,
                                    subjectId: widget.subjectModel.subjectId,
                                    date: session.date,
                                    startTime: session.startTime,
                                    endTime: session.endTime,
                                  ),
                                ))
                                .then((_) => _loadSessions());
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border(left: BorderSide(
                                color: isLocked ? Colors.grey.shade400 : const Color(0xFF667eea),
                                width: 4,
                              )),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: (isLocked ? Colors.grey : const Color(0xFF667eea)).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    isLocked ? Icons.lock_rounded : Icons.edit_calendar_rounded,
                                    color: isLocked ? Colors.grey : const Color(0xFF667eea),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('MMM dd, yyyy').format(sessionDate),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${session.startTime}  –  ${session.endTime}',
                                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isLocked)
                                  Icon(Icons.lock_rounded, color: Colors.grey.shade400, size: 20)
                                else
                                  IconButton(
                                    icon: Icon(Icons.delete_rounded, color: Colors.red.shade400),
                                    onPressed: () => _deleteSession(session.sessionId),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: (80 * index).ms, duration: 400.ms).slideX(begin: 0.05);
                  },
                  childCount: _sessions.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _sessions.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _createNewSession,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Session'),
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              elevation: 6,
            )
          : null,
    );
  }
}

class _DialogOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DialogOptionTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF667eea)),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

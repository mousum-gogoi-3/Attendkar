import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/faculty_db_helper.dart';
import 'take_attendance_screen.dart';

class SessionSetupScreen extends StatefulWidget {
  final int classId;
  final String subjectName;
  final String section;

  const SessionSetupScreen({
    super.key,
    required this.classId,
    required this.subjectName,
    required this.section,
  });

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    final sessions = await FacultyDbHelper.instance.getSessionsForClass(widget.classId);
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewSession() async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(hour: (startTime.hour + 1) % 24, minute: startTime.minute);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('New Attendance Session'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(), // Don't allow future dates for attendance
                    );
                    if (date != null) setStateDialog(() => selectedDate = date);
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('From'),
                        subtitle: Text(startTime.format(context)),
                        onTap: () async {
                          final time = await showTimePicker(context: context, initialTime: startTime);
                          if (time != null) setStateDialog(() => startTime = time);
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('To'),
                        subtitle: Text(endTime.format(context)),
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
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Create'),
              ),
            ],
          );
        }
      ),
    );

    if (result == true) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      final sessionId = await FacultyDbHelper.instance.insertAttendanceSession({
        'class_id': widget.classId,
        'date': formattedDate,
        'start_time': startTime.format(context), // Store localized formatted string directly
        'end_time': endTime.format(context),
      });

      _loadSessions();
      if (!mounted) return;
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TakeAttendanceScreen(
            sessionId: sessionId,
            date: formattedDate,
            startTime: startTime.format(context),
            endTime: endTime.format(context),
          ),
        ),
      ).then((_) => _loadSessions());
    }
  }

  Future<void> _deleteSession(int sessionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Session?'),
        content: const Text('Are you sure you want to delete this session? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FacultyDbHelper.instance.deleteSession(sessionId);
      _loadSessions();
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
            const Text('Sessions', style: TextStyle(fontSize: 18)),
            Text('${widget.subjectName} (${widget.section})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_note, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        'No sessions recorded',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _createNewSession,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Session'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    final sessionDate = DateTime.parse(session['date']);
                    final isLocked = DateTime.now().difference(sessionDate).inDays > 7;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TakeAttendanceScreen(
                                sessionId: session['session_id'],
                                date: session['date'],
                                startTime: session['start_time'],
                                endTime: session['end_time'],
                              ),
                            ),
                          ).then((_) => _loadSessions());
                        },
                        leading: CircleAvatar(
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                          foregroundColor: theme.primaryColor,
                          child: Icon(isLocked ? Icons.lock : Icons.edit_calendar),
                        ),
                        title: Text(DateFormat('MMM dd, yyyy').format(sessionDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${session['start_time']} - ${session['end_time']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteSession(session['session_id']),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _sessions.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _createNewSession,
              icon: const Icon(Icons.add),
              label: const Text('New Session'),
            )
          : null,
    );
  }
}

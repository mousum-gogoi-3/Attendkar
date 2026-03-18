import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/subject_model.dart';
import '../../models/faculty_model.dart';
import 'admin_attendance_screen.dart';
import 'admin_students_screen.dart';

class AdminSubjectControlScreen extends StatelessWidget {
  final SubjectModel subject;
  final FacultyModel faculty;

  const AdminSubjectControlScreen({
    super.key,
    required this.subject,
    required this.faculty,
  });

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
            Text(subject.name,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 17)),
            Text(faculty.name,
                style:
                    GoogleFonts.outfit(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor:
            isDark ? const Color(0xFF1A1A3E) : const Color(0xFF0CA678),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF163B30), const Color(0xFF1A4A3A)]
                            : [
                                const Color(0xFF0CA678).withValues(alpha: 0.12),
                                const Color(0xFF1971C2).withValues(alpha: 0.1)
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.menu_book_rounded,
                        size: 44,
                        color: isDark
                            ? const Color(0xFF0CA678)
                            : const Color(0xFF0CA678)),
                  ),
                  const SizedBox(height: 14),
                  Text(subject.name,
                      style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text('Select an option to manage',
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Option 1: Manage Attendance
            _OptionCard(
              icon: Icons.checklist_rounded,
              color: const Color(0xFF1971C2),
              title: 'Manage Attendance',
              subtitle: 'View, edit or delete attendance sessions',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminAttendanceScreen(subject: subject),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Option 2: Manage Students
            _OptionCard(
              icon: Icons.people_rounded,
              color: const Color(0xFF0CA678),
              title: 'Manage Students',
              subtitle: 'Add, edit, delete students or upload CSV',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminStudentsScreen(subject: subject),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : color.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.05 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

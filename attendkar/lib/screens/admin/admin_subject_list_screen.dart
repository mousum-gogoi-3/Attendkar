import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/department_model.dart';
import '../../models/faculty_model.dart';
import '../../models/subject_model.dart';
import '../../services/admin_firestore_service.dart';
import 'admin_subject_control_screen.dart';

class AdminSubjectListScreen extends StatelessWidget {
  final FacultyModel faculty;
  final DepartmentModel department;

  const AdminSubjectListScreen({
    super.key,
    required this.faculty,
    required this.department,
  });

  void _showSubjectDialog(BuildContext context, {SubjectModel? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final semesterController = TextEditingController(text: existing?.semester ?? '');
    final courseCodeController = TextEditingController(text: existing?.courseCode ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existing == null ? 'Add Subject' : 'Edit Subject',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Subject Name (e.g. Data Structures)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: semesterController,
              decoration: InputDecoration(
                hintText: 'Semester (e.g. 5)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: courseCodeController,
              decoration: InputDecoration(
                hintText: 'Course ID (e.g. CS301)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final semester = semesterController.text.trim();
              final courseCode = courseCodeController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              if (existing == null) {
                await AdminFirestoreService.createSubject(
                  name: name,
                  facultyId: faculty.facultyId,
                  departmentId: department.departmentId,
                  semester: semester,
                  courseCode: courseCode,
                );
              } else {
                await AdminFirestoreService.updateSubject(
                    existing.subjectId, name, semester, courseCode);
              }
            },
            child: Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, SubjectModel subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Subject'),
        content: Text(
            'Delete "${subject.name}"?\nAll students and attendance records for this subject will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await AdminFirestoreService.deleteSubject(subject.subjectId);
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
            Text(faculty.name,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 17)),
            Text(department.name,
                style:
                    GoogleFonts.outfit(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor:
            isDark ? const Color(0xFF1A1A3E) : const Color(0xFF7048E8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<SubjectModel>>(
        stream:
            AdminFirestoreService.streamSubjectsByFaculty(faculty.facultyId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final subjects = snap.data ?? [];
          if (subjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.book_outlined,
                      size: 72,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text('No subjects yet',
                      style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                  const SizedBox(height: 8),
                  Text('Tap + to assign a subject to ${faculty.name}',
                      style: GoogleFonts.outfit(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3))),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final subject = subjects[i];
              return _SubjectTile(
                subject: subject,
                index: i,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminSubjectControlScreen(
                      subject: subject,
                      faculty: faculty,
                    ),
                  ),
                ),
                onEdit: () =>
                    _showSubjectDialog(context, existing: subject),
                onDelete: () => _confirmDelete(context, subject),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubjectDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
        backgroundColor: const Color(0xFF7048E8),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  final SubjectModel subject;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectTile({
    required this.subject,
    required this.index,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  static const List<Color> _palette = [
    Color(0xFF0CA678),
    Color(0xFF1971C2),
    Color(0xFFE67700),
    Color(0xFFC92A2A),
    Color(0xFF7048E8),
    Color(0xFF3B5BDB),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _palette[index % _palette.length];

    return Material(
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.menu_book_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject.name,
                        style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface)),
                    if (subject.courseCode.isNotEmpty || subject.semester.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 2),
                        child: Text(
                          [
                            if (subject.courseCode.isNotEmpty) subject.courseCode,
                            if (subject.semester.isNotEmpty) 'Sem ${subject.semester}'
                          ].join(' • '),
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.primary),
                        ),
                      ),
                    Text('Tap to manage attendance & students',
                        style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

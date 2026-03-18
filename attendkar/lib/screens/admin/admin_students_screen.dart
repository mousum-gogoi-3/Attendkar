import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/subject_model.dart';
import '../../models/student_firestore_model.dart';
import '../../services/admin_firestore_service.dart';
import 'admin_upload_students_screen.dart';

class AdminStudentsScreen extends StatelessWidget {
  final SubjectModel subject;

  const AdminStudentsScreen({super.key, required this.subject});

  void _showStudentDialog(BuildContext context,
      {StudentFirestoreModel? existing}) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    final rollCtrl =
        TextEditingController(text: existing?.rollNo ?? '');
    final deptCtrl =
        TextEditingController(text: existing?.department ?? '');
    final sectionCtrl =
        TextEditingController(text: existing?.section ?? '');
    final semesterCtrl =
        TextEditingController(text: existing?.semester ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existing == null ? 'Add Student' : 'Edit Student',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nameCtrl, 'Full Name', Icons.person_outline),
                const SizedBox(height: 12),
                _dialogField(rollCtrl, 'Roll Number', Icons.numbers_outlined),
                const SizedBox(height: 12),
                _dialogField(deptCtrl, 'Department', Icons.domain_outlined),
                const SizedBox(height: 12),
                _dialogField(sectionCtrl, 'Section', Icons.group_outlined),
                const SizedBox(height: 12),
                _dialogField(semesterCtrl, 'Semester', Icons.school_outlined),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                if (existing == null) {
                  final result = await AdminFirestoreService.createStudent(
                    name: nameCtrl.text.trim(),
                    rollNo: rollCtrl.text.trim(),
                    department: deptCtrl.text.trim(),
                    section: sectionCtrl.text.trim(),
                    semester: semesterCtrl.text.trim(),
                    subjectId: subject.subjectId,
                  );
                  if (result == null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to add student. Check permissions.')),
                    );
                  }
                } else {
                  final success = await AdminFirestoreService.updateStudent(
                    existing.studentId,
                    nameCtrl.text.trim(),
                    rollCtrl.text.trim(),
                    sectionCtrl.text.trim(),
                    semesterCtrl.text.trim(),
                  );
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update student. Check permissions.')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, StudentFirestoreModel student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Student'),
        content: Text(
            'Delete "${student.name}" (${student.rollNo})? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await AdminFirestoreService.deleteStudent(student.studentId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  static Widget _dialogField(
      TextEditingController ctrl, String label, IconData icon) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? '$label is required' : null,
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
            Text('Students',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 17)),
            Text(subject.name,
                style:
                    GoogleFonts.outfit(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor:
            isDark ? const Color(0xFF163B30) : const Color(0xFF0CA678),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
            tooltip: 'Upload CSV',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AdminUploadStudentsScreen(subject: subject),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<StudentFirestoreModel>>(
        stream:
            AdminFirestoreService.streamStudentsBySubject(subject.subjectId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final students = snap.data ?? [];
          if (students.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline,
                      size: 72,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text('No students yet',
                      style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4))),
                  const SizedBox(height: 8),
                  Text('Tap + to add manually or use CSV upload',
                      style: GoogleFonts.outfit(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3))),
                ],
              ),
            );
          }
          return Column(
            children: [
              // Student count banner
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0CA678).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF0CA678).withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_rounded,
                        color: Color(0xFF0CA678), size: 20),
                    const SizedBox(width: 10),
                    Text('${students.length} student(s) enrolled',
                        style: GoogleFonts.outfit(
                            color: const Color(0xFF0CA678),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final s = students[i];
                    return Material(
                      color: isDark
                          ? const Color(0xFF1E1E2E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFF0CA678).withValues(alpha: 0.12),
                          child: Text(
                            s.name.isNotEmpty
                                ? s.name[0].toUpperCase()
                                : 'S',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0CA678)),
                          ),
                        ),
                        title: Text(s.name,
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(
                            '${s.rollNo}  •  ${s.department}  •  Sec ${s.section}${s.semester.isNotEmpty ? "  •  Sem ${s.semester}" : ""}',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5))),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                              size: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          onSelected: (v) {
                            if (v == 'edit')
                              _showStudentDialog(context, existing: s);
                            if (v == 'delete')
                              _confirmDelete(context, s);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete',
                                    style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStudentDialog(context),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Student'),
        backgroundColor: const Color(0xFF0CA678),
        foregroundColor: Colors.white,
      ),
    );
  }
}

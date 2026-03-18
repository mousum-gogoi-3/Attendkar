import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/department_model.dart';
import '../../models/faculty_model.dart';
import '../../services/admin_firestore_service.dart';
import 'admin_faculty_form_screen.dart';
import 'admin_subject_list_screen.dart';

class AdminFacultyListScreen extends StatelessWidget {
  final DepartmentModel department;

  const AdminFacultyListScreen({super.key, required this.department});

  void _confirmDeleteFaculty(BuildContext context, FacultyModel faculty) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Faculty'),
        content: Text(
            'Delete "${faculty.name}"?\nThis will remove all subjects, students and attendance records assigned to them.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await AdminFirestoreService.deleteFaculty(faculty.facultyId);
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
        title: Text(department.name,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1A1A3E) : const Color(0xFF3B5BDB),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Chip(
              label: const Text('Faculties',
                  style: TextStyle(color: Colors.white, fontSize: 11)),
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
          )
        ],
      ),
      body: StreamBuilder<List<FacultyModel>>(
        stream: AdminFirestoreService.streamFacultiesByDepartment(
            department.departmentId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final faculties = snap.data ?? [];
          if (faculties.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_search_outlined,
                      size: 72,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text('No faculty yet',
                      style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                  const SizedBox(height: 8),
                  Text('Tap + to add a faculty member',
                      style: GoogleFonts.outfit(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.3))),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: faculties.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final faculty = faculties[i];
              return _FacultyTile(
                faculty: faculty,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminSubjectListScreen(
                      faculty: faculty,
                      department: department,
                    ),
                  ),
                ),
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminFacultyFormScreen(
                      department: department,
                      existing: faculty,
                    ),
                  ),
                ),
                onDelete: () => _confirmDeleteFaculty(context, faculty),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AdminFacultyFormScreen(department: department),
          ),
        ),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Faculty'),
        backgroundColor: const Color(0xFF3B5BDB),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _FacultyTile extends StatelessWidget {
  final FacultyModel faculty;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FacultyTile({
    required this.faculty,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF7048E8).withValues(alpha: 0.12),
                child: Text(
                  faculty.name.isNotEmpty ? faculty.name[0].toUpperCase() : 'F',
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7048E8)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(faculty.name,
                            style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface)),
                        if (faculty.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              color: Color(0xFF1971C2), size: 16),
                        ]
                      ],
                    ),
                    Text(faculty.email,
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
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

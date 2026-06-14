import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/department_model.dart';
import '../../services/admin_firestore_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../screens/welcome_screen.dart';
import 'admin_faculty_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // ─── Department Dialog ────────────────────────────────────────────────────
  void _showDepartmentDialog({DepartmentModel? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final programController = TextEditingController(text: existing?.program ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existing == null ? 'New Department' : 'Edit Department',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Department Name (e.g. Computer Science)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: programController,
              decoration: InputDecoration(
                hintText: 'Program (e.g. B.Tech)',
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
              final program = programController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              try {
                if (existing == null) {
                  final result = await AdminFirestoreService.createDepartment(name, program);
                  if (result == null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to create department. Please check permissions or network.')),
                    );
                  }
                } else {
                  final success = await AdminFirestoreService.updateDepartment(
                      existing.departmentId, name, program);
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update department.')),
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
            child: Text(existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDepartment(DepartmentModel dept) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Department'),
        content: Text(
            'Delete "${dept.name}"?\nThis will remove all faculties, subjects, students and attendance records inside it.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await AdminFirestoreService.deleteDepartment(dept.departmentId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    // Clear the admin login flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_admin_logged_in');
    await FirebaseAuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1A1A3E), const Color(0xFF2D2D5E)]
                      : [const Color(0xFF3B5BDB), const Color(0xFF7048E8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B5BDB).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.shield_rounded,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Admin Panel',
                                style: GoogleFonts.outfit(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13)),
                            Text('Attend BSSRV',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.white),
                        tooltip: 'Logout',
                        onPressed: _logout,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Departments',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  Text('Tap a department to manage faculties',
                      style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                ],
              ),
            ),

            // ─── Department List ──────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<DepartmentModel>>(
                stream: AdminFirestoreService.streamDepartments(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final departments = snap.data ?? [];
                  if (departments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.domain_outlined,
                              size: 72,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text('No departments yet',
                              style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.4))),
                          const SizedBox(height: 8),
                          Text('Tap + to create the first department',
                              style: GoogleFonts.outfit(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3))),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: departments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final dept = departments[i];
                      return _DepartmentTile(
                        department: dept,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AdminFacultyListScreen(department: dept),
                          ),
                        ),
                        onEdit: () => _showDepartmentDialog(existing: dept),
                        onDelete: () => _confirmDeleteDepartment(dept),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDepartmentDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Department'),
        backgroundColor: const Color(0xFF3B5BDB),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _DepartmentTile extends StatelessWidget {
  final DepartmentModel department;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DepartmentTile({
    required this.department,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  // Department color based on name
  Color get _color {
    final colors = [
      const Color(0xFF3B5BDB),
      const Color(0xFF7048E8),
      const Color(0xFF0CA678),
      const Color(0xFFE67700),
      const Color(0xFFC92A2A),
      const Color(0xFF1971C2),
    ];
    return colors[department.name.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.domain_rounded, color: _color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(department.name,
                        style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface)),
                    if (department.program.isNotEmpty)
                      Text(department.program,
                          style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.primary)),
                    Text('Tap to manage faculties',
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color:
                                theme.colorScheme.onSurface.withValues(alpha: 0.45))),
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

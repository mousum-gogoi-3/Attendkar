import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../models/user_profile.dart';
import '../models/subject.dart';
import '../models/semester.dart';
import 'splash_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    final user = provider.userProfile;
    final theme = Theme.of(context);

    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader(theme, 'Profile'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(user.name),
            subtitle: Text('${user.course} - ${user.rollNumber}'),
            trailing: const Icon(Icons.edit, size: 20),
            onTap: () => _showEditProfileDialog(context, provider, user),
          ),
          const Divider(),
          _buildSectionHeader(theme, 'Preferences'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: user.isDarkMode,
            onChanged: (val) => provider.toggleDarkMode(val),
          ),
          const Divider(),
          
          _buildSectionHeader(theme, 'Manage Semesters'),
          if (provider.semesters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Active Semester',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                value: provider.userProfile?.activeSemesterId,
                items: provider.semesters.map((s) {
                  return DropdownMenuItem(
                    value: s.id,
                    child: Text(s.name),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    provider.switchSemester(val);
                  }
                },
              ),
            ),
          ...provider.semesters.map((s) => ListTile(
                leading: const Icon(Icons.school_outlined),
                title: Text(s.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showEditSemesterDialog(context, provider, s),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                      onPressed: () => _showDeleteSemesterDialog(context, provider, s),
                    ),
                  ],
                ),
              )),
          ListTile(
            leading: Icon(Icons.add_circle_outline, color: theme.primaryColor),
            title: Text(
              'Add New Semester',
              style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
            ),
            onTap: () => _showAddSemesterDialog(context, provider),
          ),
          const Divider(),

          _buildSectionHeader(theme, 'Manage Subjects (Active Semester)'),
          if (provider.userProfile?.activeSemesterId == null)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Please select or create a semester first.'),
            )
          else ...[
            ...provider.subjects.map((s) => ListTile(
                  leading: const Icon(Icons.book_outlined),
                  title: Text(s.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showEditSubjectDialog(context, provider, s),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                        onPressed: () => _showDeleteSubjectDialog(context, provider, s),
                      ),
                    ],
                  ),
                )),
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: theme.primaryColor),
              title: Text(
                'Add New Subject',
                style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
              ),
              onTap: () => _showAddSubjectDialog(context, provider),
            ),
          ],
          
          const Divider(),
          _buildSectionHeader(theme, 'Danger Zone'),
          ListTile(
            leading: Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            title: Text(
              'Reset All Data',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => _showResetDataDialog(context, provider),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.primaryColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AttendanceProvider provider, UserProfile user) {
    final nameCtrl = TextEditingController(text: user.name);
    final courseCtrl = TextEditingController(text: user.course);
    final rollCtrl = TextEditingController(text: user.rollNumber);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: courseCtrl, decoration: const InputDecoration(labelText: 'Course')),
            TextField(controller: rollCtrl, decoration: const InputDecoration(labelText: 'Roll Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.saveProfile(nameCtrl.text.trim(), courseCtrl.text.trim(), rollCtrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // --- Semester Dialogs ---
  void _showAddSemesterDialog(BuildContext context, AttendanceProvider provider) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Semester'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Semester Name (e.g., Semester 1)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                provider.addSemester(nameCtrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditSemesterDialog(BuildContext context, AttendanceProvider provider, Semester semester) {
    final nameCtrl = TextEditingController(text: semester.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Semester'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Semester Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                provider.updateSemester(semester.id, nameCtrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSemesterDialog(BuildContext context, AttendanceProvider provider, Semester semester) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Semester'),
        content: Text('Are you sure you want to delete ${semester.name}? WARNING: This will permanently delete ALL subjects and attendance records for this semester!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Colors.white),
            onPressed: () {
              provider.deleteSemester(semester.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  // --- Subject Dialogs ---
  void _showAddSubjectDialog(BuildContext context, AttendanceProvider provider) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subject'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Subject Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                provider.addSubject(nameCtrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditSubjectDialog(BuildContext context, AttendanceProvider provider, Subject subject) {
    final nameCtrl = TextEditingController(text: subject.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Subject'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Subject Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                provider.updateSubject(subject.id, nameCtrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSubjectDialog(BuildContext context, AttendanceProvider provider, Subject subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete ${subject.name}? This will remove it from future daily sheets.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Colors.white),
            onPressed: () {
              provider.deleteSubject(subject.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showResetDataDialog(BuildContext context, AttendanceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text('This will permanently delete all profile data, subjects, and attendance history. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Colors.white),
            onPressed: () async {
              await provider.resetAllData();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Reset Data'),
          ),
        ],
      ),
    );
  }
}

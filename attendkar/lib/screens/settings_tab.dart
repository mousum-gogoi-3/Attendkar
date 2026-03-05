import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../models/user_profile.dart';
import '../services/student_auth_service.dart';
import 'welcome_screen.dart';
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
          _buildSectionHeader(theme, 'Account'),
          ListTile(
            leading: const Icon(Icons.swap_horiz_outlined),
            title: const Text('Switch Account'),
            subtitle: const Text('Login as a different Student or Faculty'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await StudentAuthService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.logout_outlined, color: theme.colorScheme.error),
            title: Text(
              'Logout',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () async {
              await StudentAuthService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.saveProfile(nameCtrl.text.trim(), user.course, user.rollNumber);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

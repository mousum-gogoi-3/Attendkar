import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../models/user_profile.dart';
import '../services/student_auth_service.dart';
import '../services/student_data_service.dart';
import 'welcome_screen.dart';
import 'splash_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String? _rollNo;

  @override
  void initState() {
    super.initState();
    _fetchRollNo();
  }

  Future<void> _fetchRollNo() async {
    final rollNo = await StudentAuthService.getLoggedStudentRollNo();
    if (mounted) {
      setState(() {
        _rollNo = rollNo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    final theme = Theme.of(context);
    final isDarkMode = provider.userProfile?.isDarkMode ?? (theme.brightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _rollNo == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionHeader(theme, 'Profile'),
                FutureBuilder<Map<String, dynamic>?>(
                  future: StudentDataService.getStudentProfile(_rollNo!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        leading: Icon(Icons.person_outline),
                        title: Text('Loading profile...'),
                      );
                    }
                    
                    final String displayName = snapshot.data?['name'] ?? 'Unknown Student';
                    final String displayCourse = snapshot.data?['department'] ?? 'Unknown Course';
                    
                    return ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('$displayCourse - $_rollNo'),
                    );
                  },
                ),
                const Divider(),
                _buildSectionHeader(theme, 'Preferences'),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: isDarkMode,
                  onChanged: (val) {
                    if (provider.userProfile != null) {
                      provider.toggleDarkMode(val);
                    }
                  },
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

}

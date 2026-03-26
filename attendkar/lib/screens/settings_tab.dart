import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../services/student_auth_service.dart';
import '../services/student_data_service.dart';
import 'welcome_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String? _rollNo;
  String _name = '—';
  String _department = '—';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final rollNo = await StudentAuthService.getLoggedStudentRollNo();
    if (rollNo != null) {
      final profileData = await StudentDataService.getStudentProfile(rollNo);
      if (mounted) {
        setState(() {
          _rollNo = rollNo;
          if (profileData != null) {
            _name = profileData['name'] ?? '—';
            _department = profileData['department'] ?? '—';
          }
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await StudentAuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24, right: 24, bottom: 32,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                      : [const Color(0xFF667eea), const Color(0xFF764ba2)],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(isDark ? 0.1 : 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      child: Text(
                        _name != '—' && _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(_name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_rollNo != null)
                    Text(_rollNo!, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school_rounded, size: 14, color: Colors.white.withOpacity(0.8)),
                            const SizedBox(width: 6),
                            Text(_department, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          ),

          // Settings
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                // Dark mode
                _ProfileCard(
                  isDark: isDark,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.dark_mode_rounded, color: Colors.amber.shade700, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(child: Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                        Switch.adaptive(
                          value: Provider.of<AttendanceProvider>(context).isDarkMode,
                          onChanged: (val) {
                            Provider.of<AttendanceProvider>(context, listen: false).toggleDarkMode(val);
                          },
                          activeColor: const Color(0xFF667eea),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: 0.05),

                const SizedBox(height: 16),

                // Switch Account
                _ProfileCard(
                  isDark: isDark,
                  child: InkWell(
                    onTap: () async {
                      await StudentAuthService.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                          (route) => false,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF667eea).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.swap_horiz_rounded, color: const Color(0xFF667eea), size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Switch Account', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                const SizedBox(height: 2),
                                Text('Login as a different Student/Faculty', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideX(begin: 0.05),

                const SizedBox(height: 32),

                // Logout button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _ProfileCard({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black.withOpacity(0.05),
      child: child,
    );
  }
}

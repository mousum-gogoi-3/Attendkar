import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'faculty/faculty_login_screen.dart';
import 'student_login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Small logo mark
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.blur_on_rounded, color: theme.colorScheme.primary, size: 32),
                    ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),
                    
                    const SizedBox(height: 32),
                    
                    Text(
                      'Welcome to\nAttend BSSRV.',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        height: 1.1,
                        color: theme.colorScheme.onSurface,
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 600.ms),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Sign in to your enterprise portal to manage and track attendance efficiently.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                    
                    const SizedBox(height: 64),
                    
                    // Options
                    _buildSaaSCard(
                      context: context,
                      title: 'Student Portal',
                      subtitle: 'View attendance & schedule',
                      icon: Icons.school_rounded,
                      delay: 300,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildSaaSCard(
                      context: context,
                      title: 'Faculty Portal',
                      subtitle: 'Manage classes & marks',
                      icon: Icons.admin_panel_settings_rounded,
                      delay: 400,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FacultyLoginScreen()),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSaaSCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required int delay,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.4)),
          ],
        ),
      ).animate().fadeIn(delay: delay.ms, duration: 500.ms).slideY(begin: 0.1),
    );
  }
}

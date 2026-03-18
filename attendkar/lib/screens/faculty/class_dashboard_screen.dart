import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/subject_model.dart';
import 'session_setup_screen.dart';
import 'manage_students_screen.dart';

class ClassDashboardScreen extends StatelessWidget {
  final SubjectModel subjectModel;

  const ClassDashboardScreen({super.key, required this.subjectModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clean Minimalist Header
            
            Text(
              subjectModel.name,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: theme.colorScheme.onSurface,
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                _buildInfoBadge(Icons.business_rounded, 'Dept ID: ${subjectModel.departmentId}', theme),
              ],
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            
            const SizedBox(height: 48),

            // SaaS-style Action Cards
            _buildActionCard(
              context: context,
              title: 'Attendance Sessions',
              subtitle: 'Create & manage attendance records',
              icon: Icons.event_available_rounded,
              delay: 300,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SessionSetupScreen(subjectModel: subjectModel)),
                );
              },
            ),

            const SizedBox(height: 16),

            _buildActionCard(
              context: context,
              title: 'Enrolled Students',
              subtitle: 'View class roster (Managed by Admin)',
              icon: Icons.people_alt_rounded,
              delay: 400,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ManageStudentsScreen(subjectId: subjectModel.subjectId, className: subjectModel.name)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required int delay,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 500.ms).slideY(begin: 0.1);
  }
}

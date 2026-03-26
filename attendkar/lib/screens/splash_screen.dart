import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/hive_service.dart';
import '../services/faculty_auth_service.dart';
import '../services/student_auth_service.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';
import 'student_login_screen.dart';
import 'faculty/faculty_main_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();

    // 1. Check Admin Login
    final isAdminLoggedIn = prefs.getBool('is_admin_logged_in') ?? false;
    if (isAdminLoggedIn) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AdminDashboardScreen(),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
      return;
    }

    // 2. Check Faculty Login
    final isFacultyLoggedIn = await FacultyAuthService.isFacultyLoggedIn();
    if (isFacultyLoggedIn) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const FacultyMainScreen(),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
      return;
    }

    // 3. Check Student Login
    final isStudentLoggedIn = await StudentAuthService.isStudentLoggedIn();
    if (isStudentLoggedIn) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
      return;
    }

    // 4. Brand new app open -> Show Welcome Screen to pick role
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const WelcomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.jpg',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.school,
                  size: 100,
                  color: Theme.of(context).primaryColor,
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Attendkar',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Professional Attendance Tracker',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/hive_service.dart';
import 'theme/app_theme.dart';
import 'providers/attendance_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: const AttendkarApp(),
    ),
  );
}

class AttendkarApp extends StatelessWidget {
  const AttendkarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, child) {
        final isDarkMode = provider.isDarkMode;

        return MaterialApp(
          title: 'Attend BSSRV',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

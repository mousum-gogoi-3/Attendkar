import 'package:flutter/material.dart';
import 'faculty_management_screen.dart';
import 'student_management_screen.dart';
import 'class_management_screen.dart';
import 'attendance_edit_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        children: [
          _buildDashboardCard(
            context,
            'Faculty Management',
            Icons.admin_panel_settings,
            Colors.blue,
            () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FacultyManagementScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            'Student Management',
            Icons.school,
            Colors.green,
            () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentManagementScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            'Class Management',
            Icons.class_,
            Colors.orange,
            () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ClassManagementScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            'Attendance Verification',
            Icons.verified,
            Colors.red,
            () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AttendanceEditScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(16),
             gradient: LinearGradient(
               colors: [color.withOpacity(0.7), color],
               begin: Alignment.topLeft,
               end: Alignment.bottomRight,
             ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

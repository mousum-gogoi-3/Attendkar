import 'package:flutter/material.dart';
import '../repositories/i_faculty_repository.dart';
import '../repositories/sqlite/sqlite_faculty_repository.dart';
import '../models/faculty_profile.dart';

class FacultyManagementScreen extends StatefulWidget {
  const FacultyManagementScreen({super.key});

  @override
  State<FacultyManagementScreen> createState() => _FacultyManagementScreenState();
}

class _FacultyManagementScreenState extends State<FacultyManagementScreen> {
  final IFacultyRepository _facultyRepository = SQLiteFacultyRepository();
  List<FacultyProfile> _faculties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFaculties();
  }

  Future<void> _loadFaculties() async {
    setState(() => _isLoading = true);
    try {
      await _facultyRepository.init();
      final faculties = await _facultyRepository.getAllFaculty();
      setState(() {
        _faculties = faculties;
      });
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading faculty: $e')));
      }
    } finally {
      if (mounted) {
         setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleVerification(FacultyProfile faculty) async {
    try {
      await _facultyRepository.updateFacultyVerification(faculty.email, !faculty.isVerified);
      // Reload logic
      _loadFaculties();
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating verification status: $e')));
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _faculties.length,
            itemBuilder: (context, index) {
              final faculty = _faculties[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(faculty.fullName.substring(0, 1).toUpperCase()),
                  ),
                  title: Row(
                    children: [
                       Text(faculty.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                       if (faculty.isVerified) const SizedBox(width: 4),
                       if (faculty.isVerified) const Icon(Icons.verified, color: Colors.blue, size: 20),
                    ]
                  ),
                  subtitle: Text('${faculty.department} | ${faculty.email}'),
                  trailing: Switch(
                    value: faculty.isVerified,
                    onChanged: (val) => _toggleVerification(faculty),
                    activeColor: Colors.blue,
                  ),
                ),
              );
            },
          ),
    );
  }
}

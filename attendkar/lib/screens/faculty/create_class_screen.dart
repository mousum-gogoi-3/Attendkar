import 'package:flutter/material.dart';
import '../../services/faculty_db_helper.dart';
import '../../services/faculty_auth_service.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectNameController = TextEditingController();
  final _sectionController = TextEditingController();
  final _semesterController = TextEditingController();
  final _departmentController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectNameController.dispose();
    _sectionController.dispose();
    _semesterController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _createClass() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final userId = await FacultyAuthService.getLoggedUserId();
      if (userId == null) return;

      await FacultyDbHelper.instance.insertClass({
        'faculty_user_id': userId,
        'subject_name': _subjectNameController.text.trim(),
        'section': _sectionController.text.trim(),
        'semester': _semesterController.text.trim(),
        'department': _departmentController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class created successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Create New Class')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _subjectNameController,
                  label: 'Subject Name',
                  icon: Icons.book_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _sectionController,
                  label: 'Section/Batch (Optional)',
                  icon: Icons.groups_outlined,
                  isOptional: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _semesterController,
                  label: 'Semester',
                  icon: Icons.school_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _sectionController,
                  label: 'Department (Optional)',
                  icon: Icons.domain_outlined,
                  isOptional: true,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createClass,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create Class', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isOptional = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: theme.cardTheme.color,
      ),
      validator: (val) {
        if (!isOptional && (val == null || val.trim().isEmpty)) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _courseController = TextEditingController();
  final _rollNoController = TextEditingController();
  
  final List<TextEditingController> _subjectControllers = [
    TextEditingController()
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _courseController.dispose();
    _rollNoController.dispose();
    for (var c in _subjectControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addSubjectField() {
    setState(() => _subjectControllers.add(TextEditingController()));
  }

  void _removeSubjectField(int index) {
    if (_subjectControllers.length > 1) {
      setState(() {
        _subjectControllers[index].dispose();
        _subjectControllers.removeAt(index);
      });
    }
  }

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      bool hasSubjects = _subjectControllers.any((c) => c.text.trim().isNotEmpty);
      if (!hasSubjects) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one subject.')),
        );
        return;
      }

      final provider = Provider.of<AttendanceProvider>(context, listen: false);
      
      await provider.saveProfile(
        _nameController.text.trim(),
        _courseController.text.trim(),
        _rollNoController.text.trim(),
      );

      for (var controller in _subjectControllers) {
        final text = controller.text.trim();
        if (text.isNotEmpty) {
          await provider.addSubject(text);
        }
      }

      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Attendkar'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Let\'s set up your profile.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 32),
                
                _buildSectionTitle(context, 'Personal Details'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _courseController,
                  label: 'Course',
                  icon: Icons.school_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _rollNoController,
                  label: 'Roll Number',
                  icon: Icons.numbers,
                ),
                
                const SizedBox(height: 48),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle(context, 'Subjects'),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: theme.primaryColor),
                      onPressed: _addSubjectField,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                ..._subjectControllers.asMap().entries.map((entry) {
                   int idx = entry.key;
                   var controller = entry.value;
                   return Padding(
                     padding: const EdgeInsets.only(bottom: 12.0),
                     child: Row(
                       children: [
                         Expanded(
                           child: _buildTextField(
                             controller: controller,
                             label: 'Subject ${idx + 1}',
                             icon: Icons.book_outlined,
                             validator: idx == 0 
                               ? (val) => val == null || val.trim().isEmpty ? 'Required' : null
                               : null,
                           ),
                         ),
                         if (_subjectControllers.length > 1) ...[
                           const SizedBox(width: 8),
                           IconButton(
                             icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error),
                             onPressed: () => _removeSubjectField(idx),
                           ),
                         ]
                       ],
                     ),
                   );
                }),
                
                const SizedBox(height: 48),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Continue to App', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
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
      validator: validator ?? (val) {
        if (val == null || val.trim().isEmpty) return 'Please enter $label';
        return null;
      },
    );
  }
}

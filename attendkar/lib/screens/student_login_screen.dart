import 'package:flutter/material.dart';
import '../../services/student_auth_service.dart';
import '../../services/student_auth_db_helper.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class StudentLoginScreen extends StatefulWidget {
  final bool showMigrationPopup;

  const StudentLoginScreen({
    super.key,
    this.showMigrationPopup = false,
  });

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rollNoController = TextEditingController();
  
  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  List<Map<String, dynamic>> _savedAccounts = [];

  @override
  void initState() {
    super.initState();
    if (widget.showMigrationPopup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMigrationDialog();
      });
    }
    _loadSavedAccounts();
  }

  Future<void> _loadSavedAccounts() async {
    final accounts = await StudentAuthDbHelper.instance.getAllAccounts();
    if (mounted) {
      setState(() {
        _savedAccounts = accounts;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _rollNoController.dispose();
    super.dispose();
  }

  void _showMigrationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Welcome back!'),
        content: const Text(
          'We have upgraded Attendkar to include secure student accounts! Please create an account by entering your email and password to secure your existing attendance records.\n\nYour data is safe and will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Set mode to register to encourage them to create the account
              setState(() => _isLoginMode = false);
            },
            child: const Text('Create Account'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Skip for now goes straight to home
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
            child: Text('Skip for now', style: TextStyle(color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final rollNo = _rollNoController.text.trim();

      bool success = false;
      
      if (_isLoginMode) {
        success = await StudentAuthService.loginStudent(email, password);
      } else {
        success = await StudentAuthService.registerStudent(email, password, rollNo);
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        if (widget.showMigrationPopup && !_isLoginMode) {
          // They are migrating existing data, so go to HomeScreen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else if (!_isLoginMode) {
          // Brand new user registration, go to Onboarding
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        } else {
          // Normal Login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLoginMode 
              ? 'Invalid email or password' 
              : 'Failed to create account. Email might already exist.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _quickLogin(String email, String rollNo) async {
    setState(() => _isLoading = true);
    await StudentAuthService.loginWithSavedAccount(email, rollNo);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? 'Student Login' : 'Student Registration'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Icon(Icons.school, size: 80, color: theme.primaryColor),
                const SizedBox(height: 24),
                
                Text(
                  _isLoginMode ? 'Welcome Back!' : 'Create Your Account',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoginMode 
                    ? 'Login to view your attendance dashboard.' 
                    : 'Register to start tracking your attendance securely.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                
                const SizedBox(height: 48),

                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                if (!_isLoginMode) ...[
                  _buildTextField(
                    controller: _rollNoController,
                    label: 'University Roll Number',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),
                ],

                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isLoginMode ? 'Login' : 'Create Account', 
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLoginMode ? "Don't have an account? " : "Already have an account? ",
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLoginMode = !_isLoginMode;
                          _formKey.currentState?.reset();
                        });
                      },
                      child: Text(
                        _isLoginMode ? 'Register' : 'Login', 
                        style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor)
                      ),
                    ),
                  ],
                ),
                
                if (widget.showMigrationPopup) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    },
                    child: Text('Skip for now', style: TextStyle(color: Colors.grey.shade600)),
                  ),
                ],

                if (_savedAccounts.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Saved Accounts',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._savedAccounts.map((acc) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        child: Icon(Icons.person, color: theme.primaryColor),
                      ),
                      title: Text(acc['email']),
                      trailing: const Icon(Icons.login),
                      onTap: () => _quickLogin(acc['email'], acc['roll_number'] ?? ''),
                    ),
                  )),
                ]
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
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
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
        if (val == null || val.trim().isEmpty) return 'Please enter $label';
        return null;
      },
    );
  }
}

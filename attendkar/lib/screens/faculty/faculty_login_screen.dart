import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin/admin_dashboard_screen.dart';
import 'faculty_main_screen.dart';

class FacultyLoginScreen extends StatefulWidget {
  const FacultyLoginScreen({super.key});

  @override
  State<FacultyLoginScreen> createState() => _FacultyLoginScreenState();
}

class _FacultyLoginScreenState extends State<FacultyLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoginMode = true; // Still defaults to login
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final email = _emailController.text.trim();
      final password = _passwordController.text;

      try {
        if (_isLoginMode) {
          // --- ADMIN LOGIN REDIRECT CHECK ---
          if ((email.toLowerCase() == 'adminattendnahikarega@gmail.com' || email.toLowerCase() == 'admin@gmail.com') && 
              password == 'mainhoonadmin@#\$321') {
             // Sign into Firebase Auth so Firestore security rules recognise the admin
             await FirebaseAuth.instance.signInWithEmailAndPassword(
               email: 'adminattendnahikarega@gmail.com',
               password: password,
             );
             // We do not save admin login state to force manual login on restart
             if (mounted) {
               Navigator.of(context).pushReplacement(
                 MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
               );
             }
             return;
          }

          // --- FIREBASE AUTHENTICATION ---
          UserCredential userCredential;
          try {
            userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
          } on FirebaseAuthException catch (e) {
            if (mounted) _showErrorSnackbar(e.message ?? 'Authentication failed');
            return;
          }

          if (userCredential.user == null) {
            if (mounted) _showErrorSnackbar('Login failed: user object is null.');
            return;
          }

          // Verify the user is actually a faculty member
          final doc = await FirebaseFirestore.instance.collection('faculties').doc(userCredential.user!.uid).get();
          
          if (doc.exists && mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const FacultyMainScreen()),
              (route) => false,
            );
          } else {
            await FirebaseAuth.instance.signOut();
            if (mounted) _showErrorSnackbar('Account found, but not registered as Faculty.');
          }
        }
      } catch (e) {
        if (mounted) _showErrorSnackbar('An error occurred: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                
                // Minimalist header
                Text(
                  _isLoginMode ? 'Sign in to portal' : 'Faculty Registration requests are closed natively. Contact Admin.',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: theme.colorScheme.onSurface,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05),
                
                const SizedBox(height: 8),
                
                Text(
                  _isLoginMode
                      ? 'Welcome back. Please enter your details.'
                      : 'Faculty accounts are now provisioned by the Administrator.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                
                const SizedBox(height: 48),

                if (_isLoginMode) ...[
                  // Flat, structured form fields
                  _buildLabel('Email address', theme),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'name@university.edu',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  
                  const SizedBox(height: 24),
                  
                  _buildLabel('Password', theme),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _passwordController,
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading 
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Sign in'),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1),
                ],
                
                if (!_isLoginMode) ...[
                  // If they toggled register, just show a message since faculty creation is admin-only now
                   Container(
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(
                       color: theme.colorScheme.surface,
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                     ),
                     child: Column(
                       children: [
                         Icon(Icons.admin_panel_settings_rounded, size: 48, color: theme.colorScheme.primary),
                         const SizedBox(height: 16),
                         const Text(
                           'Account Provisioning',
                           style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                         ),
                         const SizedBox(height: 8),
                         Text(
                           'To maintain security, faculty accounts are now strictly managed by the system administrator. Please contact IT to provision your account.',
                           textAlign: TextAlign.center,
                           style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), height: 1.5),
                         )
                       ],
                     ),
                   ).animate().fadeIn()
                ],

                const SizedBox(height: 32),

                // Register toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLoginMode ? "Need an account? " : "Already have an account? ",
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLoginMode = !_isLoginMode;
                          _formKey.currentState?.reset();
                        });
                      },
                      child: Text(
                        _isLoginMode ? 'Contact Admin' : 'Sign in', 
                        style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.primary, fontSize: 14),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, ThemeData theme) {
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface.withOpacity(0.8),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
        prefixIcon: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
        suffixIcon: suffixIcon,
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return 'Required';
        return null;
      },
    );
  }
}

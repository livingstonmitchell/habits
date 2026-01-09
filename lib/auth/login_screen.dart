// // Simplified login screen for the habits_app
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../services/auth_service.dart';
// import '../utils/routes/app_router.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _submitting = false;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> _handleLogin() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _submitting = true);
//     try {
//       await AuthService.instance.signIn(
//         email: _emailController.text.trim(),
//         password: _passwordController.text,
//       );
//       if (mounted) {
//         Navigator.of(
//           context,
//         ).pushNamedAndRemoveUntil(AppRoutes.userDashboard, (route) => false);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Sign in failed: ${e is FirebaseAuthException ? e.message ?? e.code : e.toString()}',
//             ),
//           ),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _submitting = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Sign in')),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 TextFormField(
//                   controller: _emailController,
//                   decoration: const InputDecoration(labelText: 'Email'),
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'Enter email';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),
//                 TextFormField(
//                   controller: _passwordController,
//                   decoration: const InputDecoration(labelText: 'Password'),
//                   obscureText: true,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) return 'Enter password';
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 24),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _submitting ? null : _handleLogin,
//                     child: _submitting
//                         ? const SizedBox(
//                             width: 18,
//                             height: 18,
//                             child: CircularProgressIndicator(strokeWidth: 2),
//                           )
//                         : const Text('Continue'),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 TextButton(
//                   onPressed: () =>
//                       Navigator.pushNamed(context, AppRoutes.register),
//                   child: const Text('Create account'),
//                 ),
//                 TextButton(
//                   onPressed: () =>
//                       Navigator.pushNamed(context, AppRoutes.resetPassword),
//                   child: const Text('Forgot password?'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../utils/routes/app_router.dart';
import 'package:habits_app/utils/theme.dart'; // Ensure AppColors.primary is defined

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await AuthService.instance.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.userDashboard, 
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            content: Text(
              e is FirebaseAuthException ? e.message ?? e.code : e.toString(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Gradient
          _buildBackground(),
          
          // 2. Login Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo/Icon
                    _buildHeader(),
                    const SizedBox(height: 40),
                    
                    // Login Card
                    _buildLoginForm(),
                    
                    const SizedBox(height: 20),
                    
                    // Bottom Navigation
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
            const Color(0xFF6366F1), // Modern Indigo
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_graph_rounded, // Habit growth icon
            size: 64,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Welcome Back",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Text(
          "Track your progress, build your future.",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Email Field
            _buildTextField(
              controller: _emailController,
              label: "Email Address",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || v.isEmpty) ? "Enter your email" : null,
            ),
            const SizedBox(height: 16),
            
            // Password Field
            _buildTextField(
              controller: _passwordController,
              label: "Password",
              icon: Icons.lock_outline,
              isPassword: true,
              obscureText: _obscurePassword,
              onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
              validator: (v) => (v == null || v.isEmpty) ? "Enter your password" : null,
            ),
            
            // Forgot Password Link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.resetPassword),
                child: Text(
                  "Forgot Password?",
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitting ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "Sign In",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? ", style: TextStyle(color: Colors.white70)),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.register),
          child: const Text(
            "Create One",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.7)),
        suffixIcon: isPassword 
          ? IconButton(
              icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
              onPressed: onTogglePassword,
            ) 
          : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
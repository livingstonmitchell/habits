// import 'package:flutter/material.dart';
// import '../services/auth_service.dart';
// import '../utils/routes/app_router.dart';

// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
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

//   Future<void> _register() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _submitting = true);
//     await AuthService.instance.register(
//       email: _emailController.text.trim(),
//       password: _passwordController.text,
//     );
//     if (mounted) {
//       Navigator.of(
//         context,
//       ).pushNamedAndRemoveUntil(AppRoutes.userDashboard, (route) => false);
//     }
//     setState(() => _submitting = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Create account')),
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
//                     if (value == null || value.isEmpty) {
//                       return 'Enter password';
//                     }
//                     if (value.length < 6) return 'Min 6 characters';
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 24),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _submitting ? null : _register,
//                     child: _submitting
//                         ? const SizedBox(
//                             width: 18,
//                             height: 18,
//                             child: CircularProgressIndicator(strokeWidth: 2),
//                           )
//                         : const Text('Create account'),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('Have an account? Sign in'),
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
import 'package:habits_app/utils/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _submitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _submitting = true);
    try {
      await AuthService.instance.register(
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
            content: Text(e is FirebaseAuthException ? e.message ?? e.code : e.toString()),
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
          // 1. Background Gradient (Matches Login)
          _buildBackground(),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildRegisterForm(),
                    const SizedBox(height: 20),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
          // Back Button for better UX
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
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
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.primary,
            const Color(0xFF4F46E5), // Indigo
            const Color(0xFF7C3AED), // Violet
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          "Join Us",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          "Start your journey to better habits today.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(
              controller: _emailController,
              label: "Email Address",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.contains('@')) ? "Enter a valid email" : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              label: "Password",
              icon: Icons.lock_outline,
              isPassword: true,
              obscureText: _obscurePassword,
              onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
              validator: (v) => (v != null && v.length < 6) ? "Minimum 6 characters" : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _confirmPasswordController,
              label: "Confirm Password",
              icon: Icons.lock_reset_outlined,
              isPassword: true,
              obscureText: _obscurePassword,
              validator: (v) => (v != _passwordController.text) ? "Passwords do not match" : null,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitting ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text(
        "Already have an account? Sign In",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
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
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: isPassword 
            ? IconButton(icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility), onPressed: onTogglePassword) 
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }
}
import 'package:flutter/foundation.dart';

/// Tiny in-memory auth helper for the starter template.
/// Replace with Firebase/Auth0/etc. when wiring real auth.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  bool _signedIn = false;
  String? _email;

  bool get isSignedIn => _signedIn;
  String? get email => _email;

  Future<void> signIn({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _signedIn = true;
    _email = email;
    debugPrint('Signed in as $email');
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _signedIn = true;
    _email = email;
    debugPrint('Registered $email');
  }

  Future<void> sendPasswordReset(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    debugPrint('Password reset sent to $email');
  }

  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _signedIn = false;
    _email = null;
  }
}

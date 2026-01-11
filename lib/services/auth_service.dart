import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase-backed auth helper used across the app.
/// Keeps the same simple API as the starter version.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================
  // STATE
  // =========================

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;
  String? get email => _auth.currentUser?.email;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // =========================
  // AUTH ACTIONS
  // =========================

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      throw ArgumentError('Email and password are required');
    }

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('Signed in as ${cred.user?.email}');
      return cred;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign-in failed: ${e.code} ${e.message}');
      rethrow;
    }
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      throw ArgumentError('Email and password are required');
    }

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('Registered ${cred.user?.email}');
      return cred;
    } on FirebaseAuthException catch (e) {
      debugPrint('Registration failed: ${e.code} ${e.message}');
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    if (email.isEmpty) {
      throw ArgumentError('Email is required');
    }

    await _auth.sendPasswordResetEmail(email: email);
    debugPrint('Password reset sent to $email');
  }

  Future<void> signOut() async {
    await _auth.signOut();
    debugPrint('Signed out');
  }
}

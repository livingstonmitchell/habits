class Validators {
  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Email is required';
    if (!s.contains('@') || !s.contains('.')) return 'Enter a valid email';
    return null;
  }

  static String? password(String? v) {
    final s = (v ?? '').trim();
    if (s.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? requiredField(String? v, String name) {
    if ((v ?? '').trim().isEmpty) return '$name is required';
    return null;
  }
}

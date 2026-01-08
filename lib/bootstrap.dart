import 'package:flutter/material.dart';

/// Lightweight bootstrap for the starter template.
/// This keeps only the bits needed to ensure WidgetsBinding is ready.
Future<void> initApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future<void>.delayed(const Duration(milliseconds: 200));
}

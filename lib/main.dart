import 'package:flutter/material.dart';
import 'app_core.dart';
import 'bootstrap.dart';

void main() async {
  // Initialize all required services
  await initApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCore();
  }
}

import 'package:flutter/material.dart';
import 'package:habits_app/utils/theme.dart';

class NutritionActionScreen extends StatelessWidget {
  final String title;
  final String subtitle;

  const NutritionActionScreen({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

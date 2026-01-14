import 'package:flutter/material.dart';
import 'package:habits_app/utils/theme.dart';
import 'package:habits_app/screens/nutrition/food_scan_result_screen.dart';

class FoodScanCameraScreen extends StatelessWidget {
  const FoodScanCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera placeholder background
          Positioned.fill(
            child: Image.asset(
              "assets/images/food_sample.jpg", // <-- put any food image here
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.black,
                child: const Center(
                  child: Text("Camera Preview (placeholder)", style: TextStyle(color: Colors.white70)),
                ),
              ),
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const Spacer(),
                  const Text(
                    "Scanning food",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),

          // Fake detection labels
          Positioned(
            top: 170,
            left: 120,
            child: _Tag("Chicken"),
          ),
          Positioned(
            top: 320,
            left: 90,
            child: _Tag("Tomato"),
          ),
          Positioned(
            top: 420,
            left: 160,
            child: _Tag("Lettuce"),
          ),

          // Bottom shutter button
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FoodScanResultScreen()),
                  );
                },
                child: Container(
                  height: 76,
                  width: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.18),
                    border: Border.all(color: Colors.white.withOpacity(0.7), width: 4),
                  ),
                  child: const Center(
                    child: Icon(Icons.circle, color: Colors.white24, size: 40),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
    );
  }
}

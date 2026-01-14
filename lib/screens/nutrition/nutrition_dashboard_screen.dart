import 'package:flutter/material.dart';
import 'package:habits_app/utils/theme.dart';
import 'package:habits_app/screens/nutrition/food_scan_camera_screen.dart';

class NutritionDashboardScreen extends StatelessWidget {
  const NutritionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text("Nutrition", style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FoodScanCameraScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
        children: [
          _CaloriesCard(),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: _MacroCard(title: "Carbs left", value: "25g", icon: Icons.bakery_dining_outlined)),
              SizedBox(width: 12),
              Expanded(child: _MacroCard(title: "Protein left", value: "35g", icon: Icons.fitness_center_outlined)),
              SizedBox(width: 12),
              Expanded(child: _MacroCard(title: "Fats left", value: "15g", icon: Icons.opacity_outlined)),
            ],
          ),
          const SizedBox(height: 16),
          Text("Tracked today", style: AppText.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 10),
          _TrackedTile(
            title: "Breakfast platter",
            subtitle: "653 Calories",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FoodScanCameraScreen(),
                ),
              );
            },
          ),
        ],
      ),

      // Floating scan button like the screenshot
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FoodScanCameraScreen()),
            );
          },
          child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

class _CaloriesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("2500", style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
          SizedBox(height: 2),
          Text("Total Calories", style: TextStyle(color: Colors.black54)),
          SizedBox(height: 12),
          LinearProgressIndicator(minHeight: 10, value: 0.55),
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MacroCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 2),
                Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackedTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TrackedTile({required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.stroke),
              ),
              child: const Icon(Icons.restaurant, color: Colors.black54),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

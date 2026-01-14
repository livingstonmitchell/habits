import 'package:flutter/material.dart';
import 'package:habits_app/utils/theme.dart';

class FoodScanResultScreen extends StatelessWidget {
  const FoodScanResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              "assets/images/food_sample.jpg",
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
            ),
          ),

          // Top close
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),

          // Bottom result sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 5,
                    width: 44,
                    decoration: BoxDecoration(
                      color: AppColors.stroke,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: const [
                      Expanded(
                        child: Text(
                          "Chocolate milkshake",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: Row(
                      children: const [
                        Expanded(child: Text("Total 159 Kcal", style: TextStyle(fontWeight: FontWeight.w900))),
                        Icon(Icons.local_fire_department_outlined, color: AppColors.primary),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Expanded(child: _MiniMacro(title: "Carbs", value: "50g", icon: Icons.bakery_dining_outlined)),
                      SizedBox(width: 10),
                      Expanded(child: _MiniMacro(title: "Protein", value: "50g", icon: Icons.fitness_center_outlined)),
                      SizedBox(width: 10),
                      Expanded(child: _MiniMacro(title: "Fat", value: "50g", icon: Icons.opacity_outlined)),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text("Healthy Score", style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(width: 8),
                      const Text("8/10", style: TextStyle(color: Colors.black54)),
                      const Spacer(),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: const LinearProgressIndicator(value: 0.8, minHeight: 8),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          child: const Text("Update Details"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Saved (UI demo)")),
                            );
                          },
                          child: const Text("Next", style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMacro extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniMacro({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }
}

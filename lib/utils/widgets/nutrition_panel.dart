import 'package:flutter/material.dart';
import 'package:habits_app/utils/theme.dart';

class NutritionPanel extends StatefulWidget {
  final VoidCallback onOpenHabits;
  const NutritionPanel({super.key, required this.onOpenHabits});

  @override
  State<NutritionPanel> createState() => _NutritionPanelState();
}

class _NutritionPanelState extends State<NutritionPanel> {
  double _intake = 0.55;
  int _waterCups = 2;

  @override
  Widget build(BuildContext context) {
    final pct = (_intake * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Daily intake", style: AppText.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: _intake,
            backgroundColor: AppColors.bg,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text("Water: $_waterCups / 8", style: AppText.muted),
        ],
      ),
    );
  }
}

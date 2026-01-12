import 'package:flutter/material.dart';
import 'package:habits_app/utils/theme.dart';

class SleepPanel extends StatefulWidget {
  final VoidCallback onOpenHabits;
  const SleepPanel({super.key, required this.onOpenHabits});

  @override
  State<SleepPanel> createState() => _SleepPanelState();
}

class _SleepPanelState extends State<SleepPanel> {
  double _sleepScore = 0.72;

  @override
  Widget build(BuildContext context) {
    final scorePct = (_sleepScore * 100).round();

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
          Text("Sleep insights", style: AppText.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          Text("Score: $scorePct%", style: AppText.muted),
        ],
      ),
    );
  }
}

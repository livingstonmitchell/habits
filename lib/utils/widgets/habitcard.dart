import 'package:flutter/material.dart';
import 'package:habits_app/utils/theme.dart';


class HabitCard extends StatelessWidget {
  // ✅ so your TodayHomeScreen can pass: habit: null
  final dynamic habit;

  final String title;
  final String subtitle;
  final String emoji;
  final int color;
  final bool checkedToday;
  final VoidCallback onOpen;
  final VoidCallback onToggle;

  const HabitCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.checkedToday,
    required this.onOpen,
    required this.onToggle,
    this.habit, // ✅ NEW (fixes the red)
  });

  @override
  Widget build(BuildContext context) {
    final tileBg = Color(color).withOpacity(0.10);

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.stroke),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h2),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppText.muted),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // ✅ Dribbble-style mini action button (plus/check)
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: checkedToday ? AppColors.primarySoft : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: checkedToday ? AppColors.primarySoft : AppColors.stroke,
                  ),
                ),
                child: Icon(
                  checkedToday ? Icons.check : Icons.add,
                  size: 18,
                  color: checkedToday ? AppColors.primary : AppColors.subtext,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


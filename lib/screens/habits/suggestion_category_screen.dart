import 'package:flutter/material.dart';
import 'package:habits_app/utils/routes/app_router.dart';
import 'package:habits_app/utils/theme.dart';

class SuggestionCategoryScreen extends StatelessWidget {
  final String title;
  final List<Map<String, String>> items; // [{t:..., e:...}]
  const SuggestionCategoryScreen({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(title, style: AppText.h2),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((it) {
            final t = it["t"] ?? "";
            final e = it["e"] ?? "✨";

            return InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                // ✅ when you tap a chip -> go to Add Habit prefilled
                Navigator.pushNamed(
                  context,
                  AppRoutes.addHabit,
                  arguments: {
                    "prefillTitle": t,
                    "prefillEmoji": e,
                    "prefillCategory": title,
                    // optional: completion only for most of these
                    "prefillHabitType": "completionOnly",
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(e, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: Text(
                        t,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:habits_app/services/firestore_service.dart';
import 'package:habits_app/utils/theme.dart';
import 'package:habits_app/screens/habits/category_habits_screen.dart';
import 'package:habits_app/utils/routes/app_router.dart';

class NutritionScreen extends StatelessWidget {
  final String uid;
  const NutritionScreen({super.key, required this.uid});

  String _categoryOf(Map<String, dynamic> h) {
    final title = (h['title'] ?? '').toString().toLowerCase();
    final emoji = (h['emoji'] ?? '').toString();
    bool hasAny(List<String> w) => w.any((x) => title.contains(x));
    if (emoji.contains('💧') || emoji.contains('🍎') || hasAny(['water', 'hydrate', 'food', 'nutrition', 'protein', 'fruit', 'veg'])) {
      return "Nutrition";
    }
    return "Other";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text("Nutrition", style: AppText.h2),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addHabit),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService.instance.watchHabits(uid),
        builder: (context, snap) {
          final all = snap.data ?? [];
          final nutrition = all.where((h) => _categoryOf(h) == "Nutrition").toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              // ✅ your panel (use your existing widget)
              _NutritionPanel(onOpenHabits: () {}),
              const SizedBox(height: 14),

              _ScreenHeader(
                title: "Nutrition habits",
                action: "See all",
                onAction: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryHabitsScreen(uid: uid, title: "Nutrition", habits: nutrition),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              if (nutrition.isEmpty)
                _EmptyBox(text: "No nutrition habits yet. Tap + to add one.")
              else
                ...nutrition.take(20).map((h) => _SimpleHabitTile(habit: h)).toList(),
            ],
          );
        },
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;
  const _ScreenHeader({required this.title, required this.action, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppText.h2.copyWith(fontSize: 18)),
        const Spacer(),
        TextButton(onPressed: onAction, child: Text(action)),
      ],
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Text(text, style: AppText.muted),
    );
  }
}

class _SimpleHabitTile extends StatelessWidget {
  final Map<String, dynamic> habit;
  const _SimpleHabitTile({required this.habit});

  @override
  Widget build(BuildContext context) {
    final title = (habit['title'] ?? '').toString();
    final emoji = (habit['emoji'] ?? '✨').toString();
    final freq = (habit['frequency'] ?? 'daily').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(freq, style: AppText.muted),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

/// ✅ IMPORTANT:
/// Paste your existing _NutritionPanel widget here OR import the file where it already exists.
class _NutritionPanel extends StatelessWidget {
  final VoidCallback onOpenHabits;
  const _NutritionPanel({required this.onOpenHabits});

  @override
  Widget build(BuildContext context) {
    // Replace with your real panel code (the one you already have)
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke),
      ),
      child: const Text("Nutrition Panel (use your existing widget)"),
    );
  }
}

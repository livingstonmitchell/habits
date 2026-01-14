import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../utils/streak_utils.dart';
import 'nutrition_value_screen.dart';

class ManageNutritionScreen extends StatefulWidget {
  const ManageNutritionScreen({super.key});

  @override
  State<ManageNutritionScreen> createState() => _ManageNutritionScreenState();
}

class _ManageNutritionScreenState extends State<ManageNutritionScreen> {
  String? get _uid => AuthService.instance.currentUser?.uid;

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  DateTime _day = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Sign in required")));
    }

    final dayKey = dateKey(dateOnly(_day));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Manage Nutrition"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService.instance.watchFoodsForDay(uid, dayKey),
        builder: (context, snap) {
          final foods = snap.data ?? [];

          final totalCalories = foods.fold<int>(0, (sum, f) => sum + _asInt(f['calories']));
          final totalCarbs = foods.fold<int>(0, (sum, f) => sum + _asInt(f['carbs']));
          final totalProtein = foods.fold<int>(0, (sum, f) => sum + _asInt(f['protein']));
          final totalFat = foods.fold<int>(0, (sum, f) => sum + _asInt(f['fat']));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TopSummaryCard(
                dateText: dayKey,
                calories: totalCalories,
                carbs: totalCarbs,
                protein: totalProtein,
                fat: totalFat,
                onPickDate: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _day,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _day = picked);
                },
              ),
              const SizedBox(height: 14),

              if (foods.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: Text("No foods logged for this day.", style: AppText.muted),
                )
              else
                ...foods.map((f) {
                  final id = (f['id'] ?? '').toString();
                  final name = (f['name'] ?? 'Food').toString();
                  final meal = (f['meal'] ?? 'Any').toString();
                  final kcal = _asInt(f['calories']);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.restaurant_menu),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
                      subtitle: Text(meal),
                      trailing: Text("$kcal kcal", style: AppText.muted),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NutritionValueScreen(
                              uid: uid,
                              dayKey: dayKey,
                              foodId: id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
            ],
          );
        },
      ),
    );
  }
}

class _TopSummaryCard extends StatelessWidget {
  final String dateText;
  final int calories;
  final int carbs;
  final int protein;
  final int fat;
  final VoidCallback onPickDate;

  const _TopSummaryCard({
    required this.dateText,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Summary", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
              const Spacer(),
              TextButton(
                onPressed: onPickDate,
                child: Text(dateText, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text("$calories kcal", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 12),
          Row(
            children: [
              _mini("Carbs", "$carbs g"),
              const SizedBox(width: 10),
              _mini("Protein", "$protein g"),
              const SizedBox(width: 10),
              _mini("Fat", "$fat g"),
            ],
          ),
        ],
      ),
    );
  }

  Expanded _mini(String t, String v) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

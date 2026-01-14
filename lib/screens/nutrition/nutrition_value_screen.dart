import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';

class NutritionValueScreen extends StatelessWidget {
  final String uid;
  final String dayKey;
  final String foodId;

  const NutritionValueScreen({
    super.key,
    required this.uid,
    required this.dayKey,
    required this.foodId,
  });

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Nutrition Values"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: FirestoreService.instance.getFoodForDay(uid: uid, dayKey: dayKey, foodId: foodId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data;
          if (data == null) {
            return const Center(child: Text("Food not found"));
          }

          final name = (data['name'] ?? 'Food').toString();
          final meal = (data['meal'] ?? 'Any').toString();
          final calories = _asInt(data['calories']);
          final carbs = _asInt(data['carbs']);
          final protein = _asInt(data['protein']);
          final fat = _asInt(data['fat']);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.restaurant, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                          const SizedBox(height: 4),
                          Text("Meal: $meal", style: AppText.muted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              _ValueCard(title: "Calories", value: "$calories kcal"),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(child: _ValueCard(title: "Carbs", value: "$carbs g")),
                  const SizedBox(width: 10),
                  Expanded(child: _ValueCard(title: "Protein", value: "$protein g")),
                  const SizedBox(width: 10),
                  Expanded(child: _ValueCard(title: "Fat", value: "$fat g")),
                ],
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Text(
                  "Tip: Right now this screen shows the values you entered when adding food. "
                  "If you want automatic nutrition values (micronutrients too), we can connect to a nutrition API next.",
                  style: AppText.muted,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final String title;
  final String value;

  const _ValueCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.muted),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }
}

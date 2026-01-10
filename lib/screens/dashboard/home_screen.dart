import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:habits_app/utils/widgets/habitcard.dart';
import 'package:habits_app/utils/routes/app_router.dart';
import 'package:habits_app/services/auth_service.dart';
import 'package:habits_app/services/firestore_service.dart';
import 'package:habits_app/utils/theme.dart';
import 'package:habits_app/models/habit_models.dart';
import 'package:intl/intl.dart' show DateFormat;

class TodayHomeScreen extends StatelessWidget {
  const TodayHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      // Render a safe fallback instead of navigating from build to avoid
      // scheduler errors when the view gets disposed on web/hot-restart.
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.login),
                child: const Text('Sign in again'),
              ),
            ],
          ),
        ),
      );
    }

    final uid = user.uid;
    final todayLabel = DateFormat('EEE, MMM d').format(DateTime.now());

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addHabit),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              // ✅ Dribbble-ish header: Stack + avatar overlap + greeting
              StreamBuilder<Map<String, dynamic>?>(
                stream: FirestoreService.instance.watchProfile(uid),
                builder: (context, snap) {
                  final profile = snap.data ?? {};
                  final name = _friendlyName(profile, user);
                  final photoUrl =
                      (profile['photoUrl'] ?? profile['profileImageUrl'] ?? '')
                          .toString()
                          .trim();

                  return Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: AppColors.stroke),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _RoundIconButton(
                                  icon: Icons.grid_view_rounded,
                                  onTap: () {},
                                ),
                                const Spacer(),
                                _RoundIconButton(
                                  icon: Icons.calendar_month_rounded,
                                  onTap: () {},
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text("Hello, $name", style: AppText.h1),
                            const SizedBox(height: 6),
                            Text("Today • $todayLabel", style: AppText.muted),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.stroke),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    height: 38,
                                    width: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Quick tip: Tap + to add a habit, then check in daily.",
                                      style: AppText.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 18,
                        top: 62,
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 23,
                            backgroundColor: AppColors.primarySoft,
                            backgroundImage: photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl.isNotEmpty
                                ? null
                                : Text(
                                    name.isNotEmpty
                                        ? name.substring(0, 1).toUpperCase()
                                        : "U",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Text("Your habits", style: AppText.h2),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.addHabit),
                    child: const Text("Add"),
                  ),
                ],
              ),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirestoreService.instance.watchHabits(uid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final habits = (snap.data ?? [])
                      .where((h) => (h['isActive'] ?? true) == true)
                      .toList();

                  if (habits.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.lightbulb_outline),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "No active habits. Tap + to add one.",
                                  style: AppText.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: habits.map((h) {
                      final habitId = h['id'] as String;
                      final title = (h['title'] ?? '').toString();
                      final emoji = (h['emoji'] ?? '✨').toString();
                      final color = (h['color'] is int)
                          ? (h['color'] as int)
                          : AppColors.primary.value;

                      return StreamBuilder<bool>(
                        stream: FirestoreService.instance.watchCompletedToday(
                          uid,
                          habitId,
                        ),
                        builder: (context, doneSnap) {
                          final done = doneSnap.data ?? false;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: HabitCard(
                              title: title,
                              subtitle: (h['frequency'] ?? 'daily').toString(),
                              emoji: emoji,
                              color: color,
                              checkedToday: done,
                              onOpen: () => Navigator.pushNamed(
                                context,
                                AppRoutes.habitDetails,
                                arguments: HabitDetailsArgs(
                                  habitId: habitId,
                                  title: title.isEmpty ? 'Habit' : title,
                                  emoji: emoji,
                                  habitType: HabitType.completionOnly,
                                  goalValue: h['targetPerDay'] is int
                                      ? h['targetPerDay'] as int
                                      : int.tryParse('${h['targetPerDay']}'),
                                ),
                              ),
                              onToggle: () => FirestoreService.instance
                                  .toggleToday(uid, habitId),
                              habit: null,
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _friendlyName(Map<String, dynamic> profile, User user) {
  final display = (profile['displayName'] ?? '').toString().trim();
  final first = (profile['firstName'] ?? '').toString().trim();
  final last = (profile['lastName'] ?? '').toString().trim();
  final altName = (profile['name'] ?? profile['fullName'] ?? '')
      .toString()
      .trim();
  final firstLegacy = (profile['first_name'] ?? '').toString().trim();
  final lastLegacy = (profile['last_name'] ?? '').toString().trim();
  final combinedLegacy = '$firstLegacy $lastLegacy'.trim();
  final combined = '$first $last'.trim();
  final authName = user.displayName?.trim() ?? '';
  final email = user.email ?? '';

  if (altName.isNotEmpty) return altName;
  if (display.isNotEmpty) return display;
  if (combined.isNotEmpty) return combined;
  if (combinedLegacy.isNotEmpty) return combinedLegacy;
  if (authName.isNotEmpty) return authName;
  if (email.isNotEmpty) return email.split('@').first;
  return 'Friend';
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

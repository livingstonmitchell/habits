import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:habits_app/routes/app_router.dart';
import 'package:habits_app/utils/theme.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  void _openCalendar(BuildContext context, DateTime date) {
    Navigator.pushNamed(
      context,
      AppRoutes.calendar,
      arguments: {'initialDate': date},
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Please login again.")),
      );
    }

    // ✅ Important: Add extra bottom padding so bars don't get hidden behind BottomNavigationBar
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final extraBottomPadding = bottomSafe + 110; // adjust if your nav is taller

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text("Progress", style: AppText.h2),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 10, 16, extraBottomPadding),
          child: Column(
            children: [
              // =========================
              // Top Summary Cards
              // =========================
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<int>(
                      stream: FirestoreService.instance.watchCompletedTodayCount(uid),
                      builder: (context, doneSnap) {
                        final done = doneSnap.data ?? 0;
                        return _StatCard(
                          title: "Completed",
                          value: "$done",
                          subtitle: "today",
                          icon: Icons.check_circle_outline,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<int>(
                      stream: FirestoreService.instance.watchActiveHabitsCount(uid),
                      builder: (context, totalSnap) {
                        final total = totalSnap.data ?? 0;
                        return _StatCard(
                          title: "Habits",
                          value: "$total",
                          subtitle: "active",
                          icon: Icons.auto_awesome_outlined,
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // =========================
              // Weekly Completion Card
              // =========================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: FutureBuilder<double>(
                  future: FirestoreService.instance.weeklyCompletionRate(uid),
                  builder: (context, snap) {
                    final rate = (snap.data ?? 0).clamp(0.0, 1.0);
                    final pct = (rate * 100).round();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("Weekly completion", style: AppText.h2),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppColors.stroke),
                              ),
                              child: Text("$pct%", style: AppText.body),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),

                        _WeekPreview(
                          onTapDay: (date) => _openCalendar(context, date),
                        ),

                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: rate,
                            minHeight: 10,
                            backgroundColor: AppColors.bg,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text("Based on last 7 days", style: AppText.muted),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // =========================
              // Week + Bars Card
              // =========================
              FutureBuilder<_WeeklyBars>(
                future: _WeeklyBars.load(uid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final data = snap.data ?? _WeeklyBars.empty();

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("This week", style: AppText.h2),
                        const SizedBox(height: 12),

                        Row(
                          children: List.generate(7, (i) {
                            final day = data.days[i];
                            final ratio = data.ratios[i];
                            return Expanded(
                              child: _MiniDay(
                                label: _weekdayLetter(day),
                                day: day.day,
                                ratio: ratio,
                                isToday: _isSameDay(day, DateTime.now()),
                                onTap: () => _openCalendar(context, day),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 14),
                        const _SoftDivider(),
                        const SizedBox(height: 12),

                        Text("Completion bars", style: AppText.muted),
                        const SizedBox(height: 10),

                        // ✅ Slightly taller chart so it looks like your design
                        SizedBox(
                          height: 190,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(7, (i) {
                              final r = data.ratios[i].clamp(0.0, 1.0);
                              final pct = (r * 100).round();

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // ✅ percent above bar (optional)
                                      Text(
                                        "$pct%",
                                        style: AppText.muted.copyWith(fontSize: 11),
                                      ),
                                      const SizedBox(height: 6),

                                      _Bar(heightFactor: r),

                                      const SizedBox(height: 10),
                                      Text(
                                        _weekdayLetter(data.days[i]),
                                        style: AppText.muted.copyWith(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
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

/// ==============================
/// Weekly bars helper (read-only queries)
/// ==============================
class _WeeklyBars {
  final List<DateTime> days;
  final List<double> ratios;

  _WeeklyBars(this.days, this.ratios);

  static _WeeklyBars empty() {
    final now = DateTime.now();
    final start = _startOfDay(now.subtract(const Duration(days: 6)));
    final days = List.generate(7, (i) => start.add(Duration(days: i)));
    return _WeeklyBars(days, List.filled(7, 0));
    }

  static Future<_WeeklyBars> load(String uid) async {
    final now = DateTime.now();
    final start = _startOfDay(now.subtract(const Duration(days: 6)));
    final days = List.generate(7, (i) => start.add(Duration(days: i)));
    final keys = days.map(_dateKey).toList();

    final habitsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('habits')
        .where('isActive', isEqualTo: true)
        .get();

    final habitCount = habitsSnap.docs.length;
    if (habitCount == 0) {
      return _WeeklyBars(days, List.filled(7, 0));
    }

    final completedPerDay = List<int>.filled(7, 0);

    for (final habit in habitsSnap.docs) {
      final logsSnap = await habit.reference
          .collection('logs')
          .where('date', whereIn: keys)
          .where('isCompleted', isEqualTo: true)
          .get();

      for (final d in logsSnap.docs) {
        final dateStr = (d.data()['date'] ?? '').toString();
        final idx = keys.indexOf(dateStr);
        if (idx >= 0) completedPerDay[idx] += 1;
      }
    }

    final ratios = List<double>.generate(7, (i) => completedPerDay[i] / habitCount);
    return _WeeklyBars(days, ratios);
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return "$y-$m-$day";
  }
}

/// ==============================
/// UI components
/// ==============================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.muted),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(value, style: AppText.h1.copyWith(fontSize: 26)),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(subtitle, style: AppText.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDay extends StatelessWidget {
  final String label;
  final int day;
  final double ratio;
  final bool isToday;
  final VoidCallback onTap;

  const _MiniDay({
    required this.label,
    required this.day,
    required this.ratio,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (ratio * 100).round();

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Column(
        children: [
          Text(label, style: AppText.muted.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isToday ? AppColors.primary : AppColors.stroke,
                width: isToday ? 1.6 : 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 40,
                  width: 40,
                  child: CircularProgressIndicator(
                    value: ratio.clamp(0.0, 1.0),
                    strokeWidth: 5,
                    backgroundColor: AppColors.bg,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                Text("$day", style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text("$pct%", style: AppText.muted.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double heightFactor; // 0..1
  const _Bar({required this.heightFactor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.stroke),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.bottomCenter,
            heightFactor: (0.12 + (heightFactor * 0.88)).clamp(0.12, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, width: double.infinity, color: AppColors.stroke);
  }
}

class _WeekPreview extends StatelessWidget {
  final void Function(DateTime date) onTapDay;
  const _WeekPreview({required this.onTapDay});

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = today.subtract(Duration(days: today.weekday - 1));
    final days = List.generate(7, (i) => DateTime(start.year, start.month, start.day + i));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: days.map((d) {
          final isToday = _sameDay(d, today);
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onTapDay(d),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isToday ? AppColors.primarySoft : AppColors.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isToday ? AppColors.primary : AppColors.stroke),
                ),
                child: Column(
                  children: [
                    Text(DateFormat('E').format(d).substring(0, 1), style: AppText.muted),
                    const SizedBox(height: 6),
                    Text("${d.day}", style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// helpers
bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _weekdayLetter(DateTime d) {
  const map = {1: "M", 2: "T", 3: "W", 4: "T", 5: "F", 6: "S", 7: "S"};
  return map[d.weekday] ?? "M";
}

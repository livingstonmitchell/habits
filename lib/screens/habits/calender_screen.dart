import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:habits_app/utils/theme.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _monthCursor = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selected = DateTime.now();

  // ---- helpers
  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return "$y-$m-$day"; // ✅ matches your service usage
  }

  int _leadingBlanksForMonth(DateTime month) {
    // Monday=1..Sunday=7
    final first = DateTime(month.year, month.month, 1);
    return first.weekday - 1; // Monday->0 ... Sunday->6
  }

  int _daysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final next = DateTime(month.year, month.month + 1, 1);
    return next.difference(first).inDays;
  }

  List<DateTime> _daysOfMonth(DateTime month) {
    final count = _daysInMonth(month);
    return List.generate(count, (i) => DateTime(month.year, month.month, i + 1));
  }
  @override
void didChangeDependencies() {
  super.didChangeDependencies();

  final args = ModalRoute.of(context)?.settings.arguments as Map?;
  final initial = args?['initialDate'];

  if (initial is DateTime) {
    setState(() {
      _selected = initial;
      _monthCursor = DateTime(initial.year, initial.month, 1);
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Please login again.")),
      );
    }

    final monthLabel = DateFormat('MMMM yyyy').format(_monthCursor);
    final blanks = _leadingBlanksForMonth(_monthCursor);
    final days = _daysOfMonth(_monthCursor);
    final totalCells = blanks + days.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text("Calendar", style: AppText.h2),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _monthCursor = DateTime(_monthCursor.year, _monthCursor.month - 1, 1);
                        });
                      },
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        monthLabel,
                        textAlign: TextAlign.center,
                        style: AppText.h2,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _monthCursor = DateTime(_monthCursor.year, _monthCursor.month + 1, 1);
                        });
                      },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Weekday labels
              Row(
                children: const ["M", "T", "W", "T", "F", "S", "S"]
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              d,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.subtext,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),

              // Calendar grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalCells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  if (index < blanks) {
                    return const SizedBox.shrink();
                  }

                  final day = days[index - blanks];
                  final selected = _sameDay(day, _selected);
                  final isToday = _sameDay(day, DateTime.now());

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _selected = day),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isToday ? AppColors.primary : AppColors.stroke,
                          width: isToday ? 1.6 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: selected ? Colors.white : AppColors.text,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Selected day header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        DateFormat('EEE, MMM d').format(_selected),
                        style: AppText.h2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.stroke),
                      ),
                      child: Text("Habits", style: AppText.body),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Load habits for selected date
              FutureBuilder<_HabitsForDayResult>(
                future: _loadHabitsForDate(uid, _selected),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 18),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final res = snap.data ?? _HabitsForDayResult.empty();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                        title: "Completed",
                        count: res.completed.length,
                      ),
                      const SizedBox(height: 8),
                      if (res.completed.isEmpty)
                        _EmptyCard(text: "No habits completed on this day.")
                      else
                        Column(
                          children: res.completed.map((h) => _HabitRow(
                            emoji: h.emoji,
                            title: h.title,
                            subtitle: h.frequency,
                            done: true,
                          )).toList(),
                        ),

                      const SizedBox(height: 14),

                      _SectionTitle(
                        title: "Not completed",
                        count: res.notCompleted.length,
                      ),
                      const SizedBox(height: 8),
                      if (res.notCompleted.isEmpty)
                        _EmptyCard(text: "Great job — everything is done 🎉")
                      else
                        Column(
                          children: res.notCompleted.map((h) => _HabitRow(
                            emoji: h.emoji,
                            title: h.title,
                            subtitle: h.frequency,
                            done: false,
                          )).toList(),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Loads habits and checks completion for a specific date.
  /// Supports BOTH:
  /// - new logs: date + isCompleted in subcollection
  /// - flat logs: dateKey + checked in habit_logs
  Future<_HabitsForDayResult> _loadHabitsForDate(String uid, DateTime date) async {
    final dateKey = _dateKey(_startOfDay(date));

    // 1) Load habits (new structure)
    final habitsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('habits')
        .where('isActive', isEqualTo: true)
        .get();

    final habits = habitsSnap.docs.map((d) {
      final data = d.data();
      return _HabitLite(
        id: d.id,
        title: (data['title'] ?? '').toString(),
        emoji: (data['emoji'] ?? '✨').toString(),
        frequency: (data['frequency'] ?? 'daily').toString(),
      );
    }).toList();

    if (habits.isEmpty) {
      return _HabitsForDayResult.empty();
    }

    // 2) For each habit, see if completed on that date
    final completed = <_HabitLite>[];
    final notCompleted = <_HabitLite>[];

    for (final h in habits) {
      bool done = false;

      // Try NEW logs first
      final newLogQ = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('habits')
          .doc(h.id)
          .collection('logs')
          .where('date', isEqualTo: dateKey)
          .limit(1)
          .get();

      if (newLogQ.docs.isNotEmpty) {
        final data = newLogQ.docs.first.data();
        done = (data['isCompleted'] == true);
      } else {
        // Fallback to FLAT logs
        final flatQ = await FirebaseFirestore.instance
            .collection('habit_logs')
            .where('userId', isEqualTo: uid)
            .where('habitId', isEqualTo: h.id)
            .where('dateKey', isEqualTo: dateKey)
            .limit(1)
            .get();

        if (flatQ.docs.isNotEmpty) {
          final data = flatQ.docs.first.data();
          done = (data['checked'] == true);
        }
      }

      if (done) {
        completed.add(h);
      } else {
        notCompleted.add(h);
      }
    }

    return _HabitsForDayResult(completed: completed, notCompleted: notCompleted);
  }
}

/// ------------ small UI widgets

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppText.h2),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Text("$count", style: AppText.muted),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.subtext),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppText.muted)),
        ],
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool done;

  const _HabitRow({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
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
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? AppColors.success : Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
}

/// ------------ data helpers

class _HabitLite {
  final String id;
  final String title;
  final String emoji;
  final String frequency;

  _HabitLite({
    required this.id,
    required this.title,
    required this.emoji,
    required this.frequency,
  });
}

class _HabitsForDayResult {
  final List<_HabitLite> completed;
  final List<_HabitLite> notCompleted;

  _HabitsForDayResult({required this.completed, required this.notCompleted});

  static _HabitsForDayResult empty() => _HabitsForDayResult(completed: [], notCompleted: []);
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../utils/streak_utils.dart';

@immutable
class HabitDetailsArgs {
  const HabitDetailsArgs({
    required this.habitId,
    required this.title,
    required this.emoji,
  });

  final String habitId;
  final String title;
  final String emoji;
}

class HabitDetailsScreen extends StatefulWidget {
  const HabitDetailsScreen({super.key, HabitDetailsArgs? args})
    : args =
          args ??
          const HabitDetailsArgs(
            habitId: 'demo-habit',
            title: 'Habit Details',
            emoji: '🔥',
          );

  /// Arguments for the habit being viewed; defaults to a demo habit when none
  /// are provided (useful for embedded tabs or previews).
  final HabitDetailsArgs args;

  @override
  State<HabitDetailsScreen> createState() => _HabitDetailsScreenState();
}

class _HabitDetailsScreenState extends State<HabitDetailsScreen> {
  final _noteController = TextEditingController();
  bool _toggling = false;

  CollectionReference<Map<String, dynamic>> get _logsRef => FirebaseFirestore
      .instance
      .collection('habits')
      .doc(widget.args.habitId)
      .collection('logs');

  Stream<List<HabitLog>> get _logStream {
    return _logsRef
        .orderBy('date', descending: true)
        .limit(60)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => HabitLog.fromSnapshot(doc)).toList(),
        );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _toggleToday(HabitLog? todayLog) async {
    final now = dateOnly(DateTime.now());
    final docRef = _logsRef.doc(dateKey(now));
    final shouldMarkComplete = !(todayLog?.completed ?? false);
    final trimmedNote = _noteController.text.trim();
    final noteToSave = trimmedNote.isEmpty ? null : trimmedNote;

    setState(() => _toggling = true);
    try {
      await docRef.set({
        'date': Timestamp.fromDate(now),
        'completed': shouldMarkComplete,
        'note': shouldMarkComplete ? noteToSave : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update today\'s log: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _toggling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HabitLog>>(
      stream: _logStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.args.title)),
            body: const Center(
              child: Text('Something went wrong loading this habit.'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final logs = snapshot.data!;
        final today = dateOnly(DateTime.now());
        final completedDays = logs
            .where((log) => log.completed)
            .map((log) => log.date)
            .toSet();
        final completedKeys = completedDays.map(dateKey).toSet();
        final streak = calculateCurrentStreak(completedDays);
        final HabitLog todayLog = logs.firstWhere(
          (log) => DateUtils.isSameDay(log.date, today),
          orElse: () => HabitLog(date: today, completed: false),
        );

        final newNoteText = todayLog.note ?? '';
        if (_noteController.text != newNoteText) {
          _noteController.text = newNoteText;
        }

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                _Header(emoji: widget.args.emoji, title: widget.args.title),
                SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 170),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 24,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _StreakCard(streak: streak),
                                const SizedBox(height: 16),
                                _RecentGrid(
                                  completedKeys: completedKeys,
                                  days: 7,
                                  title: 'Last 7 days',
                                ),
                                const SizedBox(height: 12),
                                _RecentGrid(
                                  completedKeys: completedKeys,
                                  days: 30,
                                  title: 'Last 30 days',
                                  compact: true,
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: _noteController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    labelText: "Today's note (optional)",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceVariant
                                        .withOpacity(0.3),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: _toggling
                                        ? null
                                        : () => _toggleToday(todayLog),
                                    icon: _toggling
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            todayLog.completed
                                                ? Icons.check_circle
                                                : Icons.playlist_add_check,
                                          ),
                                    label: Text(
                                      todayLog.completed
                                          ? 'Unmark today'
                                          : 'Mark today completed',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _HistoryList(logs: logs),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.emoji, required this.title});

  final String emoji;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF00B4DB), const Color(0xFF38C0D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak day${streak == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Current streak'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentGrid extends StatelessWidget {
  const _RecentGrid({
    required this.completedKeys,
    required this.days,
    required this.title,
    this.compact = false,
  });

  final Set<String> completedKeys;
  final int days;
  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final cells = List.generate(days, (index) {
      final day = today.subtract(Duration(days: days - 1 - index));
      final key = dateKey(day);
      final done = completedKeys.contains(key);
      return _DayDot(date: day, done: done, compact: compact);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: compact ? 6 : 12, runSpacing: 8, children: cells),
      ],
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.date,
    required this.done,
    required this.compact,
  });

  final DateTime date;
  final bool done;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(dateOnly(DateTime.now()), date);
    final size = compact ? 22.0 : 40.0;
    final scheme = Theme.of(context).colorScheme;
    final baseColor = _dayColor(date);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? baseColor : scheme.surfaceVariant,
            border: isToday
                ? Border.all(
                    color: done ? baseColor : scheme.secondary,
                    width: 2,
                  )
                : null,
            boxShadow: done
                ? [
                    BoxShadow(
                      color: baseColor.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: done
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : null,
        ),
        if (!compact) ...[
          const SizedBox(height: 4),
          Text(
            _weekdayLabel(date),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.logs});

  final List<HabitLog> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Text('No completions yet. Start your streak today!');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('History', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...logs.map((log) {
          final subtitle = log.note?.isNotEmpty == true ? log.note : null;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              log.completed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: log.completed
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            title: Text(_friendlyDate(log.date)),
            subtitle: subtitle != null ? Text(subtitle) : null,
            trailing: log.completed
                ? const Icon(Icons.local_fire_department)
                : const SizedBox.shrink(),
          );
        }),
      ],
    );
  }
}

class HabitLog {
  HabitLog({required this.date, required this.completed, this.note});

  final DateTime date;
  final bool completed;
  final String? note;

  factory HabitLog.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawDate = data['date'];
    DateTime parsedDate;

    if (rawDate is Timestamp) {
      parsedDate = dateOnly(rawDate.toDate());
    } else if (rawDate is DateTime) {
      parsedDate = dateOnly(rawDate);
    } else {
      try {
        parsedDate = dateOnly(DateTime.parse(doc.id));
      } catch (_) {
        parsedDate = dateOnly(DateTime.now());
      }
    }

    final note = (data['note'] as String?)?.trim();

    return HabitLog(
      date: parsedDate,
      completed: data['completed'] == true,
      note: note?.isEmpty == true ? null : note,
    );
  }
}

String _weekdayLabel(DateTime date) {
  const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  return labels[date.weekday % 7];
}

String _friendlyDate(DateTime date) {
  final today = dateOnly(DateTime.now());
  if (DateUtils.isSameDay(today, date)) return 'Today';
  if (DateUtils.isSameDay(today.subtract(const Duration(days: 1)), date)) {
    return 'Yesterday';
  }
  return '${date.month}/${date.day}/${date.year}';
}

Color _dayColor(DateTime date) {
  const palette = <Color>[
    Color(0xFFEF5350), // red
    Color(0xFFAB47BC), // purple
    Color(0xFF5C6BC0), // indigo
    Color(0xFF26A69A), // teal
    Color(0xFFFFA726), // orange
    Color(0xFF29B6F6), // light blue
    Color(0xFF66BB6A), // green
  ];
  return palette[(date.weekday - 1) % palette.length];
}

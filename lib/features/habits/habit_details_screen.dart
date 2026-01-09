import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../utils/streak_utils.dart';

/// Supported habit modes. Defaults to completion-only for backward compatibility.
enum HabitType { completionOnly, steps, duration, timesPerDay }

@immutable
class HabitDetailsArgs {
  HabitDetailsArgs({
    required this.habitId,
    required this.title,
    required this.emoji,
    this.description,
    this.habitType = HabitType.completionOnly,
    this.goalValue,
    this.unitLabel,
  });

  final String habitId;
  final String title;
  final String emoji;
  final String? description;
  final HabitType habitType;
  final int? goalValue;
  final String? unitLabel;
}

class HabitDetailsScreen extends StatefulWidget {
  HabitDetailsScreen({super.key, HabitDetailsArgs? args})
    : args =
          args ??
          HabitDetailsArgs(
            habitId: 'demo-habit',
            title: 'Habit Details',
            emoji: '🔥',
            habitType: HabitType.completionOnly,
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

  HabitType get _habitType => widget.args.habitType ?? HabitType.completionOnly;
  bool get _isCompletionOnly => _habitType == HabitType.completionOnly;
  int? get _goalValue => widget.args.goalValue;
  String get _unitLabel =>
      widget.args.unitLabel ?? _defaultUnitLabel(_habitType);

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
    if (!_isCompletionOnly) {
      await _promptProgressDialog(todayLog);
      return;
    }

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

  Future<void> _promptProgressDialog(HabitLog? todayLog) async {
    final amountController = TextEditingController(
      text: todayLog?.progress?.toString() ?? '',
    );
    final noteController = TextEditingController(text: _noteController.text);

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Log progress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount to add',
                  helperText: _goalValue != null
                      ? 'Goal: ${_goalValue} $_unitLabel'
                      : 'No goal set',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'Add a quick note',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(amountController.text.trim());
                if (value == null || value < 0) {
                  Navigator.pop<int>(context, null);
                } else {
                  _noteController.text = noteController.text;
                  Navigator.pop<int>(context, value);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    amountController.dispose();
    noteController.dispose();
    if (result == null) return;
    await _saveProgress(todayLog, addedAmount: result);
  }

  Future<void> _saveProgress(
    HabitLog? todayLog, {
    required int addedAmount,
  }) async {
    final now = dateOnly(DateTime.now());
    final docRef = _logsRef.doc(dateKey(now));
    final currentProgress = todayLog?.progress ?? 0;
    final total = (currentProgress + addedAmount).clamp(0, 1 << 31);
    final goal = _goalValue ?? 1; // default to 1 so streaks still work
    final meetsGoal = total >= goal;
    final trimmedNote = _noteController.text.trim();
    final noteToSave = trimmedNote.isEmpty ? null : trimmedNote;

    setState(() => _toggling = true);
    try {
      await docRef.set({
        'date': Timestamp.fromDate(now),
        'completed': meetsGoal,
        'progress': total,
        'goal': _goalValue,
        'habitType': widget.args.habitType.name,
        'note': noteToSave,
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
            body: Center(
              child: Text('Something went wrong loading this habit.'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final logs = snapshot.data!;
        final today = dateOnly(DateTime.now());
        final completedDays = logs
            .where((log) => log.isCompleted)
            .map((log) => log.date)
            .toSet();
        final completedKeys = completedDays.map(dateKey).toSet();
        final streak = calculateCurrentStreak(completedDays);
        final HabitLog todayLog = logs.firstWhere(
          (log) => DateUtils.isSameDay(log.date, today),
          orElse: () => HabitLog(
            date: today,
            completed: false,
            goalValue: _goalValue,
            habitType: widget.args.habitType,
          ),
        );

        final todayProgress = todayLog.progress ?? 0;
        final goalValue = _goalValue;

        final newNoteText = todayLog.note ?? '';
        if (_noteController.text != newNoteText) {
          _noteController.text = newNoteText;
        }

        return Container(
          decoration: BoxDecoration(
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
                      SizedBox(height: 170),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 24,
                                offset: Offset(0, -4),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(16, 24, 16, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!_isCompletionOnly) ...[
                                  _GoalCard(
                                    progress: todayProgress,
                                    goal: goalValue,
                                    unitLabel: _unitLabel,
                                    habitType: _habitType,
                                  ),
                                  SizedBox(height: 12),
                                ],
                                _StreakCard(streak: streak),
                                SizedBox(height: 16),
                                _RecentGrid(
                                  completedKeys: completedKeys,
                                  days: 7,
                                  title: 'Last 7 days',
                                  highlight: true,
                                ),
                                SizedBox(height: 12),
                                _RecentGrid(
                                  completedKeys: completedKeys,
                                  days: 30,
                                  title: 'Last 30 days',
                                  compact: true,
                                ),
                                SizedBox(height: 20),
                                _NoteCard(controller: _noteController),
                                SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
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
                                        ? SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            _isCompletionOnly
                                                ? (todayLog.isCompleted
                                                      ? Icons.check_circle
                                                      : Icons
                                                            .playlist_add_check)
                                                : Icons.edit,
                                          ),
                                    label: Text(
                                      _isCompletionOnly
                                          ? (todayLog.isCompleted
                                                ? 'Unmark today'
                                                : 'Mark today completed')
                                          : 'Log progress',
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                _HistoryList(
                                  logs: logs,
                                  habitArgs: widget.args,
                                ),
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
                    icon: Icon(Icons.arrow_back),
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

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

HabitType? _habitTypeFromString(dynamic value) {
  if (value is String) {
    return HabitType.values
        .where((t) => t.name.toLowerCase() == value.toLowerCase())
        .cast<HabitType?>()
        .firstWhere((_) => true, orElse: () => null);
  }
  return null;
}

String? _progressSummary(HabitLog log, HabitDetailsArgs args) {
  if (args.habitType == HabitType.completionOnly) return null;
  final unit = args.unitLabel ?? _defaultUnitLabel(args.habitType);
  final goal = log.goalValue ?? args.goalValue;
  final progress = log.progress ?? (log.isCompleted ? goal : null);
  if (progress == null && goal == null) return null;

  if (goal != null && goal > 0 && progress != null) {
    final unitText = unit.isNotEmpty ? ' $unit' : '';
    return '$progress / $goal$unitText';
  }

  if (progress != null) {
    final unitText = unit.isNotEmpty ? ' $unit' : '';
    return '$progress$unitText logged';
  }

  return null;
}

class _Header extends StatefulWidget {
  const _Header({required this.emoji, required this.title});

  final String emoji;
  final String title;

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _scale = Tween<double>(
      begin: 0.85,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
        padding: EdgeInsets.fromLTRB(24, 48, 24, 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(width: 8),

            ScaleTransition(
              scale: _scale,
              child: Text(widget.emoji, style: TextStyle(fontSize: 70)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  _GoalCard({
    required this.progress,
    required this.goal,
    required this.unitLabel,
    required this.habitType,
  });

  final int progress;
  final int? goal;
  final String unitLabel;
  final HabitType habitType;

  @override
  Widget build(BuildContext context) {
    final labelUnit = unitLabel.trim().isEmpty ? '' : ' $unitLabel';
    final target = goal ?? 0;
    final fraction = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;
    final percentText = target > 0 ? '${(fraction * 100).round()}%' : '—';
    final goalText = target > 0
        ? '$progress / $target$labelUnit'
        : '$progress$labelUnit logged';

    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 10,
      shadowColor: scheme.primary.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              scheme.primaryContainer.withOpacity(0.45),
              scheme.primaryContainer.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: scheme.primary.withOpacity(0.2)),
        ),
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            _ProgressRing(
              fraction: target > 0 ? fraction : null,
              percentText: percentText,
              primary: scheme.primary,
              onPrimary: scheme.onPrimary,
              track: scheme.primary.withOpacity(0.12),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.flag,
                          size: 18,
                          color: scheme.primary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Goal',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Spacer(),
                      Text(
                        habitType.name,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(goalText, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.fraction,
    required this.percentText,
    required this.primary,
    required this.onPrimary,
    required this.track,
  });

  final double? fraction;
  final String percentText;
  final Color primary;
  final Color onPrimary;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      width: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: fraction,
            strokeWidth: 8,
            backgroundColor: track,
            valueColor: AlwaysStoppedAnimation<Color>(primary),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.75),
            ),
            child: Text(
              percentText,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  _StreakCard({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 10,
      shadowColor: scheme.primary.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              scheme.primary.withOpacity(0.18),
              scheme.secondary.withOpacity(0.14),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: scheme.primary.withOpacity(0.25)),
        ),
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.local_fire_department,
                size: 28,
                color: scheme.primary,
              ),
            ),
            SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak day${streak == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Current streak',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentGrid extends StatelessWidget {
  _RecentGrid({
    required this.completedKeys,
    required this.days,
    required this.title,
    this.compact = false,
    this.highlight = false,
  });

  final Set<String> completedKeys;
  final int days;
  final String title;
  final bool compact;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    int completedCount = 0;
    final cells = List.generate(days, (index) {
      final day = today.subtract(Duration(days: days - 1 - index));
      final key = dateKey(day);
      final done = completedKeys.contains(key);
      if (done) completedCount++;
      return _DayDot(date: day, done: done, compact: compact);
    });

    if (highlight && days == 7) {
      return _WeekStrip(
        title: title,
        completedCount: completedCount,
        days: days,
        cells: List.generate(days, (index) {
          final day = today.subtract(Duration(days: days - 1 - index));
          final key = dateKey(day);
          final done = completedKeys.contains(key);
          final isToday = DateUtils.isSameDay(day, today);
          return _WeekTile(date: day, done: done, isToday: isToday);
        }),
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (highlight)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$completedCount/$days done',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(spacing: compact ? 6 : 12, runSpacing: 8, children: cells),
      ],
    );

    if (!highlight) return content;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F7FA), Color(0xFFF1F8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: content,
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.title,
    required this.completedCount,
    required this.days,
    required this.cells,
  });

  final String title;
  final int completedCount;
  final int days;
  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chipColor = scheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.primaryContainer.withOpacity(0.26),
        border: Border.all(color: scheme.primary.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: chipColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: chipColor.withOpacity(0.4)),
                ),
                child: Text(
                  '$completedCount/$days done',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: chipColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: cells
                .map(
                  (w) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: w,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _WeekTile extends StatelessWidget {
  const _WeekTile({
    required this.date,
    required this.done,
    required this.isToday,
  });

  final DateTime date;
  final bool done;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseTextColor = isToday
        ? scheme.onPrimary
        : done
        ? scheme.onPrimaryContainer
        : scheme.onSurface;
    final borderColor = isToday
        ? scheme.primary
        : done
        ? scheme.primary
        : scheme.outline;
    final background = isToday
        ? scheme.primary
        : done
        ? scheme.primaryContainer.withOpacity(0.35)
        : scheme.surface;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${date.day}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: baseTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _weekdayLabel(date),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: baseTextColor.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 6,
      shadowColor: scheme.primary.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              scheme.surfaceVariant.withOpacity(0.35),
              scheme.surface.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: scheme.outline.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.note_alt_outlined,
                    size: 18,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Today's note",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  'Optional',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceVariant.withOpacity(0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: controller,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Add a quick note for today...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  _DayDot({required this.date, required this.done, required this.compact});

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
          duration: Duration(milliseconds: 180),
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
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: done ? Icon(Icons.check, size: 18, color: Colors.white) : null,
        ),
        if (!compact) ...[
          SizedBox(height: 4),
          Text(
            _weekdayLabel(date),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _HistoryList extends StatefulWidget {
  _HistoryList({required this.logs, required this.habitArgs});

  final List<HabitLog> logs;
  final HabitDetailsArgs habitArgs;

  @override
  State<_HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<_HistoryList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final logs = widget.logs;

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void showDetails(HabitLog log) {
      final progressLine = _progressSummary(log, widget.habitArgs) ?? '—';
      final status = log.isCompleted ? 'Done' : 'Pending';
      final noteController = TextEditingController(
        text: (log.note?.isNotEmpty ?? false) ? log.note! : '',
      );
      bool saving = false;

      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> saveNote() async {
                final trimmed = noteController.text.trim();
                setSheetState(() => saving = true);
                try {
                  final docRef = FirebaseFirestore.instance
                      .collection('habits')
                      .doc(widget.habitArgs.habitId)
                      .collection('logs')
                      .doc(dateKey(log.date));
                  await docRef.set({
                    'note': trimmed.isEmpty ? null : trimmed,
                    'updatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Note saved')));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not save note: $e')),
                    );
                  }
                } finally {
                  setSheetState(() => saving = false);
                }
              }

              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _friendlyDate(log.date),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          label: Text(status),
                          backgroundColor: log.isCompleted
                              ? scheme.primary.withOpacity(0.15)
                              : scheme.outlineVariant.withOpacity(0.3),
                        ),
                        const SizedBox(width: 10),
                        Chip(
                          label: Text('Progress: $progressLine'),
                          backgroundColor: scheme.secondaryContainer
                              .withOpacity(0.25),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Note',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Add a note for this day...',
                        filled: true,
                        fillColor: scheme.surfaceVariant.withOpacity(0.25),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: saving ? null : saveNote,
                        icon: saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Save note'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    Widget cell(
      String text, {
      bool header = false,
      TextAlign align = TextAlign.left,
      int maxLines = 2,
      TextOverflow overflow = TextOverflow.ellipsis,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Text(
          text,
          textAlign: align,
          maxLines: maxLines,
          overflow: overflow,
          style: header
              ? textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                )
              : textTheme.bodyMedium,
        ),
      );
    }

    Widget tapCell(
      String text,
      HabitLog log, {
      TextAlign align = TextAlign.left,
    }) {
      return InkWell(
        onTap: () => showDetails(log),
        child: cell(text, align: align),
      );
    }

    final rows = <TableRow>[
      TableRow(
        children: [
          cell('Date', header: true),
          cell('Status', header: true),
          cell('Progress', header: true, align: TextAlign.center),
          cell('Note', header: true),
        ],
      ),
    ];

    for (final log in logs) {
      final progressLine = _progressSummary(log, widget.habitArgs) ?? '—';
      final status = log.isCompleted ? 'Done' : 'Pending';
      final note = (log.note?.isNotEmpty ?? false) ? log.note! : '—';
      rows.add(
        TableRow(
          children: [
            tapCell(_friendlyDate(log.date), log),
            tapCell(status, log),
            tapCell(progressLine, log, align: TextAlign.center),
            tapCell(note, log),
          ],
        ),
      );
    }

    final tableCard = Card(
      elevation: 6,
      shadowColor: scheme.primary.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              scheme.surfaceVariant.withOpacity(0.25),
              scheme.surface.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: scheme.outline.withOpacity(0.18)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 520),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FixedColumnWidth(110),
                1: FixedColumnWidth(90),
                2: FixedColumnWidth(110),
                3: FixedColumnWidth(180),
              },
              border: TableBorder.symmetric(
                inside: BorderSide(
                  color: scheme.outlineVariant.withOpacity(0.4),
                  width: 0.6,
                ),
              ),
              children: rows,
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Text(
                'History',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 20),
            ],
          ),
        ),
        if (_expanded && logs.isEmpty) ...[
          const SizedBox(height: 8),
          Text('No completions yet. Start your streak today!'),
        ],
        if (_expanded && logs.isNotEmpty) ...[
          const SizedBox(height: 8),
          tableCard,
        ],
      ],
    );
  }
}

class HabitLog {
  HabitLog({
    required this.date,
    required this.completed,
    this.note,
    this.progress,
    this.goalValue,
    this.habitType,
  });

  final DateTime date;
  final bool completed;
  final String? note;
  final int? progress;
  final int? goalValue;
  final HabitType? habitType;

  /// Considers goal-based completion for streaks and history while keeping
  /// legacy boolean `completed` backward compatible.
  bool get isCompleted {
    final target = goalValue;
    if (target != null && target > 0) {
      return (progress ?? 0) >= target || completed;
    }
    return completed;
  }

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
    final progress = _asInt(data['progress']);
    final goal = _asInt(data['goal'] ?? data['goalValue']);
    final type = _habitTypeFromString(data['habitType']);

    return HabitLog(
      date: parsedDate,
      completed: data['completed'] == true,
      note: note?.isEmpty == true ? null : note,
      progress: progress,
      goalValue: goal,
      habitType: type,
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

String _defaultUnitLabel(HabitType type) {
  switch (type) {
    case HabitType.steps:
      return 'steps';
    case HabitType.duration:
      return 'minutes';
    case HabitType.timesPerDay:
      return 'times';
    case HabitType.completionOnly:
    default:
      return '';
  }
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

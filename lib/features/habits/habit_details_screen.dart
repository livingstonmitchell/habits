import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../utils/streak_utils.dart';
import 'habit_models.dart';
import 'habit_detail_helpers/goal_card.dart';
import 'habit_detail_helpers/header.dart';
import 'habit_detail_helpers/helpers.dart';
import 'habit_detail_helpers/history_list.dart';
import 'habit_detail_helpers/model.dart';
import 'habit_detail_helpers/note_card.dart';
import 'habit_detail_helpers/recent_grid.dart';
import 'habit_detail_helpers/streak_card.dart';

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

  HabitType get _habitType => widget.args.habitType;
  bool get _isCompletionOnly => _habitType == HabitType.completionOnly;
  int? get _goalValue => widget.args.goalValue;
  String get _unitLabel =>
      widget.args.unitLabel ?? defaultUnitLabel(_habitType);

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
                HabitHeader(
                  emoji: widget.args.emoji,
                  title: widget.args.title,
                ),
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
                                  HabitGoalCard(
                                    progress: todayProgress,
                                    goal: goalValue,
                                    unitLabel: _unitLabel,
                                    habitType: _habitType,
                                  ),
                                  SizedBox(height: 12),
                                ],
                                HabitStreakCard(streak: streak),
                                SizedBox(height: 16),
                                HabitRecentGrid(
                                  completedKeys: completedKeys,
                                  days: 7,
                                  title: 'Last 7 days',
                                  highlight: true,
                                ),
                                SizedBox(height: 12),
                                HabitRecentGrid(
                                  completedKeys: completedKeys,
                                  days: 30,
                                  title: 'Last 30 days',
                                  compact: true,
                                ),
                                SizedBox(height: 20),
                                HabitNoteCard(controller: _noteController),
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
                                HabitHistoryList(
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

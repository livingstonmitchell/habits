import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:habits_app/utils/theme.dart';
import 'package:habits_app/utils/widgets/appbutton.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/streak_utils.dart';
import '../../models/habit_models.dart';
import '../../features/habits/habit_detail_helpers/goal_card.dart';
import '../../features/habits/habit_detail_helpers/helpers.dart';
import '../../features/habits/habit_detail_helpers/history_list.dart';
import '../../features/habits/habit_detail_helpers/model.dart';
import '../../features/habits/habit_detail_helpers/note_card.dart';
import '../../features/habits/habit_detail_helpers/recent_grid.dart';
import '../../features/habits/habit_detail_helpers/streak_card.dart';

class HabitDetailsScreen extends StatefulWidget {
  final HabitDetailsArgs args;

  HabitDetailsScreen({super.key, HabitDetailsArgs? args})
    : args =
          args ??
          HabitDetailsArgs(
            habitId: 'demo-habit',
            title: 'Habit Details',
            emoji: '🔥',
            habitType: HabitType.completionOnly,
          );

  @override
  State<HabitDetailsScreen> createState() => _HabitDetailsScreenState();
}

class _HabitDetailsScreenState extends State<HabitDetailsScreen> {
  final _noteController = TextEditingController();
  bool _toggling = false;

  String? get _uid => AuthService.instance.currentUser?.uid;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _toggleToday({
    required HabitLog todayLog,
    required HabitType type,
    required int goal,
    required String unitLabel,
  }) async {
    if (type != HabitType.completionOnly) {
      await _promptProgressDialog(
        todayLog: todayLog,
        goal: goal,
        unitLabel: unitLabel,
        type: type,
      );
      return;
    }

    final uid = _uid;
    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in again.')));
      return;
    }

    final todayKey = dateKey(dateOnly(DateTime.now()));
    final shouldMarkComplete = !todayLog.isCompleted;
    final trimmedNote = _noteController.text.trim();
    final noteToSave = trimmedNote.isEmpty ? null : trimmedNote;

    setState(() => _toggling = true);
    try {
      final payload = <String, dynamic>{
        'date': todayKey,
        'completed': shouldMarkComplete,
        'progress': null,
        'goal': null,
        'habitType': HabitType.completionOnly.name,
        'note': shouldMarkComplete ? noteToSave : null,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (shouldMarkComplete && noteToSave != null) {
        payload['notes'] = FieldValue.arrayUnion([noteToSave]);
      }

      await FirestoreService.instance.updateHabitLog(
        uid,
        widget.args.habitId,
        todayKey,
        payload,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update today\'s log: $e')),
      );
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _promptProgressDialog({
    required HabitLog todayLog,
    required int goal,
    required String unitLabel,
    required HabitType type,
  }) async {
    final amountController = TextEditingController(
      text: todayLog.progress?.toString() ?? '',
    );
    final noteController = TextEditingController(text: _noteController.text);

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log progress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount to add',
                  helperText: goal > 0
                      ? 'Goal: $goal $unitLabel'
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
              child: const Text('Cancel'),
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
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    amountController.dispose();
    noteController.dispose();

    if (result == null) return;
    await _saveProgress(
      todayLog: todayLog,
      addedAmount: result,
      goal: goal,
      type: type,
      unitLabel: unitLabel,
    );
  }

  Future<void> _saveProgress({
    required HabitLog todayLog,
    required int addedAmount,
    required int goal,
    required HabitType type,
    required String unitLabel,
  }) async {
    final uid = _uid;
    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in again.')));
      return;
    }

    final todayKey = dateKey(dateOnly(DateTime.now()));
    final currentProgress = todayLog.progress ?? 0;
    final total = (currentProgress + addedAmount).clamp(0, 1 << 31);
    final effectiveGoal = goal <= 0 ? 1 : goal;
    final meetsGoal = total >= effectiveGoal;
    final trimmedNote = _noteController.text.trim();
    final noteToSave = trimmedNote.isEmpty ? null : trimmedNote;

    setState(() => _toggling = true);
    try {
      final payload = <String, dynamic>{
        'date': todayKey,
        'completed': meetsGoal,
        'progress': total,
        'goal': goal,
        'goalValue': goal,
        'habitType': type.name,
        'note': noteToSave,
        'unitLabel': unitLabel,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (noteToSave != null) {
        payload['notes'] = FieldValue.arrayUnion([noteToSave]);
      }

      payload['entries'] = FieldValue.arrayUnion([
        {
          'added': addedAmount,
          'total': total,
          'goal': goal,
          'note': noteToSave,
          'timestamp': Timestamp.now(),
        },
      ]);

      await FirestoreService.instance.updateHabitLog(
        uid,
        widget.args.habitId,
        todayKey,
        payload,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update today\'s log: $e')),
      );
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null)
      return const Scaffold(body: Center(child: Text("Sign in required")));

    return StreamBuilder<Map<String, dynamic>?>(
      stream: FirestoreService.instance.watchHabit(uid, widget.args.habitId),
      builder: (context, habitSnap) {
        final data = habitSnap.data;
        final hType =
            _habitTypeFromValue(data?['habitType']) ?? widget.args.habitType;
        final hGoal =
            _intFromValue(data?['goalValue']) ?? widget.args.goalValue ?? 1;
        final hUnit = data?['unitLabel'] ?? widget.args.unitLabel ?? 'times';

        return StreamBuilder<List<HabitLog>>(
          stream: FirestoreService.instance.watchHabitLogs(
            uid,
            widget.args.habitId,
          ),
          builder: (context, logSnap) {
            if (!logSnap.hasData)
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );

            final logs = logSnap.data!;
            final todayKey = dateKey(dateOnly(DateTime.now()));
            final todayLog = logs.firstWhere(
              (l) => dateKey(l.date) == todayKey,
              orElse: () => HabitLog(date: DateTime.now(), completed: false),
            );

            final newNoteText = todayLog.note ?? '';
            if (_noteController.text != newNoteText) {
              _noteController.text = newNoteText;
            }

            final streak = calculateCurrentStreak(
              logs.where((l) => l.isCompleted).map((l) => l.date).toSet(),
            );

            return Scaffold(
              body: Stack(
                children: [
                  CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildAppBar(
                        data?['title'] ?? widget.args.title,
                        data?['emoji'] ?? widget.args.emoji,
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 150),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (hType != HabitType.completionOnly)
                              HabitGoalCard(
                                progress: todayLog.progress ?? 0,
                                goal: hGoal,
                                unitLabel: hUnit,
                                habitType: hType,
                              ),
                            const SizedBox(height: 12),
                            HabitStreakCard(streak: streak),
                            const SizedBox(height: 24),
                            HabitRecentGrid(
                              completedKeys: logs
                                  .where((l) => l.isCompleted)
                                  .map((l) => dateKey(l.date))
                                  .toSet(),
                              days: 30,
                              title: 'Consistency Tracker',
                            ),
                            const SizedBox(height: 24),
                            HabitNoteCard(controller: _noteController),
                            const SizedBox(height: 24),
                            HabitHistoryList(
                              logs: logs,
                              habitArgs: widget.args,
                              uid: uid,
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                  _buildFloatingAction(todayLog, hType, hGoal, hUnit),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAppBar(String title, String emoji) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        background: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 50)),
        ),
      ),
    );
  }

  Widget _buildFloatingAction(
    HabitLog todayLog,
    HabitType type,
    int goal,
    String unit,
  ) {
    final isDone = todayLog.isCompleted;
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: AppButton(
        text: _toggling
            ? "Updating..."
            : (isDone ? "Completed Today" : "Log Progress"),
        color: isDone ? Colors.green : AppColors.primary,
        onTap: _toggling
            ? null
            : () => _toggleToday(
                todayLog: todayLog,
                type: type,
                goal: goal,
                unitLabel: unit,
              ),
      ),
    );
  }
}

HabitType? _habitTypeFromValue(dynamic v) {
  if (v == 'completionOnly' || v == HabitType.completionOnly)
    return HabitType.completionOnly;
  return HabitType.count;
}

int? _intFromValue(dynamic v) =>
    v is int ? v : int.tryParse(v?.toString() ?? '');

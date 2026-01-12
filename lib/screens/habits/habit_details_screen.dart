import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:habits_app/utils/theme.dart';
import 'package:habits_app/utils/widgets/appbutton.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/streak_utils.dart';
import '../../models/habit_models.dart';
import '../../features/habits/habit_detail_helpers/goal_card.dart';
import '../../features/habits/habit_detail_helpers/history_list.dart';
import '../../features/habits/habit_detail_helpers/model.dart';
import '../../features/habits/habit_detail_helpers/note_card.dart';
import '../../features/habits/habit_detail_helpers/recent_grid.dart';
import '../../features/habits/habit_detail_helpers/streak_card.dart';

// ✅ meditation session screen
import '../meditation/meditation_session_screen.dart';

class HabitDetailsScreen extends StatefulWidget {
  final HabitDetailsArgs args;

  HabitDetailsScreen({super.key, HabitDetailsArgs? args})
      : args = args ??
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

  // =========================
  // ✅ DELETE HABIT
  // =========================
  Future<void> _confirmAndDeleteHabit({
    required String uid,
    required String habitId,
    required String title,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete habit?"),
        content: Text(
          "This will delete \"$title\" and all its logs.\n\nThis can’t be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await FirestoreService.instance.deleteHabit(uid, habitId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Habit deleted")),
      );

      Navigator.pop(context); // go back after delete
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete habit: $e")),
      );
    }
  }

  bool _isMeditationHabit({
    required String title,
    required String emoji,
    required HabitType type,
  }) {
    final t = title.toLowerCase();
    return t.contains("meditat") || emoji.contains("🧘");
  }

  Future<void> _openMeditationOptions({
    required String habitTitle,
    required String habitEmoji,
  }) async {
    bool quotes = true;
    bool music = false;

    final result = await showModalBottomSheet<Map<String, bool>>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 5,
                      width: 44,
                      decoration: BoxDecoration(
                        color: AppColors.stroke,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text("Meditation session", style: AppText.h2),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.stroke),
                      ),
                      child: Row(
                        children: [
                          Text(habitEmoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              habitTitle,
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: quotes,
                      onChanged: (v) => setSheet(() => quotes = v),
                      title: const Text("Quotes"),
                      subtitle: const Text("Show mindful quotes while you meditate"),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: music,
                      onChanged: (v) => setSheet(() => music = v),
                      title: const Text("Music"),
                      subtitle: const Text("Play calm music while meditating (UI only)"),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          if (!quotes && !music) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Choose Quotes or Music to continue."),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context, {"quotes": quotes, "music": music});
                        },
                        child: const Text(
                          "Start session",
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeditationSessionScreen(
          title: habitTitle,
          emoji: habitEmoji,
          quotesEnabled: result["quotes"] == true,
          musicEnabled: result["music"] == true,
          onFinish: () async {
            // optional
          },
        ),
      ),
    );
  }

  Future<void> _toggleToday({
    required HabitLog todayLog,
    required HabitType type,
    required int goal,
    required String unitLabel,
    required String habitTitle,
    required String habitEmoji,
  }) async {
    if (_isMeditationHabit(title: habitTitle, emoji: habitEmoji, type: type)) {
      await _openMeditationOptions(habitTitle: habitTitle, habitEmoji: habitEmoji);
      return;
    }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again.')),
      );
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
                  helperText: goal > 0 ? 'Goal: $goal $unitLabel' : 'No goal set',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again.')),
      );
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
    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Sign in required")));
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: FirestoreService.instance.watchHabit(uid, widget.args.habitId),
      builder: (context, habitSnap) {
        final data = habitSnap.data;

        // If habit was deleted, watchHabit will become null — show message + go back.
        if (habitSnap.connectionState == ConnectionState.active && data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Habit deleted")),
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Go back"),
              ),
            ),
          );
        }

        final title = (data?['title'] ?? widget.args.title).toString();
        final emoji = (data?['emoji'] ?? widget.args.emoji).toString();

        final hType = _habitTypeFromValue(data?['habitType']) ?? widget.args.habitType;
        final hGoal = _intFromValue(data?['goalValue']) ?? widget.args.goalValue ?? 1;
        final hUnit = (data?['unitLabel'] ?? widget.args.unitLabel ?? 'times').toString();

        return StreamBuilder<List<HabitLog>>(
          stream: FirestoreService.instance.watchHabitLogs(uid, widget.args.habitId),
          builder: (context, logSnap) {
            if (!logSnap.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

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
                        title: title,
                        emoji: emoji,
                        onDelete: () => _confirmAndDeleteHabit(
                          uid: uid,
                          habitId: widget.args.habitId,
                          title: title,
                        ),
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
                  _buildFloatingAction(todayLog, hType, hGoal, hUnit, title, emoji),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ✅ UPDATED AppBar with delete icon
  Widget _buildAppBar({
    required String title,
    required String emoji,
    required VoidCallback onDelete,
  }) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primary,
      actions: [
        IconButton(
          tooltip: "Delete habit",
          onPressed: _toggling ? null : onDelete,
          icon: const Icon(Icons.delete_outline, color: Colors.white),
        ),
      ],
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
    String habitTitle,
    String habitEmoji,
  ) {
    final isDone = todayLog.isCompleted;

    final isMeditation = _isMeditationHabit(
      title: habitTitle,
      emoji: habitEmoji,
      type: type,
    );

    final label = _toggling
        ? "Updating..."
        : (isMeditation
            ? "Start Meditation"
            : (isDone ? "Completed Today" : "Log Progress"));

    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: AppButton(
        text: label,
        color: isDone ? Colors.green : AppColors.primary,
        onTap: _toggling
            ? null
            : () => _toggleToday(
                  todayLog: todayLog,
                  type: type,
                  goal: goal,
                  unitLabel: unit,
                  habitTitle: habitTitle,
                  habitEmoji: habitEmoji,
                ),
      ),
    );
  }
}

/// ✅ robust habit type parsing
HabitType? _habitTypeFromValue(dynamic v) {
  if (v == null) return null;

  if (v is HabitType) return v;

  final s = v.toString().trim();
  for (final t in HabitType.values) {
    if (t.name == s) return t;
    if (t.name.toLowerCase() == s.toLowerCase()) return t;
  }
  return null;
}

int? _intFromValue(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');

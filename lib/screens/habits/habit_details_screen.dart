// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// import '../../services/auth_service.dart';
// import '../../services/firestore_service.dart';
// import '../../utils/streak_utils.dart';
// import '../../models/habit_models.dart';
// import '../../features/habits/habit_detail_helpers/goal_card.dart';
// import '../../features/habits/habit_detail_helpers/header.dart';
// import '../../features/habits/habit_detail_helpers/helpers.dart';
// import '../../features/habits/habit_detail_helpers/history_list.dart';
// import '../../features/habits/habit_detail_helpers/model.dart';
// import '../../features/habits/habit_detail_helpers/note_card.dart';
// import '../../features/habits/habit_detail_helpers/recent_grid.dart';
// import '../../features/habits/habit_detail_helpers/streak_card.dart';

// class HabitDetailsScreen extends StatefulWidget {
//   HabitDetailsScreen({super.key, HabitDetailsArgs? args})
//     : args =
//           args ??
//           HabitDetailsArgs(
//             habitId: 'demo-habit',
//             title: 'Habit Details',
//             emoji: '🔥',
//             habitType: HabitType.completionOnly,
//           );

//   /// Arguments for the habit being viewed; defaults to a demo habit when none
//   /// are provided (useful for embedded tabs or previews).
//   final HabitDetailsArgs args;

//   @override
//   State<HabitDetailsScreen> createState() => _HabitDetailsScreenState();
// }

// HabitType? _habitTypeFromValue(dynamic value) {
//   if (value is HabitType) return value;
//   if (value is String) {
//     final lower = value.toLowerCase();
//     for (final type in HabitType.values) {
//       if (type.name.toLowerCase() == lower) return type;
//     }
//   }
//   return null;
// }

// int? _intFromValue(dynamic value) {
//   if (value is int) return value;
//   if (value is double) return value.toInt();
//   if (value is String) return int.tryParse(value);
//   return null;
// }

// class _HabitDetailsScreenState extends State<HabitDetailsScreen> {
//   final _noteController = TextEditingController();
//   bool _toggling = false;

//   HabitType? _resolvedHabitType;
//   int? _resolvedGoalValue;
//   String? _resolvedUnitLabel;

//   HabitType get _habitType => _resolvedHabitType ?? widget.args.habitType;
//   bool get _isCompletionOnly => _habitType == HabitType.completionOnly;
//   int? get _goalValue => _resolvedGoalValue ?? widget.args.goalValue;
//   String get _unitLabel =>
//       _resolvedUnitLabel ?? widget.args.unitLabel ?? defaultUnitLabel(_habitType);

//   String? get _uid => AuthService.instance.currentUser?.uid;

//   CollectionReference<Map<String, dynamic>>? get _logsRef {
//     final uid = _uid;
//     if (uid == null) return null;
//     return FirebaseFirestore.instance
//         .collection('users')
//         .doc(uid)
//         .collection('habits')
//         .doc(widget.args.habitId)
//         .collection('logs');
//   }

//   Stream<List<HabitLog>>? get _logStream {
//     final ref = _logsRef;
//     if (ref == null) return null;
//     return ref
//         .orderBy('date', descending: true)
//         .limit(60)
//         .snapshots()
//         .map(
//           (snapshot) =>
//               snapshot.docs.map((doc) => HabitLog.fromSnapshot(doc)).toList(),
//         );
//   }

//   @override
//   void dispose() {
//     _noteController.dispose();
//     super.dispose();
//   }

//   Future<void> _toggleToday(HabitLog? todayLog) async {
//     if (!_isCompletionOnly) {
//       await _promptProgressDialog(todayLog);
//       return;
//     }

//     final now = dateOnly(DateTime.now());
//     final ref = _logsRef;
//     if (ref == null) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please sign in again.')),
//         );
//       }
//       return;
//     }
//     final todayKey = dateKey(now);
//     final docRef = ref.doc(todayKey);
//     final shouldMarkComplete = !(todayLog?.completed ?? false);
//     final trimmedNote = _noteController.text.trim();
//     final noteToSave = trimmedNote.isEmpty ? null : trimmedNote;

//     setState(() => _toggling = true);
//     try {
//       await docRef.set({
//         'date': todayKey,
//         'completed': shouldMarkComplete,
//         'note': shouldMarkComplete ? noteToSave : null,
//         'updatedAt': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Could not update today\'s log: $e')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _toggling = false);
//       }
//     }
//   }

//   Future<void> _promptProgressDialog(HabitLog? todayLog) async {
//     final amountController = TextEditingController(
//       text: todayLog?.progress?.toString() ?? '',
//     );
//     final noteController = TextEditingController(text: _noteController.text);

//     final result = await showDialog<int>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Log progress'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: amountController,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(
//                   labelText: 'Amount to add',
//                   helperText: _goalValue != null
//                       ? 'Goal: ${_goalValue} $_unitLabel'
//                       : 'No goal set',
//                 ),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: noteController,
//                 minLines: 2,
//                 maxLines: 3,
//                 decoration: const InputDecoration(
//                   labelText: 'Note',
//                   hintText: 'Add a quick note',
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('Cancel'),
//             ),
//             FilledButton(
//               onPressed: () {
//                 final value = int.tryParse(amountController.text.trim());
//                 if (value == null || value < 0) {
//                   Navigator.pop<int>(context, null);
//                 } else {
//                   _noteController.text = noteController.text;
//                   Navigator.pop<int>(context, value);
//                 }
//               },
//               child: Text('Save'),
//             ),
//           ],
//         );
//       },
//     );

//     amountController.dispose();
//     noteController.dispose();
//     if (result == null) return;
//     await _saveProgress(todayLog, addedAmount: result);
//   }

//   Future<void> _saveProgress(
//     HabitLog? todayLog, {
//     required int addedAmount,
//   }) async {
//     final now = dateOnly(DateTime.now());
//     final ref = _logsRef;
//     if (ref == null) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please sign in again.')),
//         );
//       }
//       return;
//     }
//     final todayKey = dateKey(now);
//     final docRef = ref.doc(todayKey);
//     final currentProgress = todayLog?.progress ?? 0;
//     final total = (currentProgress + addedAmount).clamp(0, 1 << 31);
//     final goal = _goalValue ?? 1; // default to 1 so streaks still work
//     final meetsGoal = total >= goal;
//     final trimmedNote = _noteController.text.trim();
//     final noteToSave = trimmedNote.isEmpty ? null : trimmedNote;

//     setState(() => _toggling = true);
//     try {
//       await docRef.set({
//         'date': todayKey,
//         'completed': meetsGoal,
//         'progress': total,
//         'goal': _goalValue,
//         'habitType': _habitType.name,
//         'note': noteToSave,
//         'updatedAt': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Could not update today\'s log: $e')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _toggling = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final uid = _uid;
//     if (uid == null) {
//       return const Scaffold(
//         body: Center(child: Text('Please sign in to view this habit.')),
//       );
//     }

//     final logsStream = _logStream;
//     if (logsStream == null) {
//       return const Scaffold(
//         body: Center(child: Text('Unable to load habit logs.')),
//       );
//     }

//     return StreamBuilder<Map<String, dynamic>?>(
//       stream: FirestoreService.instance.watchHabit(uid, widget.args.habitId),
//       builder: (context, habitSnap) {
//         final habitData = habitSnap.data;
//         final title = (habitData?['title'] ?? widget.args.title).toString();
//         final emoji = (habitData?['emoji'] ?? widget.args.emoji).toString();
//         final habitType = _habitTypeFromValue(habitData?['habitType']) ?? widget.args.habitType;
//         final goalValue = _intFromValue(habitData?['goalValue']) ?? widget.args.goalValue;
//         final unitLabel = (habitData?['unitLabel'] ?? widget.args.unitLabel)?.toString();

//         // Cache resolved values so actions use the latest habit metadata
//         _resolvedHabitType = habitType;
//         _resolvedGoalValue = goalValue;
//         _resolvedUnitLabel = unitLabel;

//         return StreamBuilder<List<HabitLog>>(
//           stream: logsStream,
//           builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return Scaffold(
//             appBar: AppBar(title: Text(title)),
//             body: Center(
//               child: Text('Something went wrong loading this habit.'),
//             ),
//           );
//         }

//         if (!snapshot.hasData) {
//           return Scaffold(body: Center(child: CircularProgressIndicator()));
//         }

//         final logs = snapshot.data!;
//         final today = dateOnly(DateTime.now());
//         final completedDays = logs
//             .where((log) => log.isCompleted)
//             .map((log) => log.date)
//             .toSet();
//         final completedKeys = completedDays.map(dateKey).toSet();
//         final streak = calculateCurrentStreak(completedDays);
//         final HabitLog todayLog = logs.firstWhere(
//           (log) => DateUtils.isSameDay(log.date, today),
//           orElse: () => HabitLog(
//             date: today,
//             completed: false,
//             goalValue: _goalValue,
//             habitType: widget.args.habitType,
//           ),
//         );

//         final todayProgress = todayLog.progress ?? 0;
//         final effectiveGoalValue = this._goalValue ?? goalValue;

//         final newNoteText = todayLog.note ?? '';
//         if (_noteController.text != newNoteText) {
//           _noteController.text = newNoteText;
//         }

//         return Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//           child: Scaffold(
//             backgroundColor: Colors.transparent,
//             body: Stack(
//               children: [
//                 HabitHeader(
//                   emoji: emoji,
//                   title: title,
//                 ),
//                 SafeArea(
//                   child: Column(
//                     children: [
//                       SizedBox(height: 170),
//                       Expanded(
//                         child: Container(
//                           decoration: BoxDecoration(
//                             color: Theme.of(context).colorScheme.surface,
//                             borderRadius: BorderRadius.vertical(
//                               top: Radius.circular(24),
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.08),
//                                 blurRadius: 24,
//                                 offset: Offset(0, -4),
//                               ),
//                             ],
//                           ),
//                           child: SingleChildScrollView(
//                             padding: EdgeInsets.fromLTRB(16, 24, 16, 32),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 if (!_isCompletionOnly) ...[
//                                   HabitGoalCard(
//                                     progress: todayProgress,
//                                     goal: effectiveGoalValue,
//                                     unitLabel: unitLabel ?? _unitLabel,
//                                     habitType: habitType,
//                                   ),
//                                   SizedBox(height: 12),
//                                 ],
//                                 HabitStreakCard(streak: streak),
//                                 SizedBox(height: 16),
//                                 HabitRecentGrid(
//                                   completedKeys: completedKeys,
//                                   days: 7,
//                                   title: 'Last 7 days',
//                                   highlight: true,
//                                 ),
//                                 SizedBox(height: 12),
//                                 HabitRecentGrid(
//                                   completedKeys: completedKeys,
//                                   days: 30,
//                                   title: 'Last 30 days',
//                                   compact: true,
//                                 ),
//                                 SizedBox(height: 20),
//                                 HabitNoteCard(controller: _noteController),
//                                 SizedBox(height: 12),
//                                 SizedBox(
//                                   width: double.infinity,
//                                   child: FilledButton.icon(
//                                     style: FilledButton.styleFrom(
//                                       padding: EdgeInsets.symmetric(
//                                         vertical: 14,
//                                         horizontal: 16,
//                                       ),
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(14),
//                                       ),
//                                     ),
//                                     onPressed: _toggling
//                                         ? null
//                                         : () => _toggleToday(todayLog),
//                                     icon: _toggling
//                                         ? SizedBox(
//                                             width: 18,
//                                             height: 18,
//                                             child: CircularProgressIndicator(
//                                               strokeWidth: 2,
//                                               color: Colors.white,
//                                             ),
//                                           )
//                                         : Icon(
//                                             _isCompletionOnly
//                                                 ? (todayLog.isCompleted
//                                                       ? Icons.check_circle
//                                                       : Icons
//                                                             .playlist_add_check)
//                                                 : Icons.edit,
//                                           ),
//                                     label: Text(
//                                       _isCompletionOnly
//                                           ? (todayLog.isCompleted
//                                                 ? 'Unmark today'
//                                                 : 'Mark today completed')
//                                           : 'Log progress',
//                                     ),
//                                   ),
//                                 ),
//                                 SizedBox(height: 16),
//                                 HabitHistoryList(
//                                   logs: logs,
//                                   habitArgs: widget.args,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Positioned(
//                   top: MediaQuery.of(context).padding.top + 8,
//                   left: 8,
//                   child: IconButton(
//                     onPressed: () => Navigator.of(context).maybePop(),
//                     icon: Icon(Icons.arrow_back),
//                     color: Colors.white,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//         );
//       },    );
//   }
// }

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
      : args = args ?? HabitDetailsArgs(
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
  bool _isSaving = false;

  String? get _uid => AuthService.instance.currentUser?.uid;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) return const Scaffold(body: Center(child: Text("Sign in required")));

    return StreamBuilder<Map<String, dynamic>?>(
      stream: FirestoreService.instance.watchHabit(uid, widget.args.habitId),
      builder: (context, habitSnap) {
        final data = habitSnap.data;
        final hType = _habitTypeFromValue(data?['habitType']) ?? widget.args.habitType;
        final hGoal = _intFromValue(data?['goalValue']) ?? widget.args.goalValue ?? 1;
        final hUnit = data?['unitLabel'] ?? widget.args.unitLabel ?? 'times';

        return StreamBuilder<List<HabitLog>>(
          stream: FirestoreService.instance.watchHabitLogs(uid, widget.args.habitId),
          builder: (context, logSnap) {
            if (!logSnap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

            final logs = logSnap.data!;
            final todayKey = dateKey(dateOnly(DateTime.now()));
            final todayLog = logs.firstWhere(
              (l) => dateKey(l.date) == todayKey,
              orElse: () => HabitLog(date: DateTime.now(), completed: false),
            );

            final streak = calculateCurrentStreak(logs.where((l) => l.isCompleted).map((l) => l.date).toSet());

            return Scaffold(
              body: Stack(
                children: [
                  CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildAppBar(data?['title'] ?? widget.args.title, data?['emoji'] ?? widget.args.emoji),
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
                              completedKeys: logs.where((l) => l.isCompleted).map((l) => dateKey(l.date)).toSet(),
                              days: 30,
                              title: 'Consistency Tracker',
                            ),
                            const SizedBox(height: 24),
                            HabitNoteCard(controller: _noteController),
                            const SizedBox(height: 24),
                            HabitHistoryList(logs: logs, habitArgs: widget.args),
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
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        background: Center(child: Text(emoji, style: const TextStyle(fontSize: 50))),
      ),
    );
  }

  Widget _buildFloatingAction(HabitLog todayLog, HabitType type, int goal, String unit) {
    final isDone = todayLog.isCompleted;
    return Positioned(
      bottom: 30, left: 20, right: 20,
      child: AppButton(
        text: _isSaving ? "Updating..." : (isDone ? "Completed Today" : "Log Progress"),
        color: isDone ? Colors.green : AppColors.primary,
        onTap: () async {
          if (type == HabitType.completionOnly) {
             setState(() => _isSaving = true);
             await FirestoreService.instance.updateHabitLog(_uid!, widget.args.habitId, dateKey(DateTime.now()), {
               'completed': !isDone,
               'date': dateKey(DateTime.now()),
               'updatedAt': FieldValue.serverTimestamp(),
             });
             setState(() => _isSaving = false);
          } else {
             // Show your progress sheet logic here
          }
        },
      ),
    );
  }
}

HabitType? _habitTypeFromValue(dynamic v) {
  if (v == 'completionOnly' || v == HabitType.completionOnly) return HabitType.completionOnly;
  return HabitType.count;
}

int? _intFromValue(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');
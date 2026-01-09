import 'package:flutter/foundation.dart';

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

import 'package:flutter/material.dart';

import '../../../utils/streak_utils.dart';
import '../habit_models.dart';
import 'model.dart';

String? progressSummary(HabitLog log, HabitDetailsArgs args) {
  if (args.habitType == HabitType.completionOnly) return null;
  final unit = args.unitLabel ?? defaultUnitLabel(args.habitType);
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

String weekdayLabel(DateTime date) {
  const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  return labels[date.weekday % 7];
}

String friendlyDate(DateTime date) {
  final today = dateOnly(DateTime.now());
  if (DateUtils.isSameDay(today, date)) return 'Today';
  if (DateUtils.isSameDay(today.subtract(const Duration(days: 1)), date)) {
    return 'Yesterday';
  }
  return '${date.month}/${date.day}/${date.year}';
}

String defaultUnitLabel(HabitType type) {
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

Color dayColor(DateTime date) {
  const palette = <Color>[
    Color(0xFFEF5350),
    Color(0xFFAB47BC),
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFFFA726),
    Color(0xFF29B6F6),
    Color(0xFF66BB6A),
  ];
  return palette[(date.weekday - 1) % palette.length];
}

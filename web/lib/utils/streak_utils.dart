import 'package:flutter/material.dart';

/// Returns a date truncated to midnight in the local timezone.
DateTime dateOnly(DateTime input) => DateUtils.dateOnly(input.toLocal());

/// Creates a stable `yyyy-MM-dd` key for storing or reading day-specific docs.
String dateKey(DateTime date) {
  final normalized = dateOnly(date);
  final y = normalized.year.toString().padLeft(4, '0');
  final m = normalized.month.toString().padLeft(2, '0');
  final d = normalized.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Calculates the current streak of completed days up to `today` (inclusive).
///
/// The streak increments while there are consecutive completed days working
/// backwards from today. It stops at the first missing or incomplete day.
int calculateCurrentStreak(Set<DateTime> completedDays, {DateTime? today}) {
  final completedKeys = completedDays.map(dateKey).toSet();
  var cursor = dateOnly(today ?? DateTime.now());
  var streak = 0;

  while (completedKeys.contains(dateKey(cursor))) {
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return streak;
}

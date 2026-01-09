import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/streak_utils.dart';
import '../habit_models.dart';

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
    final progressValue = _asInt(data['progress']);
    final goalValue = _asInt(data['goal'] ?? data['goalValue']);
    final type = _habitTypeFromString(data['habitType']);

    return HabitLog(
      date: parsedDate,
      completed: data['completed'] == true,
      note: note?.isEmpty == true ? null : note,
      progress: progressValue,
      goalValue: goalValue,
      habitType: type,
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
    final lower = value.toLowerCase();
    for (final type in HabitType.values) {
      if (type.name.toLowerCase() == lower) return type;
    }
  }
  return null;
}

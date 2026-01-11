import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/streak_utils.dart';
import '../../../models/habit_models.dart';

class HabitLog {
  HabitLog({
    required this.date,
    required this.completed,
    List<String>? notes,
    List<ProgressEntry>? entries,
    this.progress,
    this.goalValue,
    this.habitType,
  }) : notes = notes ?? const [],
       entries = entries ?? const [];

  final DateTime date;
  final bool completed;
  final List<String> notes;
  final List<ProgressEntry> entries;
  final int? progress;
  final int? goalValue;
  final HabitType? habitType;

  String? get note => notes.isEmpty ? null : notes.last;

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
    } else if (rawDate is String) {
      parsedDate = dateOnly(DateTime.tryParse(rawDate) ?? DateTime.now());
    } else if (rawDate is DateTime) {
      parsedDate = dateOnly(rawDate);
    } else {
      try {
        parsedDate = dateOnly(DateTime.parse(doc.id));
      } catch (_) {
        parsedDate = dateOnly(DateTime.now());
      }
    }

    final dynamic rawNotes = data['notes'];
    final List<String> notes = rawNotes is Iterable
        ? rawNotes
              .map((e) => (e ?? '').toString().trim())
              .where((e) => e.isNotEmpty)
              .toList()
        : [];

    final note = (data['note'] as String?)?.trim();
    if (note != null && note.isNotEmpty && !notes.contains(note)) {
      notes.add(note);
    }
    final progressValue = _asInt(data['progress']);
    final goalValue = _asInt(data['goal'] ?? data['goalValue']);
    final type = _habitTypeFromString(data['habitType']);

    final rawEntries = data['entries'];
    final entries = rawEntries is Iterable
        ? rawEntries
              .map((e) => ProgressEntry.fromMap(e))
              .whereType<ProgressEntry>()
              .toList()
        : <ProgressEntry>[];

    return HabitLog(
      date: parsedDate,
      completed: data['completed'] == true,
      notes: notes,
      entries: entries,
      progress: progressValue,
      goalValue: goalValue,
      habitType: type,
    );
  }
}

class ProgressEntry {
  ProgressEntry({
    required this.added,
    required this.total,
    this.goal,
    this.note,
    this.timestamp,
  });

  final int added;
  final int total;
  final int? goal;
  final String? note;
  final DateTime? timestamp;

  static ProgressEntry? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final goalVal = _asInt(raw['goal']);
    final noteVal = (raw['note'] ?? '').toString().trim();
    DateTime? ts;
    final t = raw['timestamp'];
    if (t is Timestamp) ts = t.toDate();
    return ProgressEntry(
      added: _asInt(raw['added']) ?? 0,
      total: _asInt(raw['total']) ?? 0,
      goal: goalVal,
      note: noteVal.isEmpty ? null : noteVal,
      timestamp: ts,
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

import 'package:cloud_firestore/cloud_firestore.dart';
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


class Habit {
  final String id;
  final String userId; // for old flat structure
  final String title;
  final String emoji;
  final int color;
  final String frequency; // daily/weekly
  final int? targetPerDay;
  final bool isActive;
  final DateTime? createdAt;

  Habit({
    required this.id,
    required this.userId,
    required this.title,
    required this.emoji,
    required this.color,
    required this.frequency,
    this.targetPerDay,
    required this.isActive,
    this.createdAt,
  });

  /// ✅ Works with QueryDocumentSnapshot or DocumentSnapshot
  factory Habit.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ) ?? {};

    return Habit(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      emoji: (data['emoji'] ?? '✨').toString(),
      color: (data['color'] is int)
          ? data['color'] as int
          : int.tryParse((data['color'] ?? '').toString()) ?? 0xFFF97316,
      frequency: (data['frequency'] ?? 'daily').toString(),
      targetPerDay: data['targetPerDay'] is int ? data['targetPerDay'] as int : int.tryParse('${data['targetPerDay']}'),
      isActive: (data['isActive'] ?? true) == true,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'emoji': emoji,
      'color': color,
      'frequency': frequency,
      'targetPerDay': targetPerDay,
      'isActive': isActive,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
    };
  }
}

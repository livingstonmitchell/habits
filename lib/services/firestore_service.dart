import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habits_app/features/habits/habit_detail_helpers/model.dart';
import 'package:habits_app/models/habit_models.dart';
import 'package:habits_app/models/users.dart';
import 'package:habits_app/utils/streak_utils.dart' as DateUtilsX;

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  // =========================
  // USERS
  // =========================

  DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      _db.collection('users').doc(uid);

  /// Supports BOTH styles:
  /// 1) createUserProfile(UserProfile profile)
  /// 2) createUserProfile(profile: null, uid:..., displayName:..., email:..., photoUrl:...)
  Future<void> createUserProfile(
    UserProfile? profile, {
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
  }) {
    // If model is provided, use it.
    if (profile != null) {
      return _db
          .collection('users')
          .doc(profile.uid)
          .set(profile.toMap(), SetOptions(merge: true));
    }

    // Otherwise use named params.
    if (uid == null || displayName == null || email == null) {
      throw ArgumentError(
        'Provide either a UserProfile OR uid, displayName, and email.',
      );
    }

    return userDoc(uid).set({
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Typed profile watcher
  Stream<UserProfile?> watchTypedProfile(String uid) {
    return userDoc(uid)
        .snapshots()
        .map((d) => d.exists ? UserProfile.fromDoc(d) : null);
  }

  /// Raw map profile watcher (handy for quick UI binding)
  Stream<Map<String, dynamic>?> watchProfile(String uid) {
    return userDoc(uid).snapshots().map((d) => d.data());
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> patch) {
    return userDoc(uid).update(patch);
  }

  // =========================
  // HABITS
  // =========================

  /// New structure (recommended): users/{uid}/habits/{habitId}
  CollectionReference<Map<String, dynamic>> habitsCol(String uid) =>
      userDoc(uid).collection('habits');

  /// Old structure support: /habits where userId == uid
  Stream<List<Habit>> watchHabitsFlat(String uid) {
    return _db
        .collection('habits')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Habit.fromDoc(d)).toList());
  }

  /// New structure watcher (returns map with id)
  Stream<List<Map<String, dynamic>>> watchHabits(String uid) {
    return habitsCol(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<Map<String, dynamic>?> watchHabit(String uid, String habitId) {
    return habitsCol(uid).doc(habitId).snapshots().map((d) {
      if (!d.exists) return null;
      return {'id': d.id, ...(d.data() ?? {})};
    });
  }

  /// Add habit (new structure)
  Future<String> addHabit(String uid, Map<String, dynamic> habit) async {
    final ref = await habitsCol(uid).add({
      ...habit,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Add habit (old flat structure) using Habit model
  Future<String> addHabitFlat(Habit habit) async {
    final ref = await _db.collection('habits').add(habit.toMap());
    return ref.id;
  }

  Future<void> updateHabit(String uid, String habitId, Map<String, dynamic> patch) {
    return habitsCol(uid).doc(habitId).update(patch);
  }

  /// ✅ DELETE habit (new structure) + delete its logs too
  Future<void> deleteHabit(String uid, String habitId) async {
    final habitRef = habitsCol(uid).doc(habitId);

    // delete logs subcollection
    final logsSnap = await habitRef.collection('logs').get();
    for (final d in logsSnap.docs) {
      await d.reference.delete();
    }

    // delete habit doc
    await habitRef.delete();
  }

  /// Old flat structure delete
  Future<void> deleteHabitFlat(String habitId) {
    return _db.collection('habits').doc(habitId).delete();
  }

  // =========================
  // LOGS
  // =========================

  /// New structure: users/{uid}/habits/{habitId}/logs/{logId}
  CollectionReference<Map<String, dynamic>> logsCol(String uid, String habitId) =>
      habitsCol(uid).doc(habitId).collection('logs');

  /// Old flat structure: habit_logs collection
  CollectionReference<Map<String, dynamic>> flatLogsCol() =>
      _db.collection('habit_logs');

  // 1. Method to watch logs for a specific habit
  Stream<List<HabitLog>> watchHabitLogs(String uid, String habitId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('habits')
        .doc(habitId)
        .collection('logs')
        .orderBy('date', descending: true)
        .limit(60) // Show last 2 months
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => HabitLog.fromSnapshot(doc)).toList());
  }

  // 2. Method to update or create a log entry
  Future<void> updateHabitLog(
    String uid,
    String habitId,
    String logId,
    Map<String, dynamic> data,
  ) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('habits')
        .doc(habitId)
        .collection('logs')
        .doc(logId)
        .set(data, SetOptions(merge: true));
  }

  // ---- Watch today log / completed (new structure)
  Stream<Map<String, dynamic>?> watchTodayLog(String uid, String habitId) {
    final today = DateUtilsX.dateKey(DateTime.now());
    return logsCol(uid, habitId)
        .where('date', isEqualTo: today)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : {'id': s.docs.first.id, ...s.docs.first.data()});
  }

  Stream<bool> watchCompletedToday(String uid, String habitId) {
    return watchTodayLog(uid, habitId).map((log) => (log?['isCompleted'] == true));
  }

  Future<void> toggleToday(String uid, String habitId) async {
    final todayKey = DateUtilsX.dateKey(DateTime.now());
    final q = await logsCol(uid, habitId).where('date', isEqualTo: todayKey).limit(1).get();

    if (q.docs.isEmpty) {
      await logsCol(uid, habitId).add({
        'date': todayKey,
        'isCompleted': true,
        'note': '',
      });
      return;
    }

    final doc = q.docs.first;
    final current = (doc.data()['isCompleted'] ?? false) as bool;
    await doc.reference.update({'isCompleted': !current});
  }

  Future<void> upsertTodayNote(String uid, String habitId, String note) async {
    final todayKey = DateUtilsX.dateKey(DateTime.now());
    final q = await logsCol(uid, habitId).where('date', isEqualTo: todayKey).limit(1).get();

    if (q.docs.isEmpty) {
      await logsCol(uid, habitId).add({
        'date': todayKey,
        'isCompleted': false,
        'note': note,
      });
      return;
    }

    await q.docs.first.reference.update({'note': note});
  }

  Stream<List<Map<String, dynamic>>> watchRecentLogs(
    String uid,
    String habitId, {
    int days = 14,
  }) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days - 1));

    return logsCol(uid, habitId)
        .where('date', isGreaterThanOrEqualTo: DateUtilsX.dateKey(start))
        .where('date', isLessThanOrEqualTo: DateUtilsX.dateKey(end))
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ---- Old flat structure watchers / toggle (kept for compatibility)

  Stream<bool> watchCheckedTodayFlat(String uid, String habitId, DateTime date) {
    final key = DateUtilsX.dateKey(date);
    return flatLogsCol()
        .where('userId', isEqualTo: uid)
        .where('habitId', isEqualTo: habitId)
        .where('dateKey', isEqualTo: key)
        .limit(1)
        .snapshots()
        .map((s) =>
            s.docs.isNotEmpty && ((s.docs.first.data()['checked'] ?? false) as bool));
  }

  /// This version matches your FIRST code (habit_logs with dateKey/checked)
  Future<void> toggleCheckInFlat({
    required String uid,
    required String habitId,
    required DateTime date,
  }) async {
    final key = DateUtilsX.dateKey(date);

    final q = await flatLogsCol()
        .where('userId', isEqualTo: uid)
        .where('habitId', isEqualTo: habitId)
        .where('dateKey', isEqualTo: key)
        .limit(1)
        .get();

    final now = DateTime.now();

    if (q.docs.isEmpty) {
      await flatLogsCol().add({
        'userId': uid,
        'habitId': habitId,
        'dateKey': key,
        'checked': true,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
      return;
    }

    final doc = q.docs.first;
    final current = (doc.data()['checked'] ?? false) as bool;
    await doc.reference.update({
      'checked': !current,
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  /// This version matches your SECOND/THIRD code (subcollection logs with date/isCompleted)
  Future<void> toggleCheckIn({
    required String uid,
    required String habitId,
    required DateTime date,
  }) async {
    final key = DateUtilsX.dateKey(date);

    final q = await logsCol(uid, habitId).where('date', isEqualTo: key).limit(1).get();

    if (q.docs.isEmpty) {
      await logsCol(uid, habitId).add({
        'date': key,
        'isCompleted': true,
        'note': '',
      });
      return;
    }

    final doc = q.docs.first;
    final current = (doc.data()['isCompleted'] ?? false) as bool;
    await doc.reference.update({'isCompleted': !current});
  }

  // =========================
  // PROGRESS / STATS
  // =========================

  /// Old flat summary (from first code)
  Future<Map<String, int>> progressSummaryFlat({
    required String uid,
    required DateTime from,
    required DateTime to,
  }) async {
    final fromKey = DateUtilsX.dateKey(from);
    final toKey = DateUtilsX.dateKey(to);

    final q = await flatLogsCol()
        .where('userId', isEqualTo: uid)
        .where('dateKey', isGreaterThanOrEqualTo: fromKey)
        .where('dateKey', isLessThanOrEqualTo: toKey)
        .get();

    final checkedCount =
        q.docs.where((d) => (d.data()['checked'] ?? false) == true).length;

    return {'checked': checkedCount, 'totalLogs': q.docs.length};
  }

  /// New structure weekly summary
  Future<Map<String, int>> weeklySummary(String uid, {int days = 7}) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days - 1));

    final habitsSnap = await habitsCol(uid).get();
    int completed = 0;
    int total = 0;

    for (final h in habitsSnap.docs) {
      final logsSnap = await logsCol(uid, h.id)
          .where('date', isGreaterThanOrEqualTo: DateUtilsX.dateKey(start))
          .where('date', isLessThanOrEqualTo: DateUtilsX.dateKey(end))
          .get();

      total += logsSnap.docs.length;
      completed += logsSnap.docs
          .where((d) => (d.data()['isCompleted'] ?? false) == true)
          .length;
    }

    return {'completed': completed, 'totalLogs': total};
  }

  Stream<int> watchActiveHabitsCount(String uid) {
    return habitsCol(uid)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<int> watchCompletedTodayCount(String uid) {
    final todayKey = DateUtilsX.dateKey(DateTime.now());

    return habitsCol(uid)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((habitsSnap) async {
          int done = 0;
          for (final h in habitsSnap.docs) {
            final q = await logsCol(uid, h.id)
                .where('date', isEqualTo: todayKey)
                .where('isCompleted', isEqualTo: true)
                .limit(1)
                .get();
            if (q.docs.isNotEmpty) done++;
          }
          return done;
        });
  }

  Future<double> weeklyCompletionRate(String uid) async {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 6));

    final habitsSnap =
        await habitsCol(uid).where('isActive', isEqualTo: true).get();

    final activeCount = habitsSnap.docs.length;
    if (activeCount == 0) return 0;

    int completed = 0;
    final possible = activeCount * 7;

    for (final h in habitsSnap.docs) {
      final logsSnap = await logsCol(uid, h.id)
          .where('date', isGreaterThanOrEqualTo: DateUtilsX.dateKey(start))
          .where('date', isLessThanOrEqualTo: DateUtilsX.dateKey(end))
          .where('isCompleted', isEqualTo: true)
          .get();
      completed += logsSnap.docs.length;
    }

    return completed / possible;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/training_schedule_model.dart';
import '../../../core/models/training_session_model.dart';
import '../../auth/providers/auth_provider.dart';

final schedulesProvider = StreamProvider<List<TrainingScheduleModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref.watch(firestoreProvider)
      .collection('training_schedules')
      .orderBy('label')
      .snapshots()
      .map((s) => s.docs.map(TrainingScheduleModel.fromFirestore).toList())
      .handleError((_) {});
});

final sessionProvider = StreamProvider.family<TrainingSessionModel?, String>(
    (ref, sessionId) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref.watch(firestoreProvider)
      .collection('training_sessions')
      .doc(sessionId)
      .snapshots()
      .map((d) => d.exists ? TrainingSessionModel.fromFirestore(d) : null)
      .handleError((_) {});
});

/// Recent sessions for a coach — used to build per-child attendance history.
/// Requires composite index: coachId ASC + date DESC (see firestore.indexes.json).
final coachSessionsProvider =
    StreamProvider.family<List<TrainingSessionModel>, String>(
        (ref, coachId) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null || coachId.isEmpty) return const Stream.empty();
  final since = DateTime.now().subtract(const Duration(days: 60));
  return ref.watch(firestoreProvider)
      .collection('training_sessions')
      .where('coachId', isEqualTo: coachId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
      .orderBy('date', descending: true)
      .limit(30)
      .snapshots()
      .map((s) => s.docs.map(TrainingSessionModel.fromFirestore).toList())
      .handleError((_) {});
});

class ScheduleNotifier extends StateNotifier<AsyncValue<void>> {
  ScheduleNotifier(this._db) : super(const AsyncValue.data(null));
  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  Future<void> addSchedule(TrainingScheduleModel s) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final id = _uuid.v4();
      await _db.collection('training_schedules').doc(id).set(s.toFirestore());
    });
  }

  Future<void> deleteSchedule(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        _db.collection('training_schedules').doc(id).delete());
  }

  /// Toggle a child's attendance for a session.
  /// Creates the session document if it doesn't exist.
  Future<void> toggleAttendance({
    required TrainingScheduleModel schedule,
    required DateTime date,
    required String childId,
    required bool present,
    required String coachId,
  }) async {
    final sessionId = TrainingSessionModel.makeId(schedule.id, date);
    final ref = _db.collection('training_sessions').doc(sessionId);
    await ref.set({
      'scheduleId': schedule.id,
      'coachId': coachId,
      'date': Timestamp.fromDate(date),
    }, SetOptions(merge: true));
    await ref.update({'attendance.$childId': present});
  }

  /// Mark all children as present for a session (reset attendance).
  Future<void> resetToAllPresent({
    required TrainingScheduleModel schedule,
    required DateTime date,
    required String coachId,
  }) async {
    final sessionId = TrainingSessionModel.makeId(schedule.id, date);
    await _db.collection('training_sessions').doc(sessionId).set({
      'scheduleId': schedule.id,
      'coachId': coachId,
      'date': Timestamp.fromDate(date),
      'attendance': <String, bool>{},
    });
  }
}

final scheduleNotifierProvider =
    StateNotifierProvider<ScheduleNotifier, AsyncValue<void>>((ref) =>
        ScheduleNotifier(ref.watch(firestoreProvider)));

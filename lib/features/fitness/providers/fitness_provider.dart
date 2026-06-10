import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/fitness_exercise_model.dart';
import '../../../core/models/fitness_goal_model.dart';
import '../../../core/models/fitness_log_model.dart';
import '../../auth/providers/auth_provider.dart';

typedef ExerciseKey = ({String childId, String exerciseId});

// ── Exercises catalog ─────────────────────────────────────────────────────────
final fitnessExercisesProvider = StreamProvider<List<FitnessExercise>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('fitness_exercises')
      .snapshots()
      .map((s) {
        final list = s.docs.map(FitnessExercise.fromFirestore).toList();
        list.sort((a, b) => a.name.compareTo(b.name));
        return list;
      });
});

// ── All logs for a child (descending — newest first) ─────────────────────────
final childFitnessLogsProvider =
    StreamProvider.family<List<FitnessLog>, String>((ref, childId) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('fitness_logs')
      .where('childId', isEqualTo: childId)
      .snapshots()
      .map((s) {
        final list = s.docs.map(FitnessLog.fromFirestore).toList();
        list.sort((a, b) => b.date.compareTo(a.date)); // newest first
        return list;
      });
});

// ── Logs for a specific exercise, ascending by date (for chart) ───────────────
final exerciseLogsProvider =
    Provider.family<List<FitnessLog>, ExerciseKey>((ref, key) {
  final allLogs =
      ref.watch(childFitnessLogsProvider(key.childId)).value ?? [];
  return allLogs
      .where((l) => l.exerciseId == key.exerciseId)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
});

// ── Goal for a specific exercise ──────────────────────────────────────────────
final exerciseGoalProvider =
    StreamProvider.family<FitnessGoal?, ExerciseKey>((ref, key) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('fitness_goals')
      .doc('${key.childId}_${key.exerciseId}') // composite key
      .snapshots()
      .map((doc) => doc.exists ? FitnessGoal.fromFirestore(doc) : null)
      .handleError((_) {});
});

// ── Notifier ──────────────────────────────────────────────────────────────────
class FitnessNotifier extends StateNotifier<AsyncValue<void>> {
  FitnessNotifier(this._db) : super(const AsyncValue.data(null));

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  Future<void> seedDefaultsIfEmpty() async {
    try {
      final snap =
          await _db.collection('fitness_exercises').limit(1).get();
      if (snap.docs.isNotEmpty) return;
      final batch = _db.batch();
      for (final ex in FitnessExercise.defaults) {
        batch.set(
          _db.collection('fitness_exercises').doc(ex.id),
          ex.toFirestore(),
        );
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> addExercise(String name, String unit) async {
    final id = _uuid.v4();
    await _db.collection('fitness_exercises').doc(id).set(
          FitnessExercise(id: id, name: name, unit: unit, isDefault: false)
              .toFirestore(),
        );
  }

  Future<void> addLog({
    required String childId,
    required String exerciseId,
    required String exerciseName,
    required String exerciseUnit,
    required DateTime date,
    required double value,
    required int difficulty,
    required String comment,
    String? assignmentId,
  }) async {
    final id = _uuid.v4();
    await _db.collection('fitness_logs').doc(id).set(
          FitnessLog(
            id: id,
            childId: childId,
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            exerciseUnit: exerciseUnit,
            date: date,
            value: value,
            difficulty: difficulty,
            comment: comment,
            assignmentId: assignmentId,
          ).toFirestore(),
        );
    // Auto-mark goal achieved if target reached
    await _checkGoalAchievement(childId, exerciseId, value);
  }

  Future<void> deleteLog(String logId) async {
    await _db.collection('fitness_logs').doc(logId).delete();
  }

  Future<void> setGoal({
    required String childId,
    required String exerciseId,
    required String exerciseName,
    required String exerciseUnit,
    required double targetValue,
    required DateTime deadline,
  }) async {
    final docId = '${childId}_$exerciseId';
    await _db.collection('fitness_goals').doc(docId).set(
          FitnessGoal(
            id: docId,
            childId: childId,
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            exerciseUnit: exerciseUnit,
            targetValue: targetValue,
            deadline: deadline,
            isAchieved: false,
          ).toFirestore(),
        );
  }

  Future<void> deleteGoal(String childId, String exerciseId) async {
    await _db
        .collection('fitness_goals')
        .doc('${childId}_$exerciseId')
        .delete();
  }

  Future<void> _checkGoalAchievement(
    String childId,
    String exerciseId,
    double latestValue,
  ) async {
    try {
      final docId = '${childId}_$exerciseId';
      final doc =
          await _db.collection('fitness_goals').doc(docId).get();
      if (!doc.exists) return;
      final goal = FitnessGoal.fromFirestore(doc);
      if (!goal.isAchieved && latestValue >= goal.targetValue) {
        await _db
            .collection('fitness_goals')
            .doc(docId)
            .update({'isAchieved': true});
      }
    } catch (_) {}
  }
}

final fitnessNotifierProvider =
    StateNotifierProvider<FitnessNotifier, AsyncValue<void>>((ref) {
  return FitnessNotifier(ref.watch(firestoreProvider));
});

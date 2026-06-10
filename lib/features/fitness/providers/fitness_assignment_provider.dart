import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/fitness_assignment_model.dart';
import '../../../core/models/fitness_log_model.dart';
import '../../auth/providers/auth_provider.dart';

// ── All assignments (coach management view) ───────────────────────────────────
final allAssignmentsProvider = StreamProvider<List<FitnessAssignment>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('fitness_assignments')
      .snapshots()
      .map((s) {
        final list = s.docs.map(FitnessAssignment.fromFirestore).toList();
        list.sort((a, b) => b.deadline.compareTo(a.deadline));
        return list;
      });
});

// ── Filtered views for coach tabs ─────────────────────────────────────────────
final activeAssignmentsProvider = Provider<List<FitnessAssignment>>((ref) {
  final all = ref.watch(allAssignmentsProvider).value ?? [];
  final now = DateTime.now();
  return all
      .where((a) =>
          a.status == AssignmentStatus.active && a.deadline.isAfter(now))
      .toList();
});

final draftAssignmentsProvider = Provider<List<FitnessAssignment>>((ref) {
  final all = ref.watch(allAssignmentsProvider).value ?? [];
  return all.where((a) => a.status == AssignmentStatus.draft).toList();
});

final completedAssignmentsProvider = Provider<List<FitnessAssignment>>((ref) {
  final all = ref.watch(allAssignmentsProvider).value ?? [];
  final now = DateTime.now();
  return all
      .where((a) =>
          a.status == AssignmentStatus.completed ||
          (a.status == AssignmentStatus.active && a.deadline.isBefore(now)))
      .toList();
});

// ── Single assignment by id ────────────────────────────────────────────────────
final assignmentByIdProvider =
    Provider.family<FitnessAssignment?, String>((ref, id) {
  final all = ref.watch(allAssignmentsProvider).value ?? [];
  try {
    return all.firstWhere((a) => a.id == id);
  } catch (_) {
    return null;
  }
});

// ── Logs for all athletes in an assignment within its date range ───────────────
final assignmentLogsProvider =
    StreamProvider.family<List<FitnessLog>, String>((ref, assignmentId) {
  final assignment =
      ref.watch(assignmentByIdProvider(assignmentId));
  if (assignment == null) return const Stream.empty();
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('fitness_logs')
      .where('exerciseId', isEqualTo: assignment.exerciseId)
      .where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(assignment.startDate))
      .where('date',
          isLessThanOrEqualTo: Timestamp.fromDate(assignment.deadline))
      .snapshots()
      .map((s) {
        final assignedIds = assignment.assignedChildIds.toSet();
        return s.docs
            .map(FitnessLog.fromFirestore)
            .where((l) => assignedIds.contains(l.childId))
            .toList();
      });
});

// ── Assignments for a specific child (active = deadline not yet passed) ───────
final activeChildAssignmentsProvider =
    Provider.family<List<FitnessAssignment>, String>((ref, childId) {
  final all = ref.watch(allAssignmentsProvider).value ?? [];
  final now = DateTime.now();
  return all
      .where((a) =>
          a.assignedChildIds.contains(childId) &&
          a.deadline.isAfter(now))
      .toList();
});

// ── Compute cumulative progress for one assignment / one child ────────────────
/// Returns the progress based on assignment type (sum for rep-based, max for goal-based).
double assignmentProgress(
  List<FitnessLog> logs,
  FitnessAssignment assignment,
  String childId,
) {
  // Filter logs for this specific child and assignment within date range
  final relevantLogs = logs.where((l) =>
      l.childId == childId &&
      (l.assignmentId == assignment.id || l.assignmentId == null) && // Support legacy/manual logs
      l.exerciseId == assignment.exerciseId &&
      !l.date.isBefore(assignment.startDate) &&
      !l.date.isAfter(assignment.deadline));

  if (relevantLogs.isEmpty) return 0.0;

  if (assignment.isCumulative) {
    // Sum of all values (e.g. 1000 pushups total)
    return relevantLogs.fold(0.0, (acc, l) => acc + l.value);
  } else {
    // Peak value (e.g. 3 min plank record)
    return relevantLogs.map((l) => l.value).reduce((a, b) => a > b ? a : b);
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class AssignmentNotifier extends StateNotifier<AsyncValue<void>> {
  AssignmentNotifier(this._db) : super(const AsyncValue.data(null));

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  Future<void> createAssignment({
    required String coachId,
    required String title,
    required String exerciseId,
    required String exerciseName,
    required String exerciseUnit,
    required double targetValue,
    required DateTime startDate,
    required DateTime deadline,
    required List<String> assignedChildIds,
    String coachComment = '',
    AssignmentStatus status = AssignmentStatus.active,
    bool isCumulative = true,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final id = _uuid.v4();
      await _db.collection('fitness_assignments').doc(id).set(
            FitnessAssignment(
              id: id,
              coachId: coachId,
              title: title,
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              exerciseUnit: exerciseUnit,
              targetValue: targetValue,
              startDate: startDate,
              deadline: deadline,
              assignedChildIds: assignedChildIds,
              coachComment: coachComment,
              status: status,
              isCumulative: isCumulative,
            ).toFirestore(),
          );
    });
  }

  Future<void> updateAssignment(
    String id, {
    double? targetValue,
    DateTime? deadline,
    String? coachComment,
    AssignmentStatus? status,
  }) async {
    final data = <String, dynamic>{};
    if (targetValue != null) data['targetValue'] = targetValue;
    if (deadline != null) data['deadline'] = Timestamp.fromDate(deadline);
    if (coachComment != null) data['coachComment'] = coachComment;
    if (status != null) data['status'] = status.name;
    if (data.isEmpty) return;
    await _db.collection('fitness_assignments').doc(id).update(data);
  }

  Future<void> completeAssignment(String id) async {
    await _db
        .collection('fitness_assignments')
        .doc(id)
        .update({'status': AssignmentStatus.completed.name});
  }

  Future<void> deleteAssignment(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db.collection('fitness_assignments').doc(id).delete();
    });
  }
}

final assignmentNotifierProvider =
    StateNotifierProvider<AssignmentNotifier, AsyncValue<void>>((ref) {
  return AssignmentNotifier(ref.watch(firestoreProvider));
});

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/belt_exercise_model.dart';
import '../../../core/constants/belt_levels.dart';

// ── Stream ────────────────────────────────────────────────────────────────────

final beltExercisesProvider =
    StreamProvider<List<BeltExerciseModel>>((ref) async* {
  final snap = await FirebaseFirestore.instance
      .collection('belt_exercises')
      .orderBy('name')
      .get();

  // Seed defaults if collection is empty
  if (snap.docs.isEmpty) {
    final batch = FirebaseFirestore.instance.batch();
    for (final ex in BeltExerciseModel.defaults) {
      batch.set(
        FirebaseFirestore.instance.collection('belt_exercises').doc(ex.id),
        ex.toFirestore(),
      );
    }
    await batch.commit();
    yield BeltExerciseModel.defaults;
    return;
  }

  yield snap.docs.map(BeltExerciseModel.fromFirestore).toList();

  yield* FirebaseFirestore.instance
      .collection('belt_exercises')
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(BeltExerciseModel.fromFirestore).toList());
});

// ── Filtered provider (optional belt filter) ───────────────────────────────────

final filteredExercisesProvider = Provider.family<
    List<BeltExerciseModel>,
    ({List<BeltExerciseModel> all, String query, BeltLevel? belt})>((ref, args) {
  var list = args.all;
  if (args.belt != null) {
    list = list.where((e) => e.forBelts.contains(args.belt)).toList();
  }
  if (args.query.isNotEmpty) {
    final q = args.query.toLowerCase();
    list = list.where((e) => e.name.toLowerCase().contains(q)).toList();
  }
  return list;
});

// ── Notifier ──────────────────────────────────────────────────────────────────

final exerciseLibraryNotifierProvider =
    StateNotifierProvider<ExerciseLibraryNotifier, AsyncValue<void>>(
        (ref) => ExerciseLibraryNotifier());

class ExerciseLibraryNotifier extends StateNotifier<AsyncValue<void>> {
  ExerciseLibraryNotifier() : super(const AsyncValue.data(null));

  final _col = FirebaseFirestore.instance.collection('belt_exercises');

  Future<void> addExercise({
    required String name,
    required String description,
    required ExerciseCategory category,
    required List<BeltLevel> forBelts,
    String? videoUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final ref = _col.doc();
      await ref.set(BeltExerciseModel(
        id: ref.id, name: name, description: description,
        category: category, forBelts: forBelts,
        videoUrl: videoUrl, isDefault: false,
      ).toFirestore());
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      rethrow;
    }
  }

  Future<void> deleteExercise(String id) async {
    await _col.doc(id).delete();
  }
}

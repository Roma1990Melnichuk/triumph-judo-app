import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/competition_result_model.dart';
import '../../../core/models/competition_type_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../team/providers/children_provider.dart';
import '../../achievements/achievement_checker.dart';
import '../../../core/utils/stream_utils.dart';

// ── Results for a specific child ─────────────────────────────────────────────
final childResultsProvider =
    StreamProvider.family<List<CompetitionResultModel>, String>((ref, childId) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('competition_results')
      .where('childId', isEqualTo: childId)
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map(CompetitionResultModel.fromFirestore).toList())
      .fallbackOnError(const []);
});

// ── Total competition results count (for medals stat on dashboard) ────────────
final totalResultsCountProvider = StreamProvider<int>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('competition_results')
      .snapshots()
      .map((s) => s.size)
      .fallbackOnError(0);
});

// ── Recent results across all children (for dashboard) ───────────────────────
final recentResultsProvider =
    StreamProvider<List<CompetitionResultModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('competition_results')
      .orderBy('date', descending: true)
      .limit(10)
      .snapshots()
      .map((s) => s.docs.map(CompetitionResultModel.fromFirestore).toList())
      .fallbackOnError(const []);
});

// ── All results stream (for medal tracker) ───────────────────────────────────
final allResultsProvider =
    StreamProvider<List<CompetitionResultModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('competition_results')
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map(CompetitionResultModel.fromFirestore).toList())
      .fallbackOnError(const []);
});

// ── Competition types ────────────────────────────────────────────────────────
final competitionTypesProvider =
    StreamProvider<List<CompetitionTypeModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('competition_types')
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(CompetitionTypeModel.fromFirestore).toList())
      .fallbackOnError(const []);
});

class CompetitionsNotifier extends StateNotifier<AsyncValue<void>> {
  CompetitionsNotifier(this._db, this._ref)
      : super(const AsyncValue.data(null));

  final FirebaseFirestore _db;
  final Ref _ref;
  final _uuid = const Uuid();

  Future<void> addResult(CompetitionResultModel result) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final id = _uuid.v4();
      await _db
          .collection('competition_results')
          .doc(id)
          .set(result.toFirestore());
      // Recalculate cached points
      await _ref
          .read(childrenNotifierProvider.notifier)
          .recalcPoints(result.childId);
      // Auto-achievements check
      await AchievementChecker.onResultAdded(result.childId, _db);
    });
  }

  Future<void> deleteResult(CompetitionResultModel result) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db.collection('competition_results').doc(result.id).delete();
      await _ref
          .read(childrenNotifierProvider.notifier)
          .recalcPoints(result.childId);
    });
  }

  Future<void> resetSeason(int seasonYear) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final snap = await _db
          .collection('competition_results')
          .where('seasonYear', isEqualTo: seasonYear)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Recalc points for all affected children
      final affectedIds =
          snap.docs.map((d) => d.data()['childId'] as String).toSet();
      for (final childId in affectedIds) {
        await _ref
            .read(childrenNotifierProvider.notifier)
            .recalcPoints(childId);
      }
    });
  }

  Future<void> addCompetitionType(String name, String coachId) async {
    final id = _uuid.v4();
    await _db.collection('competition_types').doc(id).set({
      'name': name,
      'createdByCoachId': coachId,
    });
  }

  Future<void> deleteCompetitionType(String typeId) async {
    await _db.collection('competition_types').doc(typeId).delete();
  }
}

final competitionsNotifierProvider =
    StateNotifierProvider<CompetitionsNotifier, AsyncValue<void>>((ref) {
  return CompetitionsNotifier(ref.watch(firestoreProvider), ref);
});

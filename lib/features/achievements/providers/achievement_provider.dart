import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/achievement_model.dart';
import '../../auth/providers/auth_provider.dart';

final childAchievementsProvider =
    StreamProvider.family<List<AchievementModel>, String>((ref, childId) {
  final db = ref.watch(firestoreProvider);
  return db
      .collection('achievements')
      .where('childId', isEqualTo: childId)
      .snapshots()
      .map((s) => s.docs.map(AchievementModel.fromFirestore).toList());
});

// All granted achievements across all athletes — for coach stats screen.
// Safety limit: at 10K athletes × 61 defs = 610K docs; cap at 20K to prevent OOM.
final allGrantedAchievementsProvider =
    StreamProvider<List<AchievementModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('achievements')
      .limit(20000)
      .snapshots()
      .map((s) => s.docs.map(AchievementModel.fromFirestore).toList());
});

final achievementNotifierProvider =
    StateNotifierProvider<AchievementNotifier, AsyncValue<void>>((ref) {
  return AchievementNotifier(ref.watch(firestoreProvider));
});

class AchievementNotifier extends StateNotifier<AsyncValue<void>> {
  AchievementNotifier(this._db) : super(const AsyncValue.data(null));

  final FirebaseFirestore _db;

  Future<void> grant(
    String childId,
    String defId,
    String coachId, {
    String? note,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final docId = '${childId}_$defId';
      await _db.collection('achievements').doc(docId).set({
        'childId': childId,
        'achievementId': defId,
        'earnedAt': FieldValue.serverTimestamp(),
        'grantedByCoachId': coachId,
        if (note != null && note.isNotEmpty) 'note': note,
      });
    });
  }

  Future<void> grantBulk({
    required List<String> childIds,
    required List<String> defIds,
    required String coachId,
    String? note,
    void Function(int done, int total)? onProgress,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      const maxBatchSize = 400;
      var currentBatchSize = 0;
      var batch = _db.batch();
      final total = childIds.length * defIds.length;
      var done = 0;

      for (final childId in childIds) {
        for (final defId in defIds) {
          final docRef = _db.collection('achievements').doc('${childId}_$defId');
          batch.set(docRef, {
            'childId': childId,
            'achievementId': defId,
            'earnedAt': FieldValue.serverTimestamp(),
            'grantedByCoachId': coachId,
            if (note != null && note.isNotEmpty) 'note': note,
          });
          currentBatchSize++;
          done++;

          if (currentBatchSize >= maxBatchSize) {
            await batch.commit();
            onProgress?.call(done, total);
            batch = _db.batch();
            currentBatchSize = 0;
          }
        }
      }
      if (currentBatchSize > 0) {
        await batch.commit();
        onProgress?.call(done, total);
      }
    });
  }

  Future<void> revoke(String childId, String defId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db
          .collection('achievements')
          .doc('${childId}_$defId')
          .delete();
    });
  }
}

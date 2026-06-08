import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/competition_result_model.dart';

class _Season {
  const _Season(this.id, this.start, this.end);
  final String id;
  final DateTime start;
  final DateTime end;
}

class AchievementChecker {
  static Future<void> _unlock(
      FirebaseFirestore db, String childId, String defId) async {
    final docId = '${childId}_$defId';
    final existing = await db.collection('achievements').doc(docId).get();
    if (existing.exists) return;
    await db.collection('achievements').doc(docId).set({
      'childId': childId,
      'achievementId': defId,
      'earnedAt': FieldValue.serverTimestamp(),
      'grantedByCoachId': null,
    });
  }

  /// Called after a belt is awarded to one or more athletes.
  static Future<void> onBeltAdvanced(
      String childId, BeltLevel belt, FirebaseFirestore db) async {
    await _unlock(db, childId, 'belt_${belt.name}');
  }

  /// Called after a competition result is added. Queries all results for the child.
  static Future<void> onResultAdded(
      String childId, FirebaseFirestore db) async {
    final snap = await db
        .collection('competition_results')
        .where('childId', isEqualTo: childId)
        .get();

    final results = snap.docs
        .map((d) => CompetitionResultModel.fromFirestore(d))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final medals = results.where((r) => r.place <= 3).length;

    final checks = <String, bool>{
      'first_tournament':    results.isNotEmpty,
      'first_medal':         medals >= 1,
      'bronze_medalist':     results.any((r) => r.place == 3),
      'silver_medalist':     results.any((r) => r.place == 2),
      'champion':            results.any((r) => r.place == 1),
      'medals_10':           medals >= 10,
      'medals_20':           medals >= 20,
      'tournament_3_streak': results.length >= 3,
    };

    // 5 podiums in a row (most recent 5)
    if (results.length >= 5) {
      checks['podium_5_streak'] = results.take(5).every((r) => r.place <= 3);
    }

    for (final entry in checks.entries) {
      if (entry.value) await _unlock(db, childId, entry.key);
    }
  }

  /// Called when viewing profile with known training count.
  static Future<void> checkTrainingCount(
      String childId, int count, FirebaseFirestore db) async {
    if (count >= 1)   await _unlock(db, childId, 'first_training');
    if (count >= 10)  await _unlock(db, childId, 'trainings_10');
    if (count >= 50)  await _unlock(db, childId, 'trainings_50');
    if (count >= 100) await _unlock(db, childId, 'trainings_100');
    if (count >= 250) await _unlock(db, childId, 'trainings_250');
    if (count >= 500) await _unlock(db, childId, 'trainings_500');
  }

  /// Called when viewing profile with known consecutive streak.
  static Future<void> checkStreak(
      String childId, int streak, FirebaseFirestore db) async {
    if (streak >= 7)   await _unlock(db, childId, 'streak_7');
    if (streak >= 14)  await _unlock(db, childId, 'streak_14');
    if (streak >= 30)  await _unlock(db, childId, 'streak_30');
    if (streak >= 100) await _unlock(db, childId, 'streak_100');
  }

  /// Called after attendance is saved. Awards seasonal discipline achievements
  /// for any completed season (Sep–Nov, Dec–Feb, Mar–May, Jun–Aug) with 0 absences.
  static Future<void> checkSeasonalDiscipline(
      String childId, FirebaseFirestore db) async {
    final now = DateTime.now();
    final ay = now.month >= 9 ? now.year : now.year - 1;

    final seasons = [
      _Season('autumn_discipline', DateTime(ay,     9,  1), DateTime(ay,     11, 30, 23, 59, 59)),
      _Season('winter_discipline', DateTime(ay,     12, 1), DateTime(ay + 1, 2,  28, 23, 59, 59)),
      _Season('spring_discipline', DateTime(ay + 1, 3,  1), DateTime(ay + 1, 5,  31, 23, 59, 59)),
      _Season('summer_discipline', DateTime(ay + 1, 6,  1), DateTime(ay + 1, 8,  31, 23, 59, 59)),
    ];

    for (final season in seasons) {
      if (now.isBefore(season.end)) continue;

      final existing = await db
          .collection('achievements')
          .doc('${childId}_${season.id}')
          .get();
      if (existing.exists) continue;

      final snap = await db
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(season.start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(season.end))
          .get();

      final hadAbsence = snap.docs.any((doc) {
        final absent =
            List<String>.from(doc['absentChildIds'] as List? ?? []);
        return absent.contains(childId);
      });

      if (!hadAbsence) await _unlock(db, childId, season.id);
    }
  }
}

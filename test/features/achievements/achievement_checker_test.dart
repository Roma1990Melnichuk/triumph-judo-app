import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/competition_result_model.dart';
import 'package:judo_app/features/achievements/achievement_checker.dart';

var _resultCounter = 0;

CompetitionResultModel _result({
  required String childId,
  required int place,
  DateTime? date,
  int points = 10,
}) {
  _resultCounter++;
  return CompetitionResultModel(
    id: '${childId}_result_$_resultCounter',
    childId: childId,
    childName: 'Test',
    competitionName: 'Test Cup',
    level: CompetitionLevel.local,
    place: place,
    points: points,
    date: date ?? DateTime.now(),
    seasonYear: 2026,
    addedByCoachId: 'coach1',
  );
}

Future<void> _addResult(FakeFirebaseFirestore db, CompetitionResultModel r) =>
    db.collection('competition_results').doc(r.id).set(r.toFirestore());

Future<bool> _hasAchievement(
        FakeFirebaseFirestore db, String childId, String defId) async =>
    (await db
            .collection('achievements')
            .doc('${childId}_$defId')
            .get())
        .exists;

void main() {
  group('AchievementChecker — Belt achievements', () {
    late FakeFirebaseFirestore db;
    const childId = 'child_belt_1';

    setUp(() => db = FakeFirebaseFirestore());

    for (final belt in BeltLevel.values) {
      test('belt_${belt.name} unlocked when advanceBelts called', () async {
        await AchievementChecker.onBeltAdvanced(childId, belt, db);
        expect(await _hasAchievement(db, childId, 'belt_${belt.name}'), isTrue);
      });
    }

    test('same belt achievement not duplicated on second call', () async {
      await AchievementChecker.onBeltAdvanced(childId, BeltLevel.yellow, db);
      await AchievementChecker.onBeltAdvanced(childId, BeltLevel.yellow, db);

      final snap = await db
          .collection('achievements')
          .where('childId', isEqualTo: childId)
          .where('achievementId', isEqualTo: 'belt_yellow')
          .get();
      expect(snap.docs.length, equals(1));
    });
  });

  group('AchievementChecker — Tournament achievements', () {
    late FakeFirebaseFirestore db;
    const childId = 'child_tour_1';

    setUp(() => db = FakeFirebaseFirestore());

    test('first_tournament unlocked after 1 result', () async {
      await _addResult(db, _result(childId: childId, place: 5));
      await AchievementChecker.onResultAdded(childId, db);
      expect(await _hasAchievement(db, childId, 'first_tournament'), isTrue);
    });

    test('first_medal unlocked after place ≤ 3', () async {
      await _addResult(db, _result(childId: childId, place: 3));
      await AchievementChecker.onResultAdded(childId, db);
      expect(await _hasAchievement(db, childId, 'first_medal'), isTrue);
    });

    test('first_medal NOT unlocked for place > 3', () async {
      await _addResult(db, _result(childId: childId, place: 4));
      await AchievementChecker.onResultAdded(childId, db);
      expect(await _hasAchievement(db, childId, 'first_medal'), isFalse);
    });

    test('champion unlocked after place = 1', () async {
      await _addResult(db, _result(childId: childId, place: 1));
      await AchievementChecker.onResultAdded(childId, db);
      expect(await _hasAchievement(db, childId, 'champion'), isTrue);
    });

    test('champion NOT unlocked for place = 2', () async {
      await _addResult(db, _result(childId: childId, place: 2));
      await AchievementChecker.onResultAdded(childId, db);
      expect(await _hasAchievement(db, childId, 'champion'), isFalse);
    });

    test('medals_10 unlocked after 10 medals', () async {
      for (var i = 0; i < 10; i++) {
        await _addResult(db, _result(childId: childId, place: 2));
      }
      await AchievementChecker.onResultAdded(childId, db);
      expect(await _hasAchievement(db, childId, 'medals_10'), isTrue);
    });

    test('medals_10 NOT unlocked with only 9 medals', () async {
      for (var i = 0; i < 9; i++) {
        await _addResult(db, _result(childId: childId, place: 1));
      }
      await AchievementChecker.onResultAdded(childId, db);
      expect(await _hasAchievement(db, childId, 'medals_10'), isFalse);
    });

    test('medals_20 unlocked after 20 medals', () async {
      for (var i = 0; i < 20; i++) {
        await _addResult(db, _result(childId: childId, place: 3));
      }
      await AchievementChecker.onResultAdded(childId, db);
      expect(await _hasAchievement(db, childId, 'medals_20'), isTrue);
    });

    test('tournament_3_streak unlocked after 3+ results', () async {
      for (var i = 0; i < 3; i++) {
        await _addResult(db, _result(childId: childId, place: 5));
      }
      await AchievementChecker.onResultAdded(childId, db);
      expect(await _hasAchievement(db, childId, 'tournament_3_streak'), isTrue);
    });

    test('tournament_3_streak NOT unlocked with only 2 results', () async {
      for (var i = 0; i < 2; i++) {
        await _addResult(db, _result(childId: childId, place: 5));
      }
      await AchievementChecker.onResultAdded(childId, db);
      expect(await _hasAchievement(db, childId, 'tournament_3_streak'), isFalse);
    });

    test('podium_5_streak unlocked when last 5 are all podium', () async {
      for (var i = 0; i < 5; i++) {
        await _addResult(db, _result(
          childId: childId,
          place: 1,
          date: DateTime.now().subtract(Duration(days: i)),
        ));
      }
      await AchievementChecker.onResultAdded(childId, db);
      expect(await _hasAchievement(db, childId, 'podium_5_streak'), isTrue);
    });

    test('podium_5_streak NOT unlocked if one of last 5 is place > 3', () async {
      // 4 medals + 1 non-medal
      for (var i = 0; i < 4; i++) {
        await _addResult(db, _result(
          childId: childId,
          place: 1,
          date: DateTime.now().subtract(Duration(days: i)),
        ));
      }
      await _addResult(db, _result(
        childId: childId,
        place: 5,
        date: DateTime.now().subtract(const Duration(days: 4)),
      ));
      await AchievementChecker.onResultAdded(childId, db);
      expect(await _hasAchievement(db, childId, 'podium_5_streak'), isFalse);
    });

    test('no duplicate achievements on repeated calls', () async {
      await _addResult(db, _result(childId: childId, place: 1));
      await AchievementChecker.onResultAdded(childId, db);
      await AchievementChecker.onResultAdded(childId, db);

      final snap = await db
          .collection('achievements')
          .where('childId', isEqualTo: childId)
          .where('achievementId', isEqualTo: 'champion')
          .get();
      expect(snap.docs.length, equals(1));
    });
  });

  group('AchievementChecker — Training milestones', () {
    late FakeFirebaseFirestore db;
    const childId = 'child_train_1';

    setUp(() => db = FakeFirebaseFirestore());

    test('first_training unlocked at count = 1', () async {
      await AchievementChecker.checkTrainingCount(childId, 1, db);
      expect(await _hasAchievement(db, childId, 'first_training'), isTrue);
    });

    test('trainings_10 unlocked at count = 10', () async {
      await AchievementChecker.checkTrainingCount(childId, 10, db);
      expect(await _hasAchievement(db, childId, 'trainings_10'), isTrue);
    });

    test('trainings_10 NOT unlocked at count = 9', () async {
      await AchievementChecker.checkTrainingCount(childId, 9, db);
      expect(await _hasAchievement(db, childId, 'trainings_10'), isFalse);
    });

    test('trainings_50 unlocked at count = 50', () async {
      await AchievementChecker.checkTrainingCount(childId, 50, db);
      expect(await _hasAchievement(db, childId, 'trainings_50'), isTrue);
      expect(await _hasAchievement(db, childId, 'trainings_10'), isTrue);
      expect(await _hasAchievement(db, childId, 'first_training'), isTrue);
    });

    test('trainings_100 unlocked at count = 100', () async {
      await AchievementChecker.checkTrainingCount(childId, 100, db);
      expect(await _hasAchievement(db, childId, 'trainings_100'), isTrue);
    });

    test('trainings_250 unlocked at count = 250', () async {
      await AchievementChecker.checkTrainingCount(childId, 250, db);
      expect(await _hasAchievement(db, childId, 'trainings_250'), isTrue);
    });

    test('trainings_500 unlocked at count = 500', () async {
      await AchievementChecker.checkTrainingCount(childId, 500, db);
      expect(await _hasAchievement(db, childId, 'trainings_500'), isTrue);
    });

    test('trainings_500 NOT unlocked at count = 499', () async {
      await AchievementChecker.checkTrainingCount(childId, 499, db);
      expect(await _hasAchievement(db, childId, 'trainings_500'), isFalse);
    });
  });

  group('AchievementChecker — Streak milestones', () {
    late FakeFirebaseFirestore db;
    const childId = 'child_streak_1';

    setUp(() => db = FakeFirebaseFirestore());

    test('streak_7 unlocked at streak = 7', () async {
      await AchievementChecker.checkStreak(childId, 7, db);
      expect(await _hasAchievement(db, childId, 'streak_7'), isTrue);
    });

    test('streak_7 NOT unlocked at streak = 6', () async {
      await AchievementChecker.checkStreak(childId, 6, db);
      expect(await _hasAchievement(db, childId, 'streak_7'), isFalse);
    });

    test('streak_14 unlocked at streak = 14', () async {
      await AchievementChecker.checkStreak(childId, 14, db);
      expect(await _hasAchievement(db, childId, 'streak_14'), isTrue);
      expect(await _hasAchievement(db, childId, 'streak_7'), isTrue);
    });

    test('streak_30 (Невидимий воїн) unlocked at streak = 30', () async {
      await AchievementChecker.checkStreak(childId, 30, db);
      expect(await _hasAchievement(db, childId, 'streak_30'), isTrue);
    });

    test('streak_100 unlocked at streak = 100', () async {
      await AchievementChecker.checkStreak(childId, 100, db);
      expect(await _hasAchievement(db, childId, 'streak_100'), isTrue);
    });

    test('streak_100 NOT unlocked at streak = 99', () async {
      await AchievementChecker.checkStreak(childId, 99, db);
      expect(await _hasAchievement(db, childId, 'streak_100'), isFalse);
    });

    test('all lower streaks also unlocked at streak = 100', () async {
      await AchievementChecker.checkStreak(childId, 100, db);
      expect(await _hasAchievement(db, childId, 'streak_7'), isTrue);
      expect(await _hasAchievement(db, childId, 'streak_14'), isTrue);
      expect(await _hasAchievement(db, childId, 'streak_30'), isTrue);
      expect(await _hasAchievement(db, childId, 'streak_100'), isTrue);
    });
  });

  group('AchievementChecker — isolation (different childIds)', () {
    late FakeFirebaseFirestore db;

    setUp(() => db = FakeFirebaseFirestore());

    test('achievement for child1 does not appear for child2', () async {
      await AchievementChecker.onBeltAdvanced('child1', BeltLevel.yellow, db);
      expect(await _hasAchievement(db, 'child1', 'belt_yellow'), isTrue);
      expect(await _hasAchievement(db, 'child2', 'belt_yellow'), isFalse);
    });

    test('training count achievements isolated per child', () async {
      await AchievementChecker.checkTrainingCount('child1', 100, db);
      await AchievementChecker.checkTrainingCount('child2', 5, db);
      expect(await _hasAchievement(db, 'child1', 'trainings_100'), isTrue);
      expect(await _hasAchievement(db, 'child2', 'trainings_100'), isFalse);
    });
  });
}

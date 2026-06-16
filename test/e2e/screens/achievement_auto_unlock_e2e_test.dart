/// TC-ACH-AUTO — Автоматичне розблокування досягнень.
///
/// Ключові правила:
///   1. checkTrainingCount: порогові значення 1, 10, 50, 100, 250, 500
///   2. checkStreak: порогові значення 7, 14, 30, 100
///   3. onBeltAdvanced: розблоковує belt_{beltLevel.name} з grantedByCoachId=null
///   4. Всі авто-розблокування: grantedByCoachId = null (не вручну)
///   5. Ідемпотентність: повторний виклик НЕ дублює досягнення
///   6. checkSeasonalDiscipline: тільки якщо сезон завершений + немає пропусків
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/features/achievements/achievement_checker.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

Future<List<Map<String, dynamic>>> _childAchievements(
  FakeFirebaseFirestore db,
  String childId,
) async {
  final snap = await db
      .collection('achievements')
      .where('childId', isEqualTo: childId)
      .get();
  return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
}

Future<Map<String, dynamic>?> _findAchievement(
  FakeFirebaseFirestore db,
  String childId,
  String achievementId,
) async {
  final snap = await db
      .collection('achievements')
      .where('childId', isEqualTo: childId)
      .where('achievementId', isEqualTo: achievementId)
      .get();
  if (snap.docs.isEmpty) return null;
  return snap.docs.first.data();
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── TC-ACH-AUTO-001: checkTrainingCount — порогові значення ───────────────

  group('TC-ACH-AUTO-001: checkTrainingCount — порогові значення', () {
    const child = 'child1';

    test('1 тренування → розблоковує first_training', () async {
      final db = _db();
      await AchievementChecker.checkTrainingCount(child, 1, db);
      final ach = await _findAchievement(db, child, 'first_training');
      expect(ach, isNotNull, reason: 'Перше тренування → first_training');
    });

    test('10 тренувань → розблоковує trainings_10', () async {
      final db = _db();
      await AchievementChecker.checkTrainingCount(child, 10, db);
      final ach = await _findAchievement(db, child, 'trainings_10');
      expect(ach, isNotNull);
    });

    test('50 тренувань → розблоковує trainings_50', () async {
      final db = _db();
      await AchievementChecker.checkTrainingCount(child, 50, db);
      final ach = await _findAchievement(db, child, 'trainings_50');
      expect(ach, isNotNull);
    });

    test('100 тренувань → розблоковує trainings_100', () async {
      final db = _db();
      await AchievementChecker.checkTrainingCount(child, 100, db);
      final ach = await _findAchievement(db, child, 'trainings_100');
      expect(ach, isNotNull);
    });

    test('250 тренувань → розблоковує trainings_250', () async {
      final db = _db();
      await AchievementChecker.checkTrainingCount(child, 250, db);
      final ach = await _findAchievement(db, child, 'trainings_250');
      expect(ach, isNotNull);
    });

    test('500 тренувань → розблоковує trainings_500', () async {
      final db = _db();
      await AchievementChecker.checkTrainingCount(child, 500, db);
      final ach = await _findAchievement(db, child, 'trainings_500');
      expect(ach, isNotNull);
    });

    test('9 тренувань → НЕ розблоковує trainings_10', () async {
      final db = _db();
      await AchievementChecker.checkTrainingCount(child, 9, db);
      final ach = await _findAchievement(db, child, 'trainings_10');
      expect(ach, isNull);
    });

    test('11 тренувань → розблоковує trainings_10 (але не trainings_50)', () async {
      final db = _db();
      await AchievementChecker.checkTrainingCount(child, 11, db);

      final ach10 = await _findAchievement(db, child, 'trainings_10');
      final ach50 = await _findAchievement(db, child, 'trainings_50');
      expect(ach10, isNotNull);
      expect(ach50, isNull);
    });

    test('100 тренувань → розблоковує всі попередні (1, 10, 50, 100)', () async {
      final db = _db();
      await AchievementChecker.checkTrainingCount(child, 100, db);

      final ids = ['first_training', 'trainings_10', 'trainings_50', 'trainings_100'];
      for (final id in ids) {
        final ach = await _findAchievement(db, child, id);
        expect(ach, isNotNull, reason: '$id повинен бути розблокований при 100');
      }
    });
  });

  // ── TC-ACH-AUTO-002: checkStreak — серія відвідуваності ──────────────────

  group('TC-ACH-AUTO-002: checkStreak — порогові значення', () {
    const child = 'child2';

    test('7 тренувань поспіль → streak_7', () async {
      final db = _db();
      await AchievementChecker.checkStreak(child, 7, db);
      final ach = await _findAchievement(db, child, 'streak_7');
      expect(ach, isNotNull);
    });

    test('14 тренувань поспіль → streak_14', () async {
      final db = _db();
      await AchievementChecker.checkStreak(child, 14, db);
      final ach = await _findAchievement(db, child, 'streak_14');
      expect(ach, isNotNull);
    });

    test('30 тренувань поспіль → streak_30', () async {
      final db = _db();
      await AchievementChecker.checkStreak(child, 30, db);
      final ach = await _findAchievement(db, child, 'streak_30');
      expect(ach, isNotNull);
    });

    test('100 тренувань поспіль → streak_100', () async {
      final db = _db();
      await AchievementChecker.checkStreak(child, 100, db);
      final ach = await _findAchievement(db, child, 'streak_100');
      expect(ach, isNotNull);
    });

    test('6 тренувань поспіль → streak_7 ще НЕ розблоковано', () async {
      final db = _db();
      await AchievementChecker.checkStreak(child, 6, db);
      final ach = await _findAchievement(db, child, 'streak_7');
      expect(ach, isNull);
    });

    test('30 підряд → розблоковує streak_7, streak_14, streak_30', () async {
      final db = _db();
      await AchievementChecker.checkStreak(child, 30, db);

      for (final id in ['streak_7', 'streak_14', 'streak_30']) {
        final ach = await _findAchievement(db, child, id);
        expect(ach, isNotNull, reason: '$id при серії 30');
      }
      final ach100 = await _findAchievement(db, child, 'streak_100');
      expect(ach100, isNull, reason: 'streak_100 при серії 30 не розблоковано');
    });
  });

  // ── TC-ACH-AUTO-003: grantedByCoachId = null для авто-досягнень ───────────

  group('TC-ACH-AUTO-003: авто-досягнення завжди grantedByCoachId=null', () {
    const child = 'child3';

    test('first_training — grantedByCoachId = null', () async {
      final db = _db();
      await AchievementChecker.checkTrainingCount(child, 1, db);

      final ach = await _findAchievement(db, child, 'first_training');
      expect(ach, isNotNull);
      expect(ach?['grantedByCoachId'], isNull,
          reason: 'Авто-досягнення не прив\'язане до тренера');
    });

    test('streak_7 — grantedByCoachId = null', () async {
      final db = _db();
      await AchievementChecker.checkStreak(child, 7, db);

      final ach = await _findAchievement(db, child, 'streak_7');
      expect(ach?['grantedByCoachId'], isNull);
    });

    test('onBeltAdvanced — belt_white — grantedByCoachId = null', () async {
      final db = _db();
      await AchievementChecker.onBeltAdvanced(child, BeltLevel.white, db);

      final snap = await db
          .collection('achievements')
          .where('childId', isEqualTo: child)
          .get();
      expect(snap.docs, isNotEmpty);
      for (final doc in snap.docs) {
        expect(doc.data()['grantedByCoachId'], isNull);
      }
    });
  });

  // ── TC-ACH-AUTO-004: onBeltAdvanced — розблоковує belt_{level.name} ───────

  group('TC-ACH-AUTO-004: onBeltAdvanced → belt_{beltLevel.name}', () {
    test('onBeltAdvanced(child, BeltLevel.white) → achievement belt_white', () async {
      final db = _db();
      await AchievementChecker.onBeltAdvanced('child1', BeltLevel.white, db);

      final ach = await _findAchievement(db, 'child1', 'belt_white');
      expect(ach, isNotNull);
    });

    test('onBeltAdvanced(child, BeltLevel.yellow) → achievement belt_yellow', () async {
      final db = _db();
      await AchievementChecker.onBeltAdvanced('child1', BeltLevel.yellow, db);

      final ach = await _findAchievement(db, 'child1', 'belt_yellow');
      expect(ach, isNotNull);
    });

    test('onBeltAdvanced(child, BeltLevel.black) → achievement belt_black', () async {
      final db = _db();
      await AchievementChecker.onBeltAdvanced('child1', BeltLevel.black, db);

      final ach = await _findAchievement(db, 'child1', 'belt_black');
      expect(ach, isNotNull);
    });

    test('кожен рівень пояса → правильний achievementId', () async {
      for (final level in BeltLevel.values) {
        final db = _db();
        await AchievementChecker.onBeltAdvanced('child1', level, db);

        final expectedId = 'belt_${level.name}';
        final ach = await _findAchievement(db, 'child1', expectedId);
        expect(ach, isNotNull,
            reason: 'Рівень ${level.name} повинен давати $expectedId');
      }
    });
  });

  // ── TC-ACH-AUTO-005: ідемпотентність ──────────────────────────────────────

  group('TC-ACH-AUTO-005: ідемпотентність — повторний виклик не дублює', () {
    const child = 'child5';

    test('подвійний checkTrainingCount(1) → 1 досягнення first_training', () async {
      final db = _db();
      await AchievementChecker.checkTrainingCount(child, 1, db);
      await AchievementChecker.checkTrainingCount(child, 1, db);

      final snap = await db
          .collection('achievements')
          .where('childId', isEqualTo: child)
          .where('achievementId', isEqualTo: 'first_training')
          .get();
      expect(snap.docs, hasLength(1),
          reason: 'Ідемпотентність: тільки 1 документ при повторному виклику');
    });

    test('подвійний checkStreak(7) → 1 досягнення streak_7', () async {
      final db = _db();
      await AchievementChecker.checkStreak(child, 7, db);
      await AchievementChecker.checkStreak(child, 7, db);

      final snap = await db
          .collection('achievements')
          .where('childId', isEqualTo: child)
          .where('achievementId', isEqualTo: 'streak_7')
          .get();
      expect(snap.docs, hasLength(1));
    });

    test('подвійний onBeltAdvanced(white) → 1 досягнення belt_white', () async {
      final db = _db();
      await AchievementChecker.onBeltAdvanced(child, BeltLevel.white, db);
      await AchievementChecker.onBeltAdvanced(child, BeltLevel.white, db);

      final snap = await db
          .collection('achievements')
          .where('childId', isEqualTo: child)
          .where('achievementId', isEqualTo: 'belt_white')
          .get();
      expect(snap.docs, hasLength(1));
    });
  });

  // ── TC-ACH-AUTO-006: ізоляція між дітьми ─────────────────────────────────

  group('TC-ACH-AUTO-006: досягнення не перетинаються між дітьми', () {
    test('first_training для child1 не з\'являється в child2', () async {
      final db = _db();
      await AchievementChecker.checkTrainingCount('child1', 1, db);

      final ach = await _findAchievement(db, 'child2', 'first_training');
      expect(ach, isNull,
          reason: 'Досягнення child1 не повинно потрапити до child2');
    });

    test('streak_7 для різних дітей — окремі записи', () async {
      final db = _db();
      await AchievementChecker.checkStreak('child1', 7, db);
      await AchievementChecker.checkStreak('child2', 7, db);

      final snap1 = await _findAchievement(db, 'child1', 'streak_7');
      final snap2 = await _findAchievement(db, 'child2', 'streak_7');
      expect(snap1, isNotNull);
      expect(snap2, isNotNull);
    });
  });
}

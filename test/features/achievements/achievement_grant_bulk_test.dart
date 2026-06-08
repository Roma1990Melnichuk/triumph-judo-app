import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/features/achievements/providers/achievement_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

AchievementNotifier _makeNotifier(FakeFirebaseFirestore db) =>
    AchievementNotifier(db);

Future<Map<String, dynamic>?> _getDoc(
    FakeFirebaseFirestore db, String childId, String defId) async {
  final snap =
      await db.collection('achievements').doc('${childId}_$defId').get();
  return snap.exists ? snap.data() : null;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('AchievementNotifier.grantBulk', () {
    late FakeFirebaseFirestore db;
    late AchievementNotifier notifier;

    setUp(() {
      db = FakeFirebaseFirestore();
      notifier = _makeNotifier(db);
    });

    // ── Document creation ────────────────────────────────────────────────────

    test('одна ачивка одному спортсмену — створює один документ', () async {
      await notifier.grantBulk(
        childIds: ['c1'],
        defIds: ['first_training'],
        coachId: 'coach1',
      );

      final doc = await _getDoc(db, 'c1', 'first_training');
      expect(doc, isNotNull);
    });

    test('id документа має формат childId_defId', () async {
      await notifier.grantBulk(
        childIds: ['kid99'],
        defIds: ['champion'],
        coachId: 'coach1',
      );

      final snap =
          await db.collection('achievements').doc('kid99_champion').get();
      expect(snap.exists, isTrue);
    });

    test('записує правильні поля', () async {
      await notifier.grantBulk(
        childIds: ['c1'],
        defIds: ['first_medal'],
        coachId: 'coach42',
      );

      final doc = await _getDoc(db, 'c1', 'first_medal');
      expect(doc!['childId'], 'c1');
      expect(doc['achievementId'], 'first_medal');
      expect(doc['grantedByCoachId'], 'coach42');
      expect(doc['earnedAt'], isA<Timestamp>());
    });

    // ── Note ─────────────────────────────────────────────────────────────────

    test('note записується коли не порожній', () async {
      await notifier.grantBulk(
        childIds: ['c1'],
        defIds: ['fair_play'],
        coachId: 'coach1',
        note: 'Відмінна поведінка на турнірі',
      );

      final doc = await _getDoc(db, 'c1', 'fair_play');
      expect(doc!['note'], 'Відмінна поведінка на турнірі');
    });

    test('note відсутній коли null', () async {
      await notifier.grantBulk(
        childIds: ['c1'],
        defIds: ['friend_of_team'],
        coachId: 'coach1',
      );

      final doc = await _getDoc(db, 'c1', 'friend_of_team');
      expect(doc!.containsKey('note'), isFalse);
    });

    test('note відсутній коли порожній рядок', () async {
      await notifier.grantBulk(
        childIds: ['c1'],
        defIds: ['friend_of_team'],
        coachId: 'coach1',
        note: '',
      );

      final doc = await _getDoc(db, 'c1', 'friend_of_team');
      expect(doc!.containsKey('note'), isFalse);
    });

    // ── Bulk writes ───────────────────────────────────────────────────────────

    test('N ачивок одному спортсмену — N документів', () async {
      const defIds = ['first_training', 'first_medal', 'champion'];
      await notifier.grantBulk(
        childIds: ['c1'],
        defIds: defIds,
        coachId: 'coach1',
      );

      for (final defId in defIds) {
        final doc = await _getDoc(db, 'c1', defId);
        expect(doc, isNotNull, reason: 'Очікується документ для $defId');
      }
    });

    test('одна ачивка N спортсменам — N документів', () async {
      const childIds = ['c1', 'c2', 'c3'];
      await notifier.grantBulk(
        childIds: childIds,
        defIds: ['team_leader'],
        coachId: 'coach1',
      );

      for (final childId in childIds) {
        final doc = await _getDoc(db, childId, 'team_leader');
        expect(doc, isNotNull, reason: 'Очікується документ для $childId');
      }
    });

    test('M ачивок × N спортсменів — M×N документів', () async {
      const childIds = ['c1', 'c2', 'c3'];
      const defIds = ['fair_play', 'respect', 'friend_of_team'];
      await notifier.grantBulk(
        childIds: childIds,
        defIds: defIds,
        coachId: 'coach1',
      );

      var total = 0;
      for (final childId in childIds) {
        for (final defId in defIds) {
          final doc = await _getDoc(db, childId, defId);
          expect(doc, isNotNull,
              reason: 'Очікується документ $childId × $defId');
          total++;
        }
      }
      expect(total, childIds.length * defIds.length);
    });

    test('кожен документ містить правильний childId та achievementId', () async {
      await notifier.grantBulk(
        childIds: ['alice', 'bob'],
        defIds: ['throw_master', 'hold_master'],
        coachId: 'coach9',
      );

      final aliceThrow = await _getDoc(db, 'alice', 'throw_master');
      expect(aliceThrow!['childId'], 'alice');
      expect(aliceThrow['achievementId'], 'throw_master');

      final bobHold = await _getDoc(db, 'bob', 'hold_master');
      expect(bobHold!['childId'], 'bob');
      expect(bobHold['achievementId'], 'hold_master');
    });

    // ── Edge cases ────────────────────────────────────────────────────────────

    test('порожній childIds — нічого не записує', () async {
      await notifier.grantBulk(
        childIds: [],
        defIds: ['champion'],
        coachId: 'coach1',
      );

      final snap =
          await db.collection('achievements').get();
      expect(snap.docs, isEmpty);
    });

    test('порожній defIds — нічого не записує', () async {
      await notifier.grantBulk(
        childIds: ['c1'],
        defIds: [],
        coachId: 'coach1',
      );

      final snap = await db.collection('achievements').get();
      expect(snap.docs, isEmpty);
    });

    test('повторна видача перезаписує документ (idempotent)', () async {
      await notifier.grantBulk(
        childIds: ['c1'],
        defIds: ['champion'],
        coachId: 'coach1',
        note: 'перша видача',
      );

      await notifier.grantBulk(
        childIds: ['c1'],
        defIds: ['champion'],
        coachId: 'coach2',
        note: 'друга видача',
      );

      final snap = await db.collection('achievements').get();
      expect(snap.docs.length, 1, reason: 'Документ лише один (перезапис)');

      final doc = await _getDoc(db, 'c1', 'champion');
      expect(doc!['grantedByCoachId'], 'coach2');
      expect(doc['note'], 'друга видача');
    });

    // ── State transitions ─────────────────────────────────────────────────────

    test('стан стає AsyncData після успішного grant', () async {
      await notifier.grantBulk(
        childIds: ['c1'],
        defIds: ['first_training'],
        coachId: 'coach1',
      );

      expect(notifier.state, isA<AsyncData<void>>());
    });
  });

  // ── Single grant (regression) ─────────────────────────────────────────────

  group('AchievementNotifier.grant (регресія)', () {
    test('grant зберігає одну ачивку з коректними полями', () async {
      final db = FakeFirebaseFirestore();
      final notifier = _makeNotifier(db);

      await notifier.grant('c1', 'first_training', 'coach1',
          note: 'молодець');

      final snap =
          await db.collection('achievements').doc('c1_first_training').get();
      expect(snap.exists, isTrue);
      expect(snap.data()!['note'], 'молодець');
      expect(snap.data()!['grantedByCoachId'], 'coach1');
    });

    test('revoke видаляє документ', () async {
      final db = FakeFirebaseFirestore();
      final notifier = _makeNotifier(db);

      await db.collection('achievements').doc('c1_champion').set({
        'childId': 'c1',
        'achievementId': 'champion',
        'grantedByCoachId': 'coach1',
      });

      await notifier.revoke('c1', 'champion');

      final snap =
          await db.collection('achievements').doc('c1_champion').get();
      expect(snap.exists, isFalse);
    });
  });
}

/// E2E тести для AchievementNotifier — повний CRUD ачівок + cross-role.
/// Покриває: grant, grantBulk, revoke, idempotency, cross-role flow.
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/features/achievements/providers/achievement_provider.dart';

// ── Хелпери ───────────────────────────────────────────────────────────────────

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

AchievementNotifier _notifier(FakeFirebaseFirestore db) =>
    AchievementNotifier(db);

String _docId(String childId, String defId) => '${childId}_${defId}';

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── grant ─────────────────────────────────────────────────────────────────

  group('AchievementNotifier — grant', () {
    test('зберігає ачівку у Firestore з правильними полями', () async {
      final db = _db();
      final n = _notifier(db);

      await n.grant('kid1', 'first_win', 'coach1');

      final doc =
          await db.collection('achievements').doc(_docId('kid1', 'first_win')).get();
      expect(doc.exists, isTrue);
      expect(doc['childId'], 'kid1');
      expect(doc['achievementId'], 'first_win');
      expect(doc['grantedByCoachId'], 'coach1');
    });

    test('grant з note — поле note збережено', () async {
      final db = _db();
      final n = _notifier(db);

      await n.grant('kid1', 'mvp', 'coach1', note: 'Кращий на турнірі');

      final doc = await db
          .collection('achievements')
          .doc(_docId('kid1', 'mvp'))
          .get();
      expect(doc['note'], 'Кращий на турнірі');
    });

    test('grant без note — поле note відсутнє', () async {
      final db = _db();
      final n = _notifier(db);

      await n.grant('kid1', 'first_win', 'coach1');

      final doc = await db
          .collection('achievements')
          .doc(_docId('kid1', 'first_win'))
          .get();
      expect(doc.data()!.containsKey('note'), isFalse);
    });

    test('grant idempotent — повторний grant не дублює документ', () async {
      final db = _db();
      final n = _notifier(db);

      await n.grant('kid1', 'first_win', 'coach1');
      await n.grant('kid1', 'first_win', 'coach1');

      final snap = await db
          .collection('achievements')
          .where('childId', isEqualTo: 'kid1')
          .get();
      expect(snap.docs, hasLength(1));
    });

    test('різні дефініції — різні документи', () async {
      final db = _db();
      final n = _notifier(db);

      await n.grant('kid1', 'first_win', 'coach1');
      await n.grant('kid1', 'belt_white', 'coach1');
      await n.grant('kid1', 'top3_tournament', 'coach1');

      final snap = await db
          .collection('achievements')
          .where('childId', isEqualTo: 'kid1')
          .get();
      expect(snap.docs, hasLength(3));
    });

    test('різні спортсмени — різні документи', () async {
      final db = _db();
      final n = _notifier(db);

      await n.grant('kid1', 'first_win', 'coach1');
      await n.grant('kid2', 'first_win', 'coach1');
      await n.grant('kid3', 'first_win', 'coach1');

      final snap =
          await db.collection('achievements').get();
      expect(snap.docs, hasLength(3));
    });

    test('стан = AsyncData після grant', () async {
      final db = _db();
      final n = _notifier(db);

      await n.grant('kid1', 'first_win', 'coach1');

      expect(n.state, isA<AsyncData<void>>());
    });
  });

  // ── grantBulk ─────────────────────────────────────────────────────────────

  group('AchievementNotifier — grantBulk', () {
    test('5 спортсменів × 2 ачівки = 10 документів', () async {
      final db = _db();
      final n = _notifier(db);

      await n.grantBulk(
        childIds: ['kid1', 'kid2', 'kid3', 'kid4', 'kid5'],
        defIds: ['first_win', 'belt_white'],
        coachId: 'coach1',
      );

      final snap = await db.collection('achievements').get();
      expect(snap.docs, hasLength(10));
    });

    test('grantBulk ідемпотентний — повторний виклик не дублює', () async {
      final db = _db();
      final n = _notifier(db);

      await n.grantBulk(
        childIds: ['kid1', 'kid2'],
        defIds: ['first_win'],
        coachId: 'coach1',
      );
      await n.grantBulk(
        childIds: ['kid1', 'kid2'],
        defIds: ['first_win'],
        coachId: 'coach1',
      );

      final snap = await db.collection('achievements').get();
      expect(snap.docs, hasLength(2));
    });

    test('onProgress колбек викликається', () async {
      final db = _db();
      final n = _notifier(db);
      final progress = <int>[];

      await n.grantBulk(
        childIds: ['kid1', 'kid2', 'kid3'],
        defIds: ['first_win'],
        coachId: 'coach1',
        onProgress: (done, total) => progress.add(done),
      );

      expect(progress, isNotEmpty);
      expect(progress.last, 3);
    });

    test('grantBulk з note — поле note у всіх документах', () async {
      final db = _db();
      final n = _notifier(db);

      await n.grantBulk(
        childIds: ['kid1', 'kid2'],
        defIds: ['mvp'],
        coachId: 'coach1',
        note: 'Відмінний виступ',
      );

      final snap = await db.collection('achievements').get();
      for (final doc in snap.docs) {
        expect(doc['note'], 'Відмінний виступ');
      }
    });

    test('стан = AsyncData після grantBulk', () async {
      final db = _db();
      final n = _notifier(db);

      await n.grantBulk(
        childIds: ['kid1'],
        defIds: ['first_win'],
        coachId: 'coach1',
      );

      expect(n.state, isA<AsyncData<void>>());
    });
  });

  // ── revoke ────────────────────────────────────────────────────────────────

  group('AchievementNotifier — revoke', () {
    test('видаляє документ з Firestore', () async {
      final db = _db();
      final n = _notifier(db);

      await n.grant('kid1', 'first_win', 'coach1');
      await n.revoke('kid1', 'first_win');

      final doc = await db
          .collection('achievements')
          .doc(_docId('kid1', 'first_win'))
          .get();
      expect(doc.exists, isFalse);
    });

    test('revoke залишає ачівки інших спортсменів', () async {
      final db = _db();
      final n = _notifier(db);

      await n.grant('kid1', 'first_win', 'coach1');
      await n.grant('kid2', 'first_win', 'coach1');
      await n.revoke('kid1', 'first_win');

      final snap = await db.collection('achievements').get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first['childId'], 'kid2');
    });

    test('revoke залишає інші ачівки того ж спортсмена', () async {
      final db = _db();
      final n = _notifier(db);

      await n.grant('kid1', 'first_win', 'coach1');
      await n.grant('kid1', 'belt_white', 'coach1');
      await n.revoke('kid1', 'first_win');

      final snap = await db
          .collection('achievements')
          .where('childId', isEqualTo: 'kid1')
          .get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first['achievementId'], 'belt_white');
    });

    test('стан = AsyncData після revoke', () async {
      final db = _db();
      final n = _notifier(db);

      await n.grant('kid1', 'first_win', 'coach1');
      await n.revoke('kid1', 'first_win');

      expect(n.state, isA<AsyncData<void>>());
    });
  });

  // ── Cross-role: тренер видає → спортсмен бачить ───────────────────────────

  group('Achievements — cross-role flow', () {
    test('тренер видає ачівку → документ видимий через childAchievementsProvider',
        () async {
      final db = _db();
      final coachN = _notifier(db);

      await coachN.grant('kid1', 'first_win', 'coach1', note: 'Перша перемога!');

      // Дитина бачить через свій запит
      final snap = await db
          .collection('achievements')
          .where('childId', isEqualTo: 'kid1')
          .get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first['achievementId'], 'first_win');
      expect(snap.docs.first['note'], 'Перша перемога!');
    });

    test('тренер масово видає → всі спортсмени отримали ачівку', () async {
      final db = _db();
      final coachN = _notifier(db);

      await coachN.grantBulk(
        childIds: ['kid1', 'kid2', 'kid3'],
        defIds: ['tournament_winner'],
        coachId: 'coach1',
      );

      for (final kidId in ['kid1', 'kid2', 'kid3']) {
        final snap = await db
            .collection('achievements')
            .where('childId', isEqualTo: kidId)
            .get();
        expect(snap.docs, hasLength(1),
            reason: '$kidId повинен мати 1 ачівку');
      }
    });

    test('тренер скасовує ачівку → спортсмен більше не бачить її', () async {
      final db = _db();
      final coachN = _notifier(db);

      await coachN.grant('kid1', 'first_win', 'coach1');
      await coachN.revoke('kid1', 'first_win');

      final snap = await db
          .collection('achievements')
          .where('childId', isEqualTo: 'kid1')
          .get();
      expect(snap.docs, isEmpty);
    });

    test('повний сценарій: видати 3 ачівки, скасувати 1, залишити 2', () async {
      final db = _db();
      final n = _notifier(db);

      await n.grant('kid1', 'first_win', 'coach1');
      await n.grant('kid1', 'belt_white', 'coach1');
      await n.grant('kid1', 'mvp', 'coach1', note: 'MVP сезону');

      var snap = await db
          .collection('achievements')
          .where('childId', isEqualTo: 'kid1')
          .get();
      expect(snap.docs, hasLength(3));

      await n.revoke('kid1', 'belt_white');

      snap = await db
          .collection('achievements')
          .where('childId', isEqualTo: 'kid1')
          .get();
      expect(snap.docs, hasLength(2));
      final ids = snap.docs.map((d) => d['achievementId'] as String).toSet();
      expect(ids, containsAll(['first_win', 'mvp']));
      expect(ids, isNot(contains('belt_white')));
    });
  });
}

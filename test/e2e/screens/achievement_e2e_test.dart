/// E2E тести для AchievementNotifier — CRUD досягнень.
/// Покриває: grant (створення), revoke (видалення), grantBulk.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/features/achievements/providers/achievement_provider.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

ProviderContainer _container(FakeFirebaseFirestore db) => ProviderContainer(
      overrides: [firestoreProvider.overrideWithValue(db)],
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('AchievementNotifier — grant (тренер видає досягнення)', () {
    test('створює документ у колекції achievements', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(achievementNotifierProvider.notifier).grant(
            'kid1',
            'friend_of_team',
            'coach1',
          );

      final snap = await db.collection('achievements').get();
      expect(snap.docs, hasLength(1));

      final data = snap.docs.first.data();
      expect(data['childId'], 'kid1');
      expect(data['achievementId'], 'friend_of_team');
      expect(data['grantedByCoachId'], 'coach1');
    });

    test('doc ID = childId_defId', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(achievementNotifierProvider.notifier).grant(
            'kid1',
            'champion',
            'coach1',
          );

      final doc = await db.collection('achievements').doc('kid1_champion').get();
      expect(doc.exists, isTrue);
      expect(doc['achievementId'], 'champion');
    });

    test('зберігає note коли передано', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(achievementNotifierProvider.notifier).grant(
            'kid1',
            'friend_of_team',
            'coach1',
            note: 'Завжди допомагає',
          );

      final doc = await db.collection('achievements').doc('kid1_friend_of_team').get();
      expect(doc['note'], 'Завжди допомагає');
    });

    test('не зберігає note коли порожній рядок', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(achievementNotifierProvider.notifier).grant(
            'kid1',
            'friend_of_team',
            'coach1',
            note: '',
          );

      final doc = await db.collection('achievements').doc('kid1_friend_of_team').get();
      expect(doc.data()!.containsKey('note'), isFalse);
    });

    test('стан = AsyncData після успішного grant', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(achievementNotifierProvider.notifier).grant(
            'kid1',
            'friend_of_team',
            'coach1',
          );

      expect(c.read(achievementNotifierProvider), isA<AsyncData<void>>());
    });

    test('повторний grant того самого досягнення — оновлює документ (upsert)', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(achievementNotifierProvider.notifier);
      await n.grant('kid1', 'champion', 'coach1');
      await n.grant('kid1', 'champion', 'coach2', note: 'Оновлено');

      final snap = await db.collection('achievements').get();
      expect(snap.docs, hasLength(1)); // same doc, overwritten
      expect(snap.docs.first['grantedByCoachId'], 'coach2');
      expect(snap.docs.first['note'], 'Оновлено');
    });
  });

  group('AchievementNotifier — revoke (відкликати досягнення)', () {
    test('видаляє документ досягнення', () async {
      final db = _db();

      // Pre-seed
      await db.collection('achievements').doc('kid1_champion').set({
        'childId': 'kid1',
        'achievementId': 'champion',
        'earnedAt': Timestamp.now(),
        'grantedByCoachId': 'coach1',
      });

      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(achievementNotifierProvider.notifier).revoke('kid1', 'champion');

      final doc = await db.collection('achievements').doc('kid1_champion').get();
      expect(doc.exists, isFalse);
    });

    test('stан = AsyncData після успішного revoke', () async {
      final db = _db();
      await db.collection('achievements').doc('kid1_champion').set({
        'childId': 'kid1',
        'achievementId': 'champion',
        'earnedAt': Timestamp.now(),
        'grantedByCoachId': 'coach1',
      });

      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(achievementNotifierProvider.notifier).revoke('kid1', 'champion');

      expect(c.read(achievementNotifierProvider), isA<AsyncData<void>>());
    });
  });

  group('AchievementNotifier — grantBulk', () {
    test('видає кілька досягнень кільком спортсменам', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(achievementNotifierProvider.notifier).grantBulk(
            childIds: ['kid1', 'kid2'],
            defIds: ['champion', 'friend_of_team'],
            coachId: 'coach1',
          );

      final snap = await db.collection('achievements').get();
      expect(snap.docs, hasLength(4)); // 2 kids × 2 defs

      final ids = snap.docs.map((d) => d.id).toSet();
      expect(ids, containsAll([
        'kid1_champion',
        'kid1_friend_of_team',
        'kid2_champion',
        'kid2_friend_of_team',
      ]));
    });

    test('стан = AsyncData після grantBulk', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(achievementNotifierProvider.notifier).grantBulk(
            childIds: ['kid1'],
            defIds: ['champion'],
            coachId: 'coach1',
          );

      expect(c.read(achievementNotifierProvider), isA<AsyncData<void>>());
    });
  });

  group('AchievementNotifier — повний сценарій', () {
    test('тренер видає → спортсмен бачить у Firestore → тренер відкликає', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(achievementNotifierProvider.notifier);

      // 1. Тренер видає досягнення
      await n.grant('kid1', 'friend_of_team', 'coach1',
          note: 'Завжди допомагає');

      // 2. Документ є у Firestore
      final doc1 = await db.collection('achievements').doc('kid1_friend_of_team').get();
      expect(doc1.exists, isTrue);
      expect(doc1['childId'], 'kid1');
      expect(doc1['achievementId'], 'friend_of_team');
      expect(doc1['note'], 'Завжди допомагає');

      // 3. childAchievementsProvider знайде цей запис
      final stream = db
          .collection('achievements')
          .where('childId', isEqualTo: 'kid1')
          .snapshots();
      final firstSnap = await stream.first;
      expect(firstSnap.docs, hasLength(1));
      expect(firstSnap.docs.first['achievementId'], 'friend_of_team');

      // 4. Тренер відкликає
      await n.revoke('kid1', 'friend_of_team');

      final doc2 = await db.collection('achievements').doc('kid1_friend_of_team').get();
      expect(doc2.exists, isFalse);
    });
  });
}

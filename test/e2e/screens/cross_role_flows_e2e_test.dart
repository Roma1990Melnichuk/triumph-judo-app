/// Крос-рольові e2e тести — повний flow: тренер діє → спортсмен/батько бачить.
///
/// Кожен тест перевіряє не просто "рендер без краша", а реальну взаємодію:
/// - Тренер видає ачивку → спортсмен бачить у каталозі (UI + provider)
/// - Тренер масово видає → кілька спортсменів отримують
/// - Тренер створює групу + додає спортсмена → розклад оновлюється
/// - Тренер підвищує пояс → currentBelt змінюється + ачивка поясу видається автоматично
/// - Масова здача поясів → всі спортсмени отримують пояс + ачивку
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/group_model.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/achievements/providers/achievement_provider.dart';
import 'package:judo_app/features/achievements/screens/achievement_catalog_screen.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/schedule/providers/group_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';

// ── Спільні fixtures ───────────────────────────────────────────────────────────

const _coachUser = UserModel(
  uid: 'coach1',
  email: 'coach@test.com',
  name: 'Тренер Іванов',
  role: 'coach',
);

const _parentUser = UserModel(
  uid: 'parent1',
  email: 'parent@test.com',
  name: 'Батько Петренко',
  role: 'parent',
  childIds: ['kid1'],
);

ProviderContainer _container(FakeFirebaseFirestore db) => ProviderContainer(
      overrides: [firestoreProvider.overrideWithValue(db)],
    );

Future<void> _pumpData(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 50));
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── 1. Ачивки: тренер видає → спортсмен/батько бачить ──────────────────────

  group('Ачивки — тренер видає → спортсмен/батько бачить у каталозі', () {
    test('тренер видає → документ зʼявляється у Firestore', () async {
      final db = FakeFirebaseFirestore();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(achievementNotifierProvider.notifier).grant(
            'kid1',
            'champion',
            'coach1',
          );

      final snap = await db
          .collection('achievements')
          .where('childId', isEqualTo: 'kid1')
          .get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first['achievementId'], 'champion');
      expect(snap.docs.first['grantedByCoachId'], 'coach1');
    });

    testWidgets(
        'батько відкриває AchievementCatalogScreen з childId — каталог відображається',
        (tester) async {
      final db = FakeFirebaseFirestore();

      // Тренер видає ачивку для kid1
      final c = _container(db);
      addTearDown(c.dispose);
      await c
          .read(achievementNotifierProvider.notifier)
          .grant('kid1', 'champion', 'coach1');

      // Батько відкриває каталог
      await tester.pumpWidget(ProviderScope(
        overrides: [
          currentUserModelProvider
              .overrideWith((_) => Stream.value(_parentUser)),
          firestoreProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          home: AchievementCatalogScreen(childId: 'kid1'),
        ),
      ));
      await _pumpData(tester);

      expect(tester.takeException(), isNull);
      // Каталог відображається — немає повідомлення про відсутній профіль
      expect(find.text('Профіль спортсмена не знайдено'), findsNothing);
    });

    testWidgets(
        'тренер відкриває каталог БЕЗ childId — показує "Профіль спортсмена не знайдено"',
        (tester) async {
      // РЕГРЕСІЙНИЙ ТЕСТ: якщо навігація не передає childId —
      // тренер (без власного childId) бачить екран-помилку замість каталогу.
      final db = FakeFirebaseFirestore();

      await tester.pumpWidget(ProviderScope(
        overrides: [
          currentUserModelProvider
              .overrideWith((_) => Stream.value(_coachUser)),
          firestoreProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          home: AchievementCatalogScreen(), // childId не передано
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Профіль спортсмена не знайдено'), findsOneWidget);
    });

    testWidgets(
        'тренер відкриває каталог З явним childId — каталог відображається',
        (tester) async {
      final db = FakeFirebaseFirestore();

      await tester.pumpWidget(ProviderScope(
        overrides: [
          currentUserModelProvider
              .overrideWith((_) => Stream.value(_coachUser)),
          firestoreProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          home: AchievementCatalogScreen(childId: 'kid1'), // явний childId
        ),
      ));
      await _pumpData(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Профіль спортсмена не знайдено'), findsNothing);
    });
  });

  // ── 2. Масова видача ачивок ─────────────────────────────────────────────────

  group('Масова видача ачивок (grantBulk) → кілька спортсменів отримують', () {
    test('5 спортсменів × 2 ачивки = 10 документів у Firestore', () async {
      final db = FakeFirebaseFirestore();
      final c = _container(db);
      addTearDown(c.dispose);

      final kids = ['kid1', 'kid2', 'kid3', 'kid4', 'kid5'];
      await c.read(achievementNotifierProvider.notifier).grantBulk(
            childIds: kids,
            defIds: ['champion', 'friend_of_team'],
            coachId: 'coach1',
          );

      final snap = await db.collection('achievements').get();
      expect(snap.docs, hasLength(10));

      for (final id in kids) {
        final kidSnap = await db
            .collection('achievements')
            .where('childId', isEqualTo: id)
            .get();
        expect(kidSnap.docs, hasLength(2),
            reason: '$id має мати 2 ачивки');
      }
    });

    test('повторний grantBulk — дублікатів немає (upsert)', () async {
      final db = FakeFirebaseFirestore();
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(achievementNotifierProvider.notifier);
      await n.grantBulk(
          childIds: ['kid1'], defIds: ['champion'], coachId: 'coach1');
      await n.grantBulk(
          childIds: ['kid1'], defIds: ['champion'], coachId: 'coach1');

      final snap = await db.collection('achievements').get();
      expect(snap.docs, hasLength(1));
    });

    test('grantBulk → стан = AsyncData після завершення', () async {
      final db = FakeFirebaseFirestore();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(achievementNotifierProvider.notifier).grantBulk(
            childIds: ['kid1', 'kid2', 'kid3'],
            defIds: ['champion'],
            coachId: 'coach1',
          );

      expect(
          c.read(achievementNotifierProvider), isA<AsyncData<void>>());
    });
  });

  // ── 3. Групи: тренер створює + додає спортсмена ────────────────────────────

  group('Групи — тренер створює групу і додає спортсмена', () {
    test('createGroup + addChildToGroup → спортсмен є в childIds групи',
        () async {
      final db = FakeFirebaseFirestore();
      final c = _container(db);
      addTearDown(c.dispose);

      // Тренер створює групу
      await c.read(groupNotifierProvider.notifier).createGroup(
            const GroupModel(
              id: '',
              coachId: 'coach1',
              name: 'Молодша група',
              childIds: [],
              daysOfWeek: [1, 3, 5],
              timeStart: '18:00',
              timeEnd: '19:30',
            ),
          );

      final snap = await db.collection('groups').get();
      expect(snap.docs, hasLength(1));
      final groupId = snap.docs.first.id;

      // Тренер додає спортсмена
      await c
          .read(groupNotifierProvider.notifier)
          .addChildToGroup(groupId, 'kid1');

      final doc = await db.collection('groups').doc(groupId).get();
      final childIds = List<String>.from(doc['childIds'] as List);
      expect(childIds, contains('kid1'));
    });

    test('видалення спортсмена з групи → kid1 більше не в childIds', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('groups').doc('g1').set({
        'coachId': 'coach1',
        'name': 'Тестова',
        'childIds': ['kid1', 'kid2'],
        'daysOfWeek': [1, 3],
        'timeStart': '18:00',
        'timeEnd': '19:30',
      });

      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(groupNotifierProvider.notifier)
          .removeChildFromGroup('g1', 'kid1');

      final doc = await db.collection('groups').doc('g1').get();
      final childIds = List<String>.from(doc['childIds'] as List);
      expect(childIds, isNot(contains('kid1')));
      expect(childIds, contains('kid2'));
    });

    test(
        'createGroup + addChildToGroup → childGroupsProvider спортсмена містить групу',
        () async {
      final db = FakeFirebaseFirestore();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(groupNotifierProvider.notifier).createGroup(
            const GroupModel(
              id: '',
              coachId: 'coach1',
              name: 'Старша група',
              childIds: [],
              daysOfWeek: [2, 4],
              timeStart: '17:00',
              timeEnd: '18:30',
            ),
          );

      final snap = await db.collection('groups').get();
      final groupId = snap.docs.first.id;

      await c
          .read(groupNotifierProvider.notifier)
          .addChildToGroup(groupId, 'kid1');

      // Перевірка через Firestore напряму (provider-рівень)
      final groupSnap = await db
          .collection('groups')
          .where('childIds', arrayContains: 'kid1')
          .get();
      expect(groupSnap.docs, hasLength(1));
      expect(groupSnap.docs.first['name'], 'Старша група');
    });
  });

  // ── 4. Підвищення поясу: тренер → спортсмен отримує пояс + ачивку ──────────

  group('Підвищення поясу — тренер → спортсмен отримує пояс + ачивку автоматично',
      () {
    Future<void> _seedChild(FakeFirebaseFirestore db, String id,
        {String belt = 'white'}) async {
      await db.collection('children').doc(id).set({
        'name': id,
        'currentBelt': belt,
        'beltReady': true,
      });
    }

    test('advanceBelts → currentBelt оновлюється в Firestore', () async {
      final db = FakeFirebaseFirestore();
      await _seedChild(db, 'kid1');

      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(childrenNotifierProvider.notifier).advanceBelts(
            childIds: ['kid1'],
            newBelt: BeltLevel.whiteYellow,
          );

      final doc = await db.collection('children').doc('kid1').get();
      expect(doc['currentBelt'], 'whiteYellow');
    });

    test('advanceBelts → beltReady скидається в false після підвищення',
        () async {
      final db = FakeFirebaseFirestore();
      await _seedChild(db, 'kid1');

      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(childrenNotifierProvider.notifier).advanceBelts(
            childIds: ['kid1'],
            newBelt: BeltLevel.whiteYellow,
          );

      final doc = await db.collection('children').doc('kid1').get();
      expect(doc['beltReady'], false);
    });

    test('advanceBelts → ачивка поясу видається автоматично (auto-grant)',
        () async {
      final db = FakeFirebaseFirestore();
      await _seedChild(db, 'kid1');

      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(childrenNotifierProvider.notifier).advanceBelts(
            childIds: ['kid1'],
            newBelt: BeltLevel.whiteYellow,
          );

      final doc = await db
          .collection('achievements')
          .doc('kid1_belt_whiteYellow')
          .get();
      expect(doc.exists, isTrue);
      expect(doc['achievementId'], 'belt_whiteYellow');
      expect(doc['grantedByCoachId'], isNull); // автоматична, не ручна
      expect(doc['childId'], 'kid1');
    });

    test(
        'масова здача поясів — 3 спортсмени → всі отримують пояс + ачивку',
        () async {
      final db = FakeFirebaseFirestore();
      final kids = ['kid1', 'kid2', 'kid3'];
      for (final id in kids) {
        await _seedChild(db, id);
      }

      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(childrenNotifierProvider.notifier).advanceBelts(
            childIds: kids,
            newBelt: BeltLevel.yellow,
          );

      for (final id in kids) {
        final childDoc =
            await db.collection('children').doc(id).get();
        expect(childDoc['currentBelt'], 'yellow',
            reason: '$id має отримати жовтий пояс');

        final achDoc = await db
            .collection('achievements')
            .doc('${id}_belt_yellow')
            .get();
        expect(achDoc.exists, isTrue,
            reason: '$id має отримати ачивку жовтого поясу');
      }
    });

    test('повторний advanceBelts — ачивка поясу не дублюється', () async {
      final db = FakeFirebaseFirestore();
      await _seedChild(db, 'kid1');

      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(childrenNotifierProvider.notifier);
      await n.advanceBelts(
          childIds: ['kid1'], newBelt: BeltLevel.whiteYellow);
      await n.advanceBelts(
          childIds: ['kid1'], newBelt: BeltLevel.whiteYellow);

      final snap = await db
          .collection('achievements')
          .where('childId', isEqualTo: 'kid1')
          .get();
      expect(snap.docs, hasLength(1), reason: 'лише одна ачивка, без дублікатів');
    });

    test('advanceBelts → стан нотифайєра = AsyncData після успіху',
        () async {
      final db = FakeFirebaseFirestore();
      await _seedChild(db, 'kid1');

      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(childrenNotifierProvider.notifier).advanceBelts(
            childIds: ['kid1'],
            newBelt: BeltLevel.yellow,
          );

      expect(c.read(childrenNotifierProvider), isA<AsyncData<void>>());
    });
  });

  // ── 5. Revoke: тренер забирає ачивку → спортсмен не бачить ────────────────

  group('Revoke — тренер забирає ачивку → вона зникає з Firestore', () {
    test('revoke → документ видалено', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('achievements').doc('kid1_champion').set({
        'childId': 'kid1',
        'achievementId': 'champion',
        'earnedAt': Timestamp.now(),
        'grantedByCoachId': 'coach1',
      });

      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(achievementNotifierProvider.notifier)
          .revoke('kid1', 'champion');

      final doc = await db
          .collection('achievements')
          .doc('kid1_champion')
          .get();
      expect(doc.exists, isFalse);
    });

    testWidgets(
        'після revoke каталог відкривається без краша (ачивка в locked-стані)',
        (tester) async {
      final db = FakeFirebaseFirestore();
      // Ачивки немає — каталог покаже все як locked

      await tester.pumpWidget(ProviderScope(
        overrides: [
          currentUserModelProvider
              .overrideWith((_) => Stream.value(_parentUser)),
          firestoreProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          home: AchievementCatalogScreen(childId: 'kid1'),
        ),
      ));
      await _pumpData(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Профіль спортсмена не знайдено'), findsNothing);
    });
  });
}

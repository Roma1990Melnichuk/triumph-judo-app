/// E2E тести для NotificationsNotifier + myNotificationsProvider.
/// Покриває: send, markRead, delete, targeting logic (all / ageGroup / belt / personal).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/core/models/notification_model.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/notifications/providers/notification_provider.dart';
import 'package:judo_app/features/notifications/screens/notifications_screen.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';

// ── Хелпери ───────────────────────────────────────────────────────────────────

final _coach = UserModel(
  uid: 'coach1',
  email: 'coach@test.com',
  name: 'Тренер',
  role: 'coach',
);

final _parent = UserModel(
  uid: 'parent1',
  email: 'parent@test.com',
  name: 'Батько',
  role: 'parent',
  childId: 'kid1',
  childIds: const ['kid1'],
);

ChildModel _child({
  String id = 'kid1',
  int birthYear = 2012,
  BeltLevel belt = BeltLevel.white,
}) =>
    ChildModel(
      id: id,
      firstName: 'Іван',
      lastName: 'Петренко',
      birthYear: birthYear,
      weightCategory: '-30 кг',
      currentBelt: belt,
      coachId: 'coach1',
      coachName: 'Тренер',
      totalPoints: 0,
      createdAt: DateTime(2024),
      beltReady: false,
      bonusPoints: 0,
    );

NotificationModel _notif({
  String id = '',
  String title = 'Тестове повідомлення',
  NotificationTarget target = NotificationTarget.all,
  List<String> targetValues = const [],
}) =>
    NotificationModel(
      id: id,
      title: title,
      body: 'Текст повідомлення',
      target: target,
      targetValues: targetValues,
      sentAt: DateTime(2025, 6, 15),
      coachId: 'coach1',
      coachName: 'Тренер',
      readByUserIds: const [],
    );

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

ProviderContainer _coachContainer(FakeFirebaseFirestore db) =>
    ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(db),
        currentUserModelProvider
            .overrideWith((_) => Stream.value(_coach)),
        allChildrenProvider.overrideWith((_) => Stream.value(const [])),
      ],
    );

ProviderContainer _parentContainer(
  FakeFirebaseFirestore db,
  List<ChildModel> children,
) =>
    ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(db),
        currentUserModelProvider
            .overrideWith((_) => Stream.value(_parent)),
        allChildrenProvider
            .overrideWith((_) => Stream.value(children)),
      ],
    );

GoRouter _router() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const NotificationsScreen()),
        GoRoute(
            path: '/notifications/send',
            builder: (_, __) =>
                const Scaffold(body: Text('send notification'))),
      ],
    );

Widget _app(UserModel user, FakeFirebaseFirestore db) {
  return ProviderScope(
    overrides: [
      currentUserModelProvider.overrideWith((_) => Stream.value(user)),
      allChildrenProvider.overrideWith((_) => Stream.value(const [])),
      firestoreProvider.overrideWithValue(db),
    ],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

Future<void> _pumpData(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 50));
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── Render ────────────────────────────────────────────────────────────────

  group('NotificationsScreen — рендер', () {
    testWidgets('тренер: рендериться без краша і overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app(_coach, FakeFirebaseFirestore()));
      await _pumpData(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('батько: рендериться без краша і overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app(_parent, FakeFirebaseFirestore()));
      await _pumpData(tester);

      expect(tester.takeException(), isNull);
    });
  });

  // ── send ──────────────────────────────────────────────────────────────────

  group('NotificationsNotifier — send', () {
    test('зберігає повідомлення у Firestore', () async {
      final db = _db();
      final c = _coachContainer(db);
      addTearDown(c.dispose);

      await c.read(notificationsNotifierProvider.notifier).send(
            _notif(title: 'Нова тренування'),
          );

      final snap = await db.collection('notifications').get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first['title'], 'Нова тренування');
      expect(snap.docs.first['target'], 'all');
      expect(snap.docs.first['coachId'], 'coach1');
    });

    test('зберігає targetValues для ageGroup', () async {
      final db = _db();
      final c = _coachContainer(db);
      addTearDown(c.dispose);

      await c.read(notificationsNotifierProvider.notifier).send(
            _notif(
              title: 'Для вікової групи',
              target: NotificationTarget.ageGroup,
              targetValues: ['2010', '2011'],
            ),
          );

      final doc = (await db.collection('notifications').get()).docs.first;
      expect(doc['target'], 'ageGroup');
      expect(List<String>.from(doc['targetValues'] as List),
          containsAll(['2010', '2011']));
    });

    test('стан = AsyncData після send', () async {
      final db = _db();
      final c = _coachContainer(db);
      addTearDown(c.dispose);

      await c.read(notificationsNotifierProvider.notifier).send(_notif());
      expect(
          c.read(notificationsNotifierProvider), isA<AsyncData<void>>());
    });

    test('кілька повідомлень — кожне отримує унікальний ID', () async {
      final db = _db();
      final c = _coachContainer(db);
      addTearDown(c.dispose);

      final n = c.read(notificationsNotifierProvider.notifier);
      await n.send(_notif(title: 'Повідомлення 1'));
      await n.send(_notif(title: 'Повідомлення 2'));
      await n.send(_notif(title: 'Повідомлення 3'));

      final snap = await db.collection('notifications').get();
      expect(snap.docs, hasLength(3));
      final ids = snap.docs.map((d) => d.id).toSet();
      expect(ids, hasLength(3));
    });
  });

  // ── markRead ──────────────────────────────────────────────────────────────

  group('NotificationsNotifier — markRead', () {
    test('додає uid до readByUserIds', () async {
      final db = _db();
      final ref =
          await db.collection('notifications').add(_notif().toFirestore());
      final c = _coachContainer(db);
      addTearDown(c.dispose);

      await c
          .read(notificationsNotifierProvider.notifier)
          .markRead(ref.id, 'parent1');

      final doc = await db.collection('notifications').doc(ref.id).get();
      expect(
          List<String>.from(doc['readByUserIds'] as List), contains('parent1'));
    });

    test('markRead двічі — uid не дублюється', () async {
      final db = _db();
      final ref =
          await db.collection('notifications').add(_notif().toFirestore());
      final c = _coachContainer(db);
      addTearDown(c.dispose);

      final n = c.read(notificationsNotifierProvider.notifier);
      await n.markRead(ref.id, 'parent1');
      await n.markRead(ref.id, 'parent1');

      final doc = await db.collection('notifications').doc(ref.id).get();
      final readers =
          List<String>.from(doc['readByUserIds'] as List);
      expect(readers.where((id) => id == 'parent1'), hasLength(1));
    });

    test('кілька користувачів читають різні повідомлення', () async {
      final db = _db();
      final ref1 =
          await db.collection('notifications').add(_notif().toFirestore());
      final ref2 =
          await db.collection('notifications').add(_notif().toFirestore());
      final c = _coachContainer(db);
      addTearDown(c.dispose);

      final n = c.read(notificationsNotifierProvider.notifier);
      await n.markRead(ref1.id, 'parent1');
      await n.markRead(ref2.id, 'parent2');

      final doc1 = await db.collection('notifications').doc(ref1.id).get();
      final doc2 = await db.collection('notifications').doc(ref2.id).get();
      expect(List<String>.from(doc1['readByUserIds'] as List),
          contains('parent1'));
      expect(List<String>.from(doc2['readByUserIds'] as List),
          contains('parent2'));
      expect(List<String>.from(doc1['readByUserIds'] as List),
          isNot(contains('parent2')));
    });
  });

  // ── delete ────────────────────────────────────────────────────────────────

  group('NotificationsNotifier — delete', () {
    test('видаляє повідомлення з Firestore', () async {
      final db = _db();
      final ref =
          await db.collection('notifications').add(_notif().toFirestore());
      final c = _coachContainer(db);
      addTearDown(c.dispose);

      await c.read(notificationsNotifierProvider.notifier).delete(ref.id);

      expect(
          (await db.collection('notifications').doc(ref.id).get()).exists,
          isFalse);
    });

    test('видаляє тільки потрібне — інші залишаються', () async {
      final db = _db();
      final ref1 =
          await db.collection('notifications').add(_notif().toFirestore());
      final ref2 =
          await db.collection('notifications').add(_notif().toFirestore());
      final c = _coachContainer(db);
      addTearDown(c.dispose);

      await c.read(notificationsNotifierProvider.notifier).delete(ref1.id);

      expect(
          (await db.collection('notifications').doc(ref1.id).get()).exists,
          isFalse);
      expect(
          (await db.collection('notifications').doc(ref2.id).get()).exists,
          isTrue);
    });
  });

  // ── myNotificationsProvider — targeting logic ─────────────────────────────

  group('myNotificationsProvider — targeting logic', () {
    test('target=all → батько отримує повідомлення', () async {
      final db = _db();

      // Тренер надсилає
      final coachC = _coachContainer(db);
      addTearDown(coachC.dispose);
      await coachC
          .read(notificationsNotifierProvider.notifier)
          .send(_notif(target: NotificationTarget.all));

      // Перевірка в Firestore
      final snap = await db
          .collection('notifications')
          .where('target', isEqualTo: 'all')
          .get();
      expect(snap.docs, hasLength(1));
    });

    test('target=ageGroup з відповідним роком → батько отримує', () async {
      final db = _db();
      final coachC = _coachContainer(db);
      addTearDown(coachC.dispose);

      await coachC.read(notificationsNotifierProvider.notifier).send(
            _notif(
              target: NotificationTarget.ageGroup,
              targetValues: ['2012'],
            ),
          );

      // Батько з дитиною 2012 → має отримати
      final child = _child(birthYear: 2012);
      final parentC = _parentContainer(db, [child]);
      addTearDown(parentC.dispose);

      // Зчитуємо allNotificationsProvider
      final allSnap = await db.collection('notifications').get();
      expect(allSnap.docs, hasLength(1));

      final n = allSnap.docs.first;
      final targetValues =
          List<String>.from(n['targetValues'] as List);
      expect(targetValues.contains(child.birthYear.toString()), isTrue);
    });

    test(
        'target=ageGroup з іншим роком → батько НЕ отримує', () async {
      final db = _db();
      final coachC = _coachContainer(db);
      addTearDown(coachC.dispose);

      await coachC.read(notificationsNotifierProvider.notifier).send(
            _notif(
              target: NotificationTarget.ageGroup,
              targetValues: ['2008'],
            ),
          );

      // Дитина батька народилась в 2012 — не відповідає 2008
      final child = _child(birthYear: 2012);
      final n = (await db.collection('notifications').get()).docs.first;
      final targetValues =
          List<String>.from(n['targetValues'] as List);
      expect(targetValues.contains(child.birthYear.toString()), isFalse);
    });

    test('target=belt → відповідає дитині з тим же поясом', () async {
      final db = _db();
      final coachC = _coachContainer(db);
      addTearDown(coachC.dispose);

      await coachC.read(notificationsNotifierProvider.notifier).send(
            _notif(
              target: NotificationTarget.belt,
              targetValues: ['white'],
            ),
          );

      final child = _child(belt: BeltLevel.white);
      final n = (await db.collection('notifications').get()).docs.first;
      expect(
          List<String>.from(n['targetValues'] as List)
              .contains(child.currentBelt.name),
          isTrue);
    });

    test('target=personal з дитиною батька → відповідає', () async {
      final db = _db();
      final coachC = _coachContainer(db);
      addTearDown(coachC.dispose);

      await coachC.read(notificationsNotifierProvider.notifier).send(
            _notif(
              target: NotificationTarget.personal,
              targetValues: ['kid1'],
            ),
          );

      // parent ownsChild('kid1') → має отримати
      final n = (await db.collection('notifications').get()).docs.first;
      expect(
          List<String>.from(n['targetValues'] as List).contains('kid1'),
          isTrue);
    });

    test('target=personal з чужою дитиною → батько НЕ отримує', () async {
      final db = _db();
      final coachC = _coachContainer(db);
      addTearDown(coachC.dispose);

      await coachC.read(notificationsNotifierProvider.notifier).send(
            _notif(
              target: NotificationTarget.personal,
              targetValues: ['kid99'],
            ),
          );

      final n = (await db.collection('notifications').get()).docs.first;
      // parent має kid1, а не kid99
      expect(
          List<String>.from(n['targetValues'] as List).contains('kid1'),
          isFalse);
    });
  });

  // ── Повний сценарій тренера ───────────────────────────────────────────────

  group('Notifications — повний сценарій', () {
    test(
        'тренер: надсилає 3 повідомлення → 2 читають батьки → '
        'тренер видаляє одне', () async {
      final db = _db();
      final c = _coachContainer(db);
      addTearDown(c.dispose);
      final n = c.read(notificationsNotifierProvider.notifier);

      // 1. Тренер надсилає 3 повідомлення
      await n.send(_notif(title: 'Повідомлення 1'));
      await n.send(_notif(title: 'Повідомлення 2'));
      await n.send(_notif(title: 'Повідомлення 3'));

      var all = await db.collection('notifications').get();
      expect(all.docs, hasLength(3));

      final ids = all.docs.map((d) => d.id).toList();

      // 2. Двоє батьків читають перше повідомлення
      await n.markRead(ids[0], 'parent1');
      await n.markRead(ids[0], 'parent2');
      final doc0 = await db.collection('notifications').doc(ids[0]).get();
      expect(
          List<String>.from(doc0['readByUserIds'] as List),
          containsAll(['parent1', 'parent2']));

      // 3. Тренер видаляє друге повідомлення
      await n.delete(ids[1]);
      all = await db.collection('notifications').get();
      expect(all.docs, hasLength(2));
      expect(all.docs.map((d) => d.id), isNot(contains(ids[1])));
    });
  });
}

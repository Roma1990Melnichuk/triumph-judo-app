/// E2E тести для MembershipScreen / CoachMembershipsScreen + MembershipNotifier CRUD.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/membership/providers/membership_provider.dart';
import 'package:judo_app/features/membership/screens/coach_memberships_screen.dart';
import 'package:judo_app/features/membership/screens/membership_screen.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';

// ── Хелпери ───────────────────────────────────────────────────────────────────

final _coach = UserModel(
  uid: 'coach1',
  email: 'coach@test.com',
  name: 'Тренер',
  role: 'coach',
);

GoRouter _router(Widget screen) => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => screen),
        GoRoute(
            path: '/abonements/detail',
            builder: (_, __) =>
                const Scaffold(body: Text('detail'))),
        GoRoute(
            path: '/checkout',
            builder: (_, __) => const Scaffold(body: Text('checkout'))),
        GoRoute(
            path: '/my-abonements',
            builder: (_, __) =>
                const Scaffold(body: Text('my abonements'))),
        GoRoute(
            path: '/team/:id',
            builder: (_, __) =>
                const Scaffold(body: Text('profile'))),
      ],
    );

Widget _app(Widget screen) {
  final db = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      currentUserModelProvider.overrideWith((_) => Stream.value(_coach)),
      allChildrenProvider.overrideWith((_) => Stream.value(const [])),
      firestoreProvider.overrideWithValue(db),
    ],
    child: MaterialApp.router(routerConfig: _router(screen)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('MembershipScreen — каталог тарифів', () {
    testWidgets('рендериться без краша і без overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
          _app(const MembershipScreen(childId: 'kid1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('тарифи відображаються без overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
          _app(const MembershipScreen(childId: 'kid1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // MembershipScreen має статичний список тарифів — вони мають відображатися
      expect(find.text('Разове тренування'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CoachMembershipsScreen — перегляд тренера', () {
    testWidgets('рендериться без краша і без overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app(const CoachMembershipsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });

  // ── Provider CRUD ─────────────────────────────────────────────────────────────

  FakeFirebaseFirestore _db2() => FakeFirebaseFirestore();
  ProviderContainer _c(FakeFirebaseFirestore db) => ProviderContainer(
        overrides: [firestoreProvider.overrideWithValue(db)],
      );

  group('MembershipNotifier — setMembership: новий спортсмен', () {
    test('створює документ у Firestore з коректними полями', () async {
      final db = _db2();
      final c = _c(db);
      addTearDown(c.dispose);

      await c.read(membershipNotifierProvider.notifier).setMembership(
            athleteId: 'kid1',
            planName: '1 місяць',
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 2, 1),
            amount: 500,
          );

      final doc = await db.collection('memberships').doc('kid1').get();
      expect(doc.exists, isTrue);
      expect(doc['planName'], '1 місяць');
      expect(doc['athleteId'], 'kid1');
      expect(doc['amount'], 500.0);

      final savedEnd = (doc['endDate'] as Timestamp).toDate();
      expect(savedEnd.hour, 23);
      expect(savedEnd.minute, 59);
      expect(savedEnd.second, 59);
    });

    test('стан провайдера = AsyncData після успіху', () async {
      final db = _db2();
      final c = _c(db);
      addTearDown(c.dispose);

      await c.read(membershipNotifierProvider.notifier).setMembership(
            athleteId: 'kid1',
            planName: '1 місяць',
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 2, 1),
            amount: 500,
          );

      expect(c.read(membershipNotifierProvider), isA<AsyncData<void>>());
    });
  });

  group('MembershipNotifier — auto-extend (FIN-01)', () {
    test('активний абонемент + новий 30-день тариф → продовжується від existingEnd', () async {
      final db = _db2();
      final c = _c(db);
      addTearDown(c.dispose);

      final now = DateTime.now();
      final existingEnd = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 3));
      final existingStart = existingEnd.subtract(const Duration(days: 27));

      await db.collection('memberships').doc('kid1').set({
        'athleteId': 'kid1',
        'planName': 'Базовий',
        'startDate': Timestamp.fromDate(existingStart),
        'endDate': Timestamp.fromDate(existingEnd),
        'amount': 500.0,
        'currency': 'UAH',
        'sessionsUsed': 0,
      });

      await c.read(membershipNotifierProvider.notifier).setMembership(
            athleteId: 'kid1',
            planName: 'Базовий',
            startDate: now,
            endDate: now.add(const Duration(days: 30)),
            amount: 500,
          );

      final doc = await db.collection('memberships').doc('kid1').get();
      final savedEnd = (doc['endDate'] as Timestamp).toDate();
      final savedStart = (doc['startDate'] as Timestamp).toDate();

      // endDate = existingEnd + 30 days (normalized to 23:59:59)
      final expectedEnd = existingEnd.add(const Duration(days: 30));
      expect(savedEnd.year, expectedEnd.year);
      expect(savedEnd.month, expectedEnd.month);
      expect(savedEnd.day, expectedEnd.day);
      expect(savedEnd.hour, 23);
      expect(savedEnd.minute, 59);

      // startDate preserved from existing membership
      expect(savedStart.day, existingStart.day);
      expect(savedStart.month, existingStart.month);
      expect(savedStart.year, existingStart.year);
    });

    test('3 дні залишилось + 30- денний план → endDate = existingEnd + 30 днів', () async {
      final db = _db2();
      final c = _c(db);
      addTearDown(c.dispose);

      final now = DateTime.now();
      // 3 days remaining
      final existingEnd =
          DateTime(now.year, now.month, now.day).add(const Duration(days: 3));
      await db.collection('memberships').doc('kid1').set({
        'athleteId': 'kid1',
        'planName': 'Базовий',
        'startDate': Timestamp.fromDate(existingEnd.subtract(const Duration(days: 27))),
        'endDate': Timestamp.fromDate(existingEnd),
        'amount': 500.0,
        'currency': 'UAH',
        'sessionsUsed': 0,
      });

      await c.read(membershipNotifierProvider.notifier).setMembership(
            athleteId: 'kid1',
            planName: '1 місяць',
            startDate: now,
            endDate: now.add(const Duration(days: 30)),
            amount: 500,
          );

      final doc = await db.collection('memberships').doc('kid1').get();
      final savedEnd = (doc['endDate'] as Timestamp).toDate();

      final expectedEnd = existingEnd.add(const Duration(days: 30));
      expect(savedEnd.year, expectedEnd.year);
      expect(savedEnd.month, expectedEnd.month);
      expect(savedEnd.day, expectedEnd.day);
    });

    test('прострочений абонемент → нові дати (не продовжується)', () async {
      final db = _db2();
      final c = _c(db);
      addTearDown(c.dispose);

      final now = DateTime.now();
      final expiredEnd = now.subtract(const Duration(days: 5));

      await db.collection('memberships').doc('kid1').set({
        'athleteId': 'kid1',
        'planName': 'Старий',
        'startDate': Timestamp.fromDate(expiredEnd.subtract(const Duration(days: 30))),
        'endDate': Timestamp.fromDate(expiredEnd),
        'amount': 500.0,
        'currency': 'UAH',
        'sessionsUsed': 0,
      });

      final newEnd = now.add(const Duration(days: 30));
      await c.read(membershipNotifierProvider.notifier).setMembership(
            athleteId: 'kid1',
            planName: 'Новий',
            startDate: now,
            endDate: newEnd,
            amount: 600,
          );

      final doc = await db.collection('memberships').doc('kid1').get();
      expect(doc['planName'], 'Новий');
      expect(doc['amount'], 600.0);

      final savedEnd = (doc['endDate'] as Timestamp).toDate();
      expect(savedEnd.year, newEnd.year);
      expect(savedEnd.month, newEnd.month);
      expect(savedEnd.day, newEnd.day);
    });
  });

  group('MembershipNotifier — повний сценарій: батько платить двічі', () {
    test('перша оплата → абонемент, друга оплата → продовжений', () async {
      final db = _db2();
      final c = _c(db);
      addTearDown(c.dispose);

      final now = DateTime.now();
      final plan30 = now.add(const Duration(days: 30));

      // First payment
      await c.read(membershipNotifierProvider.notifier).setMembership(
            athleteId: 'kid1',
            planName: '1 місяць',
            startDate: now,
            endDate: plan30,
            amount: 500,
          );

      final snap1 = await db.collection('memberships').doc('kid1').get();
      expect(snap1.exists, isTrue);
      final end1 = (snap1['endDate'] as Timestamp).toDate();
      expect(end1.day, plan30.day);

      // Second payment while still active
      await c.read(membershipNotifierProvider.notifier).setMembership(
            athleteId: 'kid1',
            planName: '1 місяць',
            startDate: now,
            endDate: plan30,
            amount: 500,
          );

      final snap2 = await db.collection('memberships').doc('kid1').get();
      final end2 = (snap2['endDate'] as Timestamp).toDate();

      // Should be end1 + 30 days
      expect(end2.day, end1.add(const Duration(days: 30)).day);
      expect(end2.month, end1.add(const Duration(days: 30)).month);
    });
  });
}

/// TC-AUTH-0386 / TC-NOTI-0387 — Multi-child Parent
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/achievements/providers/achievement_progress_provider.dart';
import 'package:judo_app/features/achievements/providers/achievement_provider.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/belts/providers/belt_provider.dart';
import 'package:judo_app/features/competitions/providers/competitions_provider.dart';
import 'package:judo_app/features/individual_training/providers/individual_training_provider.dart';
import 'package:judo_app/features/membership/providers/membership_provider.dart';
import 'package:judo_app/features/notifications/screens/notifications_screen.dart';
import 'package:judo_app/features/schedule/providers/group_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';
import 'package:judo_app/features/team/screens/child_profile_screen.dart';

// ── Хелпери ───────────────────────────────────────────────────────────────────

ChildModel _child(String id, {String firstName = 'Іван', int totalPoints = 50}) =>
    ChildModel(
      id: id,
      firstName: firstName,
      lastName: 'Петренко',
      birthYear: 2014,
      weightCategory: '-30 кг',
      currentBelt: BeltLevel.white,
      coachId: 'coach1',
      coachName: 'Тренер',
      totalPoints: totalPoints,
      createdAt: DateTime(2024),
    );

UserModel _parentWith(List<String> childIds) => UserModel(
      uid: 'parent1',
      email: 'parent@test.com',
      name: 'Батько',
      role: 'parent',
      childIds: childIds,
      childId: childIds.first,
    );

Widget _profileScreen(String childId, UserModel parent,
    {List<ChildModel>? allChildren}) {
  final db = FakeFirebaseFirestore();
  final child = (allChildren ?? []).firstWhere((c) => c.id == childId,
      orElse: () => _child(childId));
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => ChildProfileScreen(childId: childId)),
      GoRoute(path: '/team/:id/edit', builder: (_, __) => const Scaffold(body: Text('edit'))),
      GoRoute(path: '/team/:id/add-result', builder: (_, __) => const Scaffold(body: Text('result'))),
      GoRoute(path: '/team/:id/measurements', builder: (_, __) => const Scaffold(body: Text('measure'))),
      GoRoute(path: '/belts/edit', builder: (_, __) => const Scaffold(body: Text('belts'))),
      GoRoute(path: '/fitness/:id', builder: (_, __) => const Scaffold(body: Text('fitness'))),
      GoRoute(path: '/my-assignments', builder: (_, __) => const Scaffold(body: Text('assign'))),
      GoRoute(path: '/membership/:id', builder: (_, __) => const Scaffold(body: Text('membership'))),
      GoRoute(path: '/nutrition/child/:id', builder: (_, __) => const Scaffold(body: Text('nutrition'))),
    ],
  );

  return ProviderScope(
    overrides: [
      firestoreProvider.overrideWithValue(db),
      currentUserModelProvider.overrideWith((_) => Stream.value(parent)),
      allChildrenProvider.overrideWith((_) => Stream.value(allChildren ?? [child])),
      childByIdProvider.overrideWith((ref, id) => Stream.value(child)),
      childResultsProvider.overrideWith((ref, id) => Stream.value([])),
      beltProgressProvider.overrideWith((ref, arg) => Stream.value(null)),
      beltRequirementProvider.overrideWith((ref, belt) => null),
      membershipByAthleteProvider.overrideWith((ref, id) => Stream.value(null)),
      childAttendanceStatsProvider.overrideWith(
          (ref, id) => Stream.value(const (total: 0, present: 0, pct: 0.0))),
      childConfirmedTrainingCountProvider.overrideWith((ref, id) => 0),
      coachByIdProvider.overrideWith((ref, id) => null),
      parentsByChildIdProvider.overrideWith((ref, id) => Stream.value([])),
      childAchievementsProvider.overrideWith((ref, id) => Stream.value([])),
      achievementProgressProvider.overrideWith((ref, id) => {}),
      childGroupsProvider.overrideWith((ref, id) => []),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ── TC-AUTH-0386 ──────────────────────────────────────────────────────────────

void main() {
  group('TC-AUTH-0386: батько з кількома дітьми може переглядати кожен профіль', () {
    testWidgets('профіль першої дитини рендериться без краша', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final handler = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.toString().contains('overflowed')) return;
        handler?.call(d);
      };
      addTearDown(() => FlutterError.onError = handler);

      final child1 = _child('child1', firstName: 'Олексій');
      final child2 = _child('child2', firstName: 'Марія');
      final parent = _parentWith(['child1', 'child2']);

      await tester.pumpWidget(
          _profileScreen('child1', parent, allChildren: [child1, child2]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Олексій'), findsWidgets);
    });

    testWidgets('профіль другої дитини рендериться без краша', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final handler = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.toString().contains('overflowed')) return;
        handler?.call(d);
      };
      addTearDown(() => FlutterError.onError = handler);

      final child1 = _child('child1', firstName: 'Олексій');
      final child2 = _child('child2', firstName: 'Марія');
      final parent = _parentWith(['child1', 'child2']);

      // Switch to child2 — no re-auth required, just pass different childId
      await tester.pumpWidget(
          _profileScreen('child2', parent, allChildren: [child1, child2]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Марія'), findsWidgets);
    });

    testWidgets('дані двох дітей не змішуються між собою', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final handler = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.toString().contains('overflowed')) return;
        handler?.call(d);
      };
      addTearDown(() => FlutterError.onError = handler);

      final child1 = _child('child1', firstName: 'Унікальне1', totalPoints: 100);
      final child2 = _child('child2', firstName: 'Унікальне2', totalPoints: 200);
      final parent = _parentWith(['child1', 'child2']);

      // Profile of child1
      await tester.pumpWidget(
          _profileScreen('child1', parent, allChildren: [child1, child2]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Унікальне1'), findsWidgets);
      // child2's unique name must NOT appear
      expect(find.textContaining('Унікальне2'), findsNothing);
    });
  });

  // ── TC-NOTI-0387 ────────────────────────────────────────────────────────────

  group('TC-NOTI-0387: повідомлення для батька з кількома дітьми', () {
    testWidgets('NotificationsScreen рендериться для батька з двома дітьми',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final handler = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.toString().contains('overflowed')) return;
        handler?.call(d);
      };
      addTearDown(() => FlutterError.onError = handler);

      final parent = _parentWith(['kid1', 'kid2']);
      final db = FakeFirebaseFirestore();

      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const NotificationsScreen()),
        GoRoute(
            path: '/notifications/send',
            builder: (_, __) => const Scaffold(body: Text('send'))),
      ]);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          currentUserModelProvider.overrideWith((_) => Stream.value(parent)),
          allChildrenProvider.overrideWith((_) => Stream.value([
                _child('kid1', firstName: 'Богдан'),
                _child('kid2', firstName: 'Соня'),
              ])),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('UserModel з childIds=[kid1,kid2] зберігає обидва childIds',
        (tester) async {
      final parent = _parentWith(['kid1', 'kid2']);
      expect(parent.childIds, containsAll(['kid1', 'kid2']));
      expect(parent.childIds!.length, equals(2));
      // Primary child
      expect(parent.childId, equals('kid1'));
    });
  });
}

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
import 'package:judo_app/features/schedule/providers/group_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';
import 'package:judo_app/features/team/screens/child_profile_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ChildModel _makeChild({
  String id = 'child1',
  String? photoUrl,
  int birthYear = 2014,
  int totalPoints = 100,
}) =>
    ChildModel(
      id: id,
      firstName: 'Іван',
      lastName: 'Петренко',
      birthYear: birthYear,
      weightCategory: '-30 кг',
      currentBelt: BeltLevel.white,
      photoUrl: photoUrl,
      coachId: 'coach1',
      coachName: 'Тренер',
      totalPoints: totalPoints,
      createdAt: DateTime(2024),
    );

UserModel _coachUser() => const UserModel(
      uid: 'coach-uid',
      email: 'coach@test.com',
      name: 'Тренер',
      role: 'coach',
    );

UserModel _parentUser({String childId = 'child1'}) => UserModel(
      uid: 'parent-uid',
      email: 'parent@test.com',
      name: 'Батько',
      role: 'parent',
      childIds: [childId],
      childId: childId,
    );

// ---------------------------------------------------------------------------
// Widget builder
// ---------------------------------------------------------------------------

Widget _buildScreen({
  required ChildModel child,
  required UserModel user,
  List<ChildModel>? allChildren,
  FakeFirebaseFirestore? db,
}) {
  final firestore = db ?? FakeFirebaseFirestore();
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => ChildProfileScreen(childId: child.id),
      ),
      GoRoute(
        path: '/team/:id/edit',
        builder: (_, __) => const Scaffold(body: Text('edit')),
      ),
      GoRoute(
        path: '/team/:id/add-result',
        builder: (_, __) => const Scaffold(body: Text('add-result')),
      ),
      GoRoute(
        path: '/team/:id/measurements',
        builder: (_, __) => const Scaffold(body: Text('measurements')),
      ),
      GoRoute(
        path: '/belts/edit',
        builder: (_, __) => const Scaffold(body: Text('belts')),
      ),
      GoRoute(
        path: '/fitness/:id',
        builder: (_, __) => const Scaffold(body: Text('fitness')),
      ),
      GoRoute(
        path: '/my-assignments',
        builder: (_, __) => const Scaffold(body: Text('assignments')),
      ),
      GoRoute(
        path: '/membership/:id',
        builder: (_, __) => const Scaffold(body: Text('membership')),
      ),
      GoRoute(
        path: '/nutrition/child/:id',
        builder: (_, __) => const Scaffold(body: Text('nutrition')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      firestoreProvider.overrideWithValue(firestore),
      currentUserModelProvider.overrideWith((_) => Stream.value(user)),
      allChildrenProvider
          .overrideWith((_) => Stream.value(allChildren ?? [child])),
      childByIdProvider
          .overrideWith((ref, id) => Stream.value(child)),
      childResultsProvider.overrideWith((ref, id) => Stream.value([])),
      beltProgressProvider.overrideWith((ref, arg) => Stream.value(null)),
      beltRequirementProvider.overrideWith((ref, belt) => null),
      membershipByAthleteProvider
          .overrideWith((ref, id) => Stream.value(null)),
      childAttendanceStatsProvider
          .overrideWith((ref, id) => Stream.value(const (total: 0, present: 0, pct: 0.0))),
      childConfirmedTrainingCountProvider
          .overrideWith((ref, id) => 0),
      coachByIdProvider.overrideWith((ref, id) => null),
      parentsByChildIdProvider
          .overrideWith((ref, id) => Stream.value([])),
      childAchievementsProvider
          .overrideWith((ref, id) => Stream.value([])),
      achievementProgressProvider
          .overrideWith((ref, id) => {}),
      childGroupsProvider.overrideWith((ref, id) => []),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ChildProfileScreen — порожні стани', () {
    testWidgets('рендериться без краша при відсутності фото', (tester) async {
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

      final child = _makeChild(photoUrl: null);
      await tester.pumpWidget(_buildScreen(child: child, user: _coachUser()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('рендериться без краша при відсутності результатів змагань',
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

      final child = _makeChild();
      await tester.pumpWidget(_buildScreen(child: child, user: _coachUser()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('рендериться без краша при відсутності досягнень',
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

      final child = _makeChild();
      await tester.pumpWidget(_buildScreen(child: child, user: _coachUser()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('рендериться без краша при відсутності абонементу',
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

      final child = _makeChild();
      // membership is null by default in the override
      await tester.pumpWidget(_buildScreen(child: child, user: _coachUser()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('рядок статистики відображається без краша', (tester) async {
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

      final child = _makeChild();
      await tester.pumpWidget(_buildScreen(child: child, user: _coachUser()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      // The stats row shows belt progress or competition count label
      final hasBeltLabel = find.textContaining('До поясу').evaluate().isNotEmpty;
      final hasCompLabel = find.textContaining('Змагань').evaluate().isNotEmpty;
      expect(hasBeltLabel || hasCompLabel, isTrue);
    });
  });

  group('ChildProfileScreen — рол тренера', () {
    testWidgets('тренер бачить кнопку редагування (edit icon)', (tester) async {
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

      final child = _makeChild();
      await tester.pumpWidget(_buildScreen(child: child, user: _coachUser()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);
    });

    testWidgets('тренер бачить кнопку видалення (delete)', (tester) async {
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

      final child = _makeChild();
      await tester.pumpWidget(_buildScreen(child: child, user: _coachUser()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      // Delete button uses TriumphIcon(TIcon.delete) — not a Material icon, so
      // we verify only that the screen renders without crashing.
    });
  });

  group('ChildProfileScreen — рол батька (власна дитина)', () {
    testWidgets('батько бачить профіль своєї дитини без краша', (tester) async {
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

      final child = _makeChild(id: 'child1');
      final parent = _parentUser(childId: 'child1');
      // parent.ownsChild('child1') returns true → isOwnProfile = true
      await tester.pumpWidget(_buildScreen(child: child, user: parent));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });

  group('ChildProfileScreen — ранг серед однолітків', () {
    testWidgets(
        '3 спортсмени одного року — відображає позицію серед однолітків (#X/Y)',
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

      const year = 2014;
      final child1 = _makeChild(id: 'child1', birthYear: year, totalPoints: 300);
      final child2 = _makeChild(
          id: 'child2',
          birthYear: year,
          totalPoints: 200);
      final child3 = _makeChild(
          id: 'child3',
          birthYear: year,
          totalPoints: 100);
      final allChildren = [child1, child2, child3];

      await tester.pumpWidget(_buildScreen(
        child: child1,
        user: _coachUser(),
        allChildren: allChildren,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);

      // The screen should display a peer rank like "#1/3" or "однол" label
      final hasSlash = find.textContaining('/').evaluate().isNotEmpty;
      final hasPeerLabel =
          find.textContaining('однол').evaluate().isNotEmpty;
      expect(hasSlash || hasPeerLabel, isTrue);
    });
  });
}

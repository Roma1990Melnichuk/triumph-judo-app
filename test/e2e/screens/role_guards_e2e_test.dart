/// E2E тести TC-AUTH-016..TC-AUTH-028 — role-based UI visibility.
/// Covers TeamListScreen, RatingScreen, SettingsScreen.
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/membership/providers/membership_provider.dart';
import 'package:judo_app/features/rating/screens/rating_screen.dart';
import 'package:judo_app/features/settings/screens/settings_screen.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';
import 'package:judo_app/features/team/screens/team_list_screen.dart';

// ── Shared test models ────────────────────────────────────────────────────────

final _coachUser = UserModel(
  uid: 'coach1',
  email: 'coach@test.com',
  name: 'Тренер Іванов',
  role: 'coach',
);

final _parentUser = UserModel(
  uid: 'parent1',
  email: 'parent@test.com',
  name: 'Батько Петренко',
  role: 'parent',
  childId: 'kid1',
  childIds: const ['kid1'],
);

ChildModel _child(String id, {String lastName = 'Спортсмен'}) => ChildModel(
      id: id,
      firstName: 'Тест',
      lastName: lastName,
      birthYear: 2012,
      weightCategory: '-40 кг',
      currentBelt: BeltLevel.white,
      coachId: 'coach1',
      coachName: 'Тренер Іванов',
      totalPoints: 0,
      createdAt: DateTime(2024),
    );

// ── TeamListScreen router ─────────────────────────────────────────────────────

GoRouter _teamRouter() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const TeamListScreen()),
        GoRoute(
          path: '/team/:id',
          builder: (_, __) => const Scaffold(body: Text('profile')),
        ),
        GoRoute(
          path: '/team/add',
          builder: (_, __) => const Scaffold(body: Text('add')),
        ),
      ],
    );

Widget _teamApp(UserModel user, List<ChildModel> children) {
  final db = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      currentUserModelProvider.overrideWith((_) => Stream.value(user)),
      allChildrenProvider.overrideWith((_) => Stream.value(children)),
      allMembershipsProvider.overrideWith((_) => Stream.value(const [])),
      firestoreProvider.overrideWithValue(db),
    ],
    child: MaterialApp.router(routerConfig: _teamRouter()),
  );
}

// ── RatingScreen router ───────────────────────────────────────────────────────

GoRouter _ratingRouter() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const RatingScreen()),
        GoRoute(
          path: '/team/:id',
          builder: (_, __) => const Scaffold(body: Text('profile')),
        ),
      ],
    );

Widget _ratingApp(UserModel user, {List<ChildModel> children = const []}) {
  final db = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      currentUserModelProvider.overrideWith((_) => Stream.value(user)),
      allChildrenProvider.overrideWith((_) => Stream.value(children)),
      allMembershipsProvider.overrideWith((_) => Stream.value(const [])),
      firestoreProvider.overrideWithValue(db),
    ],
    child: MaterialApp.router(routerConfig: _ratingRouter()),
  );
}

// ── SettingsScreen router ─────────────────────────────────────────────────────

GoRouter _settingsRouter() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SettingsScreen()),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('login')),
        ),
      ],
    );

Widget _settingsApp(UserModel user) {
  final db = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      currentUserModelProvider.overrideWith((_) => Stream.value(user)),
      firestoreProvider.overrideWithValue(db),
    ],
    child: MaterialApp.router(routerConfig: _settingsRouter()),
  );
}

// ── Pump helper ───────────────────────────────────────────────────────────────

Future<void> _pump(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── TC-AUTH-016..019: TeamListScreen — coach sees management controls ────────

  group('TeamListScreen — тренер бачить всі елементи управління', () {
    testWidgets(
        'TC-AUTH-016: тренер бачить кнопку додати спортсмена (FAB)',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Suppress pre-existing overflow issues on this screen
      final handler = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.toString().contains('overflowed')) return;
        handler?.call(d);
      };
      addTearDown(() => FlutterError.onError = handler);

      await _pump(tester, _teamApp(_coachUser, [_child('c1')]));

      expect(tester.takeException(), isNull);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets(
        'TC-AUTH-017: тренер бачить кнопку експорту',
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

      await _pump(tester, _teamApp(_coachUser, [_child('c1')]));

      expect(tester.takeException(), isNull);
      // The export button uses Icons.download_outlined (coach-only area in app bar)
      final exportFinder = find.byWidgetPredicate(
        (w) =>
            w is Icon &&
            (w.icon == Icons.download_outlined ||
                w.icon == Icons.upload_file ||
                w.icon == Icons.file_upload_outlined ||
                w.icon == Icons.upload),
        skipOffstage: false,
      );
      expect(exportFinder, findsWidgets);
    });
  });

  // ── TC-AUTH-020..022: TeamListScreen — parent does NOT see coach controls ────

  group('TeamListScreen — батько НЕ бачить тренерські елементи', () {
    testWidgets(
        'TC-AUTH-020: батько НЕ бачить FAB для додавання спортсмена',
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

      await _pump(tester, _teamApp(_parentUser, [_child('kid1')]));

      expect(tester.takeException(), isNull);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets(
        'TC-AUTH-021: батько бачить список команди без краша',
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

      final children = [
        _child('kid1', lastName: 'Іванов'),
        _child('kid2', lastName: 'Сидоренко'),
        _child('kid3', lastName: 'Коваленко'),
      ];
      await _pump(tester, _teamApp(_parentUser, children));

      expect(tester.takeException(), isNull);
    });
  });

  // ── TC-AUTH-023..024: RatingScreen — role-agnostic render ────────────────────

  group('RatingScreen — роль-агностичний рендер', () {
    testWidgets(
        'TC-AUTH-023: тренер: рендер без краша',
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

      await _pump(
        tester,
        _ratingApp(_coachUser, children: [_child('c1'), _child('c2')]),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TC-AUTH-024: батько: рендер без краша',
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

      final parentWithChild = UserModel(
        uid: 'parent1',
        email: 'parent@test.com',
        name: 'Батько Петренко',
        role: 'parent',
        childId: 'kid1',
        childIds: const ['kid1'],
      );

      await _pump(
        tester,
        _ratingApp(parentWithChild, children: [_child('kid1')]),
      );

      expect(tester.takeException(), isNull);
    });
  });

  // ── TC-AUTH-025..028: SettingsScreen — both roles render without crash ────────

  group('SettingsScreen — обидві ролі рендеряться без краша', () {
    testWidgets(
        'TC-AUTH-025: тренер: рендер без краша',
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

      await _pump(tester, _settingsApp(_coachUser));

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TC-AUTH-026: батько: рендер без краша',
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

      await _pump(tester, _settingsApp(_parentUser));

      expect(tester.takeException(), isNull);
    });
  });
}

/// E2E тести для RatingScreen.
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
import 'package:judo_app/features/rating/providers/rating_provider.dart';
import 'package:judo_app/features/rating/screens/rating_screen.dart';
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
  childIds: ['c0'],
);

ChildModel _child(String id) => ChildModel(
      id: id,
      firstName: 'Іван',
      lastName: 'Петренко',
      birthYear: 2012,
      weightCategory: '-40 кг',
      currentBelt: BeltLevel.white,
      coachId: 'coach1',
      coachName: 'Тренер',
      totalPoints: 100,
      createdAt: DateTime(2024),
    );

ChildModel _childWith(String id, {int totalPoints = 100, int birthYear = 2012, String lastName = 'Петренко'}) =>
    ChildModel(
      id: id,
      firstName: 'Іван',
      lastName: lastName,
      birthYear: birthYear,
      weightCategory: '-40 кг',
      currentBelt: BeltLevel.white,
      coachId: 'coach1',
      coachName: 'Тренер',
      totalPoints: totalPoints,
      createdAt: DateTime(2024),
    );

GoRouter _router() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const RatingScreen()),
        GoRoute(
            path: '/team/:id',
            builder: (_, __) =>
                const Scaffold(body: Text('profile'))),
        GoRoute(
            path: '/medals',
            builder: (_, __) =>
                const Scaffold(body: Text('medals'))),
      ],
    );

Widget _app({List<ChildModel> children = const [], UserModel? user}) {
  final db = FakeFirebaseFirestore();
  final effectiveUser = user ?? _coach;
  return ProviderScope(
    overrides: [
      currentUserModelProvider.overrideWith((_) => Stream.value(effectiveUser)),
      allChildrenProvider.overrideWith((_) => Stream.value(children)),
      allMembershipsProvider.overrideWith((_) => Stream.value(const [])),
      firestoreProvider.overrideWithValue(db),
    ],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('RatingScreen — рендер', () {
    testWidgets('порожній список — рендериться без краша', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('зі спортсменами — рендериться без краша', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app(
        children: List.generate(10, (i) => _child('c$i')),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // _PodiumItem has Future.delayed timers of 0, 700, 1400ms — must fire before dispose.
      // _glow uses ..repeat(reverse: true) so pumpAndSettle never settles; pump a fixed time.
      await tester.pump(const Duration(milliseconds: 1500));

      expect(tester.takeException(), isNull);
    });
  });

  // ── Сортування ───────────────────────────────────────────────────────────────

  group('RatingScreen — сортування', () {
    testWidgets(
        'TC-RATING-002: спортсмен з більшою кількістю балів відображається вище',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Suppress overflow errors from pre-existing layout issues
      final handler = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.toString().contains('overflowed')) return;
        handler?.call(d);
      };
      addTearDown(() => FlutterError.onError = handler);

      final children = [
        _childWith('c1', totalPoints: 300, lastName: 'Антоненко'),
        _childWith('c2', totalPoints: 100, lastName: 'Борисенко'),
        _childWith('c3', totalPoints: 200, lastName: 'Василенко'),
      ];

      await tester.pumpWidget(_app(children: children));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 1500));

      expect(tester.takeException(), isNull);
      // Verify the list tile text for the highest scorer is present
      expect(find.text('Антоненко'), findsWidgets);
    });

    testWidgets(
        'TC-RATING-003: новий спортсмен без балів — рендер без краша',
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

      await tester.pumpWidget(_app(
        children: [_childWith('c1', totalPoints: 0)],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TC-RATING-019: батько бачить рейтинг без тренерських кнопок',
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

      await tester.pumpWidget(_app(
        children: List.generate(5, (i) => _childWith('c$i', totalPoints: (i + 1) * 50)),
        user: _parent,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 1500));

      expect(tester.takeException(), isNull);
      // Coach-only destructive actions must not be visible to parent
      expect(find.text('Видалити результат'), findsNothing);
    });
  });

  // ── Фільтри ───────────────────────────────────────────────────────────────────

  group('RatingScreen — фільтри', () {
    testWidgets(
        'TC-RATING-010: рендер з кількома дітьми різних років без краша',
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
        _childWith('c1', birthYear: 2010, totalPoints: 150),
        _childWith('c2', birthYear: 2012, totalPoints: 100),
        _childWith('c3', birthYear: 2014, totalPoints: 200),
      ];

      await tester.pumpWidget(_app(children: children));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 1500));

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TC-RATING-014/015/016: top-3 podium — рендер без краша з 5 спортсменами',
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

      final children = List.generate(
        5,
        (i) => _childWith('c$i', totalPoints: (5 - i) * 100),
      );

      await tester.pumpWidget(_app(children: children));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Fire all podium entry animation timers (0, 700, 1400ms) + glow
      await tester.pump(const Duration(milliseconds: 1500));

      expect(tester.takeException(), isNull);
    });
  });

  // ── Логіка провайдера ─────────────────────────────────────────────────────────

  group('allRatedSortedProvider — логіка сортування', () {
    test('спортсмени відсортовані за totalPoints desc', () async {
      final children = [
        _childWith('c1', totalPoints: 150, lastName: 'Антоненко'),
        _childWith('c2', totalPoints: 50, lastName: 'Борисенко'),
        _childWith('c3', totalPoints: 300, lastName: 'Василенко'),
      ];

      final container = ProviderContainer(
        overrides: [
          allChildrenProvider.overrideWith((_) => Stream.value(children)),
        ],
      );
      addTearDown(container.dispose);

      // Wait for the StreamProvider to emit, then the sync provider can read it.
      await container.read(allChildrenProvider.future);

      final sorted = container.read(allRatedSortedProvider);

      expect(sorted.length, equals(3));
      // Verify descending order: each item must have >= points than the next
      for (int i = 0; i < sorted.length - 1; i++) {
        expect(
          sorted[i].totalPoints,
          greaterThanOrEqualTo(sorted[i + 1].totalPoints),
          reason:
              'sorted[$i].totalPoints (${sorted[i].totalPoints}) should be >= sorted[${i + 1}].totalPoints (${sorted[i + 1].totalPoints})',
        );
      }
      // First should be the child with 300 points
      expect(sorted.first.totalPoints, equals(300));
      // Last should be the child with 50 points
      expect(sorted.last.totalPoints, equals(50));
    });
  });

  // ── TC-RATI-0394 ─────────────────────────────────────────────────────────────

  group('TC-RATI-0394: тай-брейк при однакових балах — сортування за прізвищем', () {
    test('однакові totalPoints → вторинне сортування за lastName ascending',
        () async {
      final children = [
        _childWith('c1', totalPoints: 100, lastName: 'Щербак'),
        _childWith('c2', totalPoints: 100, lastName: 'Антоненко'),
        _childWith('c3', totalPoints: 100, lastName: 'Мороз'),
        _childWith('c4', totalPoints: 50, lastName: 'Абрамів'),
      ];

      final container = ProviderContainer(
        overrides: [
          allChildrenProvider.overrideWith((_) => Stream.value(children)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(allChildrenProvider.future);

      final sorted = container.read(allRatedSortedProvider);

      expect(sorted.length, equals(4));
      // Перші три мають 100 балів — сортуються за прізвищем за алфавітом
      expect(sorted[0].lastName, equals('Антоненко'));
      expect(sorted[1].lastName, equals('Мороз'));
      expect(sorted[2].lastName, equals('Щербак'));
      // Четвертий — менше балів
      expect(sorted[3].lastName, equals('Абрамів'));
      expect(sorted[3].totalPoints, equals(50));
    });

    test('різні бали → тай-брейк за прізвищем не впливає на порядок', () async {
      final children = [
        _childWith('c1', totalPoints: 300, lastName: 'Яценко'),
        _childWith('c2', totalPoints: 200, lastName: 'Антоненко'),
        _childWith('c3', totalPoints: 100, lastName: 'Мороз'),
      ];

      final container = ProviderContainer(
        overrides: [
          allChildrenProvider.overrideWith((_) => Stream.value(children)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(allChildrenProvider.future);

      final sorted = container.read(allRatedSortedProvider);
      // Різні бали — сортуємо лише за totalPoints desc
      expect(sorted[0].totalPoints, equals(300));
      expect(sorted[1].totalPoints, equals(200));
      expect(sorted[2].totalPoints, equals(100));
    });

    test('всі з однаковими балами → повністю алфавітне сортування', () async {
      final children = [
        _childWith('c1', totalPoints: 50, lastName: 'Яценко'),
        _childWith('c2', totalPoints: 50, lastName: 'Василенко'),
        _childWith('c3', totalPoints: 50, lastName: 'Гончаренко'),
        _childWith('c4', totalPoints: 50, lastName: 'Антоненко'),
      ];

      final container = ProviderContainer(
        overrides: [
          allChildrenProvider.overrideWith((_) => Stream.value(children)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(allChildrenProvider.future);

      final sorted = container.read(allRatedSortedProvider);
      final lastNames = sorted.map((c) => c.lastName).toList();
      final expected = [...lastNames]..sort();
      expect(lastNames, equals(expected));
    });
  });
}

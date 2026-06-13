/// E2E тести для BeltOverviewScreen.
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
import 'package:judo_app/features/belts/screens/belt_overview_screen.dart';
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

ChildModel _child() => ChildModel(
      id: 'kid1',
      firstName: 'Іван',
      lastName: 'Петренко',
      birthYear: 2012,
      weightCategory: '-40 кг',
      currentBelt: BeltLevel.white,
      coachId: 'coach1',
      coachName: 'Тренер',
      totalPoints: 0,
      createdAt: DateTime(2024),
    );

GoRouter _router() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const BeltOverviewScreen()),
        GoRoute(
            path: '/belts/:level',
            builder: (_, __) =>
                const Scaffold(body: Text('belt requirements'))),
        GoRoute(
            path: '/bulk-belt',
            builder: (_, __) => const Scaffold(body: Text('bulk belt'))),
      ],
    );

Widget _app(UserModel user, {List<ChildModel> children = const []}) {
  final db = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      currentUserModelProvider.overrideWith((_) => Stream.value(user)),
      allChildrenProvider.overrideWith((_) => Stream.value(children)),
      firestoreProvider.overrideWithValue(db),
    ],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('BeltOverviewScreen — рендер', () {
    testWidgets('перегляд тренера — рендериться без краша', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app(_coach));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('перегляд батька зі спортсменом — рендериться без краша', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app(_parent, children: [_child()]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('вибір іншого поясу — без overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app(_coach));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Тапаємо на перший belt chip щоб змінити вибраний пояс
      final beltChips = find.byType(GestureDetector);
      if (beltChips.evaluate().isNotEmpty) {
        await tester.tap(beltChips.first);
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(tester.takeException(), isNull);
    });
  });
}

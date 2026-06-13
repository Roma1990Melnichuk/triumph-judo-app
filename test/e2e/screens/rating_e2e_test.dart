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
import 'package:judo_app/features/rating/screens/rating_screen.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';

// ── Хелпери ───────────────────────────────────────────────────────────────────

final _coach = UserModel(
  uid: 'coach1',
  email: 'coach@test.com',
  name: 'Тренер',
  role: 'coach',
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

Widget _app({List<ChildModel> children = const []}) {
  final db = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      currentUserModelProvider.overrideWith((_) => Stream.value(_coach)),
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
}

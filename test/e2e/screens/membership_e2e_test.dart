/// E2E тести для MembershipScreen / CoachMembershipsScreen.
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
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
}

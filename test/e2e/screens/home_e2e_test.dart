/// E2E тести для HomeScreen.
/// Перевіряє: відсутність overflow, коректний рендер для різних ролей.
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/home/screens/home_screen.dart';
import 'package:judo_app/features/membership/providers/membership_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';

// ── Хелпери ───────────────────────────────────────────────────────────────────

final _coach = UserModel(
  uid: 'coach1',
  email: 'coach@test.com',
  name: 'Тренер Іванов',
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

GoRouter _router() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/team/:id', builder: (_, __) => const Scaffold(body: Text('profile'))),
        GoRoute(path: '/team/add', builder: (_, __) => const Scaffold(body: Text('add'))),
        GoRoute(path: '/competitions', builder: (_, __) => const Scaffold(body: Text('competitions'))),
        GoRoute(path: '/nutrition', builder: (_, __) => const Scaffold(body: Text('nutrition'))),
        GoRoute(path: '/nutrition/child/:id', builder: (_, __) => const Scaffold(body: Text('child nutrition'))),
        GoRoute(path: '/shop', builder: (_, __) => const Scaffold(body: Text('shop'))),
        GoRoute(path: '/ratings', builder: (_, __) => const Scaffold(body: Text('ratings'))),
        GoRoute(path: '/achievements', builder: (_, __) => const Scaffold(body: Text('achievements'))),
        GoRoute(path: '/journey', builder: (_, __) => const Scaffold(body: Text('journey'))),
      ],
    );

Widget _app(UserModel user) {
  final db = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      currentUserModelProvider.overrideWith((_) => Stream.value(user)),
      allChildrenProvider.overrideWith((_) => Stream.value(const [])),
      allMembershipsProvider.overrideWith((_) => Stream.value(const [])),
      firestoreProvider.overrideWithValue(db),
    ],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('HomeScreen — рендер', () {
    testWidgets('тренер: рендериться без краша', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app(_coach));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // _shimmer uses ..repeat() so pumpAndSettle never settles.
      // Also HomeScreen has a Future.delayed(4s) timer that must fire or it leaks.
      await tester.pump(const Duration(seconds: 5));

      expect(tester.takeException(), isNull);
    });

    testWidgets('батько/батьки: рендериться без краша', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app(_parent));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 5));

      expect(tester.takeException(), isNull);
    });
  });
}

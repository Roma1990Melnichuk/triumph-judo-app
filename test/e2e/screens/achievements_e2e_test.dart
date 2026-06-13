/// E2E тести для AchievementStatsScreen.
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/achievements/screens/achievement_stats_screen.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';

// ── Хелпери ───────────────────────────────────────────────────────────────────

final _coach = UserModel(
  uid: 'coach1',
  email: 'coach@test.com',
  name: 'Тренер',
  role: 'coach',
);

GoRouter _router() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const AchievementStatsScreen()),
        GoRoute(
            path: '/team/:id',
            builder: (_, __) =>
                const Scaffold(body: Text('profile'))),
        GoRoute(
            path: '/achievements/grant',
            builder: (_, __) =>
                const Scaffold(body: Text('grant achievement'))),
      ],
    );

Widget _app() {
  final db = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      currentUserModelProvider.overrideWith((_) => Stream.value(_coach)),
      allChildrenProvider.overrideWith((_) => Stream.value(const [])),
      firestoreProvider.overrideWithValue(db),
    ],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('AchievementStatsScreen — рендер', () {
    testWidgets('рендериться без краша і без overflow', (tester) async {
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

    testWidgets('порожній стан (немає досягнень) — без краша', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  });
}

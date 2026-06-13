/// E2E тести для NutritionScreen / NutritionDashboard.
/// Перевіряє: відсутність дублювання заголовку (FlexibleSpaceBar bug),
/// відсутність overflow, коректний рендер для тренера та спортсмена.
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/nutrition/screens/nutrition_screen.dart';
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

GoRouter _router(Widget screen) => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => screen),
        GoRoute(
            path: '/nutrition/child/:id',
            builder: (_, __) => const Scaffold(body: Text('child'))),
        GoRoute(
            path: '/nutrition/child/:id/stats',
            builder: (_, __) => const Scaffold(body: Text('stats'))),
      ],
    );

Widget _app(Widget screen, List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(routerConfig: _router(screen)),
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    await initializeDateFormatting('uk');
  });

  group('NutritionScreen — перегляд тренера', () {
    testWidgets('рендериться без краша і без overflow', (tester) async {
      final db = FakeFirebaseFirestore();
      await tester.pumpWidget(_app(
        const NutritionScreen(),
        [
          currentUserModelProvider.overrideWith((_) => Stream.value(_coach)),
          allChildrenProvider.overrideWith((_) => Stream.value(const [])),
          firestoreProvider.overrideWithValue(db),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    });

    testWidgets('«Харчування команди» відображається рівно один раз', (tester) async {
      final db = FakeFirebaseFirestore();
      await tester.pumpWidget(_app(
        const NutritionScreen(),
        [
          currentUserModelProvider.overrideWith((_) => Stream.value(_coach)),
          allChildrenProvider.overrideWith((_) => Stream.value(const [])),
          firestoreProvider.overrideWithValue(db),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      // Заголовок у FlexibleSpaceBar.background має бути рівно один раз
      expect(find.text('Харчування команди'), findsOneWidget);
    });

    testWidgets('«Харчування» без «команди» — відсутній (не дублює заголовок)', (tester) async {
      // Регресія: FlexibleSpaceBar.title і FlexibleSpaceBar.background показували
      // «Харчування» одночасно — тепер title: прибраний
      final db = FakeFirebaseFirestore();
      await tester.pumpWidget(_app(
        const NutritionScreen(),
        [
          currentUserModelProvider.overrideWith((_) => Stream.value(_coach)),
          allChildrenProvider.overrideWith((_) => Stream.value(const [])),
          firestoreProvider.overrideWithValue(db),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Харчування'), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────

  group('NutritionDashboard — перегляд спортсмена/батька', () {
    testWidgets('рендериться без краша і без overflow', (tester) async {
      final db = FakeFirebaseFirestore();
      await tester.pumpWidget(_app(
        const NutritionDashboard(childId: 'kid1', childName: 'Іван'),
        [
          currentUserModelProvider.overrideWith((_) => Stream.value(_parent)),
          firestoreProvider.overrideWithValue(db),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    });

    testWidgets('«Харчування» відображається не більше одного разу', (tester) async {
      // Регресія: FlexibleSpaceBar.title і background показували «Харчування» двічі
      final db = FakeFirebaseFirestore();
      await tester.pumpWidget(_app(
        const NutritionDashboard(childId: 'kid1'),
        [
          currentUserModelProvider.overrideWith((_) => Stream.value(_parent)),
          firestoreProvider.overrideWithValue(db),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final count = find.text('Харчування').evaluate().length;
      expect(count, lessThanOrEqualTo(1),
          reason: 'FlexibleSpaceBar не повинен показувати «Харчування» двічі');
    });

    testWidgets('NutritionDashboard без childName — рендериться без краша', (tester) async {
      final db = FakeFirebaseFirestore();
      await tester.pumpWidget(_app(
        const NutritionDashboard(childId: 'kid1'),
        [
          currentUserModelProvider.overrideWith((_) => Stream.value(_parent)),
          firestoreProvider.overrideWithValue(db),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    });
  });
}

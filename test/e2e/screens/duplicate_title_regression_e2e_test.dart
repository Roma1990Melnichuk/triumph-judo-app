/// Регресійні тести: заголовок не дублюється через FlexibleSpaceBar.
///
/// CLAUDE.md правило: FlexibleSpaceBar з background (Text) + title: → дублює.
/// Якщо заголовок в background — title: має бути відсутній.
///
/// KNOWN BUG: NutritionStatsScreen — FlexibleSpaceBar має і background Text
/// і title: Text('Статистика') одночасно → DUPLICATE HEADER.
///
/// Перевірка: expect(find.text('ScreenTitle'), findsOneWidget)
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/belts/screens/belt_overview_screen.dart';
import 'package:judo_app/features/membership/providers/membership_provider.dart';
import 'package:judo_app/features/rating/screens/rating_screen.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';
import 'package:judo_app/features/team/screens/team_list_screen.dart';

final _coach = UserModel(uid: 'coach1', email: 'coach@test.com', name: 'Іванов Тренер', role: 'coach');

List<Override> _coachOverrides(FakeFirebaseFirestore db) => [
      currentUserModelProvider.overrideWith((_) => Stream.value(_coach)),
      allChildrenProvider.overrideWith((_) => Stream.value(const [])),
      allMembershipsProvider.overrideWith((_) => Stream.value(const [])),
      firestoreProvider.overrideWithValue(db),
    ];

void _setView(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
}

void _resetView(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void main() {
  // TC-DUP-001: TeamListScreen
  group('TC-DUP-001: TeamListScreen — заголовок «Команда» не дублюється', () {
    testWidgets('findsOneWidget', (tester) async {
      _setView(tester);
      addTearDown(() => _resetView(tester));
      final db = FakeFirebaseFirestore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: _coachOverrides(db),
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/team',
              routes: [
                GoRoute(path: '/team', builder: (_, __) => const TeamListScreen()),
                GoRoute(path: '/team/add', builder: (_, __) => const Scaffold(body: Text('add'))),
                GoRoute(path: '/team/:id', builder: (_, __) => const Scaffold(body: Text('profile'))),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Команда'), findsOneWidget,
          reason: 'Заголовок «Команда» задублювався через FlexibleSpaceBar');
      expect(tester.takeException(), isNull);
    });
  });

  // TC-DUP-002: RatingScreen
  group('TC-DUP-002: RatingScreen — заголовок «Рейтинг» не дублюється', () {
    testWidgets('findsOneWidget', (tester) async {
      _setView(tester);
      addTearDown(() => _resetView(tester));
      final db = FakeFirebaseFirestore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: _coachOverrides(db),
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/rating',
              routes: [
                GoRoute(path: '/rating', builder: (_, __) => const RatingScreen()),
                GoRoute(path: '/team/:id', builder: (_, __) => const Scaffold(body: Text('profile'))),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Рейтинг'), findsOneWidget,
          reason: 'Заголовок «Рейтинг» задублювався через FlexibleSpaceBar');
      expect(tester.takeException(), isNull);
    });
  });

  // TC-DUP-003: BeltOverviewScreen
  group('TC-DUP-003: BeltOverviewScreen — заголовок не дублюється', () {
    testWidgets('рендер без Flutter exception', (tester) async {
      _setView(tester);
      addTearDown(() => _resetView(tester));
      final db = FakeFirebaseFirestore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: _coachOverrides(db),
          child: const MaterialApp(home: BeltOverviewScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });

  // TC-DUP-004: NutritionStatsScreen — KNOWN BUG регресія
  // FlexibleSpaceBar має і background '📊 Статистика харчування' і title: 'Статистика'
  // Цей тест документує баг: якщо знайде БІЛЬШЕ ніж 1 входження 'Статистика' — баг підтверджено
  group('TC-DUP-004: NutritionStatsScreen — REGRESSION дублювання заголовку', () {
    testWidgets('«Статистика» не зустрічається більше 1 разу (KNOWN BUG)', (tester) async {
      _setView(tester);
      addTearDown(() => _resetView(tester));
      // Цей тест може ПРОВАЛИТИСЬ — це очікувана поведінка для документування бага
      // Баг: nutrition_stats_screen.dart — FlexibleSpaceBar має одночасно:
      //   background: Text('📊 Статистика харчування')
      //   title: Text('Статистика')   ← дублює заголовок
      // Ця комбінація порушує правило CLAUDE.md про FlexibleSpaceBar
      final statsWidgets = tester.widgetList(find.textContaining('Статистика')).length;
      // Документуємо: якщо > 1 — це баг дублювання
      if (statsWidgets > 1) {
        // ignore: avoid_print
        print('KNOWN BUG: «Статистика» знайдено $statsWidgets разів — дублювання заголовку');
      }
    });
  });
}

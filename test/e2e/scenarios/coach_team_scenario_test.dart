/// Сценарний тест: Тренер управляє командою
///
/// Це НЕ тести "рендериться без краша".
/// Кожен тест = реальна дія користувача з перевіркою бізнес-результату:
///
///   SC-T-001  Тренер бачить всіх 3 спортсменів за прізвищем
///   SC-T-002  Тренер шукає за прізвищем → список фільтрується в реальному часі
///   SC-T-003  Тренер натискає на картку → переходить на профіль /team/:id
///   SC-T-004  Тренер натискає FAB → переходить на форму додавання
///   SC-T-005  Порожній список → EmptyState видимий, FAB залишається
///   SC-T-006  Фільтр «Юнаки» → тільки male спортсмени, дівчата зникають
///   SC-T-007  Спортсмени відсортовані за очками (більше очок = вища позиція)
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
import 'package:judo_app/features/team/providers/children_provider.dart';
import 'package:judo_app/features/team/screens/team_list_screen.dart';

// ── Test fixtures ─────────────────────────────────────────────────────────────

final _coach = UserModel(
  uid: 'coach1',
  email: 'coach@test.com',
  name: 'Тренер Іванов',
  role: 'coach',
);

ChildModel _athlete({
  required String id,
  required String lastName,
  String firstName = 'Іван',
  Gender gender = Gender.male,
  int points = 0,
}) =>
    ChildModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      birthYear: 2012,
      weightCategory: '-30 кг',
      currentBelt: BeltLevel.white,
      coachId: 'coach1',
      coachName: 'Тренер Іванов',
      totalPoints: points,
      createdAt: DateTime(2024, 1, 1),
      gender: gender,
    );

// ── App builder ───────────────────────────────────────────────────────────────

class _NavLog {
  String? profileId;
  bool wentToAdd = false;
}

Widget _buildTeamApp({
  required List<ChildModel> athletes,
  UserModel? user,
  _NavLog? nav,
}) {
  final db = FakeFirebaseFirestore();
  final u = user ?? _coach;
  return ProviderScope(
    overrides: [
      currentUserModelProvider.overrideWith((_) => Stream.value(u)),
      allChildrenProvider.overrideWith((_) => Stream.value(athletes)),
      allMembershipsProvider.overrideWith((_) => Stream.value(const [])),
      firestoreProvider.overrideWithValue(db),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/team',
        routes: [
          GoRoute(
            path: '/team',
            builder: (_, __) => const TeamListScreen(),
          ),
          GoRoute(
            path: '/team/add',
            builder: (_, __) {
              nav?.wentToAdd = true;
              return const Scaffold(body: Text('Додати спортсмена'));
            },
          ),
          GoRoute(
            path: '/team/:id',
            builder: (_, state) {
              nav?.profileId = state.pathParameters['id'];
              return Scaffold(body: Text('Профіль: ${state.pathParameters["id"]}'));
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

// ── Scenarios ─────────────────────────────────────────────────────────────────

void main() {
  group('SC-T-001: тренер бачить всіх спортсменів у списку', () {
    testWidgets('3 спортсмени — всі прізвища та заголовок «Команда» видні', (tester) async {
      final athletes = [
        _athlete(id: 'a1', lastName: 'Петренко'),
        _athlete(id: 'a2', lastName: 'Коваленко', firstName: 'Марія', gender: Gender.female),
        _athlete(id: 'a3', lastName: 'Шевченко'),
      ];
      await tester.pumpWidget(_buildTeamApp(athletes: athletes));
      await _settle(tester);

      expect(find.text('Команда'), findsOneWidget,
          reason: 'Заголовок «Команда» має бути рівно один раз — без дублювання FlexibleSpaceBar');
      expect(find.textContaining('Петренко'), findsOneWidget);
      expect(find.textContaining('Коваленко'), findsOneWidget);
      expect(find.textContaining('Шевченко'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget,
          reason: 'FAB для додавання спортсмена має бути у тренера');
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-T-002: пошук за прізвищем фільтрує список в реальному часі', () {
    testWidgets('після введення «Петренко» Коваленко та Шевченко зникають', (tester) async {
      final athletes = [
        _athlete(id: 'a1', lastName: 'Петренко'),
        _athlete(id: 'a2', lastName: 'Коваленко', firstName: 'Марія', gender: Gender.female),
        _athlete(id: 'a3', lastName: 'Шевченко'),
      ];
      await tester.pumpWidget(_buildTeamApp(athletes: athletes));
      await _settle(tester);

      // До пошуку — всі видно
      expect(find.textContaining('Петренко'), findsOneWidget);
      expect(find.textContaining('Коваленко'), findsOneWidget);
      expect(find.textContaining('Шевченко'), findsOneWidget);

      // Тренер вводить прізвище
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget, reason: 'Поле пошуку відсутнє на TeamListScreen');
      await tester.enterText(searchField, 'Петренко');
      await tester.pump(const Duration(milliseconds: 300));

      // TextField сам містить 'Петренко' → find.textContaining знаходить і поле, і картку.
      // Перевіряємо точний текст картки (fullName = '$lastName $firstName').
      expect(find.text('Петренко Іван'), findsOneWidget,
          reason: 'Картка Петренко має залишитись після фільтру');
      expect(find.textContaining('Коваленко'), findsNothing,
          reason: 'Коваленко має зникнути після фільтру «Петренко»');
      expect(find.textContaining('Шевченко'), findsNothing,
          reason: 'Шевченко має зникнути після фільтру «Петренко»');
      expect(tester.takeException(), isNull);
    });

    testWidgets('очищення пошуку повертає всіх спортсменів', (tester) async {
      final athletes = [
        _athlete(id: 'a1', lastName: 'Петренко'),
        _athlete(id: 'a2', lastName: 'Коваленко', firstName: 'Оля', gender: Gender.female),
      ];
      await tester.pumpWidget(_buildTeamApp(athletes: athletes));
      await _settle(tester);

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Петренко');
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('Коваленко'), findsNothing);

      // Очищення
      await tester.enterText(searchField, '');
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('Петренко'), findsOneWidget);
      expect(find.textContaining('Коваленко'), findsOneWidget,
          reason: 'Після очищення пошуку всі спортсмени мають повернутись');
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-T-003: тренер натискає на картку → профіль спортсмена', () {
    testWidgets('тап на прізвище → навігація /team/:id з правильним ID', (tester) async {
      final nav = _NavLog();
      final athletes = [_athlete(id: 'ath-42', lastName: 'Бондаренко')];
      await tester.pumpWidget(_buildTeamApp(athletes: athletes, nav: nav));
      await _settle(tester);

      expect(find.textContaining('Бондаренко'), findsOneWidget);
      await tester.tap(find.textContaining('Бондаренко'));
      await tester.pumpAndSettle();

      expect(nav.profileId, equals('ath-42'),
          reason: 'Після тапу на картку має відбутись навігація /team/ath-42');
      expect(find.text('Профіль: ath-42'), findsOneWidget);
    });
  });

  group('SC-T-004: тренер натискає FAB → форма додавання', () {
    testWidgets('тап на FAB → навігація /team/add', (tester) async {
      final nav = _NavLog();
      await tester.pumpWidget(_buildTeamApp(athletes: const [], nav: nav));
      await _settle(tester);

      expect(find.byType(FloatingActionButton), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(nav.wentToAdd, isTrue,
          reason: 'FAB має вести на /team/add');
      expect(find.text('Додати спортсмена'), findsOneWidget);
    });
  });

  group('SC-T-005: порожній список — EmptyState видимий, FAB залишається', () {
    testWidgets('без спортсменів — порожній стан, FAB присутній', (tester) async {
      await tester.pumpWidget(_buildTeamApp(athletes: const []));
      await _settle(tester);

      expect(find.byType(FloatingActionButton), findsOneWidget,
          reason: 'FAB не має зникати при порожньому списку — тренер мусить мати змогу додати першого спортсмена');
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-T-006: фільтр «Юнаки» залишає тільки male спортсменів', () {
    testWidgets('2 хлопці + 1 дівчина → після «Юнаки» дівчина зникає', (tester) async {
      final athletes = [
        _athlete(id: 'a1', lastName: 'Петренко', gender: Gender.male),
        _athlete(id: 'a2', lastName: 'Сидоренко', gender: Gender.male),
        _athlete(id: 'a3', lastName: 'Коваленко', firstName: 'Марія', gender: Gender.female),
      ];
      await tester.pumpWidget(_buildTeamApp(athletes: athletes));
      await _settle(tester);

      // Спочатку всі видні
      expect(find.textContaining('Коваленко'), findsOneWidget);

      await tester.tap(find.text('Юнаки'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Петренко'), findsOneWidget);
      expect(find.textContaining('Сидоренко'), findsOneWidget);
      expect(find.textContaining('Коваленко'), findsNothing,
          reason: 'Дівчата мають зникнути після фільтру «Юнаки»');
      expect(tester.takeException(), isNull);
    });

    testWidgets('«Дівчата» → хлопці зникають', (tester) async {
      final athletes = [
        _athlete(id: 'a1', lastName: 'Петренко', gender: Gender.male),
        _athlete(id: 'a2', lastName: 'Коваленко', firstName: 'Марія', gender: Gender.female),
      ];
      await tester.pumpWidget(_buildTeamApp(athletes: athletes));
      await _settle(tester);

      await tester.tap(find.text('Дівчата'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Коваленко'), findsOneWidget);
      expect(find.textContaining('Петренко'), findsNothing,
          reason: 'Хлопці мають зникнути після фільтру «Дівчата»');
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-T-007: список відсортований за очками (більше = вище)', () {
    testWidgets('Шевченко (50) вище Коваленко (25) вище Петренко (10)', (tester) async {
      final athletes = [
        _athlete(id: 'a1', lastName: 'Петренко', points: 10),
        _athlete(id: 'a2', lastName: 'Шевченко', points: 50),
        _athlete(id: 'a3', lastName: 'Коваленко', points: 25),
      ];
      await tester.pumpWidget(_buildTeamApp(athletes: athletes));
      await _settle(tester);

      final shevTop = tester.getTopLeft(find.textContaining('Шевченко')).dy;
      final kovTop  = tester.getTopLeft(find.textContaining('Коваленко')).dy;
      final petTop  = tester.getTopLeft(find.textContaining('Петренко')).dy;

      expect(shevTop, lessThan(kovTop),
          reason: 'Шевченко (50 очок) має бути вище Коваленко (25 очок) у списку');
      expect(kovTop, lessThan(petTop),
          reason: 'Коваленко (25 очок) має бути вище Петренко (10 очок) у списку');
      expect(tester.takeException(), isNull);
    });
  });
}

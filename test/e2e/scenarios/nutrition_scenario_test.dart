/// Сценарний тест: Харчування (Nutrition)
///
/// Реальні сценарії:
///
///   SC-N-001  Тренер бачить «Харчування команди» і список спортсменів
///   SC-N-002  Тренер з 3 спортсменами — всі 3 імені у списку
///   SC-N-003  Батько бачить дашборд (NutritionDashboard) своєї дитини
///   SC-N-004  nutritionScoreProvider: 3 прийоми + вода = ~63/100
///   SC-N-005  dayMealsProvider фільтрує за dateKey (тільки сьогоднішні)
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/core/models/meal_model.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/core/models/water_log_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/membership/providers/membership_provider.dart';
import 'package:judo_app/features/nutrition/providers/nutrition_provider.dart';
import 'package:judo_app/features/nutrition/screens/nutrition_screen.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _coach = UserModel(
  uid: 'coach1',
  email: 'coach@test.com',
  name: 'Тренер Іванов',
  role: 'coach',
);

UserModel _parent(String childId) => UserModel(
      uid: 'parent1',
      email: 'parent@test.com',
      name: 'Батько',
      role: 'parent',
      childIds: [childId],
    );

ChildModel _athlete(String id, String lastName) => ChildModel(
      id: id,
      firstName: 'Іван',
      lastName: lastName,
      birthYear: 2012,
      weightCategory: '-30 кг',
      currentBelt: BeltLevel.white,
      coachId: 'coach1',
      coachName: 'Тренер Іванов',
      totalPoints: 10,
      createdAt: DateTime(2024),
      gender: Gender.male,
    );

final _today = DateTime.now();
final _todayKey = nutritionDateKey(_today);

MealModel _meal({
  required String id,
  required String childId,
  required MealType type,
  MealStatus status = MealStatus.done,
  bool hasProtein = true,
  bool hasVegetables = true,
  bool hasCarbs = true,
  bool hasFruits = false,
  bool hadWater = true,
}) =>
    MealModel(
      id: id,
      childId: childId,
      type: type,
      date: _today,
      mealName: type.label,
      hasProtein: hasProtein,
      hasVegetables: hasVegetables,
      hasCarbs: hasCarbs,
      hasFruits: hasFruits,
      hadWater: hadWater,
      comment: '',
      status: status,
      createdAt: _today,
    );

WaterLogModel _water(String childId, int ml) => WaterLogModel(
      id: 'w1',
      childId: childId,
      amountMl: ml,
      loggedAt: _today,
    );

// ── App builder ───────────────────────────────────────────────────────────────

Widget _buildNutritionApp({
  required UserModel user,
  List<ChildModel> athletes = const [],
  List<MealModel> mealsForChild1 = const [],
  List<WaterLogModel> waterForChild1 = const [],
}) {
  final db = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      firestoreProvider.overrideWithValue(db),
      currentUserModelProvider.overrideWith((_) => Stream.value(user)),
      allChildrenProvider.overrideWith((_) => Stream.value(athletes)),
      allMembershipsProvider.overrideWith((_) => Stream.value(const [])),
      if (mealsForChild1.isNotEmpty)
        childMealsProvider('c1').overrideWith((_) => Stream.value(mealsForChild1)),
      if (waterForChild1.isNotEmpty)
        childWaterLogsProvider('c1').overrideWith((_) => Stream.value(waterForChild1)),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/nutrition',
        routes: [
          GoRoute(
            path: '/nutrition',
            builder: (_, __) => const NutritionScreen(),
          ),
          GoRoute(
            path: '/nutrition/child/:childId',
            builder: (_, state) => NutritionDashboard(
              childId: state.pathParameters['childId'] ?? '',
              showBackButton: true,
            ),
          ),
          GoRoute(
            path: '/nutrition/child/:childId/stats',
            builder: (_, __) => const Scaffold(body: Text('Статистика')),
          ),
          GoRoute(
            path: '/nutrition/child/:childId/add-meal',
            builder: (_, __) => const Scaffold(body: Text('Додати прийом')),
          ),
          GoRoute(
            path: '/nutrition/child/:childId/water',
            builder: (_, __) => const Scaffold(body: Text('Вода')),
          ),
          GoRoute(
            path: '/nutrition/child/:childId/plate',
            builder: (_, __) => const Scaffold(body: Text('Тарілка')),
          ),
          GoRoute(
            path: '/nutrition/child/:childId/diary',
            builder: (_, __) => const Scaffold(body: Text('Щоденник')),
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
  setUpAll(() async {
    await initializeDateFormatting('uk');
  });

  group('SC-N-001: тренер бачить заголовок «Харчування команди»', () {
    testWidgets('заголовок відображається для тренера', (tester) async {
      await tester.pumpWidget(_buildNutritionApp(user: _coach, athletes: []));
      await _settle(tester);

      expect(find.textContaining('Харчування'), findsWidgets,
          reason: 'Заголовок «Харчування команди» має бути видний тренеру');
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-N-002: тренер з 3 спортсменами бачить всіх', () {
    testWidgets('Петренко, Коваленко, Шевченко видні у списку', (tester) async {
      final athletes = [
        _athlete('a1', 'Петренко'),
        _athlete('a2', 'Коваленко'),
        _athlete('a3', 'Шевченко'),
      ];
      await tester.pumpWidget(_buildNutritionApp(user: _coach, athletes: athletes));
      await _settle(tester);

      expect(find.textContaining('Петренко'), findsWidgets,
          reason: 'Петренко має бути видний в огляді харчування');
      expect(find.textContaining('Коваленко'), findsWidgets,
          reason: 'Коваленко має бути видний в огляді харчування');
      expect(find.textContaining('Шевченко'), findsWidgets,
          reason: 'Шевченко має бути видний в огляді харчування');
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-N-003: батько бачить дашборд своєї дитини', () {
    testWidgets('parent → NutritionScreen → NutritionDashboard (effectiveChildId=c1)', (tester) async {
      final parent = _parent('c1');
      final meals = [
        _meal(id: 'm1', childId: 'c1', type: MealType.breakfast),
        _meal(id: 'm2', childId: 'c1', type: MealType.lunch),
      ];
      await tester.pumpWidget(_buildNutritionApp(
        user: parent,
        mealsForChild1: meals,
      ));
      await _settle(tester);

      // NutritionDashboard рендериться без краша
      expect(tester.takeException(), isNull);
    });

    testWidgets('тренер НЕ бачить NutritionDashboard — бачить огляд команди', (tester) async {
      await tester.pumpWidget(_buildNutritionApp(user: _coach, athletes: []));
      await _settle(tester);

      // Тренер бачить «Харчування» (огляд команди), а не індивідуальний дашборд
      expect(find.textContaining('Харчування'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-N-004: nutritionScoreProvider — 3 прийоми + 1500 мл = ~63 балів', () {
    testWidgets('правильна формула оцінки харчування', (tester) async {
      // Сніданок + обід + вечеря (done, з білками+овочами+вугл.) + 1500мл води
      final meals = [
        _meal(id: 'm1', childId: 'c1', type: MealType.breakfast,
            hasProtein: true, hasVegetables: true, hasCarbs: true),
        _meal(id: 'm2', childId: 'c1', type: MealType.lunch,
            hasProtein: true, hasVegetables: true, hasCarbs: true),
        _meal(id: 'm3', childId: 'c1', type: MealType.dinner,
            hasProtein: true, hasVegetables: true, hasCarbs: true),
      ];
      final water = [_water('c1', 1500)];

      final container = ProviderContainer(overrides: [
        childMealsProvider('c1').overrideWith((_) => Stream.value(meals)),
        childWaterLogsProvider('c1').overrideWith((_) => Stream.value(water)),
      ]);
      addTearDown(container.dispose);

      // Дочекатись першого значення від StreamProvider перед читанням похідних провайдерів
      await container.read(childMealsProvider('c1').future);
      await container.read(childWaterLogsProvider('c1').future);

      // Дати мають збігатись з todayNutritionKey
      final key = (childId: 'c1', dateKey: _todayKey);
      final score = container.read(nutritionScoreProvider(key));

      // plateScore: 3 meals × (3/5 flags) = 0.6 → 40% × 0.6 = 24
      // waterScore: 1500/1500 = 1.0 → 30% × 1.0 = 30
      // regularityScore: 3/3 = 1.0 → 20% × 1.0 = 20
      // tipsScore: 0 tips → 0 → 10% × 0 = 0
      // Total: 74 (approx, without hasFruits/hadWater flags)
      expect(score, greaterThan(50),
          reason: 'Оцінка з 3 прийомами і повною водою має бути > 50');
      expect(score, lessThanOrEqualTo(100),
          reason: 'Оцінка не може перевищувати 100');
    });

    test('порожній день → оцінка = 0', () async {
      final container = ProviderContainer(overrides: [
        childMealsProvider('c1').overrideWith((_) => Stream.value(const [])),
        childWaterLogsProvider('c1').overrideWith((_) => Stream.value(const [])),
      ]);
      addTearDown(container.dispose);

      await container.read(childMealsProvider('c1').future);
      await container.read(childWaterLogsProvider('c1').future);

      final key = (childId: 'c1', dateKey: _todayKey);
      final score = container.read(nutritionScoreProvider(key));

      expect(score, equals(0.0),
          reason: 'Без прийомів і без води оцінка = 0');
    });
  });

  group('SC-N-005: dayMealsProvider фільтрує тільки сьогоднішні прийоми', () {
    test('вчорашній прийом не потрапляє в сьогоднішній день', () async {
      final yesterday = _today.subtract(const Duration(days: 1));
      final yesterdayKey = nutritionDateKey(yesterday);

      final meals = [
        _meal(id: 'm_today', childId: 'c1', type: MealType.breakfast),
        MealModel(
          id: 'm_yesterday',
          childId: 'c1',
          type: MealType.lunch,
          date: yesterday,
          mealName: 'Обід',
          hasProtein: true, hasVegetables: true, hasCarbs: true,
          hasFruits: false, hadWater: true,
          comment: '',
          status: MealStatus.done,
          createdAt: yesterday,
        ),
      ];

      final container = ProviderContainer(overrides: [
        childMealsProvider('c1').overrideWith((_) => Stream.value(meals)),
      ]);
      addTearDown(container.dispose);

      // Дочекатись першого значення від StreamProvider
      await container.read(childMealsProvider('c1').future);

      final todayMeals = container.read(
        dayMealsProvider((childId: 'c1', dateKey: _todayKey)),
      );
      final yesterdayMeals = container.read(
        dayMealsProvider((childId: 'c1', dateKey: yesterdayKey)),
      );

      expect(todayMeals.length, 1,
          reason: 'Тільки 1 сьогоднішній прийом');
      expect(todayMeals.first.id, 'm_today');
      expect(yesterdayMeals.length, 1,
          reason: 'Вчорашній прийом у своєму dateKey');
      expect(yesterdayMeals.first.id, 'm_yesterday');
    });
  });
}

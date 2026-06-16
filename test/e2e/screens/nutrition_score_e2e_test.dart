/// TC-NUTR-SCORE — Бізнес-логіка підрахунку балів харчування.
///
/// Ключові правила:
///   1. plateScore кожного прийому їжі = кількість увімкнених прапорців / 5
///   2. В compositeScore зараховуються ТІЛЬКИ meals зі статусом done
///   3. regularityScore = тільки breakfast + lunch + dinner (snack/supper не рахуються)
///   4. waterScore = min(waterMl / 1500, 1.0) — ціль 1500 мл, перевиконання не рахується
///   5. plateSummaryProvider — знаменник = кількість done-прийомів, не всіх
///   6. overall PlateSummary = середнє арифметичне 5 компонентів
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/meal_model.dart';
import 'dart:math' as math;

// ── Дублікат логіки nutritionScoreProvider (pure, без Riverpod) ───────────────

double _nutritionScore({
  required List<MealModel> meals,
  required int waterMl,
  int waterGoal = 1500,
  int totalTips = 0,
  int readTips = 0,
}) {
  final doneMeals = meals.where((m) => m.status == MealStatus.done).toList();

  final plateScore = doneMeals.isEmpty
      ? 0.0
      : doneMeals.map((m) => m.plateScore).reduce((a, b) => a + b) /
            doneMeals.length;

  final waterScore =
      waterGoal > 0 ? math.min(waterMl / waterGoal, 1.0) : 0.0;

  final mainDone = meals
      .where((m) =>
          m.status == MealStatus.done &&
          (m.type == MealType.breakfast ||
              m.type == MealType.lunch ||
              m.type == MealType.dinner))
      .length;
  final regularityScore = math.min(mainDone / 3.0, 1.0);

  final tipsScore =
      totalTips == 0 ? 0.0 : readTips / totalTips;

  return (plateScore * 0.4 +
          waterScore * 0.3 +
          regularityScore * 0.2 +
          tipsScore * 0.1) *
      100;
}

({
  double proteinPct,
  double vegetablesPct,
  double carbsPct,
  double fruitsPct,
  double waterPct,
  double overall,
}) _plateSummary({
  required List<MealModel> meals,
  required int waterMl,
  int waterGoal = 1500,
}) {
  final done = meals.where((m) => m.status == MealStatus.done).toList();
  final waterPct =
      waterGoal > 0 ? math.min(waterMl / waterGoal, 1.0) : 0.0;

  if (done.isEmpty) {
    return (
      proteinPct: 0,
      vegetablesPct: 0,
      carbsPct: 0,
      fruitsPct: 0,
      waterPct: waterPct,
      overall: waterPct / 5.0,
    );
  }
  final n = done.length.toDouble();
  final p = done.where((m) => m.hasProtein).length / n;
  final v = done.where((m) => m.hasVegetables).length / n;
  final c = done.where((m) => m.hasCarbs).length / n;
  final f = done.where((m) => m.hasFruits).length / n;
  return (
    proteinPct: p,
    vegetablesPct: v,
    carbsPct: c,
    fruitsPct: f,
    waterPct: waterPct,
    overall: (p + v + c + f + waterPct) / 5.0,
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

MealModel _meal({
  String id = 'm1',
  MealType type = MealType.breakfast,
  MealStatus status = MealStatus.done,
  bool hasProtein = false,
  bool hasVegetables = false,
  bool hasCarbs = false,
  bool hasFruits = false,
  bool hadWater = false,
}) =>
    MealModel(
      id: id,
      childId: 'child1',
      type: type,
      date: DateTime(2026, 1, 1),
      mealName: 'Тест',
      hasProtein: hasProtein,
      hasVegetables: hasVegetables,
      hasCarbs: hasCarbs,
      hasFruits: hasFruits,
      hadWater: hadWater,
      comment: '',
      status: status,
      createdAt: DateTime(2026, 1, 1),
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── TC-NUTR-SCORE-001: plateScore per meal ───────────────────────────────────

  group('TC-NUTR-SCORE-001: plateScore кожного прийому їжі', () {
    test('всі 5 прапорців = true → plateScore == 1.0', () {
      final m = _meal(
        hasProtein: true,
        hasVegetables: true,
        hasCarbs: true,
        hasFruits: true,
        hadWater: true,
      );
      expect(m.plateScore, equals(1.0));
    });

    test('всі 5 прапорців = false → plateScore == 0.0', () {
      final m = _meal();
      expect(m.plateScore, equals(0.0));
    });

    test('рівно 3 з 5 прапорців → plateScore == 0.6', () {
      final m = _meal(hasProtein: true, hasVegetables: true, hasCarbs: true);
      expect(m.plateScore, closeTo(0.6, 0.001));
    });

    test('тільки hadWater=true → plateScore == 0.2 (вода = 1 з 5)', () {
      final m = _meal(hadWater: true);
      expect(m.plateScore, closeTo(0.2, 0.001));
    });

    test('рівно 1 прапорець (hasProtein) → plateScore == 0.2', () {
      final m = _meal(hasProtein: true);
      expect(m.plateScore, closeTo(0.2, 0.001));
    });

    test('рівно 4 з 5 прапорців → plateScore == 0.8', () {
      final m = _meal(
          hasProtein: true,
          hasVegetables: true,
          hasCarbs: true,
          hasFruits: true);
      expect(m.plateScore, closeTo(0.8, 0.001));
    });
  });

  // ── TC-NUTR-SCORE-002: статус done/skipped/pending у score ───────────────────

  group('TC-NUTR-SCORE-002: тільки done-прийоми враховуються в compositeScore', () {
    test('meal зі статусом skipped + всі прапорці = true → не рахується у plateScore', () {
      final score = _nutritionScore(
        meals: [_meal(status: MealStatus.skipped, hasProtein: true, hasVegetables: true, hasCarbs: true, hasFruits: true, hadWater: true)],
        waterMl: 0,
      );
      expect(score, equals(0.0));
    });

    test('meal зі статусом pending + всі прапорці = true → не рахується у plateScore', () {
      final score = _nutritionScore(
        meals: [_meal(status: MealStatus.pending, hasProtein: true, hasVegetables: true, hasCarbs: true, hasFruits: true, hadWater: true)],
        waterMl: 0,
      );
      expect(score, equals(0.0));
    });

    test('1 done з усіма прапорцями + 1 skipped → plateScore = 1.0 (тільки done)', () {
      final meals = [
        _meal(id: 'm1', status: MealStatus.done, hasProtein: true, hasVegetables: true, hasCarbs: true, hasFruits: true, hadWater: true),
        _meal(id: 'm2', status: MealStatus.skipped, hasProtein: false),
      ];
      final score = _nutritionScore(meals: meals, waterMl: 0);
      // plateScore=1.0*0.4 + waterScore=0*0.3 + regularity=1/3*0.2 (breakfast done) = 0.4+0+0.0666 = ~46.7
      expect(score, greaterThan(0));
    });
  });

  // ── TC-NUTR-SCORE-003: regularityScore — тільки breakfast+lunch+dinner ────────

  group('TC-NUTR-SCORE-003: regularityScore рахує тільки 3 основних прийоми', () {
    test('тільки snack (done) → regularityScore == 0', () {
      final score = _nutritionScore(
        meals: [_meal(type: MealType.snack, status: MealStatus.done)],
        waterMl: 0,
      );
      // plateScore=0*0.4 + water=0 + regularity=0*0.2 + tips=0 = 0
      expect(score, equals(0.0));
    });

    test('тільки supper (done) → regularityScore == 0', () {
      final score = _nutritionScore(
        meals: [_meal(type: MealType.supper, status: MealStatus.done)],
        waterMl: 0,
      );
      expect(score, equals(0.0));
    });

    test('breakfast done + snack done + supper done → regularityScore = 1/3', () {
      final meals = [
        _meal(id: '1', type: MealType.breakfast, status: MealStatus.done),
        _meal(id: '2', type: MealType.snack, status: MealStatus.done),
        _meal(id: '3', type: MealType.supper, status: MealStatus.done),
      ];
      // mainDone = 1 (only breakfast), regularityScore = 1/3
      final score = _nutritionScore(meals: meals, waterMl: 0);
      const expected = (1 / 3.0) * 0.2 * 100;
      expect(score, closeTo(expected, 0.5));
    });

    test('breakfast + lunch + dinner всі done → regularityScore == 1.0', () {
      final meals = [
        _meal(id: '1', type: MealType.breakfast, status: MealStatus.done),
        _meal(id: '2', type: MealType.lunch, status: MealStatus.done),
        _meal(id: '3', type: MealType.dinner, status: MealStatus.done),
      ];
      const expected = 0.2 * 100; // regularityScore=1.0, the rest=0
      final score = _nutritionScore(meals: meals, waterMl: 0);
      expect(score, closeTo(expected, 0.5));
    });

    test('4 основних прийоми done → regularityScore ВСЕ ОДНО = 1.0, не 4/3', () {
      final meals = [
        _meal(id: '1', type: MealType.breakfast, status: MealStatus.done),
        _meal(id: '2', type: MealType.lunch, status: MealStatus.done),
        _meal(id: '3', type: MealType.dinner, status: MealStatus.done),
        _meal(id: '4', type: MealType.snack, status: MealStatus.done),
      ];
      final score3 = _nutritionScore(meals: meals.take(3).toList(), waterMl: 0);
      final score4 = _nutritionScore(meals: meals, waterMl: 0);
      // regularityScore is capped at 1.0, so adding snack should not change regularity
      expect(score4, closeTo(score3, 0.5));
    });
  });

  // ── TC-NUTR-SCORE-004: waterScore — ціль 1500 мл ─────────────────────────────

  group('TC-NUTR-SCORE-004: waterScore — ціль 1500 мл, перевиконання не рахується', () {
    test('waterMl == 1500 → waterScore == 1.0 (повна ціль)', () {
      final score = _nutritionScore(meals: [], waterMl: 1500);
      // waterScore=1.0, plateScore=0, regularity=0, tips=0
      expect(score, closeTo(1.0 * 0.3 * 100, 0.1));
    });

    test('waterMl == 3000 (вдвічі більше) → waterScore == 1.0 (не 2.0)', () {
      final score3000 = _nutritionScore(meals: [], waterMl: 3000);
      final score1500 = _nutritionScore(meals: [], waterMl: 1500);
      expect(score3000, closeTo(score1500, 0.01),
          reason: 'Перевиконання цілі не дає додаткових балів');
    });

    test('waterMl == 750 → waterScore == 0.5', () {
      final score = _nutritionScore(meals: [], waterMl: 750);
      expect(score, closeTo(0.5 * 0.3 * 100, 0.1));
    });

    test('waterMl == 0 → waterScore == 0', () {
      final score = _nutritionScore(meals: [], waterMl: 0);
      expect(score, closeTo(0, 0.01));
    });
  });

  // ── TC-NUTR-SCORE-005: tipsScore — частка прочитаних порад ──────────────────

  group('TC-NUTR-SCORE-005: tipsScore — частка прочитаних порад', () {
    test('0 порад → tipsScore == 0 (ділення на нуль не відбувається)', () {
      final score = _nutritionScore(
        meals: [], waterMl: 0, totalTips: 0, readTips: 0);
      expect(score, equals(0.0));
    });

    test('1 порада, дитина НЕ прочитала → tipsScore == 0', () {
      final score = _nutritionScore(
        meals: [], waterMl: 0, totalTips: 1, readTips: 0);
      expect(score, closeTo(0.0, 0.01));
    });

    test('1 порада, дитина прочитала → tipsScore == 1.0 (10 балів)', () {
      final score = _nutritionScore(
        meals: [], waterMl: 0, totalTips: 1, readTips: 1);
      expect(score, closeTo(1.0 * 0.1 * 100, 0.1));
    });

    test('3 поради, прочитана 1 → tipsScore == 1/3', () {
      final score = _nutritionScore(
        meals: [], waterMl: 0, totalTips: 3, readTips: 1);
      expect(score, closeTo((1 / 3.0) * 0.1 * 100, 0.1));
    });
  });

  // ── TC-NUTR-SCORE-006: plateSummary ─────────────────────────────────────────

  group('TC-NUTR-SCORE-006: plateSummary — знаменник = тільки done-прийоми', () {
    test('2 done, 1 skipped — proteinPct ділиться на 2 (не 3)', () {
      final meals = [
        _meal(id: '1', status: MealStatus.done, hasProtein: true),
        _meal(id: '2', status: MealStatus.done, hasProtein: false),
        _meal(id: '3', status: MealStatus.skipped, hasProtein: true),
      ];
      final summary = _plateSummary(meals: meals, waterMl: 0);
      // 1 done has protein out of 2 done meals = 0.5
      expect(summary.proteinPct, closeTo(0.5, 0.001));
    });

    test('0 done → всі компоненти == 0, крім waterPct', () {
      final meals = [
        _meal(id: '1', status: MealStatus.skipped, hasProtein: true),
      ];
      final summary = _plateSummary(meals: meals, waterMl: 0);
      expect(summary.proteinPct, equals(0.0));
      expect(summary.vegetablesPct, equals(0.0));
      expect(summary.carbsPct, equals(0.0));
      expect(summary.fruitsPct, equals(0.0));
    });

    test('waterMl == 3000 (подвійна ціль) → waterPct == 1.0', () {
      final summary = _plateSummary(meals: [], waterMl: 3000);
      expect(summary.waterPct, equals(1.0));
    });

    test('overall == середнє арифметичне 5 компонентів', () {
      final meals = [
        _meal(
          id: '1',
          status: MealStatus.done,
          hasProtein: true,
          hasVegetables: false,
          hasCarbs: true,
          hasFruits: false,
        ),
      ];
      // waterMl = 750 → waterPct = 0.5
      final summary = _plateSummary(meals: meals, waterMl: 750);
      final expected = (1.0 + 0.0 + 1.0 + 0.0 + 0.5) / 5.0;
      expect(summary.overall, closeTo(expected, 0.001));
    });

    test('всі 5 компонентів >= 80% → overall >= 0.8', () {
      final meals = [
        _meal(
          id: '1',
          status: MealStatus.done,
          hasProtein: true,
          hasVegetables: true,
          hasCarbs: true,
          hasFruits: true,
          hadWater: true,
        ),
      ];
      final summary = _plateSummary(meals: meals, waterMl: 1500);
      expect(summary.proteinPct, greaterThanOrEqualTo(0.8));
      expect(summary.vegetablesPct, greaterThanOrEqualTo(0.8));
      expect(summary.carbsPct, greaterThanOrEqualTo(0.8));
      expect(summary.fruitsPct, greaterThanOrEqualTo(0.8));
      expect(summary.waterPct, greaterThanOrEqualTo(0.8));
      expect(summary.overall, greaterThanOrEqualTo(0.8));
    });
  });

  // ── TC-NUTR-SCORE-007: повний сценарій дня ───────────────────────────────────

  group('TC-NUTR-SCORE-007: повний день з ідеальним харчуванням', () {
    test('3 основних прийоми (всі done, всі прапорці) + 1500 мл + всі поради → score >= 90', () {
      final meals = [
        _meal(id: '1', type: MealType.breakfast, status: MealStatus.done,
            hasProtein: true, hasVegetables: true, hasCarbs: true, hasFruits: true, hadWater: true),
        _meal(id: '2', type: MealType.lunch, status: MealStatus.done,
            hasProtein: true, hasVegetables: true, hasCarbs: true, hasFruits: true, hadWater: true),
        _meal(id: '3', type: MealType.dinner, status: MealStatus.done,
            hasProtein: true, hasVegetables: true, hasCarbs: true, hasFruits: true, hadWater: true),
      ];
      final score = _nutritionScore(
        meals: meals, waterMl: 1500, totalTips: 2, readTips: 2);
      expect(score, greaterThanOrEqualTo(90));
    });

    test('нульовий день (0 прийомів, 0 води, 0 порад) → score == 0', () {
      final score = _nutritionScore(meals: [], waterMl: 0);
      expect(score, equals(0.0));
    });
  });
}

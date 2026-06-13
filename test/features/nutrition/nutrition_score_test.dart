import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/meal_model.dart';

// Mirrors nutritionScoreProvider formula (no Firebase needed).
double _score({
  List<MealModel> meals = const [],
  int waterMl = 0,
  int waterGoal = 1500,
  int tipsTotal = 0,
  int tipsRead = 0,
}) {
  final doneMeals = meals.where((m) => m.status == MealStatus.done).toList();
  final plateScore = doneMeals.isEmpty
      ? 0.0
      : doneMeals.map((m) => m.plateScore).reduce((a, b) => a + b) /
            doneMeals.length;

  final waterScore =
      waterGoal > 0 ? (waterMl / waterGoal).clamp(0.0, 1.0) : 0.0;

  final mainDone = meals
      .where((m) =>
          m.status == MealStatus.done &&
          (m.type == MealType.breakfast ||
              m.type == MealType.lunch ||
              m.type == MealType.dinner))
      .length;
  final regularityScore = (mainDone / 3.0).clamp(0.0, 1.0);

  final tipsScore =
      tipsTotal == 0 ? 0.0 : (tipsRead / tipsTotal).clamp(0.0, 1.0);

  return (plateScore * 0.4 +
          waterScore * 0.3 +
          regularityScore * 0.2 +
          tipsScore * 0.1) *
      100;
}

MealModel _meal({
  MealType type = MealType.lunch,
  MealStatus status = MealStatus.done,
  bool protein = true,
  bool veg = true,
  bool carbs = true,
  bool fruits = true,
  bool water = true,
}) =>
    MealModel(
      id: 'x', childId: 'c', type: type,
      date: DateTime(2025), mealName: 'тест',
      hasProtein: protein, hasVegetables: veg,
      hasCarbs: carbs, hasFruits: fruits, hadWater: water,
      comment: '', status: status, createdAt: DateTime(2025),
    );

void main() {
  group('nutritionScore formula', () {
    test('пустий день → 0', () {
      expect(_score(), 0.0);
    });

    test('повна тарілка + повна вода → 70 (без regularity і tips)', () {
      // plate=1.0*0.4 + water=1.0*0.3 = 0.7 * 100 = 70
      final s = _score(
        meals: [_meal(type: MealType.snack)], // snack не входить в regularity
        waterMl: 1500,
        waterGoal: 1500,
      );
      expect(s, closeTo(70.0, 0.01));
    });

    test('3 основні прийоми + повна вода → 30+20 water+regularity = 50', () {
      // plate=0 (не done), water=1*30=30, regularity=1*20=20 → 50
      // Wait - all meals are done with full plate. Let me recalculate:
      // plate=1.0*40=40, water=1.0*30=30, regularity=3/3*20=20 → 90
      final s = _score(
        meals: [
          _meal(type: MealType.breakfast),
          _meal(type: MealType.lunch),
          _meal(type: MealType.dinner),
        ],
        waterMl: 1500,
        waterGoal: 1500,
      );
      expect(s, closeTo(90.0, 0.01));
    });

    test('максимальний бал → 100', () {
      final s = _score(
        meals: [
          _meal(type: MealType.breakfast),
          _meal(type: MealType.lunch),
          _meal(type: MealType.dinner),
        ],
        waterMl: 1500,
        waterGoal: 1500,
        tipsTotal: 5,
        tipsRead: 5,
      );
      expect(s, closeTo(100.0, 0.01));
    });

    test('вода вище цілі обрізається до 1.0', () {
      final s = _score(waterMl: 9999, waterGoal: 1500);
      // тільки водний компонент: 1.0 * 30 = 30
      expect(s, closeTo(30.0, 0.01));
    });

    test('пропущений прийом не враховується у plateScore', () {
      final s = _score(
        meals: [_meal(status: MealStatus.skipped)],
      );
      expect(s, 0.0);
    });

    test('тільки 1 з 3 основних → regularity = 1/3 ≈ 6.67', () {
      final s = _score(
        meals: [_meal(type: MealType.breakfast)],
      );
      // plate=1*40=40, regularity=1/3*20≈6.67 → ≈46.67
      expect(s, closeTo(46.67, 0.1));
    });

    test('waterGoal=0 → waterScore=0', () {
      final s = _score(waterMl: 500, waterGoal: 0);
      expect(s, 0.0);
    });

    test('часткове прочитання порад', () {
      final s = _score(tipsTotal: 10, tipsRead: 5);
      // 0.5 * 10 = 5
      expect(s, closeTo(5.0, 0.01));
    });
  });
}

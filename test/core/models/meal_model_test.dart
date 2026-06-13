import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/meal_model.dart';

void main() {
  // ── MealType ──────────────────────────────────────────────────────────────

  group('MealType', () {
    test('усі типи мають label', () {
      for (final t in MealType.values) {
        expect(t.label, isNotEmpty);
      }
    });

    test('fromString повертає correct enum', () {
      expect(MealType.fromString('breakfast'), MealType.breakfast);
      expect(MealType.fromString('lunch'),     MealType.lunch);
      expect(MealType.fromString('dinner'),    MealType.dinner);
    });

    test('fromString невідомий → breakfast за замовчуванням', () {
      expect(MealType.fromString('unknown'), MealType.breakfast);
    });
  });

  // ── MealStatus ────────────────────────────────────────────────────────────

  group('MealStatus', () {
    test('fromString невідомий → pending за замовчуванням', () {
      expect(MealStatus.fromString('???'), MealStatus.pending);
    });

    test('fromString всі значення', () {
      expect(MealStatus.fromString('done'),    MealStatus.done);
      expect(MealStatus.fromString('skipped'), MealStatus.skipped);
      expect(MealStatus.fromString('pending'), MealStatus.pending);
    });
  });

  // ── MealModel.dateKey ─────────────────────────────────────────────────────

  group('MealModel.dateKey', () {
    MealModel _meal(DateTime date) => MealModel(
      id: 'x', childId: 'c', type: MealType.breakfast, date: date,
      mealName: 'тест', hasProtein: false, hasVegetables: false,
      hasCarbs: false, hasFruits: false, hadWater: false,
      comment: '', status: MealStatus.done,
      createdAt: date,
    );

    test('format YYYY-MM-DD', () {
      final m = _meal(DateTime(2025, 6, 7));
      expect(m.dateKey, '2025-06-07');
    });

    test('однозначні місяць і день доповнюються нулями', () {
      final m = _meal(DateTime(2025, 1, 5));
      expect(m.dateKey, '2025-01-05');
    });
  });

  // ── MealModel.plateScore ──────────────────────────────────────────────────

  group('MealModel.plateScore', () {
    MealModel _meal({
      bool protein = false, bool veg = false, bool carbs = false,
      bool fruits = false, bool water = false,
    }) =>
        MealModel(
          id: 'x', childId: 'c', type: MealType.lunch,
          date: DateTime(2025), mealName: 'тест',
          hasProtein: protein, hasVegetables: veg,
          hasCarbs: carbs, hasFruits: fruits, hadWater: water,
          comment: '', status: MealStatus.done,
          createdAt: DateTime(2025),
        );

    test('0 елементів → 0.0', () {
      expect(_meal().plateScore, 0.0);
    });

    test('1 елемент → 0.2', () {
      expect(_meal(protein: true).plateScore, closeTo(0.2, 0.001));
    });

    test('5 елементів → 1.0', () {
      expect(_meal(
        protein: true, veg: true, carbs: true, fruits: true, water: true,
      ).plateScore, 1.0);
    });

    test('3 елементи → 0.6', () {
      expect(_meal(protein: true, veg: true, carbs: true).plateScore,
          closeTo(0.6, 0.001));
    });
  });
}

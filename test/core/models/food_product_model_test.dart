import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/food_product_model.dart';

void main() {
  // ── FoodCategory ──────────────────────────────────────────────────────────

  group('FoodCategory', () {
    test('усі категорії мають label', () {
      for (final c in FoodCategory.values) {
        expect(c.label, isNotEmpty);
      }
    });

    test('fromString невідомий → protein за замовчуванням', () {
      expect(FoodCategory.fromString('???'), FoodCategory.protein);
    });

    test('fromString "vegetables"', () {
      expect(FoodCategory.fromString('vegetables'), FoodCategory.vegetables);
    });
  });

  // ── FoodProductModel.defaults ─────────────────────────────────────────────

  group('FoodProductModel.defaults', () {
    test('не порожній список', () {
      expect(FoodProductModel.defaults, isNotEmpty);
    });

    test('всі id унікальні', () {
      final ids = FoodProductModel.defaults.map((p) => p.id).toSet();
      expect(ids.length, FoodProductModel.defaults.length);
    });

    test('не-питні продукти мають calories > 0', () {
      // Вода (fd_water) легально має 0 калорій
      final nonWater = FoodProductModel.defaults
          .where((p) => p.id != 'fd_water')
          .toList();
      expect(
        nonWater.every((p) => p.calories > 0),
        isTrue,
      );
    });

    test('у всіх непорожній name', () {
      expect(
        FoodProductModel.defaults.every((p) => p.name.isNotEmpty),
        isTrue,
      );
    });

    test('є хоча б один продукт кожної категорії', () {
      final cats = FoodProductModel.defaults.map((p) => p.category).toSet();
      for (final c in FoodCategory.values) {
        expect(cats, contains(c), reason: 'відсутня категорія ${c.name}');
      }
    });
  });

  // ── toFirestore ───────────────────────────────────────────────────────────

  group('FoodProductModel.toFirestore', () {
    test('містить name, category, calories, protein, fat, carbs', () {
      const p = FoodProductModel(
        id: 'x', name: 'Яйце', category: FoodCategory.protein,
        description: 'desc', calories: 77,
        protein: 6.3, fat: 5.3, carbs: 0.6,
      );
      final map = p.toFirestore();
      expect(map['name'],     'Яйце');
      expect(map['category'], 'protein');
      expect(map['calories'], 77);
      expect(map['protein'],  6.3);
    });
  });
}

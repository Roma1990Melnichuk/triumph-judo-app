import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/child_model.dart';

void main() {
  group('displayWeight', () {
    test('прибирає "-" з від\'ємних категорій', () {
      expect(displayWeight('-30 кг'), '30 кг');
      expect(displayWeight('-48 кг'), '48 кг');
      expect(displayWeight('-60 кг'), '60 кг');
    });

    test('зберігає "+" у категоріях "понад N кг" — щоб не дублювати в списку', () {
      expect(displayWeight('+48 кг'), '+48 кг');
      expect(displayWeight('+60 кг'), '+60 кг');
    });

    test('не змінює рядок без знаку', () {
      expect(displayWeight('60 кг'), '60 кг');
      expect(displayWeight(''), '');
    });
  });

  group('weightCategories', () {
    test('містить +48 кг (для жіночих категорій)', () {
      expect(weightCategories, contains('+48 кг'));
    });

    test('містить +60 кг', () {
      expect(weightCategories, contains('+60 кг'));
    });

    test('всі категорії унікальні', () {
      expect(weightCategories.toSet().length, weightCategories.length);
    });

    test('не порожній', () {
      expect(weightCategories, isNotEmpty);
    });
  });
}

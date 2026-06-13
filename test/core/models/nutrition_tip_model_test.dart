import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/nutrition_tip_model.dart';

void main() {
  // ── TipCategory ───────────────────────────────────────────────────────────

  group('TipCategory', () {
    test('усі категорії мають label', () {
      for (final c in TipCategory.values) {
        expect(c.label, isNotEmpty);
      }
    });

    test('fromString невідомий → general', () {
      expect(TipCategory.fromString('xyz'), TipCategory.general);
    });

    test('fromString коректно парсить hydration', () {
      expect(TipCategory.fromString('hydration'), TipCategory.hydration);
    });
  });

  // ── NutritionTipModel.isReadBy ────────────────────────────────────────────

  group('NutritionTipModel.isReadBy', () {
    NutritionTipModel _tip(List<String> readBy) => NutritionTipModel(
      id: '1', title: 'Тест', body: 'Body',
      category: TipCategory.general,
      publishedAt: DateTime(2025), coachId: 'coach1',
      readBy: readBy,
    );

    test('повертає true якщо childId у readBy', () {
      expect(_tip(['child1', 'child2']).isReadBy('child1'), isTrue);
    });

    test('повертає false якщо childId відсутній', () {
      expect(_tip(['child2']).isReadBy('child1'), isFalse);
    });

    test('порожній readBy → false', () {
      expect(_tip([]).isReadBy('child1'), isFalse);
    });
  });

  // ── toFirestore ───────────────────────────────────────────────────────────

  group('NutritionTipModel.toFirestore', () {
    test('містить title, body, category, coachId, readBy', () {
      final tip = NutritionTipModel(
        id: '1', title: 'Заголовок', body: 'Текст',
        category: TipCategory.preTrain,
        publishedAt: DateTime(2025), coachId: 'coach99',
        readBy: ['c1'],
      );
      final map = tip.toFirestore();
      expect(map['title'],    'Заголовок');
      expect(map['body'],     'Текст');
      expect(map['category'], 'preTrain');
      expect(map['coachId'],  'coach99');
      expect(map['readBy'],   ['c1']);
    });
  });

  // ── copyWithReadBy ────────────────────────────────────────────────────────

  group('NutritionTipModel.copyWithReadBy', () {
    test('повертає нову модель з оновленим readBy', () {
      final tip = NutritionTipModel(
        id: '1', title: 'T', body: 'B',
        category: TipCategory.general,
        publishedAt: DateTime(2025), coachId: 'c',
        readBy: [],
      );
      final updated = tip.copyWithReadBy(['x']);
      expect(updated.readBy, ['x']);
      expect(tip.readBy, isEmpty); // оригінал не змінився
    });
  });
}

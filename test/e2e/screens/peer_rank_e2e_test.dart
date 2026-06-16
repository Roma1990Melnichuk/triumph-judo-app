/// E2E тести для computePeerRanks — місце серед однолітків і у ваговій категорії.
/// Тестує логіку, яка відображається на екрані профілю спортсмена.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/features/team/utils/peer_rank.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

ChildModel _child({
  required String id,
  required int birthYear,
  required int totalPoints,
  String weightCategory = '-40 кг',
  String lastName = 'Петренко',
}) =>
    ChildModel(
      id: id,
      firstName: 'Іван',
      lastName: lastName,
      birthYear: birthYear,
      weightCategory: weightCategory,
      currentBelt: BeltLevel.white,
      coachId: 'coach1',
      coachName: 'Тренер',
      totalPoints: totalPoints,
      createdAt: DateTime(2024),
      bonusPoints: 0,
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('computePeerRanks — порожній список', () {
    test('повертає порожні мапи', () {
      final r = computePeerRanks([]);
      expect(r.yearRanks, isEmpty);
      expect(r.yearTotals, isEmpty);
      expect(r.weightRanks, isEmpty);
      expect(r.weightTotals, isEmpty);
    });
  });

  group('computePeerRanks — один спортсмен', () {
    test('rank = 1, total = 1', () {
      final r = computePeerRanks([_child(id: 'kid1', birthYear: 2015, totalPoints: 100)]);
      expect(r.yearRanks['kid1'], 1);
      expect(r.yearTotals[2015], 1);
      expect(r.weightRanks['kid1'], 1);
      expect(r.weightTotals['2015/-40 кг'], 1);
    });
  });

  group('computePeerRanks — кілька однолітків (сортування за балами)', () {
    test('перший — найбільше балів', () {
      final r = computePeerRanks([
        _child(id: 'kid1', birthYear: 2015, totalPoints: 50),
        _child(id: 'kid2', birthYear: 2015, totalPoints: 100),
        _child(id: 'kid3', birthYear: 2015, totalPoints: 75),
      ]);

      expect(r.yearRanks['kid2'], 1); // 100 балів → #1
      expect(r.yearRanks['kid3'], 2); // 75 балів → #2
      expect(r.yearRanks['kid1'], 3); // 50 балів → #3
      expect(r.yearTotals[2015], 3);
    });

    test('при рівних балах — алфавітний порядок прізвища', () {
      final r = computePeerRanks([
        _child(id: 'kidC', birthYear: 2015, totalPoints: 100, lastName: 'Сидоренко'),
        _child(id: 'kidA', birthYear: 2015, totalPoints: 100, lastName: 'Іванченко'),
        _child(id: 'kidB', birthYear: 2015, totalPoints: 100, lastName: 'Петренко'),
      ]);

      expect(r.yearRanks['kidA'], 1); // Іванченко — перший алфавітно
      expect(r.yearRanks['kidB'], 2); // Петренко
      expect(r.yearRanks['kidC'], 3); // Сидоренко
    });

    test('підраховує total правильно', () {
      final r = computePeerRanks([
        _child(id: 'k1', birthYear: 2015, totalPoints: 100),
        _child(id: 'k2', birthYear: 2015, totalPoints: 80),
        _child(id: 'k3', birthYear: 2015, totalPoints: 60),
        _child(id: 'k4', birthYear: 2016, totalPoints: 200), // інший рік
      ]);

      expect(r.yearTotals[2015], 3);
      expect(r.yearTotals[2016], 1);
    });
  });

  group('computePeerRanks — різні роки народження', () {
    test('ранги ізольовані по роках', () {
      final r = computePeerRanks([
        _child(id: 'k2015a', birthYear: 2015, totalPoints: 80),
        _child(id: 'k2015b', birthYear: 2015, totalPoints: 50),
        _child(id: 'k2016a', birthYear: 2016, totalPoints: 30),
        _child(id: 'k2016b', birthYear: 2016, totalPoints: 90),
      ]);

      expect(r.yearRanks['k2015a'], 1);
      expect(r.yearRanks['k2015b'], 2);
      expect(r.yearRanks['k2016b'], 1); // 90 балів серед 2016
      expect(r.yearRanks['k2016a'], 2); // 30 балів серед 2016
      expect(r.yearTotals[2015], 2);
      expect(r.yearTotals[2016], 2);
    });

    test('спортсмен відсутній у списку → rank = null', () {
      final r = computePeerRanks([
        _child(id: 'k1', birthYear: 2015, totalPoints: 100),
      ]);

      expect(r.yearRanks['unknown_kid'], isNull);
    });
  });

  group('computePeerRanks — вагова категорія', () {
    test('ранги за роком+вагою ізольовані', () {
      final r = computePeerRanks([
        _child(id: 'k1', birthYear: 2015, totalPoints: 100, weightCategory: '-40 кг'),
        _child(id: 'k2', birthYear: 2015, totalPoints: 80,  weightCategory: '-40 кг'),
        _child(id: 'k3', birthYear: 2015, totalPoints: 120, weightCategory: '-44 кг'),
        _child(id: 'k4', birthYear: 2015, totalPoints: 60,  weightCategory: '-44 кг'),
      ]);

      expect(r.weightRanks['k1'], 1); // #1 серед -40 кг 2015
      expect(r.weightRanks['k2'], 2); // #2 серед -40 кг 2015
      expect(r.weightRanks['k3'], 1); // #1 серед -44 кг 2015
      expect(r.weightRanks['k4'], 2); // #2 серед -44 кг 2015

      expect(r.weightTotals['2015/-40 кг'], 2);
      expect(r.weightTotals['2015/-44 кг'], 2);
    });

    test('однолітки з різними роками не змішуються у вагові групи', () {
      final r = computePeerRanks([
        _child(id: 'k1', birthYear: 2015, totalPoints: 100, weightCategory: '-40 кг'),
        _child(id: 'k2', birthYear: 2016, totalPoints: 200, weightCategory: '-40 кг'),
      ]);

      // Різні роки → різні вагові групи, кожен rank=1
      expect(r.weightRanks['k1'], 1);
      expect(r.weightRanks['k2'], 1);
      expect(r.weightTotals['2015/-40 кг'], 1);
      expect(r.weightTotals['2016/-40 кг'], 1);
    });

    test('порожня weightCategory — окрема група ""', () {
      final r = computePeerRanks([
        _child(id: 'k1', birthYear: 2015, totalPoints: 100, weightCategory: ''),
        _child(id: 'k2', birthYear: 2015, totalPoints: 80,  weightCategory: ''),
      ]);

      expect(r.weightRanks['k1'], 1);
      expect(r.weightRanks['k2'], 2);
      // UI умова: weightCategory.isNotEmpty → ці ранги не відображаються,
      // але computePeerRanks їх усе одно обчислює.
      expect(r.weightTotals['2015/'], 2);
    });
  });

  group('computePeerRanks — умови відображення (sameYearTotal > 1)', () {
    test('один спортсмен у році — total=1, UI НЕ показує ранг', () {
      final r = computePeerRanks([
        _child(id: 'kid1', birthYear: 2015, totalPoints: 100),
        _child(id: 'kid2', birthYear: 2016, totalPoints: 80), // інший рік
      ]);

      final yearTotal2015 = r.yearTotals[2015]!;
      final yearTotal2016 = r.yearTotals[2016]!;

      // Умова UI: sameYearTotal > 1 — якщо 1, ранг не показуємо
      expect(yearTotal2015, 1); // → не показувати
      expect(yearTotal2016, 1); // → не показувати
    });

    test('два однолітки — total=2, UI показує ранг', () {
      final r = computePeerRanks([
        _child(id: 'k1', birthYear: 2015, totalPoints: 100),
        _child(id: 'k2', birthYear: 2015, totalPoints: 60),
      ]);

      expect(r.yearTotals[2015], 2); // > 1 → показувати
      expect(r.yearRanks['k1'], 1);
      expect(r.yearRanks['k2'], 2);
    });
  });

  group('computePeerRanks — повний сценарій клубу', () {
    test('5 спортсменів: 3 різних роки, 2 вагові категорії', () {
      final r = computePeerRanks([
        _child(id: 'a', birthYear: 2013, totalPoints: 200, weightCategory: '-60 кг', lastName: 'Антоненко'),
        _child(id: 'b', birthYear: 2014, totalPoints: 150, weightCategory: '-50 кг', lastName: 'Бойко'),
        _child(id: 'c', birthYear: 2014, totalPoints: 180, weightCategory: '-50 кг', lastName: 'Василенко'),
        _child(id: 'd', birthYear: 2014, totalPoints: 150, weightCategory: '-55 кг', lastName: 'Гриценко'),
        _child(id: 'e', birthYear: 2013, totalPoints: 90,  weightCategory: '-60 кг', lastName: 'Данченко'),
      ]);

      // Рік 2013: a=200 → #1, e=90 → #2
      expect(r.yearRanks['a'], 1);
      expect(r.yearRanks['e'], 2);
      expect(r.yearTotals[2013], 2);

      // Рік 2014: c=180 → #1, b і d — 150 — рівні, порядок за прізвищем
      expect(r.yearRanks['c'], 1);
      expect(r.yearRanks['b'], 2); // Бойко < Гриценко
      expect(r.yearRanks['d'], 3);
      expect(r.yearTotals[2014], 3);

      // Вагова 2014/-50 кг: c=180 → #1, b=150 → #2
      expect(r.weightRanks['c'], 1);
      expect(r.weightRanks['b'], 2);
      expect(r.weightTotals['2014/-50 кг'], 2);

      // Вагова 2014/-55 кг: тільки d → #1, total=1 → UI не показує
      expect(r.weightRanks['d'], 1);
      expect(r.weightTotals['2014/-55 кг'], 1);
    });
  });
}

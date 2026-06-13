/// TC-TEAM-0388 / TC-TEAM-0389 — Dynamic Filters / Weight Logic
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/membership/providers/membership_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';

// ── Хелпери (повторює pattern з children_filter_test.dart) ───────────────────

ChildModel _child({
  required String id,
  required int birthYear,
  String weightCategory = '-30 кг',
  Gender? gender,
}) =>
    ChildModel(
      id: id,
      firstName: 'Іван',
      lastName: 'Петренко',
      birthYear: birthYear,
      weightCategory: weightCategory,
      currentBelt: BeltLevel.white,
      coachId: 'coach1',
      coachName: 'Тренер',
      totalPoints: 0,
      createdAt: DateTime(2024),
      gender: gender,
    );

ProviderContainer _container(List<ChildModel> children) => ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        allChildrenProvider.overrideWith((ref) => Stream.value(children)),
        allMembershipsProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );

Future<List<ChildModel>> _applyFilter(
    ProviderContainer c, ChildrenFilter f) async {
  await c.read(allChildrenProvider.future);
  c.read(childrenFilterProvider.notifier).state = f;
  return c.read(filteredChildrenProvider);
}

// ── TC-TEAM-0388 ─────────────────────────────────────────────────────────────

void main() {
  group('TC-TEAM-0388: фільтр років народження — тільки роки з БД', () {
    test('фільтр birthYear=2012 повертає тільки спортсменів 2012 року', () async {
      final children = [
        _child(id: 'c1', birthYear: 2010),
        _child(id: 'c2', birthYear: 2012),
        _child(id: 'c3', birthYear: 2012),
        _child(id: 'c4', birthYear: 2014),
      ];
      final c = _container(children);
      addTearDown(c.dispose);

      final result =
          await _applyFilter(c, const ChildrenFilter(birthYear: 2012));
      expect(result.length, equals(2));
      expect(result.every((ch) => ch.birthYear == 2012), isTrue);
    });

    test('фільтр birthYear з відсутнім роком → порожній список', () async {
      final children = [
        _child(id: 'c1', birthYear: 2010),
        _child(id: 'c2', birthYear: 2014),
      ];
      final c = _container(children);
      addTearDown(c.dispose);

      final result =
          await _applyFilter(c, const ChildrenFilter(birthYear: 2013));
      expect(result, isEmpty);
    });

    test('без фільтра року → повертає всіх спортсменів', () async {
      final children = [
        _child(id: 'c1', birthYear: 2010),
        _child(id: 'c2', birthYear: 2012),
        _child(id: 'c3', birthYear: 2014),
      ];
      final c = _container(children);
      addTearDown(c.dispose);

      final result = await _applyFilter(c, const ChildrenFilter());
      expect(result.length, equals(3));
    });

    test('кожен унікальний рік у БД повертає свій набір', () async {
      final children = [
        _child(id: 'c1', birthYear: 2010),
        _child(id: 'c2', birthYear: 2011),
        _child(id: 'c3', birthYear: 2012),
      ];
      final c = _container(children);
      addTearDown(c.dispose);

      for (final year in [2010, 2011, 2012]) {
        final result =
            await _applyFilter(c, ChildrenFilter(birthYear: year));
        expect(result.length, equals(1),
            reason: 'Рік $year повинен мати 1 спортсмена');
        expect(result.first.birthYear, equals(year));
      }
    });
  });

  // ── TC-TEAM-0389 ──────────────────────────────────────────────────────────

  group('TC-TEAM-0389: категорія ваги — нормалізація та фільтрація', () {
    test('weightCategories містить лише валідні формати', () {
      // Всі категорії мають починатися з "-" або "+"
      for (final w in weightCategories) {
        expect(w.startsWith('-') || w.startsWith('+'), isTrue,
            reason: '"$w" не починається з - або +');
      }
    });

    test('displayWeight видаляє префікс "-"', () {
      expect(displayWeight('-30 кг'), equals('30 кг'));
      expect(displayWeight('-40 кг'), equals('40 кг'));
    });

    test('displayWeight зберігає "+" префікс', () {
      expect(displayWeight('+48 кг'), equals('+48 кг'));
    });

    test('фільтр weightCategory повертає тільки відповідних спортсменів', () async {
      final children = [
        _child(id: 'c1', birthYear: 2012, weightCategory: '-30 кг'),
        _child(id: 'c2', birthYear: 2012, weightCategory: '-40 кг'),
        _child(id: 'c3', birthYear: 2013, weightCategory: '-30 кг'),
      ];
      final c = _container(children);
      addTearDown(c.dispose);

      final result = await _applyFilter(
          c, const ChildrenFilter(weightCategory: '-30 кг'));
      expect(result.length, equals(2));
      expect(result.every((ch) => ch.weightCategory == '-30 кг'), isTrue);
    });

    test('weightCategory зберігається в моделі як-є (точна відповідність)', () {
      for (final w in weightCategories) {
        final child = _child(id: 'x', birthYear: 2012, weightCategory: w);
        expect(child.weightCategory, equals(w));
      }
    });
  });
}

/// TC-TEAM-001 — Medal filter + filteredChildrenWithMedalsProvider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/core/models/competition_result_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/competitions/providers/competitions_provider.dart';
import 'package:judo_app/features/membership/providers/membership_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';

// ── Хелпери ───────────────────────────────────────────────────────────────────

ChildModel _child(String id, {BeltLevel belt = BeltLevel.white}) => ChildModel(
      id: id,
      firstName: 'Іван',
      lastName: 'Тест',
      birthYear: 2010,
      weightCategory: '-30 кг',
      currentBelt: belt,
      coachId: 'coach1',
      coachName: 'Тренер',
      totalPoints: 50,
      createdAt: DateTime(2024),
    );

CompetitionResultModel _result(String id, String childId, int place) =>
    CompetitionResultModel(
      id: id,
      childId: childId,
      childName: 'Тест',
      competitionName: 'Турнір',
      level: CompetitionLevel.regional,
      place: place,
      points: place == 1 ? 10 : place == 2 ? 7 : 5,
      date: DateTime(2025, 1, 1),
      seasonYear: 2025,
      addedByCoachId: 'coach1',
    );

ProviderContainer _container(
  List<ChildModel> children,
  List<CompetitionResultModel> results,
) =>
    ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        allChildrenProvider.overrideWith((ref) => Stream.value(children)),
        allMembershipsProvider.overrideWith((ref) => Stream.value([])),
        allResultsProvider.overrideWith((ref) => Stream.value(results)),
      ],
    );

Future<List<ChildModel>> applyMedalFilter(
  ProviderContainer cont,
  ChildrenFilter filter,
) async {
  await cont.read(allChildrenProvider.future);
  await cont.read(allResultsProvider.future);
  cont.read(childrenFilterProvider.notifier).state = filter;
  return cont.read(filteredChildrenWithMedalsProvider);
}

// ── TC-TEAM-001 ───────────────────────────────────────────────────────────────

void main() {
  group('TC-TEAM-001: фільтр по медалям', () {
    test('medalPlaces={} → всі спортсмени повертаються', () async {
      final children = [_child('c1'), _child('c2'), _child('c3')];
      final results = [
        _result('r1', 'c1', 1),
        _result('r2', 'c2', 3),
      ];
      final cont = _container(children, results);
      addTearDown(cont.dispose);

      final result =
          await applyMedalFilter(cont, const ChildrenFilter(medalPlaces: {}));
      expect(result, hasLength(3));
    });

    test('medalPlaces={1} → тільки той хто займав 1-ше місце', () async {
      final children = [_child('c1'), _child('c2'), _child('c3')];
      final results = [
        _result('r1', 'c1', 1),
        _result('r2', 'c2', 2),
      ];
      final cont = _container(children, results);
      addTearDown(cont.dispose);

      final result =
          await applyMedalFilter(cont, const ChildrenFilter(medalPlaces: {1}));
      expect(result.map((c) => c.id), contains('c1'));
      expect(result.any((c) => c.id == 'c2'), isFalse);
      expect(result.any((c) => c.id == 'c3'), isFalse);
    });

    test('medalPlaces={1, 2} → перше і друге місце', () async {
      final children = [_child('c1'), _child('c2'), _child('c3')];
      final results = [
        _result('r1', 'c1', 1),
        _result('r2', 'c2', 2),
        _result('r3', 'c3', 3),
      ];
      final cont = _container(children, results);
      addTearDown(cont.dispose);

      final result = await applyMedalFilter(
          cont, const ChildrenFilter(medalPlaces: {1, 2}));
      expect(result.map((c) => c.id), containsAll(['c1', 'c2']));
      expect(result.any((c) => c.id == 'c3'), isFalse);
    });

    test('medalPlaces={1, 2, 3} → всі призери, без решти', () async {
      final children = [
        _child('c1'), _child('c2'), _child('c3'), _child('c4')
      ];
      final results = [
        _result('r1', 'c1', 1),
        _result('r2', 'c2', 2),
        _result('r3', 'c3', 3),
      ];
      final cont = _container(children, results);
      addTearDown(cont.dispose);

      final result = await applyMedalFilter(
          cont, const ChildrenFilter(medalPlaces: {1, 2, 3}));
      expect(result.map((c) => c.id), containsAll(['c1', 'c2', 'c3']));
      expect(result.any((c) => c.id == 'c4'), isFalse);
    });

    test('без жодних результатів medalPlaces={1} → порожній список', () async {
      final children = [_child('c1'), _child('c2')];
      final cont = _container(children, []);
      addTearDown(cont.dispose);

      final result =
          await applyMedalFilter(cont, const ChildrenFilter(medalPlaces: {1}));
      expect(result, isEmpty);
    });

    test('medalPlaces={1} + belts фільтр разом', () async {
      final c1 = _child('c1', belt: BeltLevel.yellow);
      final c2 = _child('c2', belt: BeltLevel.white);
      final results = [
        _result('r1', 'c1', 1),
        _result('r2', 'c2', 1),
      ];
      final cont = _container([c1, c2], results);
      addTearDown(cont.dispose);

      final result = await applyMedalFilter(
          cont,
          const ChildrenFilter(
            belts: {BeltLevel.yellow},
            medalPlaces: {1},
          ));
      expect(result.map((c) => c.id), contains('c1'));
      expect(result.any((c) => c.id == 'c2'), isFalse);
    });

    test('ChildrenFilter.copyWith(medalPlaces) та clearMedalPlaces', () {
      final f = const ChildrenFilter(medalPlaces: {1, 2});
      expect(f.medalPlaces, containsAll([1, 2]));

      final cleared = f.copyWith(clearMedalPlaces: true);
      expect(cleared.medalPlaces, isEmpty);

      final updated = f.copyWith(medalPlaces: {3});
      expect(updated.medalPlaces, equals({3}));
    });
  });
}

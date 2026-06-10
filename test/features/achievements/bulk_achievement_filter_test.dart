import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/core/models/group_model.dart';
import 'package:judo_app/features/achievements/screens/bulk_grant_achievements_screen.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

ChildModel _child({
  required String id,
  String firstName = 'Іван',
  String lastName = 'Тест',
  int birthYear = 2012,
  BeltLevel belt = BeltLevel.yellow,
}) =>
    ChildModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      birthYear: birthYear,
      weightCategory: '-30 кг',
      currentBelt: belt,
      coachId: 'coach1',
      coachName: 'Тренер',
      totalPoints: 0,
      createdAt: DateTime(2024, 1, 1),
    );

GroupModel _group({
  required String id,
  required String name,
  required List<String> childIds,
}) =>
    GroupModel(
      id: id,
      coachId: 'coach1',
      name: name,
      childIds: childIds,
      daysOfWeek: const [1, 3, 5],
      timeStart: '18:00',
      timeEnd: '19:30',
    );

List<ChildModel> _run({
  List<ChildModel> all = const [],
  List<GroupModel> groups = const [],
  Set<String> groupIds = const {},
  Set<int> years = const {},
  Set<BeltLevel> belts = const {},
  Set<String> extra = const {},
  String nameQuery = '',
}) =>
    bulkAchievementsMatchedAthletes(
      all: all,
      groups: groups,
      selectedGroupIds: groupIds,
      selectedYears: years,
      selectedBelts: belts,
      extraChildIds: extra,
      nameQuery: nameQuery,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  final c1 = _child(id: 'c1', birthYear: 2012, belt: BeltLevel.yellow);
  final c2 = _child(id: 'c2', birthYear: 2013, belt: BeltLevel.orange);
  final c3 = _child(id: 'c3', birthYear: 2012, belt: BeltLevel.green);
  final c4 = _child(id: 'c4', birthYear: 2010, belt: BeltLevel.yellow);
  final all = [c1, c2, c3, c4];

  final gA = _group(id: 'gA', name: 'Група А', childIds: ['c1', 'c2']);
  final gB = _group(id: 'gB', name: 'Група Б', childIds: ['c3', 'c4']);

  group('bulkAchievementsMatchedAthletes — порожній вибір', () {
    test('без фільтрів та без extra → порожній список', () {
      expect(_run(all: all, groups: [gA, gB]), isEmpty);
    });

    test('порожній список спортсменів → порожній список', () {
      expect(_run(all: [], groupIds: {'gA'}), isEmpty);
    });
  });

  group('bulkAchievementsMatchedAthletes — фільтр по групі', () {
    test('одна група → спортсмени цієї групи', () {
      final result = _run(
          all: all, groups: [gA, gB], groupIds: {'gA'});
      expect(result.map((c) => c.id).toSet(), {'c1', 'c2'});
    });

    test('дві групи → об\'єднання спортсменів (OR всередині категорії)', () {
      final result = _run(
          all: all, groups: [gA, gB], groupIds: {'gA', 'gB'});
      expect(result.map((c) => c.id).toSet(), {'c1', 'c2', 'c3', 'c4'});
    });

    test('неіснуюча група → порожній список', () {
      expect(_run(all: all, groups: [gA, gB], groupIds: {'gX'}), isEmpty);
    });
  });

  group('bulkAchievementsMatchedAthletes — фільтр по році', () {
    test('один рік → відповідні спортсмени', () {
      final result = _run(all: all, years: {2012});
      expect(result.map((c) => c.id).toSet(), {'c1', 'c3'});
    });

    test('два роки → OR усередині', () {
      final result = _run(all: all, years: {2012, 2013});
      expect(result.map((c) => c.id).toSet(), {'c1', 'c2', 'c3'});
    });

    test('рік якого немає → порожній список', () {
      expect(_run(all: all, years: {1999}), isEmpty);
    });
  });

  group('bulkAchievementsMatchedAthletes — фільтр по поясу', () {
    test('один пояс → відповідні спортсмени', () {
      final result = _run(all: all, belts: {BeltLevel.yellow});
      expect(result.map((c) => c.id).toSet(), {'c1', 'c4'});
    });

    test('два пояси → OR усередині', () {
      final result =
          _run(all: all, belts: {BeltLevel.yellow, BeltLevel.orange});
      expect(result.map((c) => c.id).toSet(), {'c1', 'c2', 'c4'});
    });
  });

  group('bulkAchievementsMatchedAthletes — AND між категоріями', () {
    test('група + рік → перетин (AND)', () {
      // gA = {c1(2012), c2(2013)}, year=2012 → тільки c1
      final result =
          _run(all: all, groups: [gA, gB], groupIds: {'gA'}, years: {2012});
      expect(result.map((c) => c.id).toSet(), {'c1'});
    });

    test('рік + пояс → перетин (AND)', () {
      // year=2012: c1(жовтий), c3(зелений); belt=yellow → тільки c1
      final result =
          _run(all: all, years: {2012}, belts: {BeltLevel.yellow});
      expect(result.map((c) => c.id).toSet(), {'c1'});
    });

    test('група + рік + пояс → всі три фільтри AND', () {
      // gA={c1,c2}, year=2012, belt=yellow → лише c1
      final result = _run(
        all: all,
        groups: [gA, gB],
        groupIds: {'gA'},
        years: {2012},
        belts: {BeltLevel.yellow},
      );
      expect(result.map((c) => c.id).toSet(), {'c1'});
    });

    test('AND без перетину → порожній список', () {
      // gB={c3,c4}, year=2013 → перетин порожній (c3=2012, c4=2010)
      final result =
          _run(all: all, groups: [gA, gB], groupIds: {'gB'}, years: {2013});
      expect(result, isEmpty);
    });
  });

  group('bulkAchievementsMatchedAthletes — ручний вибір (extra)', () {
    test('extra без фільтрів → тільки extra', () {
      final result = _run(all: all, extra: {'c3'});
      expect(result.map((c) => c.id).toSet(), {'c3'});
    });

    test('extra доповнює фільтр (OR з результатом фільтра)', () {
      // gA={c1,c2}, extra={c4} → {c1,c2,c4}
      final result =
          _run(all: all, groups: [gA, gB], groupIds: {'gA'}, extra: {'c4'});
      expect(result.map((c) => c.id).toSet(), {'c1', 'c2', 'c4'});
    });

    test('extra вже покритий фільтром → без дублікатів', () {
      // gA={c1,c2}, extra={c1} → {c1,c2}, без дублікатів
      final result = _run(
          all: all, groups: [gA, gB], groupIds: {'gA'}, extra: {'c1'});
      final ids = result.map((c) => c.id).toList();
      expect(ids.length, 2);
      expect(ids.toSet(), {'c1', 'c2'});
    });

    test('кілька extra без фільтрів', () {
      final result = _run(all: all, extra: {'c2', 'c4'});
      expect(result.map((c) => c.id).toSet(), {'c2', 'c4'});
    });

    test('extra спортсмен не в списку all → не потрапляє у результат', () {
      final result = _run(all: all, extra: {'unknownId'});
      expect(result, isEmpty);
    });
  });

  group('bulkAchievementsMatchedAthletes — порядок та повнота', () {
    test('зберігає той самий порядок, що й all', () {
      final result = _run(all: all, years: {2012, 2013, 2010});
      final ids = result.map((c) => c.id).toList();
      expect(ids, ['c1', 'c2', 'c3', 'c4']);
    });
  });

  group('bulkAchievementsMatchedAthletes — пошук по імені (nameQuery)', () {
    final named = [
      _child(id: 'n1', firstName: 'Олексій', lastName: 'Коваль'),
      _child(id: 'n2', firstName: 'Марія',   lastName: 'Ковальчук'),
      _child(id: 'n3', firstName: 'Іван',    lastName: 'Петров'),
      _child(id: 'n4', firstName: 'Олена',   lastName: 'Іваненко'),
    ];

    test('порожній nameQuery — не фільтрує по імені', () {
      final result = _run(all: named, years: {2012}, nameQuery: '');
      expect(result.length, named.length);
    });

    test('пошук по прізвищу — часткове співпадіння', () {
      final result = _run(all: named, years: {2012}, nameQuery: 'Коваль');
      expect(result.map((c) => c.id).toSet(), {'n1', 'n2'});
    });

    test('пошук по імені', () {
      final result = _run(all: named, years: {2012}, nameQuery: 'Олен');
      expect(result.map((c) => c.id).toSet(), {'n4'});
    });

    test('пошук регістронезалежний', () {
      final result = _run(all: named, years: {2012}, nameQuery: 'ПЕТРОВ');
      expect(result.map((c) => c.id).toSet(), {'n3'});
    });

    test('пошук без збігів — порожній список', () {
      final result = _run(all: named, years: {2012}, nameQuery: 'Шевченко');
      expect(result, isEmpty);
    });

    test('nameQuery AND фільтр по поясу — перетин', () {
      // n1(yellow), n2(yellow), n3(yellow), n4(yellow)
      // nameQuery='Коваль' → n1,n2; belt=orange → порожньо (всі yellow)
      final result = _run(
        all: named,
        years: {2012},
        belts: {BeltLevel.orange},
        nameQuery: 'Коваль',
      );
      expect(result, isEmpty);
    });

    test('nameQuery з пробілами по краях — trim', () {
      final result = _run(all: named, years: {2012}, nameQuery: '  Петров  ');
      expect(result.map((c) => c.id).toSet(), {'n3'});
    });
  });
}

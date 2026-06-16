/// Тести фільтрів «Абонемент» і «Медалі» для команди.
///
/// Membership filter → filteredChildrenProvider (children_provider.dart:127)
/// Medal filter      → filteredChildrenWithMedalsProvider (competitions_provider.dart:69)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/core/models/competition_result_model.dart';
import 'package:judo_app/core/models/membership_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/competitions/providers/competitions_provider.dart';
import 'package:judo_app/features/membership/providers/membership_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';

// ── Дати (відносні, щоб тести не зламались з часом) ─────────────────────────

final _now = DateTime.now();
final _activeEnd = _now.add(const Duration(days: 60));
final _expiringEnd = _now.add(const Duration(days: 3));
final _expiredEnd = _now.subtract(const Duration(days: 30));

// ── Фабрики ──────────────────────────────────────────────────────────────────

ChildModel _child({
  required String id,
  String lastName = 'Спортсмен',
  String coachName = 'Тренер',
  BeltLevel belt = BeltLevel.white,
  Gender? gender,
  int birthYear = 2012,
  String weightCategory = '-40 кг',
  int totalPoints = 0,
}) =>
    ChildModel(
      id: id,
      firstName: 'Тест',
      lastName: lastName,
      birthYear: birthYear,
      weightCategory: weightCategory,
      currentBelt: belt,
      coachId: 'coach_${coachName.toLowerCase()}',
      coachName: coachName,
      totalPoints: totalPoints,
      createdAt: DateTime(2024),
      gender: gender,
    );

MembershipModel _membership(String athleteId, DateTime endDate) =>
    MembershipModel(
      athleteId: athleteId,
      planName: 'Стандарт',
      startDate: _now.subtract(const Duration(days: 30)),
      endDate: endDate,
      amount: 1000,
    );

MembershipModel _active(String athleteId) => _membership(athleteId, _activeEnd);
MembershipModel _expiring(String athleteId) =>
    _membership(athleteId, _expiringEnd);
MembershipModel _expired(String athleteId) =>
    _membership(athleteId, _expiredEnd);

CompetitionResultModel _result({
  required String childId,
  required int place,
  String id = '',
}) =>
    CompetitionResultModel(
      id: id.isEmpty ? '${childId}_p$place' : id,
      childId: childId,
      childName: 'Тест',
      competitionName: 'Тестові змагання',
      level: CompetitionLevel.local,
      place: place,
      points: 10,
      date: DateTime(2026, 1, 1),
      seasonYear: 2026,
      addedByCoachId: 'coach',
    );

// ── Контейнер ────────────────────────────────────────────────────────────────

ProviderContainer _container({
  required List<ChildModel> children,
  List<MembershipModel> memberships = const [],
  List<CompetitionResultModel> results = const [],
}) =>
    ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((_) => Stream.value(null)),
        allChildrenProvider.overrideWith((_) => Stream.value(children)),
        allMembershipsProvider.overrideWith((_) => Stream.value(memberships)),
        allResultsProvider.overrideWith((_) => Stream.value(results)),
      ],
    );

// Повертає результат filteredChildrenProvider (membership-aware, без медалей)
Future<List<ChildModel>> _filterByMembership(
    ProviderContainer c, ChildrenFilter f) async {
  await c.read(allChildrenProvider.future);
  await c.read(allMembershipsProvider.future);
  c.read(childrenFilterProvider.notifier).state = f;
  return c.read(filteredChildrenProvider);
}

// Повертає результат filteredChildrenWithMedalsProvider (membership + medals)
Future<List<ChildModel>> _filterWithMedals(
    ProviderContainer c, ChildrenFilter f) async {
  await c.read(allChildrenProvider.future);
  await c.read(allMembershipsProvider.future);
  await c.read(allResultsProvider.future);
  c.read(childrenFilterProvider.notifier).state = f;
  return c.read(filteredChildrenWithMedalsProvider);
}

Set<String> _ids(List<ChildModel> r) => r.map((c) => c.id).toSet();

// ── Тестові спортсмени ───────────────────────────────────────────────────────

final _a1 = _child(id: 'a1', lastName: 'Активний-1', gender: Gender.male,
    belt: BeltLevel.yellow, birthYear: 2010);
final _a2 = _child(id: 'a2', lastName: 'Активний-2', gender: Gender.female,
    belt: BeltLevel.white, birthYear: 2011);
final _e1 = _child(id: 'e1', lastName: 'Закінчується-1', gender: Gender.male,
    belt: BeltLevel.orange, birthYear: 2010);
final _x1 = _child(id: 'x1', lastName: 'Прострочений-1', gender: Gender.female,
    belt: BeltLevel.white, birthYear: 2012);
final _x2 = _child(id: 'x2', lastName: 'Прострочений-2', gender: Gender.male,
    belt: BeltLevel.yellow, birthYear: 2011);
final _n1 = _child(id: 'n1', lastName: 'БезАбонементу', gender: Gender.male);

final _allAthletes = [_a1, _a2, _e1, _x1, _x2, _n1];

final _allMemberships = [
  _active('a1'),
  _active('a2'),
  _expiring('e1'),
  _expired('x1'),
  _expired('x2'),
  // n1 — без абонементу навмисно
];

// ── Тести ────────────────────────────────────────────────────────────────────

void main() {
  // ── ФІЛЬТР «АБОНЕМЕНТ» ────────────────────────────────────────────────────

  group('Фільтр — Абонемент (membershipStatus)', () {
    late ProviderContainer c;
    setUp(() => c = _container(
          children: _allAthletes,
          memberships: _allMemberships,
        ));
    tearDown(() => c.dispose());

    // ── Базові значення ────────────────────────────────────────────────────

    test('active → тільки спортсмени з активним абонементом', () async {
      final r = await _filterByMembership(
          c, const ChildrenFilter(membershipStatus: MembershipStatus.active));
      expect(_ids(r), equals({'a1', 'a2'}));
    });

    test('expiringSoon → тільки спортсмени де закінчується', () async {
      final r = await _filterByMembership(
          c, const ChildrenFilter(membershipStatus: MembershipStatus.expiringSoon));
      expect(_ids(r), equals({'e1'}));
    });

    test('expired → тільки прострочені абонементи', () async {
      final r = await _filterByMembership(
          c, const ChildrenFilter(membershipStatus: MembershipStatus.expired));
      expect(_ids(r), equals({'x1', 'x2'}));
    });

    test('null (без фільтру) → всі спортсмени', () async {
      final r = await _filterByMembership(c, const ChildrenFilter());
      expect(r, hasLength(_allAthletes.length));
    });

    // ── Без абонементу ─────────────────────────────────────────────────────

    test('active: спортсмен без абонементу виключається', () async {
      final r = await _filterByMembership(
          c, const ChildrenFilter(membershipStatus: MembershipStatus.active));
      expect(_ids(r), isNot(contains('n1')));
    });

    test('expiringSoon: спортсмен без абонементу виключається', () async {
      final r = await _filterByMembership(
          c, const ChildrenFilter(membershipStatus: MembershipStatus.expiringSoon));
      expect(_ids(r), isNot(contains('n1')));
    });

    test('expired: спортсмен без абонементу виключається', () async {
      final r = await _filterByMembership(
          c, const ChildrenFilter(membershipStatus: MembershipStatus.expired));
      expect(_ids(r), isNot(contains('n1')));
    });

    // ── Кількість ──────────────────────────────────────────────────────────

    test('active → кількість 2', () async {
      final r = await _filterByMembership(
          c, const ChildrenFilter(membershipStatus: MembershipStatus.active));
      expect(r, hasLength(2));
    });

    test('expired → кількість 2', () async {
      final r = await _filterByMembership(
          c, const ChildrenFilter(membershipStatus: MembershipStatus.expired));
      expect(r, hasLength(2));
    });

    // ── Конкретний спортсмен ───────────────────────────────────────────────

    test('active → Активний-1 та Активний-2 присутні', () async {
      final r = await _filterByMembership(
          c, const ChildrenFilter(membershipStatus: MembershipStatus.active));
      expect(r.map((x) => x.lastName),
          containsAll(['Активний-1', 'Активний-2']));
    });

    test('expired → Прострочений-1 та Прострочений-2 присутні', () async {
      final r = await _filterByMembership(
          c, const ChildrenFilter(membershipStatus: MembershipStatus.expired));
      expect(r.map((x) => x.lastName),
          containsAll(['Прострочений-1', 'Прострочений-2']));
    });

    // ── clearMembershipStatus ──────────────────────────────────────────────

    test('clearMembershipStatus → повертає всіх', () async {
      await _filterByMembership(
          c, const ChildrenFilter(membershipStatus: MembershipStatus.active));
      final r = await _filterByMembership(
          c, const ChildrenFilter().copyWith(clearMembershipStatus: true));
      expect(r, hasLength(_allAthletes.length));
    });

    test('copyWith clearMembershipStatus скидає поле', () {
      final f = const ChildrenFilter(membershipStatus: MembershipStatus.active)
          .copyWith(clearMembershipStatus: true);
      expect(f.membershipStatus, isNull);
    });

    test('copyWith membershipStatus зберігає інші поля', () {
      const f = ChildrenFilter(birthYear: 2010, gender: Gender.male);
      final updated =
          f.copyWith(membershipStatus: MembershipStatus.active);
      expect(updated.birthYear, 2010);
      expect(updated.gender, Gender.male);
      expect(updated.membershipStatus, MembershipStatus.active);
    });

    // ── Комбіновані фільтри ────────────────────────────────────────────────

    test('active + gender=male → тільки активні хлопці', () async {
      final r = await _filterByMembership(
          c,
          const ChildrenFilter(
            membershipStatus: MembershipStatus.active,
            gender: Gender.male,
          ));
      expect(_ids(r), equals({'a1'}));
      expect(r.every((x) => x.gender == Gender.male), isTrue);
    });

    test('active + gender=female → тільки активні дівчата', () async {
      final r = await _filterByMembership(
          c,
          const ChildrenFilter(
            membershipStatus: MembershipStatus.active,
            gender: Gender.female,
          ));
      expect(_ids(r), equals({'a2'}));
    });

    test('expired + gender=male → прострочені хлопці', () async {
      final r = await _filterByMembership(
          c,
          const ChildrenFilter(
            membershipStatus: MembershipStatus.expired,
            gender: Gender.male,
          ));
      expect(_ids(r), equals({'x2'}));
    });

    test('active + belt=yellow → активні з жовтим поясом', () async {
      final r = await _filterByMembership(
          c,
          const ChildrenFilter(
            membershipStatus: MembershipStatus.active,
            belt: BeltLevel.yellow,
          ));
      expect(_ids(r), equals({'a1'}));
    });

    test('expired + belt=white → прострочені з білим поясом', () async {
      final r = await _filterByMembership(
          c,
          const ChildrenFilter(
            membershipStatus: MembershipStatus.expired,
            belt: BeltLevel.white,
          ));
      expect(_ids(r), equals({'x1'}));
    });

    test('active + birthYear=2010 → активні 2010 р.н.', () async {
      final r = await _filterByMembership(
          c,
          const ChildrenFilter(
            membershipStatus: MembershipStatus.active,
            birthYear: 2010,
          ));
      expect(_ids(r), equals({'a1'}));
    });

    test('active + birthYear=2011 → активні 2011 р.н.', () async {
      final r = await _filterByMembership(
          c,
          const ChildrenFilter(
            membershipStatus: MembershipStatus.active,
            birthYear: 2011,
          ));
      expect(_ids(r), equals({'a2'}));
    });

    test('expired + belts={white,yellow} → прострочені з двома поясами', () async {
      final r = await _filterByMembership(
          c,
          ChildrenFilter(
            membershipStatus: MembershipStatus.expired,
            belts: {BeltLevel.white, BeltLevel.yellow},
          ));
      expect(_ids(r), equals({'x1', 'x2'}));
    });

    test('active + birthYears={2010,2011} → активні за двома роками', () async {
      final r = await _filterByMembership(
          c,
          const ChildrenFilter(
            membershipStatus: MembershipStatus.active,
            birthYears: {2010, 2011},
          ));
      expect(_ids(r), equals({'a1', 'a2'}));
    });

    // ── Крайні випадки ─────────────────────────────────────────────────────

    test('список без абонементів + фільтр active → порожньо', () async {
      final emptyC = _container(children: _allAthletes, memberships: []);
      addTearDown(emptyC.dispose);
      final r = await _filterByMembership(
          emptyC, const ChildrenFilter(membershipStatus: MembershipStatus.active));
      expect(r, isEmpty);
    });

    test('один спортсмен з active → тільки він', () async {
      final single = _child(id: 'only', lastName: 'Єдиний');
      final singleC = _container(
        children: [single],
        memberships: [_active('only')],
      );
      addTearDown(singleC.dispose);
      final r = await _filterByMembership(
          singleC, const ChildrenFilter(membershipStatus: MembershipStatus.active));
      expect(_ids(r), equals({'only'}));
    });
  });

  // ── ФІЛЬТР «МЕДАЛІ» ───────────────────────────────────────────────────────

  group('Фільтр — Медалі (medalPlaces)', () {
    // Спортсмени:
    // gold1, gold2 — перше місце
    // silver1      — друге місце
    // bronze1      — третє місце
    // multi1       — і перше, і друге (кілька результатів)
    // fourth1      — четверте місце (не медаль)
    // none1        — жодних результатів

    final gold1 = _child(id: 'gold1', lastName: 'Золото-1', gender: Gender.male);
    final gold2 = _child(id: 'gold2', lastName: 'Золото-2', gender: Gender.female);
    final silver1 = _child(id: 'silver1', lastName: 'Срібло-1', gender: Gender.male);
    final bronze1 = _child(id: 'bronze1', lastName: 'Бронза-1', gender: Gender.female);
    final multi1 = _child(id: 'multi1', lastName: 'Мульти-1', gender: Gender.male);
    final fourth1 = _child(id: 'fourth1', lastName: 'Четвертий-1');
    final none1 = _child(id: 'none1', lastName: 'БезМедалей');

    final allMedal = [gold1, gold2, silver1, bronze1, multi1, fourth1, none1];
    final allResults = [
      _result(childId: 'gold1', place: 1),
      _result(childId: 'gold2', place: 1),
      _result(childId: 'silver1', place: 2),
      _result(childId: 'bronze1', place: 3),
      _result(childId: 'multi1', place: 1, id: 'multi1_1'),
      _result(childId: 'multi1', place: 2, id: 'multi1_2'),
      _result(childId: 'fourth1', place: 4),
      // none1 — немає результатів
    ];

    late ProviderContainer c;
    setUp(() => c = _container(children: allMedal, results: allResults));
    tearDown(() => c.dispose());

    // ── Одиночна вибірка ───────────────────────────────────────────────────

    test('medalPlaces={1} → тільки золоті медалісти', () async {
      final r = await _filterWithMedals(
          c, ChildrenFilter(medalPlaces: {1}));
      expect(_ids(r), containsAll(['gold1', 'gold2', 'multi1']));
      expect(_ids(r), isNot(contains('silver1')));
      expect(_ids(r), isNot(contains('bronze1')));
      expect(_ids(r), isNot(contains('fourth1')));
      expect(_ids(r), isNot(contains('none1')));
    });

    test('medalPlaces={2} → тільки срібні медалісти', () async {
      final r = await _filterWithMedals(
          c, ChildrenFilter(medalPlaces: {2}));
      expect(_ids(r), containsAll(['silver1', 'multi1']));
      expect(_ids(r), isNot(contains('gold1')));
      expect(_ids(r), isNot(contains('bronze1')));
    });

    test('medalPlaces={3} → тільки бронзові медалісти', () async {
      final r = await _filterWithMedals(
          c, ChildrenFilter(medalPlaces: {3}));
      expect(_ids(r), equals({'bronze1'}));
    });

    // ── Мультивибір ────────────────────────────────────────────────────────

    test('medalPlaces={1,2,3} → весь подіум', () async {
      final r = await _filterWithMedals(
          c, ChildrenFilter(medalPlaces: {1, 2, 3}));
      expect(_ids(r), containsAll(['gold1', 'gold2', 'silver1', 'bronze1', 'multi1']));
      expect(_ids(r), isNot(contains('fourth1')));
      expect(_ids(r), isNot(contains('none1')));
    });

    test('medalPlaces={1,2} → золото та срібло', () async {
      final r = await _filterWithMedals(
          c, ChildrenFilter(medalPlaces: {1, 2}));
      expect(_ids(r), containsAll(['gold1', 'gold2', 'silver1', 'multi1']));
      expect(_ids(r), isNot(contains('bronze1')));
    });

    test('medalPlaces={2,3} → срібло та бронза', () async {
      final r = await _filterWithMedals(
          c, ChildrenFilter(medalPlaces: {2, 3}));
      expect(_ids(r), containsAll(['silver1', 'bronze1', 'multi1']));
      expect(_ids(r), isNot(contains('gold1')));
      expect(_ids(r), isNot(contains('gold2')));
    });

    // ── Кількість ──────────────────────────────────────────────────────────

    test('medalPlaces={1} → кількість 3 (gold1, gold2, multi1)', () async {
      final r = await _filterWithMedals(
          c, ChildrenFilter(medalPlaces: {1}));
      expect(r, hasLength(3));
    });

    test('medalPlaces={3} → кількість 1', () async {
      final r = await _filterWithMedals(
          c, ChildrenFilter(medalPlaces: {3}));
      expect(r, hasLength(1));
    });

    // ── Без фільтру ────────────────────────────────────────────────────────

    test('medalPlaces={} → всі спортсмени без винятку', () async {
      final r = await _filterWithMedals(c, const ChildrenFilter());
      expect(r, hasLength(allMedal.length));
    });

    test('clearMedalPlaces → повертає всіх', () async {
      await _filterWithMedals(c, ChildrenFilter(medalPlaces: {1}));
      final r = await _filterWithMedals(
          c, const ChildrenFilter().copyWith(clearMedalPlaces: true));
      expect(r, hasLength(allMedal.length));
    });

    // ── Виключення ─────────────────────────────────────────────────────────

    test('спортсмен без результатів виключається при будь-якому medalPlaces', () async {
      for (final place in [1, 2, 3]) {
        final r = await _filterWithMedals(
            c, ChildrenFilter(medalPlaces: {place}));
        expect(_ids(r), isNot(contains('none1')),
            reason: 'none1 не повинен бути в medalPlaces={$place}');
      }
    });

    test('місце 4 (поза медалями) виключається при medalPlaces={1,2,3}', () async {
      final r = await _filterWithMedals(
          c, ChildrenFilter(medalPlaces: {1, 2, 3}));
      expect(_ids(r), isNot(contains('fourth1')));
    });

    // ── Кілька результатів у одного спортсмена ─────────────────────────────

    test('multi1: входить у medalPlaces={1} бо має 1-е місце', () async {
      final r = await _filterWithMedals(
          c, ChildrenFilter(medalPlaces: {1}));
      expect(_ids(r), contains('multi1'));
    });

    test('multi1: входить у medalPlaces={2} бо має 2-е місце', () async {
      final r = await _filterWithMedals(
          c, ChildrenFilter(medalPlaces: {2}));
      expect(_ids(r), contains('multi1'));
    });

    test('multi1: НЕ входить у medalPlaces={3} — у нього немає 3-го місця', () async {
      final r = await _filterWithMedals(
          c, ChildrenFilter(medalPlaces: {3}));
      expect(_ids(r), isNot(contains('multi1')));
    });

    // ── copyWith ───────────────────────────────────────────────────────────

    test('copyWith clearMedalPlaces скидає набір', () {
      final f = ChildrenFilter(medalPlaces: {1, 2, 3})
          .copyWith(clearMedalPlaces: true);
      expect(f.medalPlaces, isEmpty);
    });

    test('copyWith medalPlaces зберігає інші поля', () {
      const f = ChildrenFilter(birthYear: 2010, gender: Gender.male);
      final updated = f.copyWith(medalPlaces: {1, 2});
      expect(updated.birthYear, 2010);
      expect(updated.gender, Gender.male);
      expect(updated.medalPlaces, equals({1, 2}));
    });

    // ── Комбіновані фільтри ────────────────────────────────────────────────

    test('medalPlaces={1} + gender=male → золоті медалісти-хлопці', () async {
      final r = await _filterWithMedals(
          c,
          ChildrenFilter(
            medalPlaces: {1},
            gender: Gender.male,
          ));
      expect(_ids(r), containsAll(['gold1', 'multi1']));
      expect(_ids(r), isNot(contains('gold2'))); // gold2 — female
    });

    test('medalPlaces={1} + gender=female → золоті медалістки', () async {
      final r = await _filterWithMedals(
          c,
          ChildrenFilter(
            medalPlaces: {1},
            gender: Gender.female,
          ));
      expect(_ids(r), equals({'gold2'}));
    });

    test('medalPlaces={2,3} + gender=male → срібло/бронза хлопці', () async {
      final r = await _filterWithMedals(
          c,
          ChildrenFilter(
            medalPlaces: {2, 3},
            gender: Gender.male,
          ));
      expect(_ids(r), contains('silver1'));
      expect(_ids(r), contains('multi1'));
      expect(_ids(r), isNot(contains('bronze1'))); // bronze1 — female
    });

    test('medalPlaces={1,2,3} → кількість дорівнює тільки подіуму', () async {
      final r = await _filterWithMedals(
          c, ChildrenFilter(medalPlaces: {1, 2, 3}));
      // gold1, gold2, silver1, bronze1, multi1 = 5
      expect(r, hasLength(5));
    });
  });

  // ── КОМБІНАЦІЯ: АБОНЕМЕНТ + МЕДАЛІ ───────────────────────────────────────

  group('Комбінований фільтр — Абонемент + Медалі', () {
    // am1: активний абонемент + золото
    // am2: активний абонемент + срібло
    // am3: активний абонемент + без медалей
    // xm1: прострочений + золото
    // xm2: прострочений + без медалей
    // nm1: без абонементу + срібло

    final am1 = _child(id: 'am1', lastName: 'Акт-Золото', gender: Gender.male);
    final am2 = _child(id: 'am2', lastName: 'Акт-Срібло', gender: Gender.female);
    final am3 = _child(id: 'am3', lastName: 'Акт-БезМедалей');
    final xm1 = _child(id: 'xm1', lastName: 'Прост-Золото', gender: Gender.male);
    final xm2 = _child(id: 'xm2', lastName: 'Прост-БезМедалей');
    final nm1 = _child(id: 'nm1', lastName: 'БезАб-Срібло');

    final comboAthletes = [am1, am2, am3, xm1, xm2, nm1];
    final comboMemberships = [
      _active('am1'), _active('am2'), _active('am3'),
      _expired('xm1'), _expired('xm2'),
      // nm1 — без абонементу
    ];
    final comboResults = [
      _result(childId: 'am1', place: 1),
      _result(childId: 'am2', place: 2),
      _result(childId: 'xm1', place: 1),
      _result(childId: 'nm1', place: 2),
      // am3, xm2 — без результатів
    ];

    late ProviderContainer c;
    setUp(() => c = _container(
          children: comboAthletes,
          memberships: comboMemberships,
          results: comboResults,
        ));
    tearDown(() => c.dispose());

    test('active + medalPlaces={1} → тільки am1 (активний з золотом)', () async {
      final r = await _filterWithMedals(
          c,
          ChildrenFilter(
            membershipStatus: MembershipStatus.active,
            medalPlaces: {1},
          ));
      expect(_ids(r), equals({'am1'}));
    });

    test('active + medalPlaces={2} → тільки am2 (активний з сріблом)', () async {
      final r = await _filterWithMedals(
          c,
          ChildrenFilter(
            membershipStatus: MembershipStatus.active,
            medalPlaces: {2},
          ));
      expect(_ids(r), equals({'am2'}));
    });

    test('expired + medalPlaces={1} → тільки xm1 (прострочений з золотом)', () async {
      final r = await _filterWithMedals(
          c,
          ChildrenFilter(
            membershipStatus: MembershipStatus.expired,
            medalPlaces: {1},
          ));
      expect(_ids(r), equals({'xm1'}));
    });

    test('active + medalPlaces={1,2} → am1 та am2', () async {
      final r = await _filterWithMedals(
          c,
          ChildrenFilter(
            membershipStatus: MembershipStatus.active,
            medalPlaces: {1, 2},
          ));
      expect(_ids(r), equals({'am1', 'am2'}));
    });

    test('active + medalPlaces={1,2} + gender=female → тільки am2', () async {
      final r = await _filterWithMedals(
          c,
          ChildrenFilter(
            membershipStatus: MembershipStatus.active,
            medalPlaces: {1, 2},
            gender: Gender.female,
          ));
      expect(_ids(r), equals({'am2'}));
    });

    test('active + medalPlaces={1,2} + gender=male → тільки am1', () async {
      final r = await _filterWithMedals(
          c,
          ChildrenFilter(
            membershipStatus: MembershipStatus.active,
            medalPlaces: {1, 2},
            gender: Gender.male,
          ));
      expect(_ids(r), equals({'am1'}));
    });

    test('active + medalPlaces={1,2,3}: am3 відсутній (активний але без медалей)',
        () async {
      final r = await _filterWithMedals(
          c,
          ChildrenFilter(
            membershipStatus: MembershipStatus.active,
            medalPlaces: {1, 2, 3},
          ));
      expect(_ids(r), isNot(contains('am3')));
    });

    test('без фільтрів → повертає всіх 6', () async {
      final r = await _filterWithMedals(c, const ChildrenFilter());
      expect(r, hasLength(comboAthletes.length));
    });

    test('active + medalPlaces={} → всі активні (am1, am2, am3)', () async {
      final r = await _filterWithMedals(
          c,
          const ChildrenFilter(membershipStatus: MembershipStatus.active));
      expect(_ids(r), equals({'am1', 'am2', 'am3'}));
    });

    test('medalPlaces={1} без фільтру абонементу → am1 та xm1', () async {
      final r = await _filterWithMedals(
          c, ChildrenFilter(medalPlaces: {1}));
      expect(_ids(r), equals({'am1', 'xm1'}));
    });

    test('nm1 виключається при active + medalPlaces={2} — немає абонементу',
        () async {
      final r = await _filterWithMedals(
          c,
          ChildrenFilter(
            membershipStatus: MembershipStatus.active,
            medalPlaces: {2},
          ));
      expect(_ids(r), isNot(contains('nm1')));
    });

    test('активних спортсменів з медалями взагалі → am1 і am2 (не am3)', () async {
      final r = await _filterWithMedals(
          c,
          ChildrenFilter(
            membershipStatus: MembershipStatus.active,
            medalPlaces: {1, 2, 3},
          ));
      expect(_ids(r), containsAll(['am1', 'am2']));
      expect(r, hasLength(2));
    });
  });

  // ── ІЗОЛЬОВАНІ СЦЕНАРІЇ ───────────────────────────────────────────────────

  group('Ізольовані сценарії', () {
    test('повністю порожня база: будь-який фільтр → порожньо', () async {
      final c = _container(children: []);
      addTearDown(c.dispose);

      final r1 = await _filterWithMedals(
          c, const ChildrenFilter(membershipStatus: MembershipStatus.active));
      expect(r1, isEmpty);

      final r2 = await _filterWithMedals(
          c, ChildrenFilter(medalPlaces: {1, 2, 3}));
      expect(r2, isEmpty);
    });

    test('один спортсмен — активний і з золотом — знайдений по обох фільтрах',
        () async {
      final child = _child(id: 'lone', lastName: 'Єдиний');
      final c = _container(
        children: [child],
        memberships: [_active('lone')],
        results: [_result(childId: 'lone', place: 1)],
      );
      addTearDown(c.dispose);

      final r = await _filterWithMedals(
          c,
          ChildrenFilter(
            membershipStatus: MembershipStatus.active,
            medalPlaces: {1},
          ));
      expect(_ids(r), equals({'lone'}));
    });

    test('фільтр по активному абонементу + медаль: жодних збігів → порожньо',
        () async {
      final child = _child(id: 'only');
      final c = _container(
        children: [child],
        memberships: [_expired('only')],
        results: [_result(childId: 'only', place: 1)],
      );
      addTearDown(c.dispose);

      final r = await _filterWithMedals(
          c,
          ChildrenFilter(
            membershipStatus: MembershipStatus.active,
            medalPlaces: {1},
          ));
      expect(r, isEmpty);
    });
  });
}

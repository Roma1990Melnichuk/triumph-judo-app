import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/membership/providers/membership_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';

// ── Хелпери ─────────────────────────────────────────────────────────────────

ChildModel makeChild({
  String id = 'id',
  String firstName = "Ім'я",
  String lastName = 'Прізвище',
  int birthYear = 2010,
  String weightCategory = '-30 кг',
  BeltLevel currentBelt = BeltLevel.white,
  String coachId = 'coach1',
  String coachName = 'Тренер',
  int totalPoints = 0,
  Gender? gender,
}) =>
    ChildModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      birthYear: birthYear,
      weightCategory: weightCategory,
      currentBelt: currentBelt,
      coachId: coachId,
      coachName: coachName,
      totalPoints: totalPoints,
      createdAt: DateTime(2024),
      gender: gender,
    );

ProviderContainer makeContainer(List<ChildModel> children) =>
    ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        allChildrenProvider.overrideWith((ref) => Stream.value(children)),
        allMembershipsProvider.overrideWith((ref) => Stream.value([])),
      ],
    );

Future<List<ChildModel>> applyFilter(
    ProviderContainer c, ChildrenFilter f) async {
  await c.read(allChildrenProvider.future);
  c.read(childrenFilterProvider.notifier).state = f;
  return c.read(filteredChildrenProvider);
}

// ── Тестові дані ─────────────────────────────────────────────────────────────

final boy1 = makeChild(id: 'b1', lastName: 'Коваленко', firstName: 'Олексій',
    birthYear: 2010, weightCategory: '-30 кг', currentBelt: BeltLevel.white,
    coachId: 'c1', totalPoints: 10, gender: Gender.male);

final boy2 = makeChild(id: 'b2', lastName: 'Шевченко', firstName: 'Іван',
    birthYear: 2011, weightCategory: '-40 кг', currentBelt: BeltLevel.yellow,
    coachId: 'c1', totalPoints: 25, gender: Gender.male);

final boy3 = makeChild(id: 'b3', lastName: 'Мороз', firstName: 'Дмитро',
    birthYear: 2010, weightCategory: '-36 кг', currentBelt: BeltLevel.orange,
    coachId: 'c2', totalPoints: 5, gender: Gender.male);

final girl1 = makeChild(id: 'g1', lastName: 'Петренко', firstName: 'Марія',
    birthYear: 2010, weightCategory: '-30 кг', currentBelt: BeltLevel.yellow,
    coachId: 'c1', totalPoints: 30, gender: Gender.female);

final girl2 = makeChild(id: 'g2', lastName: 'Бондаренко', firstName: 'Анна',
    birthYear: 2011, weightCategory: '-36 кг', currentBelt: BeltLevel.white,
    coachId: 'c2', totalPoints: 8, gender: Gender.female);

final noGender = makeChild(id: 'ng', lastName: 'Лисенко', firstName: 'Тест',
    birthYear: 2012, weightCategory: '-30 кг', currentBelt: BeltLevel.white,
    coachId: 'c1', totalPoints: 0, gender: null);

final all = [boy1, boy2, boy3, girl1, girl2, noGender];

// ── Тести ────────────────────────────────────────────────────────────────────

void main() {

  // ── Гендер ─────────────────────────────────────────────────────────────────

  group('Фільтр — Гендер', () {
    late ProviderContainer c;
    setUp(() => c = makeContainer(all));
    tearDown(() => c.dispose());

    test('фільтр male → тільки хлопчики', () async {
      final r = await applyFilter(c, const ChildrenFilter(gender: Gender.male));
      expect(r.map((x) => x.id), containsAll(['b1', 'b2', 'b3']));
      expect(r.any((x) => x.gender == Gender.female), isFalse);
      expect(r.any((x) => x.gender == null), isFalse);
    });

    test('фільтр female → тільки дівчатка', () async {
      final r = await applyFilter(c, const ChildrenFilter(gender: Gender.female));
      expect(r.map((x) => x.id), containsAll(['g1', 'g2']));
      expect(r.any((x) => x.gender == Gender.male), isFalse);
    });

    test('фільтр male → кількість 3', () async {
      final r = await applyFilter(c, const ChildrenFilter(gender: Gender.male));
      expect(r, hasLength(3));
    });

    test('фільтр female → кількість 2', () async {
      final r = await applyFilter(c, const ChildrenFilter(gender: Gender.female));
      expect(r, hasLength(2));
    });

    test('дитина без гендеру не потрапляє в жоден гендерний фільтр', () async {
      final male = await applyFilter(c, const ChildrenFilter(gender: Gender.male));
      final female = await applyFilter(c, const ChildrenFilter(gender: Gender.female));
      expect(male.any((x) => x.id == 'ng'), isFalse);
      expect(female.any((x) => x.id == 'ng'), isFalse);
    });

    test('без фільтру гендеру → всі діти включно з тими без гендеру', () async {
      final r = await applyFilter(c, const ChildrenFilter());
      expect(r, hasLength(all.length));
    });

    test('гендер + рік → хлопці 2010 року', () async {
      final r = await applyFilter(
          c, const ChildrenFilter(gender: Gender.male, birthYear: 2010));
      expect(r.map((x) => x.id), containsAll(['b1', 'b3']));
      expect(r, hasLength(2));
    });

    test('гендер + вага → дівчата -36 кг', () async {
      final r = await applyFilter(
          c, const ChildrenFilter(gender: Gender.female, weightCategory: '-36 кг'));
      expect(r.map((x) => x.id), contains('g2'));
      expect(r, hasLength(1));
    });

    test('гендер + пояс → хлопці жовтий пояс', () async {
      final r = await applyFilter(
          c, const ChildrenFilter(gender: Gender.male, belt: BeltLevel.yellow));
      expect(r.map((x) => x.id), contains('b2'));
      expect(r, hasLength(1));
    });

    test('copyWith clearGender → скидає гендер', () {
      final f = const ChildrenFilter(gender: Gender.male)
          .copyWith(clearGender: true);
      expect(f.gender, isNull);
    });

    test('copyWith gender зберігає інші поля', () {
      const f = ChildrenFilter(birthYear: 2010, weightCategory: '-30 кг');
      final updated = f.copyWith(gender: Gender.female);
      expect(updated.birthYear, 2010);
      expect(updated.weightCategory, '-30 кг');
      expect(updated.gender, Gender.female);
    });
  });

  // ── Прізвище ────────────────────────────────────────────────────────────────

  group('Фільтр — Прізвище', () {
    late ProviderContainer c;
    setUp(() => c = makeContainer(all));
    tearDown(() => c.dispose());

    test('порожній рядок — всі', () async {
      final r = await applyFilter(c, const ChildrenFilter(lastName: ''));
      expect(r, hasLength(all.length));
    });

    test('частковий збіг', () async {
      final r = await applyFilter(c, const ChildrenFilter(lastName: 'Ков'));
      expect(r.every((x) =>
          x.lastName.toLowerCase().contains('ков') ||
          x.firstName.toLowerCase().contains('ков')), isTrue);
    });

    test('регістронезалежний', () async {
      final r1 = await applyFilter(c, const ChildrenFilter(lastName: 'петренко'));
      final r2 = await applyFilter(c, const ChildrenFilter(lastName: 'ПЕТРЕНКО'));
      expect(r1.map((x) => x.id).toSet(), equals(r2.map((x) => x.id).toSet()));
    });

    test('пошук по firstName', () async {
      final r = await applyFilter(c, const ChildrenFilter(lastName: 'Марія'));
      expect(r.map((x) => x.id), contains('g1'));
    });

    test('нема збігів — порожньо', () async {
      final r = await applyFilter(c, const ChildrenFilter(lastName: 'Zzzzz'));
      expect(r, isEmpty);
    });
  });

  // ── Рік народження ─────────────────────────────────────────────────────────

  group('Фільтр — Рік народження', () {
    late ProviderContainer c;
    setUp(() => c = makeContainer(all));
    tearDown(() => c.dispose());

    test('фільтр 2010 → тільки 2010', () async {
      final r = await applyFilter(c, const ChildrenFilter(birthYear: 2010));
      expect(r.every((x) => x.birthYear == 2010), isTrue);
    });

    test('фільтр 2011 → правильна кількість', () async {
      final r = await applyFilter(c, const ChildrenFilter(birthYear: 2011));
      expect(r.every((x) => x.birthYear == 2011), isTrue);
    });

    test('рік якого немає → порожньо', () async {
      final r = await applyFilter(c, const ChildrenFilter(birthYear: 2099));
      expect(r, isEmpty);
    });

    test('clearBirthYear → всі повертаються', () async {
      await applyFilter(c, const ChildrenFilter(birthYear: 2010));
      final r = await applyFilter(
          c, const ChildrenFilter().copyWith(clearBirthYear: true));
      expect(r, hasLength(all.length));
    });
  });

  // ── Тренер ─────────────────────────────────────────────────────────────────

  group('Фільтр — Тренер', () {
    late ProviderContainer c;
    setUp(() => c = makeContainer(all));
    tearDown(() => c.dispose());

    test('фільтр c1 → тільки діти тренера c1', () async {
      final r = await applyFilter(c, const ChildrenFilter(coachId: 'c1'));
      expect(r.every((x) => x.coachId == 'c1'), isTrue);
    });

    test('фільтр c2 → тільки діти тренера c2', () async {
      final r = await applyFilter(c, const ChildrenFilter(coachId: 'c2'));
      expect(r.every((x) => x.coachId == 'c2'), isTrue);
    });

    test('невідомий тренер → порожньо', () async {
      final r = await applyFilter(c, const ChildrenFilter(coachId: 'nobody'));
      expect(r, isEmpty);
    });

    test('clearCoachId → всі повертаються', () async {
      final r = await applyFilter(
          c, const ChildrenFilter().copyWith(clearCoachId: true));
      expect(r, hasLength(all.length));
    });
  });

  // ── Пояс ───────────────────────────────────────────────────────────────────

  group('Фільтр — Пояс', () {
    late ProviderContainer c;
    setUp(() => c = makeContainer(all));
    tearDown(() => c.dispose());

    test('фільтр white → тільки білий пояс', () async {
      final r = await applyFilter(c, const ChildrenFilter(belt: BeltLevel.white));
      expect(r.every((x) => x.currentBelt == BeltLevel.white), isTrue);
    });

    test('фільтр yellow → тільки жовтий пояс', () async {
      final r = await applyFilter(c, const ChildrenFilter(belt: BeltLevel.yellow));
      expect(r.every((x) => x.currentBelt == BeltLevel.yellow), isTrue);
    });

    test('пояс якого немає → порожньо', () async {
      final r = await applyFilter(c, const ChildrenFilter(belt: BeltLevel.black));
      expect(r, isEmpty);
    });

    test('clearBelt → всі повертаються', () async {
      final r = await applyFilter(
          c, const ChildrenFilter().copyWith(clearBelt: true));
      expect(r, hasLength(all.length));
    });
  });

  // ── Вагова категорія ────────────────────────────────────────────────────────

  group('Фільтр — Вагова категорія', () {
    late ProviderContainer c;
    setUp(() => c = makeContainer(all));
    tearDown(() => c.dispose());

    test('фільтр -30 кг → тільки -30 кг', () async {
      final r = await applyFilter(c,
          const ChildrenFilter(weightCategory: '-30 кг'));
      expect(r.every((x) => x.weightCategory == '-30 кг'), isTrue);
    });

    test('фільтр -36 кг → правильні діти', () async {
      final r = await applyFilter(c,
          const ChildrenFilter(weightCategory: '-36 кг'));
      expect(r.map((x) => x.id), containsAll(['b3', 'g2']));
    });

    test('вага якої немає → порожньо', () async {
      final r = await applyFilter(c,
          const ChildrenFilter(weightCategory: '-99 кг'));
      expect(r, isEmpty);
    });

    test('clearWeightCategory → всі повертаються', () async {
      final r = await applyFilter(
          c, const ChildrenFilter().copyWith(clearWeightCategory: true));
      expect(r, hasLength(all.length));
    });
  });

  // ── Комбінування фільтрів ───────────────────────────────────────────────────

  group('Комбінування фільтрів', () {
    late ProviderContainer c;
    setUp(() => c = makeContainer(all));
    tearDown(() => c.dispose());

    test('гендер + тренер', () async {
      final r = await applyFilter(c,
          const ChildrenFilter(gender: Gender.male, coachId: 'c1'));
      expect(r.every((x) => x.gender == Gender.male && x.coachId == 'c1'),
          isTrue);
    });

    test('гендер + рік + вага', () async {
      final r = await applyFilter(
          c,
          const ChildrenFilter(
              gender: Gender.female, birthYear: 2011, weightCategory: '-36 кг'));
      expect(r.map((x) => x.id), contains('g2'));
      expect(r, hasLength(1));
    });

    test('прізвище + гендер', () async {
      final r = await applyFilter(
          c, const ChildrenFilter(lastName: 'Петренко', gender: Gender.female));
      expect(r.map((x) => x.id), contains('g1'));
    });

    test('всі фільтри разом що дають 0', () async {
      final r = await applyFilter(
          c,
          const ChildrenFilter(
              gender: Gender.male,
              birthYear: 2011,
              weightCategory: '-30 кг',
              belt: BeltLevel.orange));
      expect(r, isEmpty);
    });
  });

  // ── Сортування ─────────────────────────────────────────────────────────────

  group('Сортування', () {
    late ProviderContainer c;
    setUp(() => c = makeContainer(all));
    tearDown(() => c.dispose());

    test('сортує за totalPoints спадно', () async {
      final r = await applyFilter(c, const ChildrenFilter());
      for (var i = 0; i < r.length - 1; i++) {
        expect(r[i].totalPoints >= r[i + 1].totalPoints, isTrue,
            reason: '${r[i].lastName}(${r[i].totalPoints}) < '
                '${r[i + 1].lastName}(${r[i + 1].totalPoints})');
      }
    });

    test('при однакових балах — за прізвищем', () async {
      final eq1 = makeChild(id: 'x1', lastName: 'Яценко', totalPoints: 5);
      final eq2 = makeChild(id: 'x2', lastName: 'Авраменко', totalPoints: 5);
      final cnt = makeContainer([eq1, eq2]);
      addTearDown(cnt.dispose);
      final r = await applyFilter(cnt, const ChildrenFilter());
      expect(r.first.id, 'x2'); // Авраменко < Яценко
    });

    test('всі 0 балів → алфавітний порядок', () async {
      final z = makeChild(id: 'z', lastName: 'Яценко', totalPoints: 0);
      final a = makeChild(id: 'a', lastName: 'Авраменко', totalPoints: 0);
      final cnt = makeContainer([z, a]);
      addTearDown(cnt.dispose);
      final r = await applyFilter(cnt, const ChildrenFilter());
      expect(r.first.id, 'a');
    });

    test('сортування після гендерного фільтру зберігається', () async {
      final r = await applyFilter(c, const ChildrenFilter(gender: Gender.male));
      for (var i = 0; i < r.length - 1; i++) {
        expect(r[i].totalPoints >= r[i + 1].totalPoints, isTrue);
      }
    });
  });

  // ── beltReady фільтр ───────────────────────────────────────────────────────

  group('Фільтр — beltReady (допущені до здачі поясу)', () {
    final ready = makeChild(id: 'r1', lastName: 'Готовий', totalPoints: 50)
        .copyWith(beltReady: true);
    final notReady = makeChild(id: 'r2', lastName: 'НеГотовий', totalPoints: 20);

    late ProviderContainer c;
    setUp(() => c = makeContainer([ready, notReady, boy1]));
    tearDown(() => c.dispose());

    test('beltReady=true → тільки готові', () async {
      final r = await applyFilter(c, const ChildrenFilter(beltReady: true));
      expect(r.map((x) => x.id), contains('r1'));
      expect(r.every((x) => x.beltReady), isTrue);
    });

    test('beltReady=false (default) → всі', () async {
      final r = await applyFilter(c, const ChildrenFilter());
      expect(r, hasLength(3));
    });

    test('beltReady=true + гендер → комбінований фільтр', () async {
      final readyMale = makeChild(id: 'rm', gender: Gender.male).copyWith(beltReady: true);
      final cnt = makeContainer([ready, readyMale, notReady]);
      addTearDown(cnt.dispose);
      final r = await applyFilter(
          cnt, const ChildrenFilter(beltReady: true, gender: Gender.male));
      expect(r.map((x) => x.id), contains('rm'));
      expect(r.any((x) => x.id == 'r1'), isFalse);
    });

    test('copyWith beltReady зберігає інші поля', () {
      const f = ChildrenFilter(birthYear: 2010, gender: Gender.male);
      final updated = f.copyWith(beltReady: true);
      expect(updated.birthYear, 2010);
      expect(updated.gender, Gender.male);
      expect(updated.beltReady, isTrue);
    });
  });

  // ── ChildModel.beltReady ───────────────────────────────────────────────────

  group('ChildModel — beltReady', () {
    test('за замовчуванням beltReady=false', () {
      final c = makeChild();
      expect(c.beltReady, isFalse);
    });

    test('copyWith beltReady=true', () {
      final c = makeChild().copyWith(beltReady: true);
      expect(c.beltReady, isTrue);
    });

    test('copyWith зберігає beltReady якщо не вказано', () {
      final c = makeChild().copyWith(beltReady: true);
      final c2 = c.copyWith(firstName: 'Новий');
      expect(c2.beltReady, isTrue);
    });

    test('toFirestore не містить beltReady (лише belt_provider управляє ним)', () {
      final c = makeChild().copyWith(beltReady: true);
      expect(c.toFirestore().containsKey('beltReady'), isFalse);
    });
  });

  // ── Мультивибір — пояс (belts) ─────────────────────────────────────────────

  group('Фільтр — Мультивибір пояс (belts)', () {
    late ProviderContainer c;
    setUp(() => c = makeContainer(all));
    tearDown(() => c.dispose());

    test('belts={white} → тільки білий пояс', () async {
      final r = await applyFilter(
          c, ChildrenFilter(belts: {BeltLevel.white}));
      expect(r.every((x) => x.currentBelt == BeltLevel.white), isTrue);
    });

    test('belts={white, yellow} → і білий, і жовтий', () async {
      final r = await applyFilter(
          c, ChildrenFilter(belts: {BeltLevel.white, BeltLevel.yellow}));
      expect(r.every((x) =>
          x.currentBelt == BeltLevel.white ||
          x.currentBelt == BeltLevel.yellow), isTrue);
      expect(r.any((x) => x.currentBelt == BeltLevel.white), isTrue);
      expect(r.any((x) => x.currentBelt == BeltLevel.yellow), isTrue);
    });

    test('belts={{}} → всі повертаються (немає фільтрації)', () async {
      final r = await applyFilter(c, const ChildrenFilter(belts: {}));
      expect(r, hasLength(all.length));
    });

    test('belts має пріоритет над belt', () async {
      // belts={white, yellow}, belt=orange — belts перекриває belt
      final r = await applyFilter(
          c,
          ChildrenFilter(
            belt: BeltLevel.orange,
            belts: {BeltLevel.white, BeltLevel.yellow},
          ));
      expect(r.any((x) => x.currentBelt == BeltLevel.orange), isFalse);
    });

    test('clearBelts → скидає набір поясів', () {
      final f = ChildrenFilter(belts: {BeltLevel.yellow})
          .copyWith(clearBelts: true);
      expect(f.belts, isEmpty);
    });
  });

  // ── Мультивибір — рік народження (birthYears) ──────────────────────────────

  group('Фільтр — Мультивибір рік народження (birthYears)', () {
    late ProviderContainer c;
    setUp(() => c = makeContainer(all));
    tearDown(() => c.dispose());

    test('birthYears={2010} → тільки 2010', () async {
      final r = await applyFilter(c, const ChildrenFilter(birthYears: {2010}));
      expect(r.every((x) => x.birthYear == 2010), isTrue);
    });

    test('birthYears={2010, 2011} → обидва роки', () async {
      final r = await applyFilter(
          c, const ChildrenFilter(birthYears: {2010, 2011}));
      expect(r.every((x) => x.birthYear == 2010 || x.birthYear == 2011),
          isTrue);
      expect(r.any((x) => x.birthYear == 2010), isTrue);
      expect(r.any((x) => x.birthYear == 2011), isTrue);
    });

    test('birthYears={} → всі', () async {
      final r = await applyFilter(c, const ChildrenFilter(birthYears: {}));
      expect(r, hasLength(all.length));
    });

    test('birthYears має пріоритет над birthYear', () async {
      final r = await applyFilter(
          c, const ChildrenFilter(birthYear: 2012, birthYears: {2010, 2011}));
      expect(r.any((x) => x.birthYear == 2012), isFalse);
    });

    test('clearBirthYears → скидає набір', () {
      final f = const ChildrenFilter(birthYears: {2010, 2011})
          .copyWith(clearBirthYears: true);
      expect(f.birthYears, isEmpty);
    });
  });

  // ── Мультивибір — вагова категорія (weightCats) ────────────────────────────

  group('Фільтр — Мультивибір вагова категорія (weightCats)', () {
    late ProviderContainer c;
    setUp(() => c = makeContainer(all));
    tearDown(() => c.dispose());

    test('weightCats={-30 кг} → тільки -30 кг', () async {
      final r = await applyFilter(
          c, const ChildrenFilter(weightCats: {'-30 кг'}));
      expect(r.every((x) => x.weightCategory == '-30 кг'), isTrue);
    });

    test('weightCats={-30 кг, -36 кг} → обидві категорії', () async {
      final r = await applyFilter(
          c, const ChildrenFilter(weightCats: {'-30 кг', '-36 кг'}));
      expect(r.every((x) =>
          x.weightCategory == '-30 кг' ||
          x.weightCategory == '-36 кг'), isTrue);
    });

    test('weightCats={} → всі', () async {
      final r = await applyFilter(c, const ChildrenFilter(weightCats: {}));
      expect(r, hasLength(all.length));
    });

    test('clearWeightCats → скидає набір', () {
      final f = const ChildrenFilter(weightCats: {'-30 кг'})
          .copyWith(clearWeightCats: true);
      expect(f.weightCats, isEmpty);
    });

    test('weightCats + гендер разом', () async {
      final r = await applyFilter(
          c,
          const ChildrenFilter(
            gender: Gender.female,
            weightCats: {'-30 кг'},
          ));
      expect(r.every(
          (x) => x.gender == Gender.female && x.weightCategory == '-30 кг'),
          isTrue);
    });
  });

  // ── Gender enum ─────────────────────────────────────────────────────────────

  group('Gender enum', () {
    test('displayName male → Хлопчик', () {
      expect(Gender.male.displayName, 'Хлопчик');
    });

    test('displayName female → Дівчинка', () {
      expect(Gender.female.displayName, 'Дівчинка');
    });

    test('icon male → ♂', () {
      expect(Gender.male.icon, '♂');
    });

    test('icon female → ♀', () {
      expect(Gender.female.icon, '♀');
    });

    test('fromString male', () {
      expect(Gender.fromString('male'), Gender.male);
    });

    test('fromString female', () {
      expect(Gender.fromString('female'), Gender.female);
    });

    test('fromString null → null', () {
      expect(Gender.fromString(null), isNull);
    });

    test('fromString невідомий рядок → null', () {
      expect(Gender.fromString('unknown'), isNull);
    });
  });
}

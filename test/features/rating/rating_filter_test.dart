import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';
import 'package:judo_app/features/rating/providers/rating_provider.dart';

ChildModel makeChild({
  String id = 'id',
  String lastName = 'Прізвище',
  int birthYear = 2010,
  String weightCategory = '-30 кг',
  int totalPoints = 0,
}) =>
    ChildModel(
      id: id,
      firstName: "Ім'я",
      lastName: lastName,
      birthYear: birthYear,
      weightCategory: weightCategory,
      currentBelt: BeltLevel.white,
      coachId: 'coach1',
      coachName: 'Тренер',
      totalPoints: totalPoints,
      createdAt: DateTime(2024),
    );

ProviderContainer makeContainer(List<ChildModel> children) {
  return ProviderContainer(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(null)),
      allChildrenProvider.overrideWith((ref) => Stream.value(children)),
    ],
  );
}

void main() {
  final c1 = makeChild(id: '1', birthYear: 2010, weightCategory: '-30 кг', totalPoints: 30);
  final c2 = makeChild(id: '2', birthYear: 2011, weightCategory: '-36 кг', totalPoints: 20);
  final c3 = makeChild(id: '3', birthYear: 2010, weightCategory: '-36 кг', totalPoints: 10);

  late ProviderContainer container;
  setUp(() => container = makeContainer([c1, c2, c3]));
  tearDown(() => container.dispose());

  group('RatingFilter — фільтрація', () {
    test('без фільтрів — всі діти', () async {
      await container.read(allChildrenProvider.future);
      expect(container.read(ratedChildrenProvider), hasLength(3));
    });

    test('фільтр по birthYear', () async {
      await container.read(allChildrenProvider.future);
      container.read(ratingFilterProvider.notifier).state =
          const RatingFilter(birthYear: 2010);
      final result = container.read(ratedChildrenProvider);
      expect(result, hasLength(2));
      expect(result.every((c) => c.birthYear == 2010), isTrue);
    });

    test('фільтр по weightCategory', () async {
      await container.read(allChildrenProvider.future);
      container.read(ratingFilterProvider.notifier).state =
          const RatingFilter(weightCategory: '-36 кг');
      final result = container.read(ratedChildrenProvider);
      expect(result, hasLength(2));
      expect(result.map((c) => c.id), containsAll(['2', '3']));
    });

    test('комбінований фільтр birthYear + weightCategory', () async {
      await container.read(allChildrenProvider.future);
      container.read(ratingFilterProvider.notifier).state =
          const RatingFilter(birthYear: 2010, weightCategory: '-36 кг');
      final result = container.read(ratedChildrenProvider);
      expect(result, hasLength(1));
      expect(result.first.id, '3');
    });

    test('фільтр без результатів → порожній список', () async {
      await container.read(allChildrenProvider.future);
      container.read(ratingFilterProvider.notifier).state =
          const RatingFilter(birthYear: 2099);
      expect(container.read(ratedChildrenProvider), isEmpty);
    });
  });

  group('RatingFilter — сортування за балами', () {
    test('сортує за totalPoints спадно', () async {
      await container.read(allChildrenProvider.future);
      final result = container.read(ratedChildrenProvider);
      expect(result[0].id, '1'); // 30
      expect(result[1].id, '2'); // 20
      expect(result[2].id, '3'); // 10
    });

    test('при однакових балах — за прізвищем', () async {
      final eq1 = makeChild(id: 'eq1', lastName: 'Яценко', totalPoints: 15);
      final eq2 = makeChild(id: 'eq2', lastName: 'Авраменко', totalPoints: 15);
      final cnt = makeContainer([eq1, eq2]);
      addTearDown(cnt.dispose);
      await cnt.read(allChildrenProvider.future);
      final result = cnt.read(ratedChildrenProvider);
      expect(result.first.id, 'eq2'); // Авраменко < Яценко
    });
  });

  group('RatingFilter — пошук по прізвищу', () {
    final ivan = makeChild(id: 'iv', lastName: 'Іваненко', totalPoints: 5);
    final maria = makeChild(id: 'ma', lastName: 'Марченко', totalPoints: 3);
    final olena = makeChild(id: 'ol', lastName: 'Олексієнко', totalPoints: 1);

    late ProviderContainer cnt;
    setUp(() => cnt = makeContainer([ivan, maria, olena]));
    tearDown(() => cnt.dispose());

    test('порожній lastName → всі', () async {
      await cnt.read(allChildrenProvider.future);
      cnt.read(ratingFilterProvider.notifier).state =
          const RatingFilter(lastName: '');
      expect(cnt.read(ratedChildrenProvider), hasLength(3));
    });

    test('частковий збіг прізвища', () async {
      await cnt.read(allChildrenProvider.future);
      cnt.read(ratingFilterProvider.notifier).state =
          const RatingFilter(lastName: 'Марч');
      final result = cnt.read(ratedChildrenProvider);
      expect(result.map((c) => c.id), contains('ma'));
      expect(result, hasLength(1));
    });

    test('регістронезалежний пошук', () async {
      await cnt.read(allChildrenProvider.future);
      cnt.read(ratingFilterProvider.notifier).state =
          const RatingFilter(lastName: 'іван');
      final result = cnt.read(ratedChildrenProvider);
      expect(result.map((c) => c.id), contains('iv'));
    });

    test('нема збігів → порожньо', () async {
      await cnt.read(allChildrenProvider.future);
      cnt.read(ratingFilterProvider.notifier).state =
          const RatingFilter(lastName: 'Zzzzz');
      expect(cnt.read(ratedChildrenProvider), isEmpty);
    });

    test('lastName + birthYear комбінація', () async {
      final a = makeChild(id: 'a', lastName: 'Коваль', birthYear: 2010, totalPoints: 10);
      final b = makeChild(id: 'b', lastName: 'Коваленко', birthYear: 2011, totalPoints: 5);
      final c2 = makeContainer([a, b]);
      addTearDown(c2.dispose);
      await c2.read(allChildrenProvider.future);
      c2.read(ratingFilterProvider.notifier).state =
          const RatingFilter(lastName: 'Коваль', birthYear: 2010);
      final result = c2.read(ratedChildrenProvider);
      expect(result.map((c) => c.id), contains('a'));
      expect(result, hasLength(1));
    });
  });

  group('RatingFilter.copyWith', () {
    test('clearBirthYear → null', () {
      final f = const RatingFilter(birthYear: 2010).copyWith(clearBirthYear: true);
      expect(f.birthYear, isNull);
    });

    test('clearWeightCategory → null', () {
      final f = const RatingFilter(weightCategory: '-30 кг')
          .copyWith(clearWeightCategory: true);
      expect(f.weightCategory, isNull);
    });

    test('зберігає незмінені поля', () {
      const f = RatingFilter(birthYear: 2010, weightCategory: '-30 кг');
      final updated = f.copyWith(clearBirthYear: true);
      expect(updated.birthYear, isNull);
      expect(updated.weightCategory, '-30 кг');
    });
  });
}

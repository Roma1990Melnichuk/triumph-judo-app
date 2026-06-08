/// Тести кириличного пошуку.
///
/// Покривають три рівні:
///   1. Чиста логіка фільтра (без UI, без Firebase)
///   2. Механізм addListener → update provider (симуляція _onSearchChanged)
///   3. Граничні випадки з українськими специфічними літерами
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/membership/providers/membership_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';

// ── Хелпери ─────────────────────────────────────────────────────────────────

ChildModel child({
  required String id,
  required String lastName,
  String firstName = 'Тест',
}) =>
    ChildModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      birthYear: 2010,
      weightCategory: '-30 кг',
      currentBelt: BeltLevel.white,
      coachId: 'c1',
      coachName: 'Тренер',
      totalPoints: 0,
      createdAt: DateTime(2024),
    );

ProviderContainer makeContainer(List<ChildModel> children) =>
    ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        allChildrenProvider.overrideWith((ref) => Stream.value(children)),
        allMembershipsProvider.overrideWith((ref) => Stream.value([])),
      ],
    );

/// Симулює механізм _onSearchChanged: TextEditingController.addListener → update
Future<List<ChildModel>> searchWith(
  ProviderContainer container,
  TextEditingController ctrl,
  String query,
) async {
  await container.read(allChildrenProvider.future);
  ctrl.text = query;
  // listener fires synchronously after text assignment in tests
  return container.read(filteredChildrenProvider);
}

// ── Тести ────────────────────────────────────────────────────────────────────

void main() {
  // Базові кириличні дані
  final kovalenko  = child(id: '1', lastName: 'Коваленко');
  final petrenko   = child(id: '2', lastName: 'Петренко');
  final kovalchuk  = child(id: '3', lastName: 'Ковальчук');
  final ivaniuk    = child(id: '4', lastName: 'Іваній');  // і = U+0456
  final shevchenko = child(id: '5', lastName: 'Шевченко');
  final yizhak     = child(id: '6', lastName: 'Їжак');    // ї = U+0457
  final yeresenko  = child(id: '7', lastName: 'Єресенко'); // є = U+0454
  final grytsenko  = child(id: '8', lastName: 'Гриценко',
                           firstName: 'Максим');

  final all = [kovalenko, petrenko, kovalchuk, ivaniuk, shevchenko,
               yizhak, yeresenko, grytsenko];

  // ── 1. Логіка фільтра ─────────────────────────────────────────────────────

  group('Кириличний пошук — логіка фільтра', () {
    late ProviderContainer c;
    setUp(() => c = makeContainer(all));
    tearDown(() => c.dispose());

    Future<List<ChildModel>> filter(String q) async {
      await c.read(allChildrenProvider.future);
      c.read(childrenFilterProvider.notifier).update(
        (s) => s.copyWith(lastName: q),
      );
      return c.read(filteredChildrenProvider);
    }

    test('порожній запит — всі записи', () async {
      final r = await filter('');
      expect(r, hasLength(all.length));
    });

    test('точний збіг по прізвищу', () async {
      final r = await filter('Петренко');
      expect(r, hasLength(1));
      expect(r.first.id, '2');
    });

    test('частковий збіг на початку (Ков → Коваленко, Ковальчук)', () async {
      final r = await filter('Ков');
      expect(r, hasLength(2));
      expect(r.map((c) => c.id), containsAll(['1', '3']));
    });

    test('частковий збіг у середині слова (ленко → Коваленко, Шевченко, Петренко)', () async {
      final r = await filter('енко');
      expect(r, hasLength(5)); // Коваленко, Петренко, Ковальчук ні, Шевченко, Гриценко
      // Перевіряємо що знайдено правильно
      final ids = r.map((c) => c.id).toSet();
      expect(ids, contains('1')); // Коваленко
      expect(ids, contains('2')); // Петренко
      expect(ids, contains('5')); // Шевченко
      expect(ids, contains('8')); // Гриценко
    });

    test('нижній регістр знаходить записи у верхньому', () async {
      final r = await filter('коваленко');
      expect(r, hasLength(1));
      expect(r.first.id, '1');
    });

    test('верхній регістр знаходить записи у нижньому', () async {
      final r = await filter('ПЕТРЕНКО');
      expect(r, hasLength(1));
      expect(r.first.id, '2');
    });

    test('мікс регістрів (кОВА)', () async {
      final r = await filter('кОВА');
      expect(r, hasLength(2)); // Коваленко, Ковальчук
    });

    test('українська і (U+0456) — Іваній', () async {
      final r = await filter('Іван');
      expect(r, hasLength(1));
      expect(r.first.id, '4');
    });

    test('українська ї (U+0457) — Їжак', () async {
      final r = await filter('Їжак');
      expect(r, hasLength(1));
      expect(r.first.id, '6');
    });

    test('українська є (U+0454) — Єресенко', () async {
      final r = await filter('Єрес');
      expect(r, hasLength(1));
      expect(r.first.id, '7');
    });

    test('пошук по firstName теж кирилицею (Максим → Гриценко Максим)', () async {
      final r = await filter('Максим');
      expect(r, hasLength(1));
      expect(r.first.id, '8');
    });

    test('очищення пошуку повертає всіх', () async {
      await filter('Ков');
      final r = await filter('');
      expect(r, hasLength(all.length));
    });

    test('запит без збігів → порожній список', () async {
      final r = await filter('Зzzz');
      expect(r, isEmpty);
    });

    test('пробіл у запиті не ламає пошук', () async {
      final r = await filter('Кова ');
      // 'коваленко'.contains('кова ') == false → порожньо
      expect(r, isEmpty);
    });
  });

  // ── 2. Механізм addListener → update ─────────────────────────────────────

  group('Кириличний пошук — механізм addListener', () {
    late ProviderContainer container;
    late TextEditingController ctrl;

    setUp(() {
      container = makeContainer([kovalenko, petrenko, kovalchuk]);

      ctrl = TextEditingController();
      // Точна копія _onSearchChanged з TeamListScreen
      ctrl.addListener(() {
        container.read(childrenFilterProvider.notifier).update(
          (state) => state.copyWith(lastName: ctrl.text),
        );
      });
    });

    tearDown(() {
      ctrl.dispose();
      container.dispose();
    });

    test('listener спрацьовує при зміні тексту', () async {
      await container.read(allChildrenProvider.future);

      ctrl.text = 'Ков';

      final result = container.read(filteredChildrenProvider);
      expect(result, hasLength(2));
      expect(result.map((c) => c.id), containsAll(['1', '3']));
    });

    test('послідовний ввід кирилиці (побуквено)', () async {
      await container.read(allChildrenProvider.future);

      // Симулюємо поступовий ввід 'Пет'
      ctrl.text = 'П';
      expect(container.read(filteredChildrenProvider), hasLength(1));

      ctrl.text = 'Пе';
      expect(container.read(filteredChildrenProvider), hasLength(1));

      ctrl.text = 'Пет';
      final result = container.read(filteredChildrenProvider);
      expect(result, hasLength(1));
      expect(result.first.id, '2');
    });

    test('видалення символу розширює результати', () async {
      await container.read(allChildrenProvider.future);

      ctrl.text = 'Ковальчук';
      expect(container.read(filteredChildrenProvider), hasLength(1));

      ctrl.text = 'Ков';
      expect(container.read(filteredChildrenProvider), hasLength(2));

      ctrl.text = '';
      expect(container.read(filteredChildrenProvider), hasLength(3));
    });

    test('listener не дублює результати при повторному встановленні того ж тексту',
        () async {
      await container.read(allChildrenProvider.future);

      ctrl.text = 'Ков';
      ctrl.text = 'Ков'; // двічі
      expect(container.read(filteredChildrenProvider), hasLength(2));
    });
  });

  // ── 3. Граничні випадки ───────────────────────────────────────────────────

  group('Кириличний пошук — граничні випадки', () {
    test('тільки пробіли — нічого не знаходить', () async {
      final c = makeContainer([kovalenko]);
      addTearDown(c.dispose);
      await c.read(allChildrenProvider.future);
      c.read(childrenFilterProvider.notifier).update(
        (s) => s.copyWith(lastName: '   '),
      );
      // '   ' не входить в жодне прізвище
      expect(c.read(filteredChildrenProvider), isEmpty);
    });

    test('один символ кирилиці знаходить всі співпадіння', () async {
      final c = makeContainer([kovalenko, kovalchuk, petrenko]);
      addTearDown(c.dispose);
      await c.read(allChildrenProvider.future);
      c.read(childrenFilterProvider.notifier).update(
        (s) => s.copyWith(lastName: 'К'),
      );
      // 'к' є в Коваленко, Ковальчук і Петрен-к-о
      expect(c.read(filteredChildrenProvider), hasLength(3));
    });

    test('прізвище що відрізняється тільки однією літерою (і vs и)', () async {
      final withI   = child(id: 'ui', lastName: 'Гриценко');  // и
      final withUkI = child(id: 'uki', lastName: 'Гріценко'); // і
      final c = makeContainer([withI, withUkI]);
      addTearDown(c.dispose);
      await c.read(allChildrenProvider.future);

      c.read(childrenFilterProvider.notifier).update(
        (s) => s.copyWith(lastName: 'Гриц'),
      );
      expect(c.read(filteredChildrenProvider), hasLength(1));
      expect(c.read(filteredChildrenProvider).first.id, 'ui');

      c.read(childrenFilterProvider.notifier).update(
        (s) => s.copyWith(lastName: 'Гріц'),
      );
      expect(c.read(filteredChildrenProvider), hasLength(1));
      expect(c.read(filteredChildrenProvider).first.id, 'uki');
    });
  });
}

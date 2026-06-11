import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

ChildModel _child(String id, {String firstName = 'Олег', String lastName = 'Тест'}) {
  return ChildModel(
    id: id,
    firstName: firstName,
    lastName: lastName,
    birthYear: 2010,
    weightCategory: '-50 кг',
    currentBelt: BeltLevel.white,
    coachId: 'coach1',
    coachName: 'Тренер',
    totalPoints: 0,
    createdAt: DateTime(2024, 1, 1),
  );
}

ProviderContainer _container(List<ChildModel> children) {
  return ProviderContainer(
    overrides: [
      allChildrenProvider.overrideWith(
        (ref) => Stream.value(children),
      ),
    ],
  );
}

// ── Tests — PERF-01: childByIdMapProvider ─────────────────────────────────────

void main() {
  group('childByIdMapProvider', () {
    test('порожній список → порожня карта', () async {
      final c = _container([]);
      await c.read(allChildrenProvider.future);

      final map = c.read(childByIdMapProvider);
      expect(map, isEmpty);
    });

    test('один спортсмен → карта з одним записом', () async {
      final child = _child('c1');
      final c = _container([child]);
      await c.read(allChildrenProvider.future);

      final map = c.read(childByIdMapProvider);
      expect(map.length, 1);
      expect(map['c1'], child);
    });

    test('багато спортсменів → кожен доступний за id', () async {
      final children = ['c1', 'c2', 'c3', 'c4', 'c5'].map(_child).toList();
      final c = _container(children);
      await c.read(allChildrenProvider.future);

      final map = c.read(childByIdMapProvider);
      expect(map.length, 5);
      for (final ch in children) {
        expect(map[ch.id], ch);
      }
    });

    test('відсутній id повертає null', () async {
      final c = _container([_child('c1')]);
      await c.read(allChildrenProvider.future);

      final map = c.read(childByIdMapProvider);
      expect(map['нема_такого'], isNull);
    });

    test('ключі відповідають id спортсменів', () async {
      final children = [_child('abc'), _child('xyz')];
      final c = _container(children);
      await c.read(allChildrenProvider.future);

      final map = c.read(childByIdMapProvider);
      expect(map.keys, containsAll(['abc', 'xyz']));
    });

    test('значення карти містять правильний fullName', () async {
      final c = _container([
        _child('c1', firstName: 'Іван', lastName: 'Коваль'),
        _child('c2', firstName: 'Марія', lastName: 'Бойко'),
      ]);
      await c.read(allChildrenProvider.future);

      final map = c.read(childByIdMapProvider);
      expect(map['c1']!.fullName, 'Коваль Іван');
      expect(map['c2']!.fullName, 'Бойко Марія');
    });

    test('карта синхронно доступна після завантаження потоку', () async {
      final c = _container([_child('c1'), _child('c2')]);
      await c.read(allChildrenProvider.future);

      // childByIdMapProvider — sync Provider, не AsyncValue
      final map = c.read(childByIdMapProvider);
      expect(map, isA<Map<String, ChildModel>>());
      expect(map.length, 2);
    });

    test('карта не містить дублікатів при однакових id', () async {
      // якщо список містить два об\'єкти з одним id — перемагає останній (Map-семантика)
      final first  = _child('c1', firstName: 'Перший');
      final second = _child('c1', firstName: 'Другий');
      final c = _container([first, second]);
      await c.read(allChildrenProvider.future);

      final map = c.read(childByIdMapProvider);
      // Map-literal {for ...} — останній запис перемагає
      expect(map.length, 1);
      expect(map['c1']!.firstName, 'Другий');
    });
  });
}

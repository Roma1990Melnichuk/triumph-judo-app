/// E2E тести для дефолтного фільтру тренера у вкладці "Команда".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/membership/providers/membership_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';
import 'package:judo_app/features/team/screens/team_list_screen.dart';

// ── Хелпери ───────────────────────────────────────────────────────────────────

UserModel _coach(String name) => UserModel(
      uid: 'uid_$name',
      email: 'coach@test.com',
      name: name,
      role: 'coach',
    );

UserModel _parent({String childId = 'c1'}) => UserModel(
      uid: 'parent1',
      email: 'parent@test.com',
      name: 'Батько',
      role: 'parent',
      childId: childId,
      childIds: [childId],
    );

ChildModel _child({
  required String id,
  required String coachName,
  String lastName = 'Спортсмен',
}) =>
    ChildModel(
      id: id,
      firstName: 'Іван',
      lastName: lastName,
      birthYear: 2012,
      weightCategory: '-40 кг',
      currentBelt: BeltLevel.white,
      coachId: 'coach1',
      coachName: coachName,
      totalPoints: 0,
      createdAt: DateTime(2024),
    );

// Допоміжна функція: pumps + повертає останній схоплений фільтр
Future<ChildrenFilter?> _pumpTeamScreenGetFilter(
  WidgetTester tester, {
  required UserModel user,
  required List<ChildModel> children,
  ChildrenFilter initialFilter = const ChildrenFilter(),
}) async {
  // Suppress overflow errors
  final handler = FlutterError.onError;
  FlutterError.onError = (d) {
    if (d.toString().contains('overflowed') ||
        d.toString().contains('cannot be seen')) return;
    handler?.call(d);
  };
  addTearDown(() => FlutterError.onError = handler);

  ChildrenFilter? captured;

  // Consumer wrapper захоплює поточне значення фільтру після кожного rebuild
  Widget wrapper = Consumer(
    builder: (_, ref, __) {
      captured = ref.watch(childrenFilterProvider);
      return const TeamListScreen();
    },
  );

  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => wrapper),
    GoRoute(
        path: '/team/:id',
        builder: (_, __) => const Scaffold(body: Text('profile'))),
    GoRoute(
        path: '/team/add',
        builder: (_, __) => const Scaffold(body: Text('add'))),
  ]);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserModelProvider.overrideWith((_) => Stream.value(user)),
        allChildrenProvider.overrideWith((_) => Stream.value(children)),
        allMembershipsProvider.overrideWith((_) => Stream.value(const [])),
        childrenFilterProvider.overrideWith((_) => initialFilter),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );

  // AsyncLoading → AsyncData (stream emits)
  await tester.pump();
  // rebuild з user != null → реєструє addPostFrameCallback
  await tester.pump(const Duration(milliseconds: 50));
  // post-frame callback fires → оновлює childrenFilterProvider
  await tester.pump();
  // rebuild з новим фільтром
  await tester.pump();

  return captured;
}

// Версія без повернення фільтру — для тестів, що перевіряють тільки рендер
Future<void> _pumpTeamScreen(
  WidgetTester tester, {
  required UserModel user,
  required List<ChildModel> children,
  ChildrenFilter initialFilter = const ChildrenFilter(),
}) async {
  await _pumpTeamScreenGetFilter(
    tester,
    user: user,
    children: children,
    initialFilter: initialFilter,
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('TeamListScreen — дефолтний фільтр тренера', () {
    testWidgets(
        'тренер відкрив вкладку → childrenFilterProvider.coachId = ім\'я тренера',
        (tester) async {
      final coach = _coach('Іванов');
      final children = [
        _child(id: 'c1', coachName: 'Іванов', lastName: 'Петренко'),
        _child(id: 'c2', coachName: 'Сидоров', lastName: 'Мороз'),
      ];

      final filter = await _pumpTeamScreenGetFilter(
          tester, user: coach, children: children);

      expect(filter?.coachId, equals('Іванов'),
          reason:
              'Після відкриття вкладки тренером фільтр повинен бути по його імені');
    });

    testWidgets(
        'вже встановлений фільтр НЕ перезаписується при повторному рендері',
        (tester) async {
      final coach = _coach('Іванов');
      final children = [
        _child(id: 'c1', coachName: 'Іванов'),
        _child(id: 'c2', coachName: 'Сидоров'),
      ];

      final filter = await _pumpTeamScreenGetFilter(
        tester,
        user: coach,
        children: children,
        initialFilter: const ChildrenFilter(coachId: 'Сидоров'),
      );

      expect(filter?.coachId, equals('Сидоров'),
          reason: 'Вже встановлений фільтр не перезаписується');
    });

    testWidgets('батько НЕ отримує дефолтний фільтр тренера', (tester) async {
      final parent = _parent();
      final children = [
        _child(id: 'c1', coachName: 'Іванов'),
      ];

      final filter = await _pumpTeamScreenGetFilter(
          tester, user: parent, children: children);

      expect(filter?.coachId, isNull,
          reason: 'Батько не тренер — фільтр по тренеру не встановлюється');
    });

    testWidgets('екран рендериться без краша', (tester) async {
      final coach = _coach('Іванов');
      final children = [
        _child(id: 'c1', coachName: 'Іванов', lastName: 'Петренко'),
        _child(id: 'c2', coachName: 'Іванов', lastName: 'Бондаренко'),
        _child(id: 'c3', coachName: 'Сидоров', lastName: 'Мороз'),
      ];

      await _pumpTeamScreen(tester, user: coach, children: children);

      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────

  group('filteredChildrenProvider — логіка фільтрації', () {
    test('фільтр по coachId показує тільки спортсменів цього тренера', () async {
      final children = [
        _child(id: 'c1', coachName: 'Іванов', lastName: 'Перший'),
        _child(id: 'c2', coachName: 'Петров', lastName: 'Другий'),
        _child(id: 'c3', coachName: 'Іванов', lastName: 'Третій'),
      ];

      final c = ProviderContainer(overrides: [
        allChildrenProvider.overrideWith((_) => Stream.value(children)),
        allMembershipsProvider.overrideWith((_) => Stream.value(const [])),
        childrenFilterProvider
            .overrideWith((_) => const ChildrenFilter(coachId: 'Іванов')),
      ]);

      await c.read(allChildrenProvider.future);
      final filtered = c.read(filteredChildrenProvider);
      c.dispose();

      expect(filtered.length, equals(2));
      expect(filtered.every((ch) => ch.coachName == 'Іванов'), isTrue);
    });

    test('порожній фільтр — всі спортсмени', () async {
      final children = [
        _child(id: 'c1', coachName: 'Іванов'),
        _child(id: 'c2', coachName: 'Петров'),
      ];

      final c = ProviderContainer(overrides: [
        allChildrenProvider.overrideWith((_) => Stream.value(children)),
        allMembershipsProvider.overrideWith((_) => Stream.value(const [])),
      ]);

      await c.read(allChildrenProvider.future);
      final filtered = c.read(filteredChildrenProvider);
      c.dispose();

      expect(filtered.length, equals(2));
    });

    test('ChildrenFilter.copyWith(clearCoachId: true) скидає coachId', () {
      const filter = ChildrenFilter(coachId: 'Іванов', lastName: 'Тест');
      final cleared = filter.copyWith(clearCoachId: true);

      expect(cleared.coachId, isNull);
      expect(cleared.lastName, equals('Тест'),
          reason: 'Інші поля зберігаються при clearCoachId');
    });

    test('ChildrenFilter.copyWith зберігає всі незмінені поля', () {
      const original = ChildrenFilter(
        coachId: 'Іванов',
        lastName: 'Петр',
        beltReady: true,
      );
      final updated = original.copyWith(lastName: 'Нов');

      expect(updated.coachId, equals('Іванов'));
      expect(updated.lastName, equals('Нов'));
      expect(updated.beltReady, isTrue);
    });
  });
}

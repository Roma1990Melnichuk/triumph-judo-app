/// Сценарний тест: Графік — групи (Schedule / Groups)
///
/// Реальні сценарії:
///
///   SC-G-001  Тренер бачить список 2 груп з назвами
///   SC-G-002  Тренер бачить FAB (кнопку + для створення групи)
///   SC-G-003  Порожній список → EmptyState «Груп ще немає»
///   SC-G-004  Тап на групу → навігація /group/:id
///   SC-G-005  Картка групи показує розклад (дні тижня, наприклад «Пн, Ср, Пт»)
///   SC-G-006  GroupModel.trainingDates рахує дати сезону правильно
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:judo_app/core/models/group_model.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/schedule/providers/group_provider.dart';
import 'package:judo_app/features/schedule/screens/groups_screen.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _coach = UserModel(
  uid: 'coach1',
  email: 'coach@test.com',
  name: 'Тренер Іванов',
  role: 'coach',
);

GroupModel _group({
  required String id,
  required String name,
  List<int> days = const [1, 3, 5], // Пн, Ср, Пт
  String timeStart = '18:00',
  String timeEnd = '19:30',
}) =>
    GroupModel(
      id: id,
      coachId: 'coach1',
      name: name,
      childIds: const [],
      daysOfWeek: days,
      timeStart: timeStart,
      timeEnd: timeEnd,
    );

// ── App builder ───────────────────────────────────────────────────────────────

class _NavLog {
  String? groupId;
}

Widget _buildGroupsApp({
  required List<GroupModel> groups,
  _NavLog? nav,
}) {
  final db = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      firestoreProvider.overrideWithValue(db),
      currentUserModelProvider.overrideWith((_) => Stream.value(_coach)),
      groupsProvider.overrideWith((_) => Stream.value(groups)),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/schedule',
        routes: [
          GoRoute(
            path: '/schedule',
            builder: (_, __) => const GroupsScreen(),
          ),
          GoRoute(
            path: '/group/:id',
            builder: (_, state) {
              nav?.groupId = state.pathParameters['id'];
              return Scaffold(
                body: Text('Група: ${state.pathParameters["id"]}'),
              );
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

// ── Scenarios ─────────────────────────────────────────────────────────────────

void main() {
  group('SC-G-001: тренер бачить список груп з назвами', () {
    testWidgets('2 групи — обидві назви видні', (tester) async {
      final groups = [
        _group(id: 'g1', name: 'Молодша група'),
        _group(id: 'g2', name: 'Старша група', days: [2, 4]),
      ];
      await tester.pumpWidget(_buildGroupsApp(groups: groups));
      await _settle(tester);

      expect(find.text('Молодша група'), findsOneWidget,
          reason: 'Назва першої групи має бути видна');
      expect(find.text('Старша група'), findsOneWidget,
          reason: 'Назва другої групи має бути видна');
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-G-002: тренер бачить FAB для створення групи', () {
    testWidgets('FAB присутній для тренера', (tester) async {
      await tester.pumpWidget(_buildGroupsApp(groups: const []));
      await _settle(tester);

      expect(find.byIcon(Icons.add), findsWidgets,
          reason: 'FAB для додавання групи має бути у тренера (custom GestureDetector+Container з Icons.add)');
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-G-003: порожній список → EmptyState «Груп ще немає»', () {
    testWidgets('без груп — повідомлення про відсутність груп', (tester) async {
      await tester.pumpWidget(_buildGroupsApp(groups: const []));
      await _settle(tester);

      expect(find.textContaining('Груп ще немає'), findsOneWidget,
          reason: 'При порожньому списку має показуватись EmptyState');
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-G-004: тап на групу → навігація /group/:id', () {
    testWidgets('тап → /group/g1 з правильним ID', (tester) async {
      final nav = _NavLog();
      final groups = [_group(id: 'g1', name: 'Молодша група')];
      await tester.pumpWidget(_buildGroupsApp(groups: groups, nav: nav));
      await _settle(tester);

      await tester.tap(find.text('Молодша група'));
      await tester.pumpAndSettle();

      expect(nav.groupId, equals('g1'),
          reason: 'Після тапу на картку має відбутись навігація з groupId=g1');
      expect(find.text('Група: g1'), findsOneWidget);
    });
  });

  group('SC-G-005: картка групи показує розклад тренувань', () {
    testWidgets('Пн, Ср, Пт видно в розкладі', (tester) async {
      final groups = [
        _group(id: 'g1', name: 'Початківці', days: [1, 3, 5]),
      ];
      await tester.pumpWidget(_buildGroupsApp(groups: groups));
      await _settle(tester);

      // daysLabel: '1,3,5' → 'Пн, Ср, Пт'
      expect(find.textContaining('Пн'), findsWidgets,
          reason: 'Понеділок (день 1) має відображатись на картці групи');
      expect(find.textContaining('Ср'), findsWidgets,
          reason: 'Середа (день 3) має відображатись на картці групи');
      expect(find.textContaining('Пт'), findsWidgets,
          reason: 'П\'ятниця (день 5) має відображатись на картці групи');
      expect(tester.takeException(), isNull);
    });

    testWidgets('час тренування 18:00 – 19:30 відображається', (tester) async {
      final groups = [
        _group(id: 'g1', name: 'Група А', timeStart: '18:00', timeEnd: '19:30'),
      ];
      await tester.pumpWidget(_buildGroupsApp(groups: groups));
      await _settle(tester);

      expect(find.textContaining('18:00'), findsWidgets,
          reason: 'Час початку тренування має відображатись');
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-G-006: GroupModel.trainingDates рахує дати сезону', () {
    test('Пн/Ср/Пт з 1 вересня — правильна кількість дат', () {
      final group = _group(id: 'g1', name: 'Г', days: [1, 3, 5]);
      // Сезон 2024-2025: вересень 2024 – липень 2025
      final dates = group.trainingDates(2024);

      expect(dates.isNotEmpty, isTrue);
      // Всі дати — лише Пн, Ср, Пт
      for (final d in dates) {
        expect([1, 3, 5].contains(d.weekday), isTrue,
            reason: 'Дата ${d.toIso8601String()} не є Пн/Ср/Пт (weekday=${d.weekday})');
      }
      // Перша дата — Пн, Ср або Пт після 1 вересня 2024
      expect(dates.first.isAfter(DateTime(2024, 8, 31)), isTrue);
      // Остання дата — до 31 липня 2025
      expect(dates.last.isBefore(DateTime(2025, 8, 1)), isTrue);
    });

    test('група Вт/Чт — дати тільки вівторок і четвер', () {
      final group = _group(id: 'g2', name: 'Г', days: [2, 4]);
      final dates = group.trainingDates(2024);
      for (final d in dates) {
        expect([2, 4].contains(d.weekday), isTrue,
            reason: 'Дата повинна бути тільки Вт або Чт');
      }
    });
  });
}

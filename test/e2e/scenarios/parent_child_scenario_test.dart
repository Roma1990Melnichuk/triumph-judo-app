/// Сценарний тест: Батько — перегляд своєї дитини
///
/// Ключова бізнес-вимога: батько НЕ має бачити чужих дітей.
/// Тренер НЕ ділиться правами з батьком.
///
///   SC-P-001  Батько бачить ТІЛЬКИ свою дитину (ізоляція по childIds)
///   SC-P-002  Батько НЕ бачить FAB (не може додавати спортсменів)
///   SC-P-003  Батько з двома дітьми бачить обох, але не чужих
///   SC-P-004  Батько з childId (legacy) — теж бачить свою дитину
///   SC-P-005  Якщо дитина батька не в загальному списку — порожній стан
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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

// ── Fixtures ──────────────────────────────────────────────────────────────────

UserModel _parent({List<String> childIds = const [], String? legacyChildId}) => UserModel(
      uid: 'parent1',
      email: 'parent@test.com',
      name: 'Батько Петренко',
      role: 'parent',
      childIds: childIds,
      childId: legacyChildId,
    );

ChildModel _athlete({required String id, required String lastName, String firstName = 'Іван'}) =>
    ChildModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      birthYear: 2012,
      weightCategory: '-30 кг',
      currentBelt: BeltLevel.white,
      coachId: 'coach1',
      coachName: 'Тренер Іванов',
      totalPoints: 5,
      createdAt: DateTime(2024, 1, 1),
      gender: Gender.male,
    );

// ── App builder ───────────────────────────────────────────────────────────────

Widget _buildApp({required UserModel user, required List<ChildModel> athletes}) {
  final db = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      currentUserModelProvider.overrideWith((_) => Stream.value(user)),
      allChildrenProvider.overrideWith((_) => Stream.value(athletes)),
      allMembershipsProvider.overrideWith((_) => Stream.value(const [])),
      firestoreProvider.overrideWithValue(db),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/team',
        routes: [
          GoRoute(path: '/team', builder: (_, __) => const TeamListScreen()),
          GoRoute(path: '/team/add', builder: (_, __) => const Scaffold(body: Text('Додати'))),
          GoRoute(path: '/team/:id', builder: (_, s) => Scaffold(body: Text('Профіль: ${s.pathParameters["id"]}'))),
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
  group('SC-P-001: батько бачить ТІЛЬКИ свою дитину', () {
    testWidgets('ownChild видний, otherChild прихований', (tester) async {
      final parent = _parent(childIds: ['c1']);
      final athletes = [
        _athlete(id: 'c1', lastName: 'Петренко', firstName: 'Максим'),
        _athlete(id: 'c2', lastName: 'Коваленко', firstName: 'Олег'),
        _athlete(id: 'c3', lastName: 'Шевченко', firstName: 'Тарас'),
      ];
      await tester.pumpWidget(_buildApp(user: parent, athletes: athletes));
      await _settle(tester);

      expect(find.textContaining('Петренко'), findsOneWidget,
          reason: 'Власна дитина батька (c1) має бути видима');
      expect(find.textContaining('Коваленко'), findsNothing,
          reason: 'ІЗОЛЯЦІЯ: батько не має бачити c2 (чуже)');
      expect(find.textContaining('Шевченко'), findsNothing,
          reason: 'ІЗОЛЯЦІЯ: батько не має бачити c3 (чуже)');
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-P-002: батько НЕ має FAB (не може додавати спортсменів)', () {
    testWidgets('FloatingActionButton відсутній для батька', (tester) async {
      final parent = _parent(childIds: ['c1']);
      final athletes = [_athlete(id: 'c1', lastName: 'Петренко')];
      await tester.pumpWidget(_buildApp(user: parent, athletes: athletes));
      await _settle(tester);

      expect(find.byType(FloatingActionButton), findsNothing,
          reason: 'Батько не має права додавати спортсменів — FAB заборонений');
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-P-003: батько з двома дітьми бачить обох', () {
    testWidgets('обидві власні діти видні, чужа — ні', (tester) async {
      final parent = _parent(childIds: ['c1', 'c2']);
      final athletes = [
        _athlete(id: 'c1', lastName: 'Петренко', firstName: 'Максим'),
        _athlete(id: 'c2', lastName: 'Петренко', firstName: 'Оля'),
        _athlete(id: 'c3', lastName: 'Сторонній', firstName: 'Іван'),
      ];
      await tester.pumpWidget(_buildApp(user: parent, athletes: athletes));
      await _settle(tester);

      expect(find.textContaining('Максим'), findsOneWidget);
      expect(find.textContaining('Оля'), findsOneWidget);
      expect(find.textContaining('Сторонній'), findsNothing,
          reason: 'Стороння дитина c3 не в childIds батька — не має відображатись');
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-P-004: legacy childId (поле, не масив) — батько бачить свою дитину', () {
    testWidgets('UserModel.childId (legacy) працює як ownsChild', (tester) async {
      // Legacy: батько з `childId: 'c1'` без `childIds`
      final parent = _parent(childIds: const [], legacyChildId: 'c1');
      final athletes = [
        _athlete(id: 'c1', lastName: 'Петренко'),
        _athlete(id: 'c2', lastName: 'Сторонній'),
      ];
      await tester.pumpWidget(_buildApp(user: parent, athletes: athletes));
      await _settle(tester);

      expect(find.textContaining('Петренко'), findsOneWidget,
          reason: 'Legacy childId=c1 має давати доступ до Петренко');
      expect(find.textContaining('Сторонній'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-P-005: дитина батька відсутня в списку → порожній стан', () {
    testWidgets('якщо childId батька не в allChildren — не видно нікого', (tester) async {
      final parent = _parent(childIds: ['nonexistent-id']);
      final athletes = [
        _athlete(id: 'c1', lastName: 'Петренко'),
      ];
      await tester.pumpWidget(_buildApp(user: parent, athletes: athletes));
      await _settle(tester);

      // Петренко — не дитина цього батька
      expect(find.textContaining('Петренко'), findsNothing,
          reason: 'Батько не може бачити c1 якщо c1 не в його childIds');
      expect(tester.takeException(), isNull);
    });
  });
}

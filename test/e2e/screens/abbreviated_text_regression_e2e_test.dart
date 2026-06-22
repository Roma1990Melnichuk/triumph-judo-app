/// Регресійні тести: заборонені скорочення в UI.
///
/// KNOWN BUG: child_card.dart ~рядок 267:
///   Text('Відвід.: ${attendanceStats.pct.round()}%')  ← НЕПРАВИЛЬНО
///   Має бути: Text('Відвідування: ${attendanceStats.pct.round()}%')
///
/// Аналогічно _MembershipDot._label: 'Закінч.' і 'Простр.' заборонені.
///
/// expect(find.textContaining('Відвід.'), findsNothing)
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
import 'package:judo_app/features/team/widgets/child_card.dart';

const _bannedAbbreviations = <String>[
  'Відвід.',
  'Відвід.:',
  'Відв.',
  'Закінч.',
  'Простр.',
  'Інд. трен.',
];

final _coach = UserModel(uid: 'coach1', email: 'coach@test.com', name: 'Тренер Іванов', role: 'coach');

ChildModel _makeChild({String id = 'child1'}) => ChildModel(
      id: id,
      firstName: 'Олексій',
      lastName: 'Петренко',
      birthYear: 2012,
      weightCategory: '-30 кг',
      currentBelt: BeltLevel.white,
      coachId: 'coach1',
      coachName: 'Тренер Іванов',
      totalPoints: 10,
      createdAt: DateTime(2024, 1, 1),
      gender: Gender.male,
    );

void _setView(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
}

void _resetView(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

Widget _teamApp(List<ChildModel> children) {
  final db = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      currentUserModelProvider.overrideWith((_) => Stream.value(_coach)),
      allChildrenProvider.overrideWith((_) => Stream.value(children)),
      allMembershipsProvider.overrideWith((_) => Stream.value(const [])),
      firestoreProvider.overrideWithValue(db),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/team',
        routes: [
          GoRoute(path: '/team', builder: (_, __) => const TeamListScreen()),
          GoRoute(path: '/team/add', builder: (_, __) => const Scaffold(body: Text('add'))),
          GoRoute(path: '/team/:id', builder: (_, __) => const Scaffold(body: Text('profile'))),
        ],
      ),
    ),
  );
}

void main() {
  // TC-ABBR-001: ChildCard без attendance
  group('TC-ABBR-001: ChildCard showAttendance=false — скорочень немає', () {
    testWidgets('жодне заборонене скорочення не відображається', (tester) async {
      _setView(tester);
      addTearDown(() => _resetView(tester));
      final db = FakeFirebaseFirestore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firestoreProvider.overrideWithValue(db),
            currentUserModelProvider.overrideWith((_) => Stream.value(_coach)),
            allMembershipsProvider.overrideWith((_) => Stream.value(const [])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ChildCard(child: _makeChild(), rank: 1, onTap: () {}, showAttendance: false),
            ),
          ),
        ),
      );
      await tester.pump();
      for (final abbr in _bannedAbbreviations) {
        expect(find.textContaining(abbr), findsNothing,
            reason: 'REGRESSION: знайдено «$abbr» в ChildCard (showAttendance=false)');
      }
      expect(tester.takeException(), isNull);
    });
  });

  // TC-ABBR-002: ChildCard з attendance — KNOWN BUG
  group('TC-ABBR-002: ChildCard showAttendance=true — REGRESSION «Відвід.»', () {
    testWidgets('«Відвід.» ЗАБОРОНЕНО — має бути «Відвідування:»', (tester) async {
      _setView(tester);
      addTearDown(() => _resetView(tester));
      final db = FakeFirebaseFirestore();
      final child = _makeChild(id: 'c1');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserModelProvider.overrideWith((_) => Stream.value(_coach)),
            allChildrenProvider.overrideWith((_) => Stream.value([child])),
            allMembershipsProvider.overrideWith((_) => Stream.value(const [])),
            firestoreProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ChildCard(child: child, rank: 1, onTap: () {}, showAttendance: true),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // REGRESSION: child_card.dart відображає 'Відвід.: X%' — це баг
      // Очікується: 'Відвідування: X%'
      expect(find.textContaining('Відвід.'), findsNothing,
          reason:
              'REGRESSION: child_card.dart (~рядок 267) відображає «Відвід.» '
              'замість «Відвідування:». Виправте label.');
      expect(tester.takeException(), isNull);
    });
  });

  // TC-ABBR-003: TeamListScreen порожня
  group('TC-ABBR-003: TeamListScreen порожня — скорочень немає', () {
    testWidgets('жодне заборонене скорочення', (tester) async {
      _setView(tester);
      addTearDown(() => _resetView(tester));
      await tester.pumpWidget(_teamApp(const []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      for (final abbr in _bannedAbbreviations) {
        expect(find.textContaining(abbr), findsNothing,
            reason: 'Знайдено «$abbr» на TeamListScreen (порожня)');
      }
      expect(tester.takeException(), isNull);
    });
  });

  // TC-ABBR-004: TeamListScreen зі спортсменами
  group('TC-ABBR-004: TeamListScreen зі спортсменами — скорочень немає', () {
    testWidgets('5 карток — жодне заборонене скорочення', (tester) async {
      _setView(tester);
      addTearDown(() => _resetView(tester));
      final children = List.generate(5, (i) => _makeChild(id: 'c$i'));
      await tester.pumpWidget(_teamApp(children));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      for (final abbr in _bannedAbbreviations) {
        expect(find.textContaining(abbr), findsNothing,
            reason: 'REGRESSION: знайдено «$abbr» на TeamListScreen (зі спортсменами)');
      }
      expect(tester.takeException(), isNull);
    });
  });
}

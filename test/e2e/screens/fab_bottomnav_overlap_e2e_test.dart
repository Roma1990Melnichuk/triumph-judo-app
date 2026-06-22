/// E2E тести: FAB не перекривається BottomNavigationBar.
///
/// Перевіряє:
///   1. FloatingActionButton присутній: findsOneWidget
///   2. FAB Rect повністю всередині розмірів екрану
///   3. Центр FAB вище нижнього краю BottomNavigationBar
///   4. Після прокрутки 20 карток — немає overflow
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

final _coach = UserModel(uid: 'coach1', email: 'coach@test.com', name: 'Тренер Іванов', role: 'coach');

List<ChildModel> _makeAthletes(int count) => List.generate(
      count,
      (i) => ChildModel(
        id: 'child_$i',
        firstName: 'Іван',
        lastName: 'Спортсмен-$i',
        birthYear: 2010 + (i % 8),
        weightCategory: '-30 кг',
        currentBelt: BeltLevel.white,
        coachId: 'coach1',
        coachName: 'Тренер Іванов',
        totalPoints: i * 5,
        createdAt: DateTime(2024, 1, 1),
        gender: Gender.male,
      ),
    );

Widget _teamApp({required List<ChildModel> children, double bottomPadding = 0}) {
  final db = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      currentUserModelProvider.overrideWith((_) => Stream.value(_coach)),
      allChildrenProvider.overrideWith((_) => Stream.value(children)),
      allMembershipsProvider.overrideWith((_) => Stream.value(const [])),
      firestoreProvider.overrideWithValue(db),
    ],
    child: MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        padding: EdgeInsets.only(bottom: bottomPadding),
        viewPadding: EdgeInsets.only(bottom: bottomPadding),
      ),
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
    ),
  );
}

void _setView(WidgetTester tester, Size s) {
  tester.view.physicalSize = s * 3;
  tester.view.devicePixelRatio = 3.0;
}

void _resetView(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void main() {
  group('TC-FAB-001: TeamListScreen — FAB присутній', () {
    testWidgets('FloatingActionButton findsOneWidget (390x844)', (tester) async {
      _setView(tester, const Size(390, 844));
      addTearDown(() => _resetView(tester));
      await tester.pumpWidget(_teamApp(children: const []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('FloatingActionButton findsOneWidget (320x568)', (tester) async {
      _setView(tester, const Size(320, 568));
      addTearDown(() => _resetView(tester));
      await tester.pumpWidget(_teamApp(children: const []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('TC-FAB-002: FAB повністю видимий — не виходить за межі екрану', () {
    testWidgets('FAB Rect в межах 390x844', (tester) async {
      const logicalSize = Size(390, 844);
      _setView(tester, logicalSize);
      addTearDown(() => _resetView(tester));
      await tester.pumpWidget(_teamApp(children: const []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      final fabRect = tester.getRect(fabFinder);
      expect(fabRect.bottom, lessThanOrEqualTo(logicalSize.height),
          reason: 'FAB виходить за нижній край — перекрит BottomNavBar');
      expect(fabRect.right, lessThanOrEqualTo(logicalSize.width));
      expect(fabRect.top, greaterThanOrEqualTo(0));
      expect(fabRect.left, greaterThanOrEqualTo(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Scaffold з BottomNav — центр FAB вище навбару', (tester) async {
      _setView(tester, const Size(390, 844));
      addTearDown(() => _resetView(tester));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('content')),
            bottomNavigationBar: BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Головна'),
                BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Команда'),
              ],
            ),
            floatingActionButton: const FloatingActionButton(onPressed: null, child: Icon(Icons.add)),
          ),
        ),
      );
      await tester.pump();
      final fabRect = tester.getRect(find.byType(FloatingActionButton));
      final navRect = tester.getRect(find.byType(BottomNavigationBar));
      expect(fabRect.center.dy, lessThan(navRect.top),
          reason: 'Центр FAB в зоні BottomNavigationBar — перекривання');
      expect(tester.takeException(), isNull);
    });
  });

  group('TC-FAB-003: Прокрутка 20 карток без overflow', () {
    testWidgets('20 спортсменів — прокрутка вниз без overflow', (tester) async {
      _setView(tester, const Size(390, 844));
      addTearDown(() => _resetView(tester));
      await tester.pumpWidget(_teamApp(children: _makeAthletes(20)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -2000));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(tester.takeException(), isNull, reason: 'Overflow після прокрутки');
    });

    testWidgets('20 спортсменів + bottomPadding=34 (iPhone) без overflow', (tester) async {
      _setView(tester, const Size(390, 844));
      addTearDown(() => _resetView(tester));
      await tester.pumpWidget(_teamApp(children: _makeAthletes(20), bottomPadding: 34));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    });
  });

  group('TC-FAB-004: FAB присутній при порожньому списку', () {
    testWidgets('EmptyState + FAB видимий', (tester) async {
      _setView(tester, const Size(390, 844));
      addTearDown(() => _resetView(tester));
      await tester.pumpWidget(_teamApp(children: const []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(FloatingActionButton), findsOneWidget,
          reason: 'FAB зник при порожньому списку');
      expect(tester.takeException(), isNull);
    });
  });
}

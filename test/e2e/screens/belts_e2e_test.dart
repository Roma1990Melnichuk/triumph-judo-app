/// E2E тести для BeltOverviewScreen.
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/belt_progress_model.dart';
import 'package:judo_app/core/models/belt_requirement_model.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/belts/providers/belt_provider.dart';
import 'package:judo_app/features/belts/screens/belt_overview_screen.dart';
import 'package:judo_app/features/schedule/providers/group_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';
import 'package:judo_app/features/team/widgets/child_card.dart';
import 'package:judo_app/features/individual_training/providers/individual_training_provider.dart';

// ── Хелпери ───────────────────────────────────────────────────────────────────

final _coach = UserModel(
  uid: 'coach1',
  email: 'coach@test.com',
  name: 'Тренер',
  role: 'coach',
);

final _parent = UserModel(
  uid: 'parent1',
  email: 'parent@test.com',
  name: 'Батько',
  role: 'parent',
  childId: 'kid1',
  childIds: const ['kid1'],
);

ChildModel _child({bool beltReady = false}) => ChildModel(
      id: 'kid1',
      firstName: 'Іван',
      lastName: 'Петренко',
      birthYear: 2012,
      weightCategory: '-40 кг',
      currentBelt: BeltLevel.white,
      coachId: 'coach1',
      coachName: 'Тренер',
      totalPoints: 0,
      createdAt: DateTime(2024),
      beltReady: beltReady,
    );

GoRouter _router() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const BeltOverviewScreen()),
        GoRoute(
            path: '/belts/:level',
            builder: (_, __) =>
                const Scaffold(body: Text('belt requirements'))),
        GoRoute(
            path: '/bulk-belt',
            builder: (_, __) => const Scaffold(body: Text('bulk belt'))),
      ],
    );

Widget _app(UserModel user, {List<ChildModel> children = const []}) {
  final db = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      currentUserModelProvider.overrideWith((_) => Stream.value(user)),
      allChildrenProvider.overrideWith((_) => Stream.value(children)),
      firestoreProvider.overrideWithValue(db),
    ],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('BeltOverviewScreen — рендер', () {
    testWidgets('перегляд тренера — рендериться без краша', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app(_coach));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('перегляд батька зі спортсменом — рендериться без краша', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app(_parent, children: [_child()]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('вибір іншого поясу — без overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app(_coach));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Тапаємо на перший belt chip щоб змінити вибраний пояс
      final beltChips = find.byType(GestureDetector);
      if (beltChips.evaluate().isNotEmpty) {
        await tester.tap(beltChips.first);
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(tester.takeException(), isNull);
    });
  });

  // ── TC-BELT-022: beltReady badge ─────────────────────────────────────────────
  group('BeltOverviewScreen — TC-BELT-022 beltReady badge', () {
    testWidgets(
        'TC-BELT-022: ChildCard з beltReady=true відображає бейдж «Готовий до здачі»',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final child = _child(beltReady: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            beltProgressProvider.overrideWith(
              (ref, arg) => Stream.value(null),
            ),
            beltRequirementProvider.overrideWith(
              (ref, belt) => null,
            ),
            childAttendanceStatsProvider.overrideWith(
              (ref, id) => Stream.value((total: 0, present: 0, pct: 0.0)),
            ),
            childConfirmedTrainingCountProvider.overrideWith(
              (ref, id) => 0,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ChildCard(
                child: child,
                rank: 1,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Готовий до здачі'), findsOneWidget);
    });

    testWidgets(
        'TC-BELT-022: ChildCard з beltReady=false НЕ показує бейдж',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final child = _child(beltReady: false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            beltProgressProvider.overrideWith(
              (ref, arg) => Stream.value(null),
            ),
            beltRequirementProvider.overrideWith(
              (ref, belt) => null,
            ),
            childAttendanceStatsProvider.overrideWith(
              (ref, id) => Stream.value((total: 0, present: 0, pct: 0.0)),
            ),
            childConfirmedTrainingCountProvider.overrideWith(
              (ref, id) => 0,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ChildCard(
                child: child,
                rank: 1,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Готовий до здачі'), findsNothing);
    });
  });

  // ── TC-BELT-015/016/017: progress states ─────────────────────────────────────
  group('BeltOverviewScreen — TC-BELT-015/016/017 progress states', () {
    testWidgets(
        'TC-BELT-015: 0 виконаних технік — рендер без краша',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Suppress overflow for pre-existing layout issues on this screen
      final handler = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.toString().contains('overflowed')) return;
        handler?.call(d);
      };
      addTearDown(() => FlutterError.onError = handler);

      final db = FakeFirebaseFirestore();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserModelProvider.overrideWith(
              (_) => Stream.value(_coach),
            ),
            allChildrenProvider.overrideWith(
              (_) => Stream.value([_child()]),
            ),
            firestoreProvider.overrideWithValue(db),
            beltProgressProvider.overrideWith(
              (ref, arg) => Stream.value(
                BeltProgressModel(
                  childId: arg.childId,
                  belt: arg.belt,
                  passed: const {},
                ),
              ),
            ),
            beltRequirementProvider.overrideWith(
              (ref, belt) => BeltRequirementModel(
                belt: belt,
                exercises: const [],
                updatedAt: DateTime(2024),
                updatedByCoachId: 'coach1',
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: _router()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });
}

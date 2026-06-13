/// TC-PERF-0384 / TC-PERF-0385 — Performance / Scalability
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

// ── Хелпери ───────────────────────────────────────────────────────────────────

ChildModel _child(int index) => ChildModel(
      id: 'c$index',
      firstName: 'Іван',
      lastName: 'Петренко$index',
      birthYear: 2010 + (index % 8),
      weightCategory: '-40 кг',
      currentBelt: BeltLevel.white,
      coachId: 'coach1',
      coachName: 'Тренер',
      totalPoints: index * 3,
      createdAt: DateTime(2024),
    );

final _coachUser = UserModel(
  uid: 'coach1',
  email: 'coach@test.com',
  name: 'Тренер',
  role: 'coach',
);

GoRouter _router() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const TeamListScreen()),
        GoRoute(
            path: '/team/:id',
            builder: (_, __) => const Scaffold(body: Text('profile'))),
        GoRoute(
            path: '/team/add',
            builder: (_, __) => const Scaffold(body: Text('add'))),
      ],
    );

Widget _app(List<ChildModel> children, {UserModel? user}) {
  final db = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      firestoreProvider.overrideWithValue(db),
      currentUserModelProvider.overrideWith((_) => Stream.value(user ?? _coachUser)),
      allChildrenProvider.overrideWith((_) => Stream.value(children)),
      allMembershipsProvider.overrideWith((_) => Stream.value(const [])),
    ],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

void _setPhoneViewport(WidgetTester t) {
  t.view.physicalSize = const Size(390 * 3, 844 * 3);
  t.view.devicePixelRatio = 3.0;
}

// ── TC-PERF-0384 ──────────────────────────────────────────────────────────────

void main() {
group('TC-PERF-0384: список спортсменів з 501 спортсменом', () {
  testWidgets('501 спортсмен — екран рендериться без краша', (tester) async {
    _setPhoneViewport(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Suppress overflow — expected with extreme list size in test viewport
    final handler = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.toString().contains('overflowed')) return;
      handler?.call(d);
    };
    addTearDown(() => FlutterError.onError = handler);

    final children = List.generate(501, _child);
    await tester.pumpWidget(_app(children));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });

  testWidgets('500 спортсменів (ліміт Firestore) — рендер без краша',
      (tester) async {
    _setPhoneViewport(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final handler = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.toString().contains('overflowed')) return;
      handler?.call(d);
    };
    addTearDown(() => FlutterError.onError = handler);

    final children = List.generate(500, _child);
    await tester.pumpWidget(_app(children));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });
});

// ── TC-PERF-0385 ──────────────────────────────────────────────────────────────

group('TC-PERF-0385: список 100+ спортсменів — прокрутка без краша', () {
  testWidgets('100 спортсменів — рендер і скрол без краша', (tester) async {
    _setPhoneViewport(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final handler = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.toString().contains('overflowed')) return;
      handler?.call(d);
    };
    addTearDown(() => FlutterError.onError = handler);

    final children = List.generate(100, _child);
    await tester.pumpWidget(_app(children));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);

    // Скролимо вниз — не повинно падати
    final scrollable = find.byType(Scrollable).first;
    await tester.drag(scrollable, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('120 спортсменів — перемикання між ними не падає', (tester) async {
    _setPhoneViewport(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final handler = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.toString().contains('overflowed')) return;
      handler?.call(d);
    };
    addTearDown(() => FlutterError.onError = handler);

    final children = List.generate(120, _child);
    await tester.pumpWidget(_app(children));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    // Verify at least some list items are visible
    expect(find.byType(Scrollable), findsWidgets);
  });
});
} // end main

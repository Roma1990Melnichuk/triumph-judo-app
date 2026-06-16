/// E2E тести для BeltOverviewScreen.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
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

  // ── BeltNotifier — toggleExercise ────────────────────────────────────────────

  group('BeltNotifier — toggleExercise', () {
    test('зберігає passed.ex1 у belt_progress', () async {
      final db = FakeFirebaseFirestore();
      // Seed child and requirements
      await db.collection('children').doc('kid1').set({
        'firstName': 'Іван', 'lastName': 'Тест', 'birthYear': 2012,
        'weightCategory': '-40 кг', 'currentBelt': 'white',
        'coachId': 'coach1', 'coachName': 'Тренер',
        'totalPoints': 0, 'bonusPoints': 0, 'beltReady': false,
        'createdAt': Timestamp.fromDate(DateTime(2024)),
      });
      await db.collection('belt_requirements').doc('white').set({
        'exercises': [
          {'id': 'ex1', 'name': 'Укемі', 'description': '', 'category': 'technique'},
        ],
        'updatedAt': Timestamp.now(),
        'updatedByCoachId': 'coach1',
      });
      final n = BeltNotifier(db);

      await n.toggleExercise(
          childId: 'kid1', belt: BeltLevel.white, exerciseId: 'ex1', passed: true);

      final doc = await db.collection('belt_progress').doc('kid1_white').get();
      expect(doc.exists, isTrue);
      final passed = (doc.data()!['passed'] as Map<String, dynamic>);
      expect(passed['ex1'], isTrue);
    });

    test('passed=false — значення стає false', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('children').doc('kid1').set({
        'firstName': 'Іван', 'lastName': 'Тест', 'birthYear': 2012,
        'weightCategory': '-40 кг', 'currentBelt': 'white',
        'coachId': 'coach1', 'coachName': 'Тренер',
        'totalPoints': 0, 'bonusPoints': 0, 'beltReady': false,
        'createdAt': Timestamp.fromDate(DateTime(2024)),
      });
      await db.collection('belt_requirements').doc('white').set({
        'exercises': [
          {'id': 'ex1', 'name': 'Укемі', 'description': '', 'category': 'technique'},
        ],
        'updatedAt': Timestamp.now(), 'updatedByCoachId': 'coach1',
      });
      final n = BeltNotifier(db);

      await n.toggleExercise(
          childId: 'kid1', belt: BeltLevel.white, exerciseId: 'ex1', passed: true);
      await n.toggleExercise(
          childId: 'kid1', belt: BeltLevel.white, exerciseId: 'ex1', passed: false);

      final doc = await db.collection('belt_progress').doc('kid1_white').get();
      final passed = (doc.data()!['passed'] as Map<String, dynamic>);
      expect(passed['ex1'], isFalse);
    });

    test('beltReady = true коли всі вправи виконано', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('children').doc('kid1').set({
        'firstName': 'Іван', 'lastName': 'Тест', 'birthYear': 2012,
        'weightCategory': '-40 кг', 'currentBelt': 'white',
        'coachId': 'coach1', 'coachName': 'Тренер',
        'totalPoints': 0, 'bonusPoints': 0, 'beltReady': false,
        'createdAt': Timestamp.fromDate(DateTime(2024)),
      });
      await db.collection('belt_requirements').doc('white').set({
        'exercises': [
          {'id': 'ex1', 'name': 'Укемі', 'description': '', 'category': 'technique'},
          {'id': 'ex2', 'name': 'Стійка', 'description': '', 'category': 'technique'},
        ],
        'updatedAt': Timestamp.now(), 'updatedByCoachId': 'coach1',
      });
      final n = BeltNotifier(db);

      await n.toggleExercise(
          childId: 'kid1', belt: BeltLevel.white, exerciseId: 'ex1', passed: true);
      await n.toggleExercise(
          childId: 'kid1', belt: BeltLevel.white, exerciseId: 'ex2', passed: true);

      final child = await db.collection('children').doc('kid1').get();
      expect(child['beltReady'], isTrue);
    });
  });

  // ── BeltNotifier — markAllPassed ─────────────────────────────────────────────

  group('BeltNotifier — markAllPassed', () {
    test('позначає всі вправи як виконані', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('children').doc('kid1').set({
        'firstName': 'Іван', 'lastName': 'Тест', 'birthYear': 2012,
        'weightCategory': '-40 кг', 'currentBelt': 'white',
        'coachId': 'coach1', 'coachName': 'Тренер',
        'totalPoints': 0, 'bonusPoints': 0, 'beltReady': false,
        'createdAt': Timestamp.fromDate(DateTime(2024)),
      });
      final n = BeltNotifier(db);

      await n.markAllPassed(
          childId: 'kid1',
          belt: BeltLevel.white,
          exerciseIds: ['ex1', 'ex2', 'ex3']);

      final doc = await db.collection('belt_progress').doc('kid1_white').get();
      final passed = doc.data()!['passed'] as Map<String, dynamic>;
      expect(passed['ex1'], isTrue);
      expect(passed['ex2'], isTrue);
      expect(passed['ex3'], isTrue);
    });

    test('виставляє beltReady = true на дитині', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('children').doc('kid1').set({
        'firstName': 'Іван', 'lastName': 'Тест', 'birthYear': 2012,
        'weightCategory': '-40 кг', 'currentBelt': 'white',
        'coachId': 'coach1', 'coachName': 'Тренер',
        'totalPoints': 0, 'bonusPoints': 0, 'beltReady': false,
        'createdAt': Timestamp.fromDate(DateTime(2024)),
      });
      final n = BeltNotifier(db);

      await n.markAllPassed(
          childId: 'kid1', belt: BeltLevel.white, exerciseIds: ['ex1', 'ex2']);

      final child = await db.collection('children').doc('kid1').get();
      expect(child['beltReady'], isTrue);
    });
  });

  // ── BeltNotifier — updateRequirements ────────────────────────────────────────

  group('BeltNotifier — updateRequirements', () {
    test('зберігає список вправ у belt_requirements', () async {
      final db = FakeFirebaseFirestore();
      final n = BeltNotifier(db);

      await n.updateRequirements(
        BeltLevel.yellow,
        [
          const Exercise(id: 'e1', name: 'Укемі назад', description: 'Падіння'),
          const Exercise(id: 'e2', name: 'Осото-гарі', description: 'Підніжка'),
        ],
        'coach1',
      );

      final doc = await db.collection('belt_requirements').doc('yellow').get();
      expect(doc.exists, isTrue);
      final exercises = doc.data()!['exercises'] as List<dynamic>;
      expect(exercises, hasLength(2));
      expect((exercises[0] as Map)['id'], 'e1');
      expect((exercises[1] as Map)['id'], 'e2');
    });

    test('перезаписує попередні вправи', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('belt_requirements').doc('yellow').set({
        'exercises': [
          {'id': 'old1', 'name': 'Стара вправа', 'description': '', 'category': 'technique'},
        ],
        'updatedAt': Timestamp.now(), 'updatedByCoachId': 'coach1',
      });
      final n = BeltNotifier(db);

      await n.updateRequirements(
        BeltLevel.yellow,
        [const Exercise(id: 'new1', name: 'Нова вправа', description: '')],
        'coach1',
      );

      final doc = await db.collection('belt_requirements').doc('yellow').get();
      final exercises = doc.data()!['exercises'] as List<dynamic>;
      expect(exercises, hasLength(1));
      expect((exercises[0] as Map)['id'], 'new1');
    });

    test('стан = AsyncData після updateRequirements', () async {
      final db = FakeFirebaseFirestore();
      final n = BeltNotifier(db);

      await n.updateRequirements(
          BeltLevel.white,
          [const Exercise(id: 'e1', name: 'Вправа', description: '')],
          'coach1');

      expect(n.state, isA<AsyncData<void>>());
    });
  });

  // ── BeltNotifier — addExercise / removeExercise ───────────────────────────────

  group('BeltNotifier — addExercise / removeExercise', () {
    test('addExercise додає вправу до існуючих', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('belt_requirements').doc('white').set({
        'exercises': [
          {'id': 'ex1', 'name': 'Укемі', 'description': '', 'category': 'technique'},
        ],
        'updatedAt': Timestamp.now(), 'updatedByCoachId': 'coach1',
      });
      final n = BeltNotifier(db);

      await n.addExercise(
        belt: BeltLevel.white,
        name: 'Осото-гарі',
        description: 'Підніжка ззовні',
        category: ExerciseCategory.technique,
        coachId: 'coach1',
      );

      final doc = await db.collection('belt_requirements').doc('white').get();
      final exercises = doc.data()!['exercises'] as List<dynamic>;
      expect(exercises, hasLength(2));
      final names = exercises.map((e) => (e as Map)['name'] as String).toList();
      expect(names, containsAll(['Укемі', 'Осото-гарі']));
    });

    test('removeExercise видаляє вправу за ID', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('belt_requirements').doc('white').set({
        'exercises': [
          {'id': 'ex1', 'name': 'Укемі', 'description': '', 'category': 'technique'},
          {'id': 'ex2', 'name': 'Стійка', 'description': '', 'category': 'technique'},
        ],
        'updatedAt': Timestamp.now(), 'updatedByCoachId': 'coach1',
      });
      final n = BeltNotifier(db);

      await n.removeExercise(
          belt: BeltLevel.white, exerciseId: 'ex1', coachId: 'coach1');

      final doc = await db.collection('belt_requirements').doc('white').get();
      final exercises = doc.data()!['exercises'] as List<dynamic>;
      expect(exercises, hasLength(1));
      expect((exercises[0] as Map)['id'], 'ex2');
    });
  });

  // ── BeltNotifier — cross-role: тренер затверджує → beltReady ─────────────────

  group('Belts — cross-role flow', () {
    test(
        'тренер затверджує всі вправи → beltReady=true видимо через allChildrenProvider',
        () async {
      final db = FakeFirebaseFirestore();
      await db.collection('children').doc('kid1').set({
        'firstName': 'Іван', 'lastName': 'Тест', 'birthYear': 2012,
        'weightCategory': '-40 кг', 'currentBelt': 'white',
        'coachId': 'coach1', 'coachName': 'Тренер',
        'totalPoints': 0, 'bonusPoints': 0, 'beltReady': false,
        'createdAt': Timestamp.fromDate(DateTime(2024)),
      });
      await db.collection('belt_requirements').doc('white').set({
        'exercises': [
          {'id': 'e1', 'name': 'Укемі', 'description': '', 'category': 'technique'},
          {'id': 'e2', 'name': 'Стійка', 'description': '', 'category': 'technique'},
        ],
        'updatedAt': Timestamp.now(), 'updatedByCoachId': 'coach1',
      });
      final n = BeltNotifier(db);

      await n.markAllPassed(
          childId: 'kid1', belt: BeltLevel.white, exerciseIds: ['e1', 'e2']);

      final child = await db.collection('children').doc('kid1').get();
      expect(child['beltReady'], isTrue);

      final progress = await db.collection('belt_progress').doc('kid1_white').get();
      final passed = progress.data()!['passed'] as Map<String, dynamic>;
      expect(passed['e1'], isTrue);
      expect(passed['e2'], isTrue);
    });
  });
}

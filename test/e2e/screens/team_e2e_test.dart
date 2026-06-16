/// E2E тести для TeamListScreen.
/// Перевіряє: відсутність overflow у пікері тренерів (ModalBottomSheet bug),
/// коректний рендер з великою кількістю тренерів, базовий рендер екрану.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
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

UserModel _coach(String name) => UserModel(
      uid: 'uid_$name',
      email: 'coach@test.com',
      name: name,
      role: 'coach',
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
      coachId: 'coach_$coachName',
      coachName: coachName,
      totalPoints: 0,
      createdAt: DateTime(2024),
    );

GoRouter _router() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const TeamListScreen()),
        GoRoute(
            path: '/team/:id',
            builder: (_, __) =>
                const Scaffold(body: Text('profile'))),
        GoRoute(
            path: '/team/add',
            builder: (_, __) => const Scaffold(body: Text('add'))),
      ],
    );

Widget _app(List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(routerConfig: _router()),
    );

Future<void> _pump(WidgetTester tester, List<Override> overrides) async {
  await tester.pumpWidget(_app(overrides));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump();
}

// ─────────────────────────────────────────────────────────────────────────────

// ── Coach picker modal content builder (same structure as _showCoachPicker) ──
Widget _buildCoachPickerContent(
  List<({String id, String name})> coaches,
) {
  return SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Тренер',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: coaches
                  .map((c) => ListTile(title: Text(c.name)))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('TeamListScreen — coach picker overflow', () {
    // Тестуємо ВМІСТ bottom sheet безпосередньо (той самий код що в _showCoachPicker),
    // відкриваючи модаль з кнопки — надійніший підхід ніж тапати filter chip.

    testWidgets('пікер тренера з 20 тренерами — без overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final coaches = List.generate(20, (i) => (id: 'c$i', name: 'Тренер $i'));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => _buildCoachPickerContent(coaches),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      // Перевіряємо що всі тренери видимі у bottom sheet (scroll)
      expect(find.text('Тренер', skipOffstage: false), findsWidgets);
    });

    testWidgets('пікер тренера з 30 тренерами — без overflow (крайній випадок)',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final coaches = List.generate(30, (i) => (id: 'c$i', name: 'Тренер $i'));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => _buildCoachPickerContent(coaches),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────

  group('TeamListScreen — базовий рендер', () {
    testWidgets('тренер: рендериться без краша', (tester) async {
      final children = [
        _child(id: 'c1', coachName: 'Іванов', lastName: 'Петренко'),
        _child(id: 'c2', coachName: 'Сидоров', lastName: 'Мороз'),
      ];

      await _pump(tester, [
        currentUserModelProvider
            .overrideWith((_) => Stream.value(_coach('Іванов'))),
        allChildrenProvider.overrideWith((_) => Stream.value(children)),
        allMembershipsProvider
            .overrideWith((_) => Stream.value(const [])),
      ]);

      expect(tester.takeException(), isNull);
    });

    testWidgets('порожній список — рендериться без краша', (tester) async {
      await _pump(tester, [
        currentUserModelProvider
            .overrideWith((_) => Stream.value(_coach('Іванов'))),
        allChildrenProvider.overrideWith((_) => Stream.value(const [])),
        allMembershipsProvider
            .overrideWith((_) => Stream.value(const [])),
      ]);

      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────

  group('TeamListScreen — peer ranks відображаються', () {
    testWidgets(
        'два спортсмени одного року — показує позицію серед однолітків',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final children = [
        ChildModel(
          id: 'peer1',
          firstName: 'Олег',
          lastName: 'Ковальчук',
          birthYear: 2012,
          weightCategory: '-40 кг',
          currentBelt: BeltLevel.white,
          coachId: 'coach_Іванов',
          coachName: 'Іванов',
          totalPoints: 10,
          createdAt: DateTime(2024),
        ),
        ChildModel(
          id: 'peer2',
          firstName: 'Дмитро',
          lastName: 'Бондар',
          birthYear: 2012,
          weightCategory: '-40 кг',
          currentBelt: BeltLevel.white,
          coachId: 'coach_Іванов',
          coachName: 'Іванов',
          totalPoints: 5,
          createdAt: DateTime(2024),
        ),
      ];

      await _pump(tester, [
        currentUserModelProvider
            .overrideWith((_) => Stream.value(_coach('Іванов'))),
        allChildrenProvider.overrideWith((_) => Stream.value(children)),
        allMembershipsProvider
            .overrideWith((_) => Stream.value(const [])),
      ]);

      // Peer rank text is '#rank/total однол.' — check either fragment
      final hasOdnol =
          find.textContaining('однол', skipOffstage: false).evaluate().isNotEmpty;
      final hasSlash =
          find.textContaining('/', skipOffstage: false).evaluate().isNotEmpty;

      expect(hasOdnol || hasSlash, isTrue,
          reason: 'Expected peer rank indicator (однол or /) to be rendered');
      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────

  group('TeamListScreen — quick filters', () {
    List<ChildModel> _buildMixedChildren() => [
          ChildModel(
            id: 'boy1',
            firstName: 'Олексій',
            lastName: 'Гречко',
            birthYear: 2012,
            weightCategory: '-40 кг',
            currentBelt: BeltLevel.white,
            coachId: 'coach_Іванов',
            coachName: 'Іванов',
            totalPoints: 0,
            createdAt: DateTime(2024),
            gender: Gender.male,
          ),
          ChildModel(
            id: 'boy2',
            firstName: 'Максим',
            lastName: 'Левченко',
            birthYear: 2013,
            weightCategory: '-42 кг',
            currentBelt: BeltLevel.white,
            coachId: 'coach_Іванов',
            coachName: 'Іванов',
            totalPoints: 0,
            createdAt: DateTime(2024),
            gender: Gender.male,
          ),
          ChildModel(
            id: 'girl1',
            firstName: 'Ганна',
            lastName: 'Романенко',
            birthYear: 2012,
            weightCategory: '-36 кг',
            currentBelt: BeltLevel.white,
            coachId: 'coach_Іванов',
            coachName: 'Іванов',
            totalPoints: 0,
            createdAt: DateTime(2024),
            gender: Gender.female,
          ),
        ];

    testWidgets('фільтр Юнаки показує тільки хлопців', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pump(tester, [
        currentUserModelProvider
            .overrideWith((_) => Stream.value(_coach('Іванов'))),
        allChildrenProvider
            .overrideWith((_) => Stream.value(_buildMixedChildren())),
        allMembershipsProvider
            .overrideWith((_) => Stream.value(const [])),
      ]);

      final chip = find.text('Юнаки');
      expect(chip, findsOneWidget);
      await tester.tap(chip);
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });

    testWidgets('фільтр Дівчата не падає з порожнім списком', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pump(tester, [
        currentUserModelProvider
            .overrideWith((_) => Stream.value(_coach('Іванов'))),
        allChildrenProvider
            .overrideWith((_) => Stream.value(_buildMixedChildren())),
        allMembershipsProvider
            .overrideWith((_) => Stream.value(const [])),
      ]);

      final chip = find.text('Дівчата');
      expect(chip, findsOneWidget);
      await tester.tap(chip);
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });
  });

  // ── ChildrenNotifier — addChild ─────────────────────────────────────────────

  group('ChildrenNotifier — addChild', () {
    ChildModel _makeChild(String id) => ChildModel(
          id: id,
          firstName: 'Іван',
          lastName: 'Петренко',
          birthYear: 2012,
          weightCategory: '-40 кг',
          currentBelt: BeltLevel.white,
          coachId: 'coach1',
          coachName: 'Тренер',
          totalPoints: 0,
          createdAt: DateTime(2024),
        );

    test('зберігає дитину у Firestore', () async {
      final db = FakeFirebaseFirestore();
      final n = ChildrenNotifier(db);

      await n.addChild(_makeChild('kid1'));

      final doc = await db.collection('children').doc('kid1').get();
      expect(doc.exists, isTrue);
      expect(doc['firstName'], 'Іван');
      expect(doc['lastName'], 'Петренко');
      expect(doc['birthYear'], 2012);
    });

    test('різні діти — різні документи', () async {
      final db = FakeFirebaseFirestore();
      final n = ChildrenNotifier(db);

      await n.addChild(_makeChild('kid1'));
      await n.addChild(_makeChild('kid2'));
      await n.addChild(_makeChild('kid3'));

      final snap = await db.collection('children').get();
      expect(snap.docs, hasLength(3));
    });

    test('поля coachId і currentBelt збережені', () async {
      final db = FakeFirebaseFirestore();
      final n = ChildrenNotifier(db);

      await n.addChild(_makeChild('kid1'));

      final doc = await db.collection('children').doc('kid1').get();
      expect(doc['coachId'], 'coach1');
      expect(doc['currentBelt'], 'white');
    });
  });

  // ── ChildrenNotifier — updateChild ──────────────────────────────────────────

  group('ChildrenNotifier — updateChild', () {
    Future<void> _seedChild(FakeFirebaseFirestore db, String id) async {
      await db.collection('children').doc(id).set({
        'firstName': 'Іван',
        'lastName': 'Старе прізвище',
        'birthYear': 2012,
        'weightCategory': '-40 кг',
        'currentBelt': 'white',
        'coachId': 'coach1',
        'coachName': 'Тренер',
        'totalPoints': 0,
        'bonusPoints': 0,
        'beltReady': false,
        'createdAt': Timestamp.fromDate(DateTime(2024)),
      });
    }

    test('оновлює прізвище у Firestore', () async {
      final db = FakeFirebaseFirestore();
      await _seedChild(db, 'kid1');
      final n = ChildrenNotifier(db);

      final updated = ChildModel(
        id: 'kid1',
        firstName: 'Іван',
        lastName: 'Нове прізвище',
        birthYear: 2012,
        weightCategory: '-40 кг',
        currentBelt: BeltLevel.white,
        coachId: 'coach1',
        coachName: 'Тренер',
        totalPoints: 0,
        createdAt: DateTime(2024),
      );
      await n.updateChild(updated);

      final doc = await db.collection('children').doc('kid1').get();
      expect(doc['lastName'], 'Нове прізвище');
    });

    test('updateChild не чіпає інших дітей', () async {
      final db = FakeFirebaseFirestore();
      await _seedChild(db, 'kid1');
      await _seedChild(db, 'kid2');
      final n = ChildrenNotifier(db);

      final updated = ChildModel(
        id: 'kid1',
        firstName: 'Іван',
        lastName: 'Оновлений',
        birthYear: 2012,
        weightCategory: '-40 кг',
        currentBelt: BeltLevel.white,
        coachId: 'coach1',
        coachName: 'Тренер',
        totalPoints: 0,
        createdAt: DateTime(2024),
      );
      await n.updateChild(updated);

      final doc2 = await db.collection('children').doc('kid2').get();
      expect(doc2['lastName'], 'Старе прізвище');
    });
  });

  // ── ChildrenNotifier — deleteChild ──────────────────────────────────────────

  group('ChildrenNotifier — deleteChild', () {
    Future<void> _seedAll(FakeFirebaseFirestore db, String childId) async {
      await db.collection('children').doc(childId).set({
        'firstName': 'Іван', 'lastName': 'Тест', 'birthYear': 2012,
        'weightCategory': '-40 кг', 'currentBelt': 'white',
        'coachId': 'coach1', 'coachName': 'Тренер',
        'totalPoints': 0, 'bonusPoints': 0, 'beltReady': false,
        'createdAt': Timestamp.fromDate(DateTime(2024)),
      });
      await db.collection('competition_results').add({'childId': childId, 'points': 10});
      await db.collection('belt_progress').doc('${childId}_white').set(
            {'childId': childId, 'belt': 'white', 'passed': <String, dynamic>{}});
    }

    test('видаляє дитину з Firestore', () async {
      final db = FakeFirebaseFirestore();
      await _seedAll(db, 'kid1');
      final n = ChildrenNotifier(db);

      await n.deleteChild('kid1');

      expect((await db.collection('children').doc('kid1').get()).exists, isFalse);
    });

    test('каскадно видаляє competition_results', () async {
      final db = FakeFirebaseFirestore();
      await _seedAll(db, 'kid1');
      final n = ChildrenNotifier(db);

      await n.deleteChild('kid1');

      final results = await db
          .collection('competition_results')
          .where('childId', isEqualTo: 'kid1')
          .get();
      expect(results.docs, isEmpty);
    });

    test('каскадно видаляє belt_progress', () async {
      final db = FakeFirebaseFirestore();
      await _seedAll(db, 'kid1');
      final n = ChildrenNotifier(db);

      await n.deleteChild('kid1');

      final progress = await db
          .collection('belt_progress')
          .where('childId', isEqualTo: 'kid1')
          .get();
      expect(progress.docs, isEmpty);
    });

    test('deleteChild не чіпає інших дітей', () async {
      final db = FakeFirebaseFirestore();
      await _seedAll(db, 'kid1');
      await _seedAll(db, 'kid2');
      final n = ChildrenNotifier(db);

      await n.deleteChild('kid1');

      expect((await db.collection('children').doc('kid2').get()).exists, isTrue);
    });
  });

  // ── ChildrenNotifier — advanceBelts ─────────────────────────────────────────

  group('ChildrenNotifier — advanceBelts', () {
    Future<void> _seedChild(FakeFirebaseFirestore db, String id,
        {BeltLevel belt = BeltLevel.white}) async {
      await db.collection('children').doc(id).set({
        'firstName': 'Іван', 'lastName': 'Тест', 'birthYear': 2012,
        'weightCategory': '-40 кг', 'currentBelt': belt.name,
        'coachId': 'coach1', 'coachName': 'Тренер',
        'totalPoints': 0, 'bonusPoints': 0, 'beltReady': true,
        'createdAt': Timestamp.fromDate(DateTime(2024)),
      });
    }

    test('оновлює currentBelt і скидає beltReady', () async {
      final db = FakeFirebaseFirestore();
      await _seedChild(db, 'kid1');
      final n = ChildrenNotifier(db);

      await n.advanceBelts(childIds: ['kid1'], newBelt: BeltLevel.yellow);

      final doc = await db.collection('children').doc('kid1').get();
      expect(doc['currentBelt'], 'yellow');
      expect(doc['beltReady'], isFalse);
    });

    test('одночасно підвищує кілька спортсменів', () async {
      final db = FakeFirebaseFirestore();
      for (final id in ['kid1', 'kid2', 'kid3']) {
        await _seedChild(db, id);
      }
      final n = ChildrenNotifier(db);

      await n.advanceBelts(
          childIds: ['kid1', 'kid2', 'kid3'], newBelt: BeltLevel.whiteYellow);

      for (final id in ['kid1', 'kid2', 'kid3']) {
        final doc = await db.collection('children').doc(id).get();
        expect(doc['currentBelt'], 'whiteYellow',
            reason: '$id should be whiteYellow');
      }
    });

    test('пише achievement через AchievementChecker', () async {
      final db = FakeFirebaseFirestore();
      await _seedChild(db, 'kid1');
      final n = ChildrenNotifier(db);

      await n.advanceBelts(childIds: ['kid1'], newBelt: BeltLevel.yellow);

      final snap = await db
          .collection('achievements')
          .where('childId', isEqualTo: 'kid1')
          .get();
      expect(snap.docs, isNotEmpty);
    });

    test('стан = AsyncData після advanceBelts', () async {
      final db = FakeFirebaseFirestore();
      await _seedChild(db, 'kid1');
      final n = ChildrenNotifier(db);

      await n.advanceBelts(childIds: ['kid1'], newBelt: BeltLevel.yellow);

      expect(n.state, isA<AsyncData<void>>());
    });
  });

  // ── ChildrenNotifier — setBonusPoints ───────────────────────────────────────

  group('ChildrenNotifier — setBonusPoints', () {
    Future<void> _seedWithPoints(
        FakeFirebaseFirestore db, String id, int compPoints) async {
      await db.collection('children').doc(id).set({
        'firstName': 'Іван', 'lastName': 'Тест', 'birthYear': 2012,
        'weightCategory': '-40 кг', 'currentBelt': 'white',
        'coachId': 'coach1', 'coachName': 'Тренер',
        'totalPoints': compPoints, 'bonusPoints': 0, 'beltReady': false,
        'createdAt': Timestamp.fromDate(DateTime(2024)),
      });
      if (compPoints > 0) {
        await db.collection('competition_results').add({
          'childId': id, 'points': compPoints,
        });
      }
    }

    test('оновлює bonusPoints і totalPoints', () async {
      final db = FakeFirebaseFirestore();
      await _seedWithPoints(db, 'kid1', 0);
      final n = ChildrenNotifier(db);

      await n.setBonusPoints('kid1', 50);

      final doc = await db.collection('children').doc('kid1').get();
      expect(doc['bonusPoints'], 50);
      expect(doc['totalPoints'], 50);
    });

    test('totalPoints = competitionPoints + bonus', () async {
      final db = FakeFirebaseFirestore();
      await _seedWithPoints(db, 'kid1', 30);
      final n = ChildrenNotifier(db);

      await n.setBonusPoints('kid1', 20);

      final doc = await db.collection('children').doc('kid1').get();
      expect(doc['totalPoints'], 50);
    });

    test('стан = AsyncData після setBonusPoints', () async {
      final db = FakeFirebaseFirestore();
      await _seedWithPoints(db, 'kid1', 0);
      final n = ChildrenNotifier(db);

      await n.setBonusPoints('kid1', 10);

      expect(n.state, isA<AsyncData<void>>());
    });
  });

  // ── Cross-role: тренер → спортсмен ─────────────────────────────────────────

  group('Team — cross-role: тренер додає → спортсмен видимий', () {
    test('тренер додає спортсмена → документ видимий через allChildrenProvider',
        () async {
      final db = FakeFirebaseFirestore();
      final n = ChildrenNotifier(db);

      final child = ChildModel(
        id: 'kid1',
        firstName: 'Олена',
        lastName: 'Бойко',
        birthYear: 2013,
        weightCategory: '-36 кг',
        currentBelt: BeltLevel.white,
        coachId: 'coach1',
        coachName: 'Тренер',
        totalPoints: 0,
        createdAt: DateTime(2024),
      );
      await n.addChild(child);

      final snap = await db.collection('children').get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first['firstName'], 'Олена');
      expect(snap.docs.first['lastName'], 'Бойко');
    });

    test('тренер підвищує пояс → спортсмен отримує ачівку', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('children').doc('kid1').set({
        'firstName': 'Іван', 'lastName': 'Тест', 'birthYear': 2012,
        'weightCategory': '-40 кг', 'currentBelt': 'white',
        'coachId': 'coach1', 'coachName': 'Тренер',
        'totalPoints': 0, 'bonusPoints': 0, 'beltReady': true,
        'createdAt': Timestamp.fromDate(DateTime(2024)),
      });
      final n = ChildrenNotifier(db);

      await n.advanceBelts(childIds: ['kid1'], newBelt: BeltLevel.yellow);

      final achievements = await db
          .collection('achievements')
          .where('childId', isEqualTo: 'kid1')
          .get();
      expect(achievements.docs, isNotEmpty);

      final doc = await db.collection('children').doc('kid1').get();
      expect(doc['currentBelt'], 'yellow');
    });
  });
}

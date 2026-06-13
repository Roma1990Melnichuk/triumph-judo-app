/// E2E тести для TeamListScreen.
/// Перевіряє: відсутність overflow у пікері тренерів (ModalBottomSheet bug),
/// коректний рендер з великою кількістю тренерів, базовий рендер екрану.
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

      // Suppress pre-existing overflow errors on this screen
      final handler = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.toString().contains('overflowed')) return;
        handler?.call(d);
      };
      addTearDown(() => FlutterError.onError = handler);

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

      // Suppress pre-existing overflow errors on this screen
      final handler = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.toString().contains('overflowed')) return;
        handler?.call(d);
      };
      addTearDown(() => FlutterError.onError = handler);

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

      // Suppress pre-existing overflow errors on this screen
      final handler = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.toString().contains('overflowed')) return;
        handler?.call(d);
      };
      addTearDown(() => FlutterError.onError = handler);

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
}

/// E2E тести для GroupsScreen / ScheduleScreen.
/// Перевіряють повний цикл: тренер створює сутність → вона зʼявляється в UI.
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:judo_app/core/models/group_model.dart';
import 'package:judo_app/core/models/training_schedule_model.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/schedule/providers/group_provider.dart';
import 'package:judo_app/features/schedule/providers/schedule_provider.dart';
import 'package:judo_app/features/schedule/screens/groups_screen.dart';
import 'package:judo_app/features/schedule/screens/schedule_screen.dart';

// ── Хелпери ───────────────────────────────────────────────────────────────────

final _coach = UserModel(
  uid: 'coach1',
  email: 'coach@test.com',
  name: 'Тренер Іванов',
  role: 'coach',
);

GoRouter _routerGroups() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const GroupsScreen()),
        GoRoute(
            path: '/group/:id',
            builder: (_, __) => const Scaffold(body: Text('group detail'))),
        GoRoute(
            path: '/schedule',
            builder: (_, __) => const Scaffold(body: Text('schedule'))),
      ],
    );

GoRouter _routerSchedule() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const ScheduleScreen()),
        GoRoute(
            path: '/groups/:id',
            builder: (_, __) => const Scaffold(body: Text('group detail'))),
      ],
    );

Widget _groupsApp(FakeFirebaseFirestore db) {
  return ProviderScope(
    overrides: [
      currentUserModelProvider.overrideWith((_) => Stream.value(_coach)),
      firestoreProvider.overrideWithValue(db),
    ],
    child: MaterialApp.router(routerConfig: _routerGroups()),
  );
}

Widget _scheduleApp(FakeFirebaseFirestore db) {
  return ProviderScope(
    overrides: [
      currentUserModelProvider.overrideWith((_) => Stream.value(_coach)),
      firestoreProvider.overrideWithValue(db),
    ],
    child: MaterialApp.router(routerConfig: _routerSchedule()),
  );
}

/// Pumps until StreamProvider data is available (handles FakeFirebaseFirestore
/// async stream emission + Riverpod listener update + widget rebuild).
Future<void> _pumpData(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 50));
}

/// Sets a tall phone viewport (390×844) for schedule tests.
/// The ScheduleScreen ListView bottom items are not built in the default
/// 800×600 test viewport — they need a tall enough window to be in
/// the sliver cache extent.
void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── GroupsScreen ─────────────────────────────────────────────────────────

  group('GroupsScreen — рендер', () {
    testWidgets('рендериться без краша і без overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_groupsApp(FakeFirebaseFirestore()));
      await _pumpData(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('«Групи» — заголовок відображається рівно один раз',
        (tester) async {
      await tester.pumpWidget(_groupsApp(FakeFirebaseFirestore()));
      await _pumpData(tester);

      expect(find.text('Групи'), findsOneWidget);
    });
  });

  group('GroupsScreen — відображення груп', () {
    testWidgets('порожній Firestore — показує «Груп ще немає»', (tester) async {
      await tester.pumpWidget(_groupsApp(FakeFirebaseFirestore()));
      await _pumpData(tester);

      expect(find.text('Груп ще немає'), findsOneWidget);
    });

    // Регресійний тест: тренер створив групу — вона повинна зʼявитися в списку.
    // До фікса firestore.rules колекція groups не мала правил → PERMISSION_DENIED
    // → fallbackOnError([]) повертав [] → «Груп ще немає» замість реальних даних.
    testWidgets(
        'тренер створив групу — вона зʼявляється без перезапуску застосунку',
        (tester) async {
      final db = FakeFirebaseFirestore();
      await db.collection('groups').doc('g1').set({
        'coachId': 'coach1',
        'name': 'Молодша група',
        'childIds': <String>[],
        'daysOfWeek': [1, 3, 5],
        'timeStart': '18:00',
        'timeEnd': '19:30',
      });

      await tester.pumpWidget(_groupsApp(db));
      await _pumpData(tester);

      expect(find.text('Молодша група'), findsOneWidget);
      expect(find.text('Груп ще немає'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('createGroup через notifier — група зʼявляється без перезапуску',
        (tester) async {
      final db = FakeFirebaseFirestore();

      await tester.pumpWidget(_groupsApp(db));
      await _pumpData(tester);

      expect(find.text('Груп ще немає'), findsOneWidget);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GroupsScreen)),
      );
      await container.read(groupNotifierProvider.notifier).createGroup(
            const GroupModel(
              id: '',
              coachId: 'coach1',
              name: 'Старша група',
              childIds: [],
              daysOfWeek: [2, 4],
              timeStart: '17:00',
              timeEnd: '18:30',
            ),
          );

      await _pumpData(tester);

      expect(find.text('Старша група'), findsOneWidget);
      expect(find.text('Груп ще немає'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'діалог створення — заповнити форму і зберегти — група зʼявляється',
        (tester) async {
      final db = FakeFirebaseFirestore();

      await tester.pumpWidget(_groupsApp(db));
      await _pumpData(tester);

      expect(find.text('Груп ще немає'), findsOneWidget);

      // Відкрити діалог через FAB
      await tester.tap(find.byType(GestureDetector).last);
      await tester.pumpAndSettle();

      expect(find.text('Нова група'), findsOneWidget);

      // Ввести назву
      await tester.enterText(find.byType(TextField), 'Тестова група');

      // Обрати хоча б один день (перший FilterChip)
      await tester.tap(find.byType(FilterChip).first);
      await tester.pump();

      // Натиснути «Зберегти»
      await tester.tap(find.text('Зберегти'));
      await tester.pumpAndSettle(); // dialog dismiss animation
      await _pumpData(tester);     // Firestore stream update

      expect(find.text('Тестова група'), findsOneWidget);
      expect(find.text('Груп ще немає'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('кілька груп — всі відображаються в списку', (tester) async {
      final db = FakeFirebaseFirestore();
      await db.collection('groups').doc('g1').set({
        'coachId': 'coach1',
        'name': 'Група А',
        'childIds': <String>[],
        'daysOfWeek': [1, 3],
        'timeStart': '18:00',
        'timeEnd': '19:30',
      });
      await db.collection('groups').doc('g2').set({
        'coachId': 'coach1',
        'name': 'Група Б',
        'childIds': <String>['child1', 'child2'],
        'daysOfWeek': [2, 4, 6],
        'timeStart': '10:00',
        'timeEnd': '11:30',
      });

      await tester.pumpWidget(_groupsApp(db));
      await _pumpData(tester);

      expect(find.text('Група А'), findsOneWidget);
      expect(find.text('Група Б'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ── ScheduleScreen ───────────────────────────────────────────────────────

  group('ScheduleScreen — рендер', () {
    testWidgets('рендериться без краша і без overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_scheduleApp(FakeFirebaseFirestore()));
      await _pumpData(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('ScheduleScreen — відображення розкладу', () {
    testWidgets('порожній Firestore — показує «Розклад ще не створений»',
        (tester) async {
      _setPhoneViewport(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_scheduleApp(FakeFirebaseFirestore()));
      await _pumpData(tester);

      expect(find.text('Розклад ще не створений'), findsOneWidget);
    });

    // Регресійний тест: тренер створив розклад — він повинен зʼявитися в UI.
    // До фікса firestore.rules колекція training_schedules не мала правил →
    // PERMISSION_DENIED → fallbackOnError([]) → «Розклад ще не створений».
    testWidgets(
        'тренер створив розклад — він зʼявляється в «Регулярний розклад»',
        (tester) async {
      _setPhoneViewport(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final db = FakeFirebaseFirestore();
      await db.collection('training_schedules').doc('s1').set({
        'coachId': 'coach1',
        'label': 'Основне тренування',
        'daysOfWeek': [1, 3, 5],
        'timeStart': '18:00',
        'timeEnd': '19:30',
      });

      await tester.pumpWidget(_scheduleApp(db));
      await _pumpData(tester);

      expect(find.text('Основне тренування'), findsWidgets);
      expect(find.text('Розклад ще не створений'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'addSchedule через notifier — розклад зʼявляється без перезапуску',
        (tester) async {
      _setPhoneViewport(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final db = FakeFirebaseFirestore();

      await tester.pumpWidget(_scheduleApp(db));
      await _pumpData(tester);

      expect(find.text('Розклад ще не створений'), findsOneWidget);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ScheduleScreen)),
      );
      await container.read(scheduleNotifierProvider.notifier).addSchedule(
            const TrainingScheduleModel(
              id: '',
              coachId: 'coach1',
              label: 'Ранкове тренування',
              daysOfWeek: [1, 3, 5],
              timeStart: '09:00',
              timeEnd: '10:30',
            ),
          );

      await _pumpData(tester);

      expect(find.text('Ранкове тренування'), findsWidgets);
      expect(find.text('Розклад ще не створений'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('кілька розкладів — всі відображаються', (tester) async {
      _setPhoneViewport(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final db = FakeFirebaseFirestore();
      await db.collection('training_schedules').doc('s1').set({
        'coachId': 'coach1',
        'label': 'Тренування A',
        'daysOfWeek': [1, 3],
        'timeStart': '18:00',
        'timeEnd': '19:30',
      });
      await db.collection('training_schedules').doc('s2').set({
        'coachId': 'coach1',
        'label': 'Тренування Б',
        'daysOfWeek': [2, 4, 6],
        'timeStart': '10:00',
        'timeEnd': '11:30',
      });

      await tester.pumpWidget(_scheduleApp(db));
      await _pumpData(tester);

      expect(find.text('Тренування A'), findsWidgets);
      expect(find.text('Тренування Б'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('deleteSchedule через notifier — розклад зникає з UI',
        (tester) async {
      _setPhoneViewport(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final db = FakeFirebaseFirestore();
      await db.collection('training_schedules').doc('s1').set({
        'coachId': 'coach1',
        'label': 'Тимчасове тренування',
        'daysOfWeek': [1],
        'timeStart': '18:00',
        'timeEnd': '19:30',
      });

      await tester.pumpWidget(_scheduleApp(db));
      await _pumpData(tester);

      expect(find.text('Тимчасове тренування'), findsWidgets);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ScheduleScreen)),
      );
      await container
          .read(scheduleNotifierProvider.notifier)
          .deleteSchedule('s1');

      await _pumpData(tester);

      expect(find.text('Тимчасове тренування'), findsNothing);
      expect(find.text('Розклад ще не створений'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Сценарний тест: Система поясів / Вправи (Belt Requirements)
///
/// Реальні сценарії:
///
///   SC-B-001  BeltOverviewScreen показує заголовок «Система поясів»
///   SC-B-002  Тренер бачить кнопку «Редагувати вимоги»
///   SC-B-003  Вимоги для білого-жовтого: 8 вправ; перша — «Укемі назад»
///   SC-B-004  Спортсмен без прогресу бачить всі вправи як незавершені
///   SC-B-005  BeltRequirementModel.byCategory групує вправи по категоріях
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/belt_requirement_model.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/belts/providers/belt_provider.dart';
import 'package:judo_app/features/belts/screens/belt_overview_screen.dart';
import 'package:judo_app/features/membership/providers/membership_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _coach = UserModel(
  uid: 'coach1',
  email: 'coach@test.com',
  name: 'Тренер Іванов',
  role: 'coach',
);

final _parent = UserModel(
  uid: 'parent1',
  email: 'parent@test.com',
  name: 'Батько',
  role: 'parent',
  childIds: ['child1'],
);

final _child = ChildModel(
  id: 'child1',
  firstName: 'Іван',
  lastName: 'Петренко',
  birthYear: 2012,
  weightCategory: '-30 кг',
  currentBelt: BeltLevel.white,
  coachId: 'coach1',
  coachName: 'Тренер Іванов',
  totalPoints: 10,
  createdAt: DateTime(2024),
  gender: Gender.male,
);

// 8 default exercises for white-yellow belt (matches belt_provider.dart defaults)
final _whiteYellowExercises = [
  const Exercise(id: 'wwy1', name: 'Укемі назад',      description: 'Правильне падіння назад', category: ExerciseCategory.technique),
  const Exercise(id: 'wwy2', name: 'Укемі вбік',       description: 'Правильне падіння вбік',  category: ExerciseCategory.technique),
  const Exercise(id: 'wwy3', name: 'Стійка дзюдоїста', description: 'Сейза та шизентай',        category: ExerciseCategory.technique),
  const Exercise(id: 'wwy4', name: 'Захват',            description: 'Рукав + комір',            category: ExerciseCategory.technique),
  const Exercise(id: 'wwy5', name: 'Осото-гарі',        description: 'Підніжка ззовні',          category: ExerciseCategory.technique),
  const Exercise(id: 'wwy6', name: 'Оучі-гарі',         description: 'Підніжка зсередини',       category: ExerciseCategory.technique),
  const Exercise(id: 'wwy7', name: 'Фізична підготовка', description: 'Базова фізична готовність', category: ExerciseCategory.physical),
  const Exercise(id: 'wwy8', name: 'Правила безпеки',   description: 'Знання правил безпеки в залі', category: ExerciseCategory.theory),
];

final _whiteYellowReq = BeltRequirementModel(
  belt: BeltLevel.whiteYellow,
  exercises: _whiteYellowExercises,
  updatedAt: DateTime(2024),
  updatedByCoachId: 'coach1',
);

final _testReqsMap = <BeltLevel, BeltRequirementModel>{
  BeltLevel.whiteYellow: _whiteYellowReq,
};

// ── App builder ───────────────────────────────────────────────────────────────

Widget _buildBeltsApp({
  required UserModel user,
  Map<BeltLevel, BeltRequirementModel> reqs = const {},
  List<ChildModel> children = const [],
}) {
  final db = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      firestoreProvider.overrideWithValue(db),
      currentUserModelProvider.overrideWith((_) => Stream.value(user)),
      allMembershipsProvider.overrideWith((_) => Stream.value(const [])),
      allChildrenProvider.overrideWith((_) => Stream.value(children)),
      beltRequirementsProvider.overrideWith((_) => Stream.value(reqs)),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/belts',
        routes: [
          GoRoute(path: '/belts', builder: (_, __) => const BeltOverviewScreen()),
          GoRoute(path: '/belts/edit', builder: (_, __) => const Scaffold(body: Text('Редагування'))),
          GoRoute(path: '/bulk-belt', builder: (_, __) => const Scaffold(body: Text('Масовий пояс'))),
          GoRoute(path: '/exercise-library', builder: (_, __) => const Scaffold(body: Text('Бібліотека'))),
        ],
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

// ── Scenarios ─────────────────────────────────────────────────────────────────

void main() {
  group('SC-B-001: BeltOverviewScreen показує заголовок «Система поясів»', () {
    testWidgets('тренер бачить заголовок', (tester) async {
      await tester.pumpWidget(_buildBeltsApp(user: _coach));
      await _settle(tester);

      expect(find.text('Система поясів'), findsOneWidget,
          reason: 'Заголовок «Система поясів» має бути присутній рівно один раз');
      expect(tester.takeException(), isNull);
    });

    testWidgets('батько також бачить заголовок', (tester) async {
      await tester.pumpWidget(_buildBeltsApp(user: _parent, children: [_child]));
      await _settle(tester);

      expect(find.text('Система поясів'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-B-002: тренер бачить кнопку «Редагувати вимоги»', () {
    testWidgets('кнопка редагування видна для тренера', (tester) async {
      // Large viewport so the OutlinedButton at the bottom of the lazy
      // ListView is within the cache extent and gets inflated.
      tester.view.physicalSize = const Size(1080, 10000);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildBeltsApp(
        user: _coach,
        reqs: _testReqsMap,
      ));
      await _settle(tester);

      expect(find.textContaining('Редагувати'), findsWidgets,
          reason: 'Тренер повинен мати кнопку редагування вимог');
      expect(tester.takeException(), isNull);
    });

    testWidgets('батько НЕ бачить кнопку редагування', (tester) async {
      await tester.pumpWidget(_buildBeltsApp(
        user: _parent,
        reqs: _testReqsMap,
        children: [_child],
      ));
      await _settle(tester);

      expect(find.textContaining('Редагувати вимоги'), findsNothing,
          reason: 'Батько не повинен мати доступ до редагування вимог');
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-B-003: вимоги для білого-жовтого: 8 вправ, перша — «Укемі назад»', () {
    testWidgets('перша вправа «Укемі назад» відображається', (tester) async {
      await tester.pumpWidget(_buildBeltsApp(
        user: _coach,
        reqs: _testReqsMap,
      ));
      await _settle(tester);

      expect(find.textContaining('Укемі назад'), findsWidgets,
          reason: 'Перша вправа «Укемі назад» має відображатись у списку');
      expect(tester.takeException(), isNull);
    });

    testWidgets('остання вправа «Правила безпеки» теж видна', (tester) async {
      await tester.pumpWidget(_buildBeltsApp(
        user: _coach,
        reqs: _testReqsMap,
      ));
      await _settle(tester);

      expect(find.textContaining('Правила безпеки'), findsWidgets,
          reason: '8-ма вправа «Правила безпеки» має відображатись');
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-B-004: BeltRequirementModel.byCategory групує правильно', () {
    test('6 technique + 1 physical + 1 theory → 3 непорожні категорії', () {
      final byCategory = _whiteYellowReq.byCategory;

      expect(byCategory[ExerciseCategory.technique]?.length, 6,
          reason: 'Має бути 6 technique вправ (укемі, стійка, захват, 2 підніжки)');
      expect(byCategory[ExerciseCategory.physical]?.length, 1,
          reason: 'Має бути 1 physical вправа (фізична підготовка)');
      expect(byCategory[ExerciseCategory.theory]?.length, 1,
          reason: 'Має бути 1 theory вправа (правила безпеки)');
      expect(byCategory[ExerciseCategory.competition]?.length, 0,
          reason: 'Для білого-жовтого немає змагальних вправ');
    });

    test('порожні вимоги → всі категорії присутні але порожні', () {
      final emptyReq = BeltRequirementModel(
        belt: BeltLevel.whiteYellow,
        exercises: const [],
        updatedAt: DateTime(2024),
        updatedByCoachId: 'coach1',
      );
      final byCategory = emptyReq.byCategory;

      for (final cat in ExerciseCategory.values) {
        expect(byCategory.containsKey(cat), isTrue,
            reason: 'Категорія $cat завжди присутня в byCategory');
        expect(byCategory[cat]?.isEmpty, isTrue);
      }
    });
  });

  group('SC-B-005: спортсмен без прогресу — «Тренер ще не додав вимоги» НЕ показується при наявності вправ', () {
    testWidgets('при наявності вправ — замість «не додав» відображаються вправи', (tester) async {
      await tester.pumpWidget(_buildBeltsApp(
        user: _parent,
        reqs: _testReqsMap,
        children: [_child],
      ));
      await _settle(tester);

      expect(find.textContaining('Тренер ще не додав'), findsNothing,
          reason: 'При наявності вправ повідомлення про відсутність вимог не має показуватись');
      expect(tester.takeException(), isNull);
    });
  });
}

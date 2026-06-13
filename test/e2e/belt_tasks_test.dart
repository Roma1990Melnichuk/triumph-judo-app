/// TC-BELT-001..TC-BELT-004 — Belt task management + beltReady logic
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/belt_requirement_model.dart';
import 'package:judo_app/features/belts/providers/belt_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<BeltNotifier> _notifier(FakeFirebaseFirestore db) async {
  return BeltNotifier(db);
}

Future<bool?> _beltReady(FakeFirebaseFirestore db, String childId) async {
  final snap = await db.collection('children').doc(childId).get();
  return snap.data()?['beltReady'] as bool?;
}

Future<List<Map<String, dynamic>>> _exercises(
    FakeFirebaseFirestore db, BeltLevel belt) async {
  final snap =
      await db.collection('belt_requirements').doc(belt.name).get();
  return (snap.data()?['exercises'] as List<dynamic>? ?? [])
      .cast<Map<String, dynamic>>();
}

// ── TC-BELT-001 ───────────────────────────────────────────────────────────────

void main() {
  group('TC-BELT-001: тренер додає завдання до категорій поясу', () {
    test('завдання додається до Фізична підготовка', () async {
      final db = FakeFirebaseFirestore();
      final n = await _notifier(db);

      await n.addExercise(
        belt: BeltLevel.whiteYellow,
        name: 'Присідання 30 разів',
        description: 'Рівно, повна амплітуда',
        category: ExerciseCategory.physical,
        coachId: 'coach1',
      );

      final exs = await _exercises(db, BeltLevel.whiteYellow);
      expect(exs.length, equals(1));
      expect(exs.first['name'], equals('Присідання 30 разів'));
      expect(exs.first['category'], equals('physical'));
    });

    test('завдання додається до Теорія', () async {
      final db = FakeFirebaseFirestore();
      final n = await _notifier(db);

      await n.addExercise(
        belt: BeltLevel.whiteYellow,
        name: 'Знання японських назв кидків',
        description: '',
        category: ExerciseCategory.theory,
        coachId: 'coach1',
      );

      final exs = await _exercises(db, BeltLevel.whiteYellow);
      expect(exs.first['category'], equals('theory'));
    });

    test('завдання додається до Змагання', () async {
      final db = FakeFirebaseFirestore();
      final n = await _notifier(db);

      await n.addExercise(
        belt: BeltLevel.whiteYellow,
        name: 'Участь у змаганнях районного рівня',
        description: 'Мінімум 1 змагання',
        category: ExerciseCategory.competition,
        coachId: 'coach1',
      );

      final exs = await _exercises(db, BeltLevel.whiteYellow);
      expect(exs.first['category'], equals('competition'));
    });

    test('декілька завдань у різних категоріях накопичуються', () async {
      final db = FakeFirebaseFirestore();
      final n = await _notifier(db);

      await n.addExercise(
        belt: BeltLevel.yellow,
        name: 'Фіз.завдання 1',
        description: '',
        category: ExerciseCategory.physical,
        coachId: 'coach1',
      );
      await n.addExercise(
        belt: BeltLevel.yellow,
        name: 'Фіз.завдання 2',
        description: '',
        category: ExerciseCategory.physical,
        coachId: 'coach1',
      );
      await n.addExercise(
        belt: BeltLevel.yellow,
        name: 'Теорія 1',
        description: '',
        category: ExerciseCategory.theory,
        coachId: 'coach1',
      );

      final exs = await _exercises(db, BeltLevel.yellow);
      expect(exs.length, equals(3));
      expect(
          exs.where((e) => e['category'] == 'physical').length, equals(2));
      expect(
          exs.where((e) => e['category'] == 'theory').length, equals(1));
    });
  });

  // ── TC-BELT-002 ─────────────────────────────────────────────────────────────

  group('TC-BELT-002: beltReady=false поки не всі завдання виконані', () {
    test('одне невиконане завдання → beltReady=false', () async {
      final db = FakeFirebaseFirestore();
      final n = await _notifier(db);

      // Add 2 exercises across different categories
      await n.addExercise(
        belt: BeltLevel.whiteYellow,
        name: 'Техніка 1',
        description: '',
        category: ExerciseCategory.technique,
        coachId: 'coach1',
      );
      await n.addExercise(
        belt: BeltLevel.whiteYellow,
        name: 'Фізпідготовка 1',
        description: '',
        category: ExerciseCategory.physical,
        coachId: 'coach1',
      );

      // Set up child
      await db.collection('children').doc('child1').set({'name': 'Тест'});

      // Pass only the first exercise
      final exs = await _exercises(db, BeltLevel.whiteYellow);
      await n.toggleExercise(
        childId: 'child1',
        belt: BeltLevel.whiteYellow,
        exerciseId: exs[0]['id'] as String,
        passed: true,
      );

      // Second exercise not passed → not ready
      expect(await _beltReady(db, 'child1'), isFalse);
    });

    test('порожній прогрес → beltReady=false', () async {
      final db = FakeFirebaseFirestore();
      final n = await _notifier(db);

      await n.addExercise(
        belt: BeltLevel.yellow,
        name: 'Кидок 1',
        description: '',
        category: ExerciseCategory.technique,
        coachId: 'coach1',
      );
      await db.collection('children').doc('child1').set({'name': 'Тест'});

      // No toggleExercise called at all → child doc has no beltReady field
      final ready = await _beltReady(db, 'child1');
      expect(ready, isNull); // field not set yet — means not ready
    });
  });

  // ── TC-BELT-003 ─────────────────────────────────────────────────────────────

  group('TC-BELT-003: beltReady=true тільки коли ВСІ завдання виконані', () {
    test('2 завдання в різних категоріях — обидва пройдено → beltReady=true',
        () async {
      final db = FakeFirebaseFirestore();
      final n = await _notifier(db);

      await n.addExercise(
        belt: BeltLevel.whiteYellow,
        name: 'Техніка А',
        description: '',
        category: ExerciseCategory.technique,
        coachId: 'coach1',
      );
      await n.addExercise(
        belt: BeltLevel.whiteYellow,
        name: 'Фізпідготовка А',
        description: '',
        category: ExerciseCategory.physical,
        coachId: 'coach1',
      );
      await db.collection('children').doc('child1').set({'name': 'Тест'});

      final exs = await _exercises(db, BeltLevel.whiteYellow);
      for (final ex in exs) {
        await n.toggleExercise(
          childId: 'child1',
          belt: BeltLevel.whiteYellow,
          exerciseId: ex['id'] as String,
          passed: true,
        );
      }

      expect(await _beltReady(db, 'child1'), isTrue);
    });

    test('4 завдання в 4 категоріях — всі пройдено → beltReady=true',
        () async {
      final db = FakeFirebaseFirestore();
      final n = await _notifier(db);

      for (final cat in ExerciseCategory.values) {
        await n.addExercise(
          belt: BeltLevel.yellow,
          name: 'Завдання ${cat.name}',
          description: '',
          category: cat,
          coachId: 'coach1',
        );
      }
      await db.collection('children').doc('child1').set({'name': 'Тест'});

      final exs = await _exercises(db, BeltLevel.yellow);
      expect(exs.length, equals(4));

      for (final ex in exs) {
        await n.toggleExercise(
          childId: 'child1',
          belt: BeltLevel.yellow,
          exerciseId: ex['id'] as String,
          passed: true,
        );
      }

      expect(await _beltReady(db, 'child1'), isTrue);
    });
  });

  // ── TC-BELT-004 ─────────────────────────────────────────────────────────────

  group(
      'TC-BELT-004: нове завдання скидає beltReady поки не пройдено', () {
    test('додавання нового завдання після повного виконання → beltReady=false',
        () async {
      final db = FakeFirebaseFirestore();
      final n = await _notifier(db);

      // Add 1 exercise and pass it
      await n.addExercise(
        belt: BeltLevel.orange,
        name: 'Перше завдання',
        description: '',
        category: ExerciseCategory.technique,
        coachId: 'coach1',
      );
      await db.collection('children').doc('child1').set({'name': 'Тест'});

      final exs1 = await _exercises(db, BeltLevel.orange);
      await n.toggleExercise(
        childId: 'child1',
        belt: BeltLevel.orange,
        exerciseId: exs1[0]['id'] as String,
        passed: true,
      );
      expect(await _beltReady(db, 'child1'), isTrue);

      // Now add a second exercise (not yet passed)
      await n.addExercise(
        belt: BeltLevel.orange,
        name: 'Нове завдання',
        description: '',
        category: ExerciseCategory.physical,
        coachId: 'coach1',
      );

      // Sync readiness manually (simulates what coach toggle would do)
      await n.syncBeltReady('child1', BeltLevel.orange);

      // Second task not passed → no longer ready
      expect(await _beltReady(db, 'child1'), isFalse);
    });

    test('після виконання нового завдання → beltReady=true знову', () async {
      final db = FakeFirebaseFirestore();
      final n = await _notifier(db);

      await n.addExercise(
        belt: BeltLevel.orange,
        name: 'Завдання 1',
        description: '',
        category: ExerciseCategory.technique,
        coachId: 'coach1',
      );
      await n.addExercise(
        belt: BeltLevel.orange,
        name: 'Завдання 2',
        description: '',
        category: ExerciseCategory.physical,
        coachId: 'coach1',
      );
      await db.collection('children').doc('child1').set({'name': 'Тест'});

      final exs = await _exercises(db, BeltLevel.orange);

      // Pass only the first
      await n.toggleExercise(
        childId: 'child1',
        belt: BeltLevel.orange,
        exerciseId: exs[0]['id'] as String,
        passed: true,
      );
      expect(await _beltReady(db, 'child1'), isFalse);

      // Pass the second → now all done
      await n.toggleExercise(
        childId: 'child1',
        belt: BeltLevel.orange,
        exerciseId: exs[1]['id'] as String,
        passed: true,
      );
      expect(await _beltReady(db, 'child1'), isTrue);
    });
  });

  // ── BeltRequirementModel.byCategory ─────────────────────────────────────────

  group('BeltRequirementModel.byCategory — завжди 4 категорії', () {
    test('порожній список вправ → всі 4 категорії присутні (порожні)', () {
      final req = BeltRequirementModel(
        belt: BeltLevel.white,
        exercises: const [],
        updatedAt: DateTime(2024),
        updatedByCoachId: '',
      );
      expect(req.byCategory.length, equals(4));
      for (final cat in ExerciseCategory.values) {
        expect(req.byCategory.containsKey(cat), isTrue);
        expect(req.byCategory[cat], isEmpty);
      }
    });

    test('вправи у конкретних категоріях → інші категорії порожні', () {
      final req = BeltRequirementModel(
        belt: BeltLevel.yellow,
        exercises: [
          const Exercise(id: 'x1', name: 'T1', category: ExerciseCategory.technique),
          const Exercise(id: 'x2', name: 'P1', category: ExerciseCategory.physical),
        ],
        updatedAt: DateTime(2024),
        updatedByCoachId: '',
      );
      expect(req.byCategory[ExerciseCategory.technique]!.length, equals(1));
      expect(req.byCategory[ExerciseCategory.physical]!.length, equals(1));
      expect(req.byCategory[ExerciseCategory.theory], isEmpty);
      expect(req.byCategory[ExerciseCategory.competition], isEmpty);
    });
  });
}

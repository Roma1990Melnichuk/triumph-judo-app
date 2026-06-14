/// E2E тести для BeltNotifier — CRUD вправ у вимогах до поясу.
/// Покриває: addExercise, updateExercise, removeExercise.
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/belt_requirement_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/belts/providers/belt_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

ProviderContainer _container(FakeFirebaseFirestore db) => ProviderContainer(
      overrides: [firestoreProvider.overrideWithValue(db)],
    );

const _belt = BeltLevel.yellow;
const _coachId = 'coach1';

List<dynamic> _exercises(Map<String, dynamic>? data) =>
    (data?['exercises'] as List<dynamic>? ?? []);

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('BeltNotifier — addExercise (тренер)', () {
    test('додає нову вправу до Firestore', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(beltNotifierProvider.notifier).addExercise(
            belt: _belt,
            name: 'Seoi Nage',
            description: 'Кидок через спину',
            category: ExerciseCategory.technique,
            coachId: _coachId,
          );

      final doc = await db.collection('belt_requirements').doc(_belt.name).get();
      expect(doc.exists, isTrue);

      final exercises = _exercises(doc.data());
      expect(exercises, hasLength(1));
      expect(exercises.first['name'], 'Seoi Nage');
      expect(exercises.first['category'], 'technique');
      expect(exercises.first['id'], isNotEmpty);
    });

    test('кілька вправ — кожна зберігається', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(beltNotifierProvider.notifier);
      await n.addExercise(
        belt: _belt,
        name: 'Вправа 1',
        description: '',
        category: ExerciseCategory.physical,
        coachId: _coachId,
      );
      await n.addExercise(
        belt: _belt,
        name: 'Вправа 2',
        description: '',
        category: ExerciseCategory.theory,
        coachId: _coachId,
      );

      final doc = await db.collection('belt_requirements').doc(_belt.name).get();
      final exercises = _exercises(doc.data());
      expect(exercises, hasLength(2));
      final names = exercises.map((e) => e['name'] as String).toList();
      expect(names, containsAll(['Вправа 1', 'Вправа 2']));
    });

    test('id вправи — унікальний для кожного addExercise', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(beltNotifierProvider.notifier);
      await n.addExercise(
          belt: _belt, name: 'A', description: '', category: ExerciseCategory.technique, coachId: _coachId);
      await n.addExercise(
          belt: _belt, name: 'B', description: '', category: ExerciseCategory.technique, coachId: _coachId);

      final doc = await db.collection('belt_requirements').doc(_belt.name).get();
      final exercises = _exercises(doc.data());
      final ids = exercises.map((e) => e['id'] as String).toSet();
      expect(ids, hasLength(2));
    });
  });

  group('BeltNotifier — updateExercise (тренер)', () {
    test('оновлює назву і опис існуючої вправи за id', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      // Add an exercise first
      await c.read(beltNotifierProvider.notifier).addExercise(
            belt: _belt,
            name: 'Стара назва',
            description: 'Старий опис',
            category: ExerciseCategory.technique,
            coachId: _coachId,
          );

      // Read back to get the generated id
      final snap1 = await db.collection('belt_requirements').doc(_belt.name).get();
      final exId = (_exercises(snap1.data()).first)['id'] as String;

      // Update
      await c.read(beltNotifierProvider.notifier).updateExercise(
            belt: _belt,
            updated: Exercise(
              id: exId,
              name: 'Нова назва',
              description: 'Новий опис',
              category: ExerciseCategory.physical,
            ),
            coachId: _coachId,
          );

      final snap2 = await db.collection('belt_requirements').doc(_belt.name).get();
      final exercises = _exercises(snap2.data());
      expect(exercises, hasLength(1)); // still 1 exercise
      expect(exercises.first['name'], 'Нова назва');
      expect(exercises.first['description'], 'Новий опис');
      expect(exercises.first['category'], 'physical');
      expect(exercises.first['id'], exId); // same id
    });

    test('оновлення не торкається інших вправ', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(beltNotifierProvider.notifier);
      await n.addExercise(belt: _belt, name: 'Вправа A', description: '', category: ExerciseCategory.technique, coachId: _coachId);
      await n.addExercise(belt: _belt, name: 'Вправа B', description: '', category: ExerciseCategory.technique, coachId: _coachId);

      final snap1 = await db.collection('belt_requirements').doc(_belt.name).get();
      final exercises1 = _exercises(snap1.data());
      final idA = exercises1.firstWhere((e) => e['name'] == 'Вправа A')['id'] as String;

      await n.updateExercise(
        belt: _belt,
        updated: Exercise(id: idA, name: 'Вправа A оновлена', description: ''),
        coachId: _coachId,
      );

      final snap2 = await db.collection('belt_requirements').doc(_belt.name).get();
      final exercises2 = _exercises(snap2.data());
      expect(exercises2, hasLength(2));

      final names = exercises2.map((e) => e['name'] as String).toSet();
      expect(names, contains('Вправа A оновлена'));
      expect(names, contains('Вправа B'));
    });
  });

  group('BeltNotifier — removeExercise (тренер)', () {
    test('видаляє вправу за id', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(beltNotifierProvider.notifier);
      await n.addExercise(belt: _belt, name: 'Вправа', description: '', category: ExerciseCategory.technique, coachId: _coachId);

      final snap1 = await db.collection('belt_requirements').doc(_belt.name).get();
      final exId = (_exercises(snap1.data()).first)['id'] as String;

      await n.removeExercise(belt: _belt, exerciseId: exId, coachId: _coachId);

      final snap2 = await db.collection('belt_requirements').doc(_belt.name).get();
      expect(_exercises(snap2.data()), isEmpty);
    });

    test('видалення однієї з кількох вправ — решта залишаються', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(beltNotifierProvider.notifier);
      await n.addExercise(belt: _belt, name: 'Залишити', description: '', category: ExerciseCategory.technique, coachId: _coachId);
      await n.addExercise(belt: _belt, name: 'Видалити', description: '', category: ExerciseCategory.physical, coachId: _coachId);

      final snap1 = await db.collection('belt_requirements').doc(_belt.name).get();
      final exToDelete = (_exercises(snap1.data()).firstWhere((e) => e['name'] == 'Видалити'))['id'] as String;

      await n.removeExercise(belt: _belt, exerciseId: exToDelete, coachId: _coachId);

      final snap2 = await db.collection('belt_requirements').doc(_belt.name).get();
      final remaining = _exercises(snap2.data());
      expect(remaining, hasLength(1));
      expect(remaining.first['name'], 'Залишити');
    });
  });

  group('BeltNotifier — повний сценарій: CRUD вправ', () {
    test('додати → оновити → видалити → немає вправ', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(beltNotifierProvider.notifier);

      // 1. Тренер додає вправу
      await n.addExercise(
        belt: _belt,
        name: 'O-soto-gari',
        description: 'Зовнішня підніжка',
        category: ExerciseCategory.technique,
        coachId: _coachId,
      );

      final snap1 = await db.collection('belt_requirements').doc(_belt.name).get();
      expect(_exercises(snap1.data()), hasLength(1));
      final exId = (_exercises(snap1.data()).first)['id'] as String;

      // 2. Тренер оновлює назву
      await n.updateExercise(
        belt: _belt,
        updated: Exercise(id: exId, name: 'O-soto-gari (оновлено)', description: 'Техніка кидка'),
        coachId: _coachId,
      );

      final snap2 = await db.collection('belt_requirements').doc(_belt.name).get();
      expect((_exercises(snap2.data()).first)['name'], 'O-soto-gari (оновлено)');

      // 3. Тренер видаляє вправу
      await n.removeExercise(belt: _belt, exerciseId: exId, coachId: _coachId);

      final snap3 = await db.collection('belt_requirements').doc(_belt.name).get();
      expect(_exercises(snap3.data()), isEmpty);
    });
  });
}

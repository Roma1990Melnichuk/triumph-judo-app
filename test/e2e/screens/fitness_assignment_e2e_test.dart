/// E2E тести для AssignmentNotifier — повний CRUD для фітнес-завдань.
/// Покриває: createAssignment, updateAssignment, completeAssignment, deleteAssignment.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/fitness_assignment_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/fitness/providers/fitness_assignment_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

ProviderContainer _container(FakeFirebaseFirestore db) => ProviderContainer(
      overrides: [firestoreProvider.overrideWithValue(db)],
    );

Future<String> _seed(FakeFirebaseFirestore db) async {
  const id = 'assign1';
  await db.collection('fitness_assignments').doc(id).set({
    'id': id,
    'coachId': 'coach1',
    'title': 'Підтягування',
    'exerciseId': 'ex1',
    'exerciseName': 'Підтягування',
    'exerciseUnit': 'рази',
    'targetValue': 100.0,
    'startDate': Timestamp.fromDate(DateTime(2026, 1, 1)),
    'deadline': Timestamp.fromDate(DateTime(2026, 2, 1)),
    'assignedChildIds': ['kid1', 'kid2'],
    'status': 'active',
    'coachComment': '',
    'isCumulative': true,
  });
  return id;
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('AssignmentNotifier — createAssignment (тренер)', () {
    test('зберігає завдання у Firestore з коректними полями', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(assignmentNotifierProvider.notifier).createAssignment(
            coachId: 'coach1',
            title: 'Підтягування',
            exerciseId: 'ex1',
            exerciseName: 'Підтягування',
            exerciseUnit: 'рази',
            targetValue: 100,
            startDate: DateTime(2026, 1, 1),
            deadline: DateTime(2026, 2, 1),
            assignedChildIds: ['kid1', 'kid2'],
          );

      final snap = await db.collection('fitness_assignments').get();
      expect(snap.docs, hasLength(1));

      final data = snap.docs.first.data();
      expect(data['coachId'], 'coach1');
      expect(data['title'], 'Підтягування');
      expect(data['exerciseId'], 'ex1');
      expect(data['targetValue'], 100.0);
      expect(data['status'], 'active');
      expect((data['assignedChildIds'] as List).cast<String>(), containsAll(['kid1', 'kid2']));
    });

    test('генерує унікальний id', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(assignmentNotifierProvider.notifier);
      await n.createAssignment(
        coachId: 'coach1',
        title: 'A',
        exerciseId: 'e1',
        exerciseName: 'A',
        exerciseUnit: 'рази',
        targetValue: 50,
        startDate: DateTime(2026, 1, 1),
        deadline: DateTime(2026, 2, 1),
        assignedChildIds: ['kid1'],
      );
      await n.createAssignment(
        coachId: 'coach1',
        title: 'B',
        exerciseId: 'e2',
        exerciseName: 'B',
        exerciseUnit: 'рази',
        targetValue: 50,
        startDate: DateTime(2026, 1, 1),
        deadline: DateTime(2026, 2, 1),
        assignedChildIds: ['kid1'],
      );

      final snap = await db.collection('fitness_assignments').get();
      expect(snap.docs, hasLength(2));
      expect(snap.docs.map((d) => d.id).toSet(), hasLength(2));
    });

    test('стан = AsyncData після createAssignment', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(assignmentNotifierProvider.notifier).createAssignment(
            coachId: 'coach1',
            title: 'Test',
            exerciseId: 'e1',
            exerciseName: 'Test',
            exerciseUnit: 'рази',
            targetValue: 50,
            startDate: DateTime(2026, 1, 1),
            deadline: DateTime(2026, 2, 1),
            assignedChildIds: ['kid1'],
          );

      expect(c.read(assignmentNotifierProvider), isA<AsyncData<void>>());
    });
  });

  group('AssignmentNotifier — updateAssignment (тренер)', () {
    test('оновлює targetValue та deadline', () async {
      final db = _db();
      final id = await _seed(db);
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(assignmentNotifierProvider.notifier).updateAssignment(
            id,
            targetValue: 200,
            deadline: DateTime(2026, 3, 1),
            coachComment: 'Гарна робота',
          );

      final doc = await db.collection('fitness_assignments').doc(id).get();
      expect(doc['targetValue'], 200.0);
      expect(doc['coachComment'], 'Гарна робота');
      final savedDeadline = (doc['deadline'] as Timestamp).toDate();
      expect(savedDeadline.month, 3);
    });

    test('оновлення без полів — без змін', () async {
      final db = _db();
      final id = await _seed(db);
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(assignmentNotifierProvider.notifier).updateAssignment(id);

      final doc = await db.collection('fitness_assignments').doc(id).get();
      expect(doc['targetValue'], 100.0); // unchanged
    });
  });

  group('AssignmentNotifier — completeAssignment (спортсмен)', () {
    test('встановлює status=completed', () async {
      final db = _db();
      final id = await _seed(db);
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(assignmentNotifierProvider.notifier).completeAssignment(id);

      final doc = await db.collection('fitness_assignments').doc(id).get();
      expect(doc['status'], AssignmentStatus.completed.name);
    });
  });

  group('AssignmentNotifier — deleteAssignment (тренер)', () {
    test('видаляє документ з Firestore', () async {
      final db = _db();
      final id = await _seed(db);
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(assignmentNotifierProvider.notifier).deleteAssignment(id);

      final doc = await db.collection('fitness_assignments').doc(id).get();
      expect(doc.exists, isFalse);
    });

    test('стан = AsyncData після deleteAssignment', () async {
      final db = _db();
      final id = await _seed(db);
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(assignmentNotifierProvider.notifier).deleteAssignment(id);

      expect(c.read(assignmentNotifierProvider), isA<AsyncData<void>>());
    });
  });

  group('AssignmentNotifier — повний сценарій: тренер + спортсмен', () {
    test('тренер створює → спортсмен бачить → виконує → статус completed', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(assignmentNotifierProvider.notifier);

      // 1. Тренер створює завдання
      await n.createAssignment(
        coachId: 'coach1',
        title: 'Прес',
        exerciseId: 'press',
        exerciseName: 'Прес',
        exerciseUnit: 'рази',
        targetValue: 300,
        startDate: DateTime(2026, 1, 1),
        deadline: DateTime(2026, 2, 1),
        assignedChildIds: ['kid1'],
        status: AssignmentStatus.active,
      );

      // 2. Завдання є в Firestore
      final snap = await db.collection('fitness_assignments')
          .where('status', isEqualTo: 'active')
          .get();
      expect(snap.docs, hasLength(1));
      final id = snap.docs.first.id;
      expect(snap.docs.first['title'], 'Прес');

      // 3. Спортсмен kid1 призначений до завдання
      final assigned = (snap.docs.first['assignedChildIds'] as List).cast<String>();
      expect(assigned, contains('kid1'));

      // 4. Тренер оновлює targetValue
      await n.updateAssignment(id, targetValue: 350);
      final updated = await db.collection('fitness_assignments').doc(id).get();
      expect(updated['targetValue'], 350.0);

      // 5. Спортсмен виконує завдання
      await n.completeAssignment(id);
      final completed = await db.collection('fitness_assignments').doc(id).get();
      expect(completed['status'], AssignmentStatus.completed.name);

      // 6. Тренер видаляє виконане завдання
      await n.deleteAssignment(id);
      final deleted = await db.collection('fitness_assignments').doc(id).get();
      expect(deleted.exists, isFalse);
    });
  });
}

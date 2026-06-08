import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/fitness_assignment_model.dart';

FitnessAssignment makeAssignment({
  String id = 'a1',
  String coachId = 'coach1',
  String title = '100 відтискань за тиждень',
  String exerciseId = 'pushups',
  String exerciseName = 'Відтискання',
  String exerciseUnit = 'рази',
  double targetValue = 100.0,
  DateTime? startDate,
  DateTime? deadline,
  List<String> assignedChildIds = const ['c1', 'c2'],
}) {
  final now = DateTime.now();
  return FitnessAssignment(
    id: id,
    coachId: coachId,
    title: title,
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    exerciseUnit: exerciseUnit,
    targetValue: targetValue,
    startDate: startDate ?? now.subtract(const Duration(days: 1)),
    deadline: deadline ?? now.add(const Duration(days: 6)),
    assignedChildIds: assignedChildIds,
  );
}

void main() {
  // ── isActive ──────────────────────────────────────────────────────────────

  group('FitnessAssignment.isActive', () {
    test('true коли deadline в майбутньому', () {
      final a = makeAssignment(
          deadline: DateTime.now().add(const Duration(days: 3)));
      expect(a.isActive, isTrue);
    });

    test('false коли deadline в минулому', () {
      final a = makeAssignment(
          deadline: DateTime.now().subtract(const Duration(days: 1)));
      expect(a.isActive, isFalse);
    });
  });

  // ── toFirestore ───────────────────────────────────────────────────────────

  group('FitnessAssignment.toFirestore', () {
    test('містить всі поля', () {
      final map = makeAssignment().toFirestore();
      expect(map['coachId'], 'coach1');
      expect(map['title'], '100 відтискань за тиждень');
      expect(map['exerciseId'], 'pushups');
      expect(map['exerciseName'], 'Відтискання');
      expect(map['exerciseUnit'], 'рази');
      expect(map['targetValue'], 100.0);
      expect(map['assignedChildIds'], ['c1', 'c2']);
    });

    test('startDate та deadline серіалізуються як Timestamp', () {
      final map = makeAssignment(
        startDate: DateTime(2026, 6, 1),
        deadline: DateTime(2026, 6, 8),
      ).toFirestore();
      expect(map['startDate'], isA<Timestamp>());
      expect(map['deadline'], isA<Timestamp>());
      expect((map['startDate'] as Timestamp).toDate(), DateTime(2026, 6, 1));
      expect((map['deadline'] as Timestamp).toDate(), DateTime(2026, 6, 8));
    });

    test('id не включається (це docId)', () {
      expect(makeAssignment().toFirestore().containsKey('id'), isFalse);
    });
  });

  // ── fromFirestore ─────────────────────────────────────────────────────────

  group('FitnessAssignment.fromFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;
    setUp(() => fakeFirestore = FakeFirebaseFirestore());

    test('зчитує всі поля коректно', () async {
      final ref =
          fakeFirestore.collection('fitness_assignments').doc('assign1');
      await ref.set({
        'coachId': 'coach42',
        'title': '50 підтягувань',
        'exerciseId': 'pullups',
        'exerciseName': 'Підтягування',
        'exerciseUnit': 'рази',
        'targetValue': 50.0,
        'startDate': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'deadline': Timestamp.fromDate(DateTime(2026, 6, 7)),
        'assignedChildIds': ['kid1', 'kid2', 'kid3'],
      });
      final a = FitnessAssignment.fromFirestore(await ref.get());
      expect(a.id, 'assign1');
      expect(a.coachId, 'coach42');
      expect(a.title, '50 підтягувань');
      expect(a.exerciseId, 'pullups');
      expect(a.targetValue, 50.0);
      expect(a.assignedChildIds, ['kid1', 'kid2', 'kid3']);
      expect(a.startDate, DateTime(2026, 6, 1));
      expect(a.deadline, DateTime(2026, 6, 7));
    });

    test('відсутні поля — значення за замовчуванням', () async {
      final ref =
          fakeFirestore.collection('fitness_assignments').doc('empty');
      await ref.set(<String, dynamic>{});
      final a = FitnessAssignment.fromFirestore(await ref.get());
      expect(a.coachId, '');
      expect(a.title, '');
      expect(a.exerciseId, '');
      expect(a.exerciseUnit, 'рази');
      expect(a.targetValue, 0.0);
      expect(a.assignedChildIds, isEmpty);
    });

    test('targetValue як int конвертується в double', () async {
      final ref =
          fakeFirestore.collection('fitness_assignments').doc('intval');
      await ref.set({
        'targetValue': 100, // int
        'startDate': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'deadline': Timestamp.fromDate(DateTime(2026, 6, 8)),
      });
      final a = FitnessAssignment.fromFirestore(await ref.get());
      expect(a.targetValue, 100.0);
      expect(a.targetValue, isA<double>());
    });
  });

  // ── round-trip ────────────────────────────────────────────────────────────

  group('FitnessAssignment — round-trip', () {
    test('toFirestore → fromFirestore зберігає всі поля', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final original = makeAssignment(
        id: 'rt1',
        title: 'Планка 300 секунд',
        exerciseId: 'plank',
        exerciseName: 'Планка',
        exerciseUnit: 'секунди',
        targetValue: 300.0,
        startDate: DateTime(2026, 6, 1),
        deadline: DateTime(2026, 6, 8),
        assignedChildIds: ['c1', 'c2', 'c3'],
      );
      await fakeFirestore
          .collection('fitness_assignments')
          .doc('rt1')
          .set(original.toFirestore());
      final doc = await fakeFirestore
          .collection('fitness_assignments')
          .doc('rt1')
          .get();
      final restored = FitnessAssignment.fromFirestore(doc);
      expect(restored.title, original.title);
      expect(restored.exerciseId, original.exerciseId);
      expect(restored.targetValue, original.targetValue);
      expect(restored.startDate, original.startDate);
      expect(restored.deadline, original.deadline);
      expect(restored.assignedChildIds, original.assignedChildIds);
      expect(restored.isActive, isTrue);
    });
  });
}

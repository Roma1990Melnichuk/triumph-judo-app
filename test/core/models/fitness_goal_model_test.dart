import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/fitness_goal_model.dart';

FitnessGoal makeGoal({
  String id = 'child1_pushups',
  String childId = 'child1',
  String exerciseId = 'pushups',
  String exerciseName = 'Відтискання',
  String exerciseUnit = 'рази',
  double targetValue = 50.0,
  DateTime? deadline,
  bool isAchieved = false,
}) =>
    FitnessGoal(
      id: id,
      childId: childId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      exerciseUnit: exerciseUnit,
      targetValue: targetValue,
      deadline: deadline ?? DateTime(2026, 12, 31),
      isAchieved: isAchieved,
    );

void main() {
  // ── toFirestore ───────────────────────────────────────────────────────────

  group('FitnessGoal.toFirestore', () {
    test('містить всі поля', () {
      final map = makeGoal().toFirestore();
      expect(map['childId'], 'child1');
      expect(map['exerciseId'], 'pushups');
      expect(map['exerciseName'], 'Відтискання');
      expect(map['exerciseUnit'], 'рази');
      expect(map['targetValue'], 50.0);
      expect(map['isAchieved'], isFalse);
    });

    test('deadline серіалізується як Timestamp', () {
      final map = makeGoal(deadline: DateTime(2026, 9, 1)).toFirestore();
      expect(map['deadline'], isA<Timestamp>());
      expect((map['deadline'] as Timestamp).toDate(), DateTime(2026, 9, 1));
    });

    test('isAchieved = true зберігається', () {
      final map = makeGoal(isAchieved: true).toFirestore();
      expect(map['isAchieved'], isTrue);
    });

    test('id не включається (це docId)', () {
      expect(makeGoal().toFirestore().containsKey('id'), isFalse);
    });
  });

  // ── fromFirestore ─────────────────────────────────────────────────────────

  group('FitnessGoal.fromFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;
    setUp(() => fakeFirestore = FakeFirebaseFirestore());

    test('зчитує всі поля коректно', () async {
      final ref = fakeFirestore.collection('fitness_goals').doc('child1_plank');
      await ref.set({
        'childId': 'child1',
        'exerciseId': 'plank',
        'exerciseName': 'Планка',
        'exerciseUnit': 'секунди',
        'targetValue': 180.0,
        'deadline': Timestamp.fromDate(DateTime(2026, 8, 1)),
        'isAchieved': false,
      });
      final goal = FitnessGoal.fromFirestore(await ref.get());
      expect(goal.id, 'child1_plank');
      expect(goal.childId, 'child1');
      expect(goal.exerciseId, 'plank');
      expect(goal.targetValue, 180.0);
      expect(goal.isAchieved, isFalse);
      expect(goal.deadline, DateTime(2026, 8, 1));
    });

    test('відсутні поля — значення за замовчуванням', () async {
      final ref = fakeFirestore.collection('fitness_goals').doc('empty');
      await ref.set(<String, dynamic>{});
      final goal = FitnessGoal.fromFirestore(await ref.get());
      expect(goal.childId, '');
      expect(goal.exerciseId, '');
      expect(goal.targetValue, 0.0);
      expect(goal.isAchieved, isFalse);
    });

    test('targetValue як int конвертується в double', () async {
      final ref = fakeFirestore.collection('fitness_goals').doc('intval');
      await ref.set({
        'deadline': Timestamp.fromDate(DateTime(2026, 12, 1)),
        'targetValue': 100, // int
      });
      final goal = FitnessGoal.fromFirestore(await ref.get());
      expect(goal.targetValue, 100.0);
      expect(goal.targetValue, isA<double>());
    });
  });

  // ── round-trip ────────────────────────────────────────────────────────────

  group('FitnessGoal — round-trip', () {
    test('toFirestore → fromFirestore зберігає всі поля', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final original = makeGoal(
        id: 'c2_squats',
        childId: 'c2',
        exerciseId: 'squats',
        targetValue: 80.0,
        deadline: DateTime(2026, 10, 15),
        isAchieved: true,
      );
      final ref = fakeFirestore.collection('fitness_goals').doc('c2_squats');
      await ref.set(original.toFirestore());
      final restored = FitnessGoal.fromFirestore(await ref.get());
      expect(restored.childId, original.childId);
      expect(restored.exerciseId, original.exerciseId);
      expect(restored.targetValue, original.targetValue);
      expect(restored.deadline, original.deadline);
      expect(restored.isAchieved, original.isAchieved);
    });
  });
}

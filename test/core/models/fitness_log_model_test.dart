import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/fitness_log_model.dart';

void main() {
  // ── FitnessDifficultyX.fromInt ────────────────────────────────────────────

  group('FitnessDifficultyX.fromInt', () {
    test('1 → easy', () {
      expect(FitnessDifficultyX.fromInt(1), FitnessdifficultY.easy);
    });

    test('2 → medium', () {
      expect(FitnessDifficultyX.fromInt(2), FitnessdifficultY.medium);
    });

    test('3 → hard', () {
      expect(FitnessDifficultyX.fromInt(3), FitnessdifficultY.hard);
    });

    test('невідоме значення → easy (default)', () {
      expect(FitnessDifficultyX.fromInt(0), FitnessdifficultY.easy);
      expect(FitnessDifficultyX.fromInt(99), FitnessdifficultY.easy);
    });
  });

  // ── FitnessdifficultY.intValue ────────────────────────────────────────────

  group('FitnessdifficultY.intValue', () {
    test('easy → 1', () => expect(FitnessdifficultY.easy.intValue, 1));
    test('medium → 2', () => expect(FitnessdifficultY.medium.intValue, 2));
    test('hard → 3', () => expect(FitnessdifficultY.hard.intValue, 3));
  });

  // ── FitnessdifficultY.label ───────────────────────────────────────────────

  group('FitnessdifficultY.label', () {
    test('easy → Легко', () => expect(FitnessdifficultY.easy.label, 'Легко'));
    test('medium → Середньо', () => expect(FitnessdifficultY.medium.label, 'Середньо'));
    test('hard → Важко', () => expect(FitnessdifficultY.hard.label, 'Важко'));
  });

  // ── fromInt / intValue round-trip ─────────────────────────────────────────

  group('FitnessDifficulty — round-trip int', () {
    test('fromInt(intValue) відновлює оригінал', () {
      for (final d in FitnessdifficultY.values) {
        expect(FitnessDifficultyX.fromInt(d.intValue), d);
      }
    });
  });

  // ── FitnessLog.toFirestore ────────────────────────────────────────────────

  group('FitnessLog.toFirestore', () {
    final log = FitnessLog(
      id: 'log1',
      childId: 'child1',
      exerciseId: 'pushups',
      exerciseName: 'Відтискання',
      exerciseUnit: 'рази',
      date: DateTime(2026, 6, 1),
      value: 42.0,
      comment: 'Добре',
      difficulty: 2,
    );

    test('містить всі поля', () {
      final map = log.toFirestore();
      expect(map['childId'], 'child1');
      expect(map['exerciseId'], 'pushups');
      expect(map['exerciseName'], 'Відтискання');
      expect(map['exerciseUnit'], 'рази');
      expect(map['value'], 42.0);
      expect(map['comment'], 'Добре');
      expect(map['difficulty'], 2);
    });

    test('date серіалізується як Timestamp', () {
      final map = log.toFirestore();
      expect(map['date'], isA<Timestamp>());
      expect((map['date'] as Timestamp).toDate(), DateTime(2026, 6, 1));
    });

    test('id не включається (це docId)', () {
      expect(log.toFirestore().containsKey('id'), isFalse);
    });
  });

  // ── FitnessLog.fromFirestore ──────────────────────────────────────────────

  group('FitnessLog.fromFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;
    setUp(() => fakeFirestore = FakeFirebaseFirestore());

    test('зчитує всі поля коректно', () async {
      final ref = fakeFirestore.collection('fitness_logs').doc('log42');
      await ref.set({
        'childId': 'kid1',
        'exerciseId': 'plank',
        'exerciseName': 'Планка',
        'exerciseUnit': 'секунди',
        'date': Timestamp.fromDate(DateTime(2026, 5, 15)),
        'value': 120.0,
        'comment': '',
        'difficulty': 3,
      });
      final l = FitnessLog.fromFirestore(await ref.get());
      expect(l.id, 'log42');
      expect(l.childId, 'kid1');
      expect(l.exerciseId, 'plank');
      expect(l.value, 120.0);
      expect(l.difficulty, 3);
      expect(l.date, DateTime(2026, 5, 15));
    });

    test('відсутні поля — значення за замовчуванням', () async {
      final ref = fakeFirestore.collection('fitness_logs').doc('empty');
      await ref.set(<String, dynamic>{});
      final l = FitnessLog.fromFirestore(await ref.get());
      expect(l.childId, '');
      expect(l.value, 0.0);
      expect(l.comment, '');
      expect(l.difficulty, 1);
    });

    test('value як int конвертується в double', () async {
      final ref = fakeFirestore.collection('fitness_logs').doc('intval');
      await ref.set({
        'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'value': 30, // int
      });
      final l = FitnessLog.fromFirestore(await ref.get());
      expect(l.value, 30.0);
      expect(l.value, isA<double>());
    });
  });

  // ── round-trip ────────────────────────────────────────────────────────────

  group('FitnessLog — round-trip', () {
    test('toFirestore → fromFirestore зберігає всі поля', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final original = FitnessLog(
        id: 'rt1',
        childId: 'c1',
        exerciseId: 'burpees',
        exerciseName: 'Берпі',
        exerciseUnit: 'рази',
        date: DateTime(2026, 3, 20),
        value: 15.0,
        comment: 'Важко',
        difficulty: 3,
      );
      final ref = fakeFirestore.collection('fitness_logs').doc('rt1');
      await ref.set(original.toFirestore());
      final restored = FitnessLog.fromFirestore(await ref.get());
      expect(restored.childId, original.childId);
      expect(restored.exerciseId, original.exerciseId);
      expect(restored.value, original.value);
      expect(restored.difficulty, original.difficulty);
      expect(restored.date, original.date);
    });
  });
}

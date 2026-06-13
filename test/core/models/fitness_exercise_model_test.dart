import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/fitness_exercise_model.dart';

void main() {
  // ── defaults ──────────────────────────────────────────────────────────────

  group('FitnessExercise.defaults', () {
    test('містить рівно 9 вправ', () {
      expect(FitnessExercise.defaults.length, 9);
    });

    test('всі мають isDefault = true', () {
      expect(FitnessExercise.defaults.every((e) => e.isDefault), isTrue);
    });

    test('відомі id присутні', () {
      final ids = FitnessExercise.defaults.map((e) => e.id).toSet();
      expect(ids, containsAll(['pushups', 'pullups', 'abs', 'plank', 'jumprope']));
      expect(ids, containsAll(['squats', 'burpees', 'sprint', 'longrun']));
    });

    test('планка має одиницю "секунди"', () {
      final plank = FitnessExercise.defaults.firstWhere((e) => e.id == 'plank');
      expect(plank.unit, 'секунди');
    });

    test('відтискання має одиницю "рази"', () {
      final pushups = FitnessExercise.defaults.firstWhere((e) => e.id == 'pushups');
      expect(pushups.unit, 'рази');
    });
  });

  // ── toFirestore ───────────────────────────────────────────────────────────

  group('FitnessExercise.toFirestore', () {
    test('містить name, unit, isDefault', () {
      const ex = FitnessExercise(id: 'x', name: 'Тест', unit: 'кг', isDefault: false);
      final map = ex.toFirestore();
      expect(map['name'], 'Тест');
      expect(map['unit'], 'кг');
      expect(map['isDefault'], isFalse);
    });

    test('id не включається (це docId)', () {
      const ex = FitnessExercise(id: 'myid', name: 'А', unit: 'б', isDefault: true);
      expect(ex.toFirestore().containsKey('id'), isFalse);
    });
  });

  // ── fromFirestore ─────────────────────────────────────────────────────────

  group('FitnessExercise.fromFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;
    setUp(() => fakeFirestore = FakeFirebaseFirestore());

    test('зчитує всі поля коректно', () async {
      final ref = fakeFirestore.collection('fitness_exercises').doc('pullups');
      await ref.set({'name': 'Підтягування', 'unit': 'рази', 'isDefault': true});
      final ex = FitnessExercise.fromFirestore(await ref.get());
      expect(ex.id, 'pullups');
      expect(ex.name, 'Підтягування');
      expect(ex.unit, 'рази');
      expect(ex.isDefault, isTrue);
    });

    test('відсутні поля дають значення за замовчуванням', () async {
      final ref = fakeFirestore.collection('fitness_exercises').doc('empty');
      await ref.set(<String, dynamic>{});
      final ex = FitnessExercise.fromFirestore(await ref.get());
      expect(ex.name, '');
      expect(ex.unit, 'рази');
      expect(ex.isDefault, isFalse);
    });
  });

  // ── round-trip ────────────────────────────────────────────────────────────

  group('FitnessExercise — round-trip', () {
    test('toFirestore → fromFirestore зберігає всі поля', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      const original = FitnessExercise(
        id: 'squats', name: 'Присідання', unit: 'рази', isDefault: true,
      );
      final ref = fakeFirestore.collection('fitness_exercises').doc('squats');
      await ref.set(original.toFirestore());
      final restored = FitnessExercise.fromFirestore(await ref.get());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.unit, original.unit);
      expect(restored.isDefault, original.isDefault);
    });
  });
}

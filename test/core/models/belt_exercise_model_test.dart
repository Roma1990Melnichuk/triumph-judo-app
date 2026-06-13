import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/belt_exercise_model.dart';
import 'package:judo_app/core/constants/belt_levels.dart';

void main() {
  // ── ExerciseCategory ──────────────────────────────────────────────────────

  group('ExerciseCategory', () {
    test('усі категорії мають label', () {
      for (final c in ExerciseCategory.values) {
        expect(c.label, isNotEmpty);
      }
    });

    test('усі категорії мають emoji', () {
      for (final c in ExerciseCategory.values) {
        expect(c.emoji, isNotEmpty);
      }
    });

    test('fromString невідомий → throws', () {
      expect(ExerciseCategory.fromString('???'), ExerciseCategory.throws);
    });

    test('fromString "groundwork"', () {
      expect(ExerciseCategory.fromString('groundwork'),
          ExerciseCategory.groundwork);
    });
  });

  // ── BeltExerciseModel.defaults ────────────────────────────────────────────

  group('BeltExerciseModel.defaults', () {
    test('не порожній список', () {
      expect(BeltExerciseModel.defaults, isNotEmpty);
    });

    test('усі id унікальні', () {
      final ids =
          BeltExerciseModel.defaults.map((e) => e.id).toSet();
      expect(ids.length, BeltExerciseModel.defaults.length);
    });

    test('всі isDefault = true', () {
      expect(
        BeltExerciseModel.defaults.every((e) => e.isDefault),
        isTrue,
      );
    });

    test('є вправи для ukemi', () {
      final ukemi = BeltExerciseModel.defaults
          .where((e) => e.category == ExerciseCategory.ukemi)
          .toList();
      expect(ukemi, isNotEmpty);
    });

    test('є вправи для кидків', () {
      final throws = BeltExerciseModel.defaults
          .where((e) => e.category == ExerciseCategory.throws)
          .toList();
      expect(throws, isNotEmpty);
    });

    test('всі вправи мають хоча б один пояс', () {
      expect(
        BeltExerciseModel.defaults.every((e) => e.forBelts.isNotEmpty),
        isTrue,
      );
    });
  });

  // ── toFirestore ───────────────────────────────────────────────────────────

  group('BeltExerciseModel.toFirestore', () {
    test('містить name, category, forBelts', () {
      const ex = BeltExerciseModel(
        id: 'test', name: 'Тест', description: 'Опис',
        category: ExerciseCategory.conditioning,
        forBelts: [BeltLevel.yellow],
        isDefault: false,
      );
      final map = ex.toFirestore();
      expect(map['name'],     'Тест');
      expect(map['category'], 'conditioning');
      expect((map['forBelts'] as List), contains('yellow'));
    });
  });
}

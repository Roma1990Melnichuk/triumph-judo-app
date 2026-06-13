import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/belt_requirement_model.dart';

void main() {
  // ── ExerciseCategory ──────────────────────────────────────────────────────

  group('ExerciseCategory', () {
    test('усі категорії мають непорожній displayName', () {
      for (final c in ExerciseCategory.values) {
        expect(c.displayName, isNotEmpty);
      }
    });

    test('fromString невідомий → technique', () {
      expect(ExerciseCategory.fromString('???'), ExerciseCategory.technique);
    });

    test('fromString null → technique', () {
      expect(ExerciseCategory.fromString(null), ExerciseCategory.technique);
    });

    test('fromString "physical"', () {
      expect(ExerciseCategory.fromString('physical'), ExerciseCategory.physical);
    });

    test('fromString "theory"', () {
      expect(ExerciseCategory.fromString('theory'), ExerciseCategory.theory);
    });

    test('fromString "competition"', () {
      expect(ExerciseCategory.fromString('competition'), ExerciseCategory.competition);
    });
  });

  // ── Exercise ──────────────────────────────────────────────────────────────

  group('Exercise', () {
    const ex = Exercise(
      id: 'e1',
      name: 'О-гоші',
      description: 'Кидок через стегно',
      category: ExerciseCategory.technique,
      videoUrl: 'https://example.com/vid',
    );

    test('toMap / fromMap round-trip', () {
      final map = ex.toMap();
      final back = Exercise.fromMap(map);
      expect(back.id,          ex.id);
      expect(back.name,        ex.name);
      expect(back.description, ex.description);
      expect(back.category,    ex.category);
      expect(back.videoUrl,    ex.videoUrl);
    });

    test('toMap зберігає category як рядок', () {
      expect(ex.toMap()['category'], 'technique');
    });

    test('copyWith змінює тільки вказані поля', () {
      final ex2 = ex.copyWith(name: 'Іпон-сеой-наге');
      expect(ex2.name,        'Іпон-сеой-наге');
      expect(ex2.category,    ExerciseCategory.technique);
      expect(ex.name,         'О-гоші'); // оригінал незмінний
    });

    test('fromMap з порожнього map → дефолти', () {
      final e = Exercise.fromMap({});
      expect(e.id,          '');
      expect(e.videoUrl,    '');
      expect(e.category,    ExerciseCategory.technique);
    });
  });

  // ── BeltRequirementModel.byCategory ──────────────────────────────────────

  group('BeltRequirementModel.byCategory', () {
    const exercises = [
      Exercise(id: 'e1', name: 'А', category: ExerciseCategory.technique),
      Exercise(id: 'e2', name: 'Б', category: ExerciseCategory.technique),
      Exercise(id: 'e3', name: 'В', category: ExerciseCategory.physical),
    ];

    final req = BeltRequirementModel(
      belt: BeltLevel.yellow,
      exercises: exercises,
      updatedAt: DateTime(2025),
      updatedByCoachId: 'coach1',
    );

    test('групує за категорією', () {
      final map = req.byCategory;
      expect(map[ExerciseCategory.technique]?.length, 2);
      expect(map[ExerciseCategory.physical]?.length, 1);
    });

    test('порожня категорія не потрапляє в map', () {
      final map = req.byCategory;
      expect(map.containsKey(ExerciseCategory.theory), isFalse);
      expect(map.containsKey(ExerciseCategory.competition), isFalse);
    });
  });

  // ── BeltRequirementModel.toFirestore ─────────────────────────────────────

  group('BeltRequirementModel.toFirestore', () {
    final req = BeltRequirementModel(
      belt: BeltLevel.blue,
      exercises: const [
        Exercise(id: 'e1', name: 'Тест'),
      ],
      description: 'Опис',
      level: '3 кю',
      updatedAt: DateTime(2025, 1, 1),
      updatedByCoachId: 'c1',
    );

    test('містить exercises, description, level, updatedByCoachId', () {
      final map = req.toFirestore();
      expect(map['description'],        'Опис');
      expect(map['level'],              '3 кю');
      expect(map['updatedByCoachId'],   'c1');
      expect((map['exercises'] as List).length, 1);
    });
  });
}

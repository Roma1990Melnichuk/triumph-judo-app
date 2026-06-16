/// TC-BELT-ADV — Бізнес-логіка підтвердження поясу.
///
/// Ключові правила:
///   1. Після advanceBelts currentBelt = вказаний новий пояс
///   2. beltReady скидається в false (спортсмен ще не готовий до наступного)
///   3. Прогрес нового поясу порожній — всі завдання не виконані
///   4. Ієрархія 12 поясів фіксована і однозначна (next завжди правильний)
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/belt_requirement_model.dart';
import 'package:judo_app/features/belts/providers/belt_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

Future<String?> _currentBelt(FakeFirebaseFirestore db, String childId) async {
  final snap = await db.collection('children').doc(childId).get();
  return snap.data()?['currentBelt'] as String?;
}

Future<bool?> _beltReady(FakeFirebaseFirestore db, String childId) async {
  final snap = await db.collection('children').doc(childId).get();
  return snap.data()?['beltReady'] as bool?;
}

Future<Map<String, bool>> _passedExercises(
    FakeFirebaseFirestore db, String childId, BeltLevel belt) async {
  final docId = '${childId}_${belt.name}';
  final snap = await db.collection('belt_progress').doc(docId).get();
  final raw = snap.data()?['passed'] as Map<String, dynamic>? ?? {};
  return raw.map((k, v) => MapEntry(k, v as bool));
}

Future<void> _setChild(FakeFirebaseFirestore db, String childId,
    {required BeltLevel belt, bool beltReady = false}) async {
  await db.collection('children').doc(childId).set({
    'currentBelt': belt.name,
    'beltReady': beltReady,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── TC-BELT-ADV-001 ──────────────────────────────────────────────────────────

  group('TC-BELT-ADV-001: після підтвердження currentBelt = новий пояс', () {
    test('white → advanceBelts(whiteYellow) → currentBelt=whiteYellow', () async {
      final db = _db();
      await _setChild(db, 'child1', belt: BeltLevel.white, beltReady: true);

      await ChildrenNotifier(db).advanceBelts(
        childIds: ['child1'],
        newBelt: BeltLevel.whiteYellow,
      );

      expect(await _currentBelt(db, 'child1'), BeltLevel.whiteYellow.name);
    });

    test('yellow → advanceBelts(yellowOrange) → currentBelt=yellowOrange', () async {
      final db = _db();
      await _setChild(db, 'child1', belt: BeltLevel.yellow, beltReady: true);

      await ChildrenNotifier(db).advanceBelts(
        childIds: ['child1'],
        newBelt: BeltLevel.yellowOrange,
      );

      expect(await _currentBelt(db, 'child1'), BeltLevel.yellowOrange.name);
    });

    test('brown → advanceBelts(black) → currentBelt=black (останній пояс)', () async {
      final db = _db();
      await _setChild(db, 'child1', belt: BeltLevel.brown, beltReady: true);

      await ChildrenNotifier(db).advanceBelts(
        childIds: ['child1'],
        newBelt: BeltLevel.black,
      );

      expect(await _currentBelt(db, 'child1'), BeltLevel.black.name);
    });

    test('тренер передає currentBelt.next! → результат відповідає ієрархії', () async {
      final db = _db();
      const startBelt = BeltLevel.green;
      final nextBelt = startBelt.next!;

      await _setChild(db, 'child1', belt: startBelt, beltReady: true);
      await ChildrenNotifier(db).advanceBelts(childIds: ['child1'], newBelt: nextBelt);

      expect(await _currentBelt(db, 'child1'), nextBelt.name);
      expect(nextBelt, equals(BeltLevel.greenBlue));
    });
  });

  // ── TC-BELT-ADV-002 ──────────────────────────────────────────────────────────

  group('TC-BELT-ADV-002: після підтвердження beltReady = false', () {
    test('beltReady=true перед підтвердженням → false після', () async {
      final db = _db();
      await _setChild(db, 'child1', belt: BeltLevel.white, beltReady: true);

      await ChildrenNotifier(db).advanceBelts(
        childIds: ['child1'],
        newBelt: BeltLevel.whiteYellow,
      );

      expect(await _beltReady(db, 'child1'), isFalse);
    });

    test('kілька спортсменів — beltReady=false у всіх після групового підтвердження', () async {
      final db = _db();
      for (final id in ['child1', 'child2', 'child3']) {
        await _setChild(db, id, belt: BeltLevel.yellow, beltReady: true);
      }

      await ChildrenNotifier(db).advanceBelts(
        childIds: ['child1', 'child2', 'child3'],
        newBelt: BeltLevel.yellowOrange,
      );

      for (final id in ['child1', 'child2', 'child3']) {
        expect(await _beltReady(db, id), isFalse,
            reason: '$id повинен мати beltReady=false після підтвердження');
      }
    });

    test('спортсмен не може одразу пройти новий пояс — beltReady=false одразу після переходу',
        () async {
      final db = _db();
      await _setChild(db, 'child1', belt: BeltLevel.orange, beltReady: true);

      await ChildrenNotifier(db).advanceBelts(
        childIds: ['child1'],
        newBelt: BeltLevel.orangeGreen,
      );

      // Immediately after advancement: NOT ready for the next belt
      expect(await _beltReady(db, 'child1'), isFalse,
          reason: 'Після переходу спортсмен ще не готовий до наступного поясу');
    });
  });

  // ── TC-BELT-ADV-003 ──────────────────────────────────────────────────────────

  group('TC-BELT-ADV-003: завдання нового поясу — статус "не виконано"', () {
    test('новий пояс не має прогресу — жодне завдання не позначене виконаним', () async {
      final db = _db();
      const toBelt = BeltLevel.whiteYellow;

      // Set up exercises for the new belt
      final beltNotifier = BeltNotifier(db);
      await beltNotifier.addExercise(
        belt: toBelt,
        name: 'Укемі назад',
        description: '',
        category: ExerciseCategory.technique,
        coachId: 'coach1',
      );
      await beltNotifier.addExercise(
        belt: toBelt,
        name: 'Стійка дзюдоїста',
        description: '',
        category: ExerciseCategory.theory,
        coachId: 'coach1',
      );

      await _setChild(db, 'child1', belt: BeltLevel.white, beltReady: true);
      await ChildrenNotifier(db).advanceBelts(
        childIds: ['child1'],
        newBelt: toBelt,
      );

      // No passed exercises for the new belt
      final passed = await _passedExercises(db, 'child1', toBelt);
      expect(passed, isEmpty,
          reason: 'Після переходу всі завдання нового поясу ще не виконані');
    });

    test('прогрес нового поясу=порожній навіть якщо на старому всі були виконані', () async {
      final db = _db();
      const fromBelt = BeltLevel.whiteYellow;
      const toBelt = BeltLevel.yellow;

      // Old belt: all exercises completed
      await db.collection('belt_progress').doc('child1_${fromBelt.name}').set({
        'childId': 'child1',
        'belt': fromBelt.name,
        'passed': {'ex1': true, 'ex2': true, 'ex3': true},
      });
      await _setChild(db, 'child1', belt: fromBelt, beltReady: true);

      await ChildrenNotifier(db).advanceBelts(childIds: ['child1'], newBelt: toBelt);

      // New belt: no progress
      final newProgress = await _passedExercises(db, 'child1', toBelt);
      expect(newProgress, isEmpty);

      // Old belt progress untouched
      final oldProgress = await _passedExercises(db, 'child1', fromBelt);
      expect(oldProgress, hasLength(3));
      expect(oldProgress.values.every((v) => v), isTrue);
    });

    test('після підтвердження beltReady=false означає що нові завдання треба виконати', () async {
      final db = _db();
      const toBelt = BeltLevel.yellow;

      // Add exercises for new belt
      final beltNotifier = BeltNotifier(db);
      await beltNotifier.addExercise(
        belt: toBelt,
        name: 'Укі-госі',
        description: '',
        category: ExerciseCategory.technique,
        coachId: 'coach1',
      );

      await _setChild(db, 'child1', belt: BeltLevel.whiteYellow, beltReady: true);
      await ChildrenNotifier(db).advanceBelts(childIds: ['child1'], newBelt: toBelt);

      // beltReady=false + no progress = tasks need to be done
      expect(await _beltReady(db, 'child1'), isFalse);
      final passed = await _passedExercises(db, 'child1', toBelt);
      expect(passed, isEmpty);
    });
  });

  // ── TC-BELT-ADV-004 ──────────────────────────────────────────────────────────

  group('TC-BELT-ADV-004: ієрархія 12 поясів — повний ланцюжок', () {
    test('кожен пояс має наступний за ієрархією або є останнім (чорний)', () {
      final allLevels = BeltLevel.values;
      expect(allLevels.length, equals(12));

      for (var i = 0; i < allLevels.length; i++) {
        final level = allLevels[i];
        if (i < allLevels.length - 1) {
          expect(level.next, equals(allLevels[i + 1]),
              reason: '${level.name}.next повинен бути ${allLevels[i + 1].name}');
          expect(level.isLast, isFalse);
        } else {
          expect(level.next, isNull,
              reason: 'Чорний пояс — останній, наступного немає');
          expect(level.isLast, isTrue);
        }
      }
    });

    test('порядок: white → whiteYellow → yellow → yellowOrange → ... → black', () {
      expect(BeltLevel.values[0],  BeltLevel.white);
      expect(BeltLevel.values[1],  BeltLevel.whiteYellow);
      expect(BeltLevel.values[2],  BeltLevel.yellow);
      expect(BeltLevel.values[3],  BeltLevel.yellowOrange);
      expect(BeltLevel.values[4],  BeltLevel.orange);
      expect(BeltLevel.values[5],  BeltLevel.orangeGreen);
      expect(BeltLevel.values[6],  BeltLevel.green);
      expect(BeltLevel.values[7],  BeltLevel.greenBlue);
      expect(BeltLevel.values[8],  BeltLevel.blue);
      expect(BeltLevel.values[9],  BeltLevel.blueBrown);
      expect(BeltLevel.values[10], BeltLevel.brown);
      expect(BeltLevel.values[11], BeltLevel.black);
    });

    test('повний маршрут white → black через advanceBelts — пояс змінюється на кожному кроці', () async {
      final db = _db();
      await _setChild(db, 'child1', belt: BeltLevel.white, beltReady: true);

      final notifier = ChildrenNotifier(db);
      var belt = BeltLevel.white;

      while (belt.next != null) {
        final nextBelt = belt.next!;
        await notifier.advanceBelts(childIds: ['child1'], newBelt: nextBelt);

        expect(await _currentBelt(db, 'child1'), nextBelt.name,
            reason: 'Після підтвердження ${belt.name} → ${nextBelt.name}');
        expect(await _beltReady(db, 'child1'), isFalse);

        belt = nextBelt;
      }

      expect(await _currentBelt(db, 'child1'), BeltLevel.black.name);
    });
  });
}

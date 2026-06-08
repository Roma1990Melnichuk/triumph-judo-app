import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/fitness_assignment_model.dart';
import 'package:judo_app/core/models/fitness_log_model.dart';
import 'package:judo_app/features/fitness/providers/fitness_assignment_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FitnessAssignment makeAssignment({
  String exerciseId = 'pushups',
  double targetValue = 100.0,
  DateTime? startDate,
  DateTime? deadline,
}) {
  final now = DateTime.now();
  return FitnessAssignment(
    id: 'a1',
    coachId: 'coach1',
    title: 'Тест',
    exerciseId: exerciseId,
    exerciseName: 'Вправа',
    exerciseUnit: 'рази',
    targetValue: targetValue,
    startDate: startDate ?? now.subtract(const Duration(days: 7)),
    deadline: deadline ?? now.add(const Duration(days: 7)),
    assignedChildIds: const ['c1'],
  );
}

FitnessLog makeLog({
  String childId = 'c1',
  String exerciseId = 'pushups',
  required DateTime date,
  required double value,
}) =>
    FitnessLog(
      id: 'log_${date.millisecondsSinceEpoch}',
      childId: childId,
      exerciseId: exerciseId,
      exerciseName: 'Відтискання',
      exerciseUnit: 'рази',
      date: date,
      value: value,
      comment: '',
      difficulty: 1,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('assignmentProgress', () {
    final today = DateTime.now();

    test('0 коли немає логів', () {
      expect(assignmentProgress([], makeAssignment()), 0.0);
    });

    test('сумує логи в межах [startDate, deadline]', () {
      final assignment = makeAssignment(
        startDate: today.subtract(const Duration(days: 6)),
        deadline: today.add(const Duration(days: 1)),
      );
      final logs = [
        makeLog(date: today.subtract(const Duration(days: 5)), value: 30),
        makeLog(date: today.subtract(const Duration(days: 3)), value: 25),
        makeLog(date: today, value: 20),
      ];
      expect(assignmentProgress(logs, assignment), 75.0);
    });

    test('ігнорує логи до startDate', () {
      final start = today.subtract(const Duration(days: 3));
      final assignment = makeAssignment(
        startDate: start,
        deadline: today.add(const Duration(days: 4)),
      );
      final logs = [
        makeLog(date: today.subtract(const Duration(days: 5)), value: 50), // до старту
        makeLog(date: today, value: 30), // в межах
      ];
      expect(assignmentProgress(logs, assignment), 30.0);
    });

    test('ігнорує логи після deadline', () {
      final deadline = today.subtract(const Duration(days: 1));
      final assignment = makeAssignment(
        startDate: today.subtract(const Duration(days: 10)),
        deadline: deadline,
      );
      final logs = [
        makeLog(date: today.subtract(const Duration(days: 5)), value: 40), // в межах
        makeLog(date: today, value: 60), // після дедлайну
      ];
      expect(assignmentProgress(logs, assignment), 40.0);
    });

    test('ігнорує логи з іншої вправи', () {
      final assignment = makeAssignment(exerciseId: 'pushups');
      final logs = [
        makeLog(exerciseId: 'pushups', date: today, value: 50),
        makeLog(exerciseId: 'pullups', date: today, value: 30), // інша вправа
      ];
      expect(assignmentProgress(logs, assignment), 50.0);
    });

    test('включає логи рівно на startDate та deadline (межі включно)', () {
      final start = DateTime(2026, 6, 1);
      final end = DateTime(2026, 6, 7);
      final assignment = makeAssignment(startDate: start, deadline: end);
      final logs = [
        makeLog(date: start, value: 10),   // рівно startDate
        makeLog(date: end, value: 15),     // рівно deadline
        makeLog(date: DateTime(2026, 6, 4), value: 20),
      ];
      expect(assignmentProgress(logs, assignment), 45.0);
    });

    test('повертає 0 коли всі логи поза межами', () {
      final assignment = makeAssignment(
        startDate: DateTime(2026, 6, 1),
        deadline: DateTime(2026, 6, 7),
      );
      final logs = [
        makeLog(date: DateTime(2026, 5, 31), value: 50),   // до
        makeLog(date: DateTime(2026, 6, 8), value: 50),    // після
      ];
      expect(assignmentProgress(logs, assignment), 0.0);
    });

    test('коректно сумує дробові значення', () {
      final assignment =
          makeAssignment(exerciseId: 'plank', targetValue: 180.0);
      final logs = [
        makeLog(exerciseId: 'plank', date: today.subtract(const Duration(days: 2)), value: 60.5),
        makeLog(exerciseId: 'plank', date: today, value: 75.5),
      ];
      expect(assignmentProgress(logs, assignment), closeTo(136.0, 0.001));
    });

    test('багато логів — сума всіх у межах', () {
      final start = DateTime(2026, 6, 1);
      final end = DateTime(2026, 6, 10);
      final assignment = makeAssignment(
          targetValue: 500, startDate: start, deadline: end);
      final logs = List.generate(
        10,
        (i) => makeLog(
            date: DateTime(2026, 6, 1 + i), value: 10.0),
      );
      expect(assignmentProgress(logs, assignment), 100.0);
    });
  });

  // ── FitnessAssignment.isActive (pure logic — not Firestore) ──────────────

  group('FitnessAssignment.isActive', () {
    test('true коли deadline завтра', () {
      expect(
        makeAssignment(deadline: DateTime.now().add(const Duration(days: 1))).isActive,
        isTrue,
      );
    });

    test('false коли deadline вчора', () {
      expect(
        makeAssignment(deadline: DateTime.now().subtract(const Duration(days: 1))).isActive,
        isFalse,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/fitness_assignment_model.dart';
import 'package:judo_app/core/models/fitness_log_model.dart';
import 'package:judo_app/features/fitness/providers/fitness_assignment_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FitnessAssignment _assignment({bool isCumulative = true}) {
  final now = DateTime.now();
  return FitnessAssignment(
    id: 'asgn1',
    coachId: 'coach1',
    title: 'Тест завдання',
    exerciseId: 'pushups',
    exerciseName: 'Віджимання',
    exerciseUnit: 'рази',
    targetValue: 100.0,
    startDate: now.subtract(const Duration(days: 7)),
    deadline: now.add(const Duration(days: 7)),
    assignedChildIds: const ['c1'],
    isCumulative: isCumulative,
  );
}

FitnessLog _log({
  required double value,
  String childId = 'c1',
  String exerciseId = 'pushups',
  String? assignmentId,
  DateTime? date,
}) {
  final d = date ?? DateTime.now();
  return FitnessLog(
    id: 'log_${d.millisecondsSinceEpoch}_$value',
    childId: childId,
    exerciseId: exerciseId,
    exerciseName: 'Віджимання',
    exerciseUnit: 'рази',
    date: d,
    value: value,
    comment: '',
    difficulty: 1,
    assignmentId: assignmentId,
  );
}

// ── Tests — FIT-02: assignmentId filtering ────────────────────────────────────

void main() {
  final a = _assignment();

  group('assignmentProgress — фільтрація за assignmentId (FIT-02)', () {
    test('лог з відповідним assignmentId враховується', () {
      final logs = [_log(value: 40, assignmentId: 'asgn1')];
      expect(assignmentProgress(logs, a, 'c1'), 40.0);
    });

    test('лог без assignmentId (legacy) враховується', () {
      final logs = [_log(value: 30, assignmentId: null)];
      expect(assignmentProgress(logs, a, 'c1'), 30.0);
    });

    test('лог з іншим assignmentId ігнорується', () {
      final logs = [_log(value: 50, assignmentId: 'asgn_ІНШЕ')];
      expect(assignmentProgress(logs, a, 'c1'), 0.0);
    });

    test('суміш: тільки "своє" і legacy додаються, чуже ігнорується', () {
      final logs = [
        _log(value: 20, assignmentId: 'asgn1'),   // своє
        _log(value: 15, assignmentId: null),        // legacy — дозволяємо
        _log(value: 99, assignmentId: 'asgn_ІНШЕ'), // чуже — виключаємо
      ];
      expect(assignmentProgress(logs, a, 'c1'), 35.0);
    });

    test('два різні завдання для тієї ж вправи не перетинаються', () {
      final a2 = FitnessAssignment(
        id: 'asgn2',
        coachId: 'coach1',
        title: 'Інше завдання',
        exerciseId: 'pushups',
        exerciseName: 'Віджимання',
        exerciseUnit: 'рази',
        targetValue: 200.0,
        startDate: a.startDate,
        deadline: a.deadline,
        assignedChildIds: const ['c1'],
        isCumulative: true,
      );

      final logs = [
        _log(value: 30, assignmentId: 'asgn1'),
        _log(value: 70, assignmentId: 'asgn2'),
      ];

      expect(assignmentProgress(logs, a, 'c1'),  30.0); // лише своє
      expect(assignmentProgress(logs, a2, 'c1'), 70.0); // лише своє
    });

    test('лог іншого спортсмена ігнорується навіть з правильним assignmentId', () {
      final logs = [
        _log(value: 50, assignmentId: 'asgn1', childId: 'c1'),
        _log(value: 30, assignmentId: 'asgn1', childId: 'c_ІНШИЙ'),
      ];
      expect(assignmentProgress(logs, a, 'c1'), 50.0);
    });

    test('peak mode з assignmentId: повертає максимум тільки своїх логів', () {
      final peak = _assignment(isCumulative: false);
      final logs = [
        _log(value: 80,  assignmentId: 'asgn1'),
        _log(value: 120, assignmentId: 'asgn_ІНШЕ'), // не рахується
        _log(value: 60,  assignmentId: 'asgn1'),
      ];
      expect(assignmentProgress(logs, peak, 'c1'), 80.0);
    });

    test('всі логи чужого завдання → 0', () {
      final logs = List.generate(
        5,
        (i) => _log(value: 10.0 * (i + 1), assignmentId: 'not_mine'),
      );
      expect(assignmentProgress(logs, a, 'c1'), 0.0);
    });
  });
}

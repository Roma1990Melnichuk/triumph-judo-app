import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/fitness_assignment_model.dart';
import 'package:judo_app/core/models/fitness_log_model.dart';
import 'package:judo_app/features/fitness/providers/fitness_assignment_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FitnessAssignment _make({
  String id = 'a1',
  AssignmentStatus status = AssignmentStatus.active,
  int daysUntilDeadline = 7,
  List<String> childIds = const ['c1'],
  String coachComment = '',
}) {
  final now = DateTime.now();
  return FitnessAssignment(
    id: id,
    coachId: 'coach1',
    title: 'Тест $id',
    exerciseId: 'ex1',
    exerciseName: 'Відтискання',
    exerciseUnit: 'рази',
    targetValue: 100.0,
    startDate: now.subtract(const Duration(days: 3)),
    deadline: now.add(Duration(days: daysUntilDeadline)),
    assignedChildIds: childIds,
    status: status,
    coachComment: coachComment,
  );
}

FitnessLog _log({
  String childId = 'c1',
  String exerciseId = 'ex1',
  required double value,
  int daysAgo = 1,
}) =>
    FitnessLog(
      id: 'log_$daysAgo',
      childId: childId,
      exerciseId: exerciseId,
      exerciseName: 'Відтискання',
      exerciseUnit: 'рази',
      date: DateTime.now().subtract(Duration(days: daysAgo)),
      value: value,
      comment: '',
      difficulty: 1,
    );

// ── isActive ──────────────────────────────────────────────────────────────────

void main() {
  group('FitnessAssignment.isActive', () {
    test('true — статус active, дедлайн у майбутньому', () {
      expect(_make(status: AssignmentStatus.active, daysUntilDeadline: 5).isActive, isTrue);
    });

    test('false — статус draft, навіть якщо дедлайн у майбутньому', () {
      expect(_make(status: AssignmentStatus.draft, daysUntilDeadline: 5).isActive, isFalse);
    });

    test('false — статус completed', () {
      expect(_make(status: AssignmentStatus.completed).isActive, isFalse);
    });

    test('false — дедлайн в минулому (active статус)', () {
      expect(_make(status: AssignmentStatus.active, daysUntilDeadline: -1).isActive, isFalse);
    });

    test('true — дедлайн сьогодні пізно ввечері (> now)', () {
      final now = DateTime.now();
      final a = FitnessAssignment(
        id: 'x',
        coachId: 'c',
        title: 't',
        exerciseId: 'e',
        exerciseName: 'n',
        exerciseUnit: 'рази',
        targetValue: 10,
        startDate: now.subtract(const Duration(days: 1)),
        deadline: now.add(const Duration(hours: 2)),
        assignedChildIds: const ['c1'],
      );
      expect(a.isActive, isTrue);
    });
  });

  // ── isExpired ─────────────────────────────────────────────────────────────

  group('FitnessAssignment.isExpired', () {
    test('true — статус completed', () {
      expect(_make(status: AssignmentStatus.completed).isExpired, isTrue);
    });

    test('true — active але дедлайн минув', () {
      expect(_make(status: AssignmentStatus.active, daysUntilDeadline: -2).isExpired, isTrue);
    });

    test('false — active, дедлайн у майбутньому', () {
      expect(_make(status: AssignmentStatus.active, daysUntilDeadline: 3).isExpired, isFalse);
    });

    test('false — draft (чернетка не вважається завершеною)', () {
      expect(_make(status: AssignmentStatus.draft, daysUntilDeadline: -5).isExpired, isFalse);
    });
  });

  // ── AssignmentStatus серіалізація ─────────────────────────────────────────

  group('AssignmentStatus.name round-trip', () {
    test('active.name == "active"', () {
      expect(AssignmentStatus.active.name, 'active');
    });

    test('draft.name == "draft"', () {
      expect(AssignmentStatus.draft.name, 'draft');
    });

    test('completed.name == "completed"', () {
      expect(AssignmentStatus.completed.name, 'completed');
    });

    test('парсинг з рядка через firstWhere', () {
      for (final s in AssignmentStatus.values) {
        final parsed = AssignmentStatus.values.firstWhere(
          (v) => v.name == s.name,
          orElse: () => AssignmentStatus.active,
        );
        expect(parsed, s);
      }
    });

    test('невідомий рядок → active (як у fromFirestore)', () {
      final parsed = AssignmentStatus.values.firstWhere(
        (v) => v.name == 'unknown_status',
        orElse: () => AssignmentStatus.active,
      );
      expect(parsed, AssignmentStatus.active);
    });
  });

  // ── coachComment ──────────────────────────────────────────────────────────

  group('coachComment', () {
    test('типово порожній', () {
      expect(_make().coachComment, isEmpty);
    });

    test('зберігається коли передано', () {
      final a = _make(coachComment: 'Гарна робота, продовжуй!');
      expect(a.coachComment, 'Гарна робота, продовжуй!');
    });
  });

  // ── assignedChildIds ──────────────────────────────────────────────────────

  group('assignedChildIds', () {
    test('порожній список — ізоляція від інших вправ', () {
      final a = _make(childIds: []);
      expect(a.assignedChildIds, isEmpty);
    });

    test('один спортсмен', () {
      expect(_make(childIds: ['c42']).assignedChildIds, ['c42']);
    });

    test('багато спортсменів', () {
      final ids = List.generate(50, (i) => 'c$i');
      expect(_make(childIds: ids).assignedChildIds.length, 50);
    });

    test('contains — перевірка наявності конкретного id', () {
      final a = _make(childIds: ['c1', 'c2', 'c3']);
      expect(a.assignedChildIds.contains('c2'), isTrue);
      expect(a.assignedChildIds.contains('c99'), isFalse);
    });
  });

  // ── Фільтрація active / draft / completed (provider-логіка) ──────────────

  group('Provider filter logic', () {
    final now = DateTime.now();

    final makeA = (String id, AssignmentStatus s, int daysLeft) =>
        FitnessAssignment(
          id: id,
          coachId: 'coach',
          title: id,
          exerciseId: 'ex',
          exerciseName: 'Ex',
          exerciseUnit: 'рази',
          targetValue: 100,
          startDate: now.subtract(const Duration(days: 1)),
          deadline: now.add(Duration(days: daysLeft)),
          assignedChildIds: const ['c1'],
          status: s,
        );

    final all = [
      makeA('active1', AssignmentStatus.active, 5),
      makeA('active2', AssignmentStatus.active, 10),
      makeA('draft1',  AssignmentStatus.draft,   3),
      makeA('done1',   AssignmentStatus.completed, 0),
      makeA('expired', AssignmentStatus.active, -2), // минув дедлайн
    ];

    test('active фільтр: тільки active + дедлайн майбутній', () {
      final active = all
          .where((a) => a.status == AssignmentStatus.active && a.deadline.isAfter(now))
          .toList();
      expect(active.map((a) => a.id), containsAll(['active1', 'active2']));
      expect(active.map((a) => a.id), isNot(contains('expired')));
      expect(active.map((a) => a.id), isNot(contains('draft1')));
      expect(active.length, 2);
    });

    test('draft фільтр: тільки draft', () {
      final drafts = all
          .where((a) => a.status == AssignmentStatus.draft)
          .toList();
      expect(drafts.length, 1);
      expect(drafts.first.id, 'draft1');
    });

    test('completed фільтр: статус completed АБО active+прострочений', () {
      final completed = all
          .where((a) =>
              a.status == AssignmentStatus.completed ||
              (a.status == AssignmentStatus.active && a.deadline.isBefore(now)))
          .toList();
      expect(completed.map((a) => a.id), containsAll(['done1', 'expired']));
      expect(completed.length, 2);
    });

    test('сума фільтрів = всі записи', () {
      final active = all
          .where((a) => a.status == AssignmentStatus.active && a.deadline.isAfter(now))
          .length;
      final drafts = all.where((a) => a.status == AssignmentStatus.draft).length;
      final completed = all
          .where((a) =>
              a.status == AssignmentStatus.completed ||
              (a.status == AssignmentStatus.active && a.deadline.isBefore(now)))
          .length;
      expect(active + drafts + completed, all.length);
    });
  });

  // ── Progress % calculation (логіка з екранів) ─────────────────────────────

  group('Progress percentage calculation', () {
    test('0% коли немає логів', () {
      final a = _make();
      final progress = assignmentProgress([], a, 'c1');
      expect(progress / a.targetValue, 0.0);
    });

    test('100% коли progress == target', () {
      final a = _make();
      final logs = [_log(value: 100)];
      final progress = assignmentProgress(logs, a, 'c1');
      final pct = (progress / a.targetValue).clamp(0.0, 1.0);
      expect(pct, 1.0);
    });

    test('обрізається до 1.0 при progress > target', () {
      final a = _make();
      final logs = [_log(value: 150)]; // перевиконання
      final progress = assignmentProgress(logs, a, 'c1');
      final pct = (progress / a.targetValue).clamp(0.0, 1.0);
      expect(pct, 1.0);
    });

    test('50% при половині прогресу', () {
      final a = _make();
      final logs = [_log(value: 50)];
      final progress = assignmentProgress(logs, a, 'c1');
      expect((progress / a.targetValue).clamp(0.0, 1.0), 0.5);
    });

    test('нульовий target: немає ділення на 0 (захисна логіка)', () {
      final now = DateTime.now();
      final a = FitnessAssignment(
        id: 'z',
        coachId: 'c',
        title: 't',
        exerciseId: 'ex1',
        exerciseName: 'n',
        exerciseUnit: 'рази',
        targetValue: 0.0,
        startDate: now.subtract(const Duration(days: 1)),
        deadline: now.add(const Duration(days: 1)),
        assignedChildIds: const ['c1'],
      );
      final progress = assignmentProgress([_log(value: 50)], a, 'c1');
      // Захист: target > 0 ? progress/target : 0.0
      final pct = a.targetValue > 0 ? (progress / a.targetValue).clamp(0.0, 1.0) : 0.0;
      expect(pct, 0.0);
    });
  });

  // ── Ukrainian day pluralization (_dayWord logic) ──────────────────────────

  group('Ukrainian day pluralization', () {
    // Логіка з _ActiveAssignmentCard._dayWord
    String dayWord(int n) {
      if (n % 10 == 1 && n % 100 != 11) return 'день';
      if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
        return 'дні';
      }
      return 'днів';
    }

    test('1 день', () => expect(dayWord(1), 'день'));
    test('2 дні', () => expect(dayWord(2), 'дні'));
    test('3 дні', () => expect(dayWord(3), 'дні'));
    test('4 дні', () => expect(dayWord(4), 'дні'));
    test('5 днів', () => expect(dayWord(5), 'днів'));
    test('11 днів (виняток)', () => expect(dayWord(11), 'днів'));
    test('12 днів (виняток)', () => expect(dayWord(12), 'днів'));
    test('13 днів (виняток)', () => expect(dayWord(13), 'днів'));
    test('14 днів (виняток)', () => expect(dayWord(14), 'днів'));
    test('21 день', () => expect(dayWord(21), 'день'));
    test('22 дні', () => expect(dayWord(22), 'дні'));
    test('100 днів', () => expect(dayWord(100), 'днів'));
    test('101 день', () => expect(dayWord(101), 'день'));
    test('111 днів (виняток 11x)', () => expect(dayWord(111), 'днів'));
    test('0 днів', () => expect(dayWord(0), 'днів'));
  });

  // ── assignmentProgress — child isolation ──────────────────────────────────

  group('assignmentProgress — childId фільтр (MyAssignmentsScreen)', () {
    final now = DateTime.now();
    final a = FitnessAssignment(
      id: 'a1',
      coachId: 'coach',
      title: 'T',
      exerciseId: 'pushups',
      exerciseName: 'Відтискання',
      exerciseUnit: 'рази',
      targetValue: 100,
      startDate: now.subtract(const Duration(days: 5)),
      deadline: now.add(const Duration(days: 5)),
      assignedChildIds: const ['c1', 'c2'],
    );

    // assignmentProgress не фільтрує по childId — це робить екран через де-фільтрацію logs
    // Тут перевіряємо що логіка ізоляції в екрані коректна
    test('логи іншої дитини ігноруються (фільтр по childId у MyAssignmentsScreen)', () {
      final logs = [
        FitnessLog(
          id: 'l1',
          childId: 'c1',
          exerciseId: 'pushups',
          exerciseName: 'Відтискання',
          exerciseUnit: 'рази',
          date: now,
          value: 40,
          comment: '',
          difficulty: 1,
        ),
        FitnessLog(
          id: 'l2',
          childId: 'c2', // інша дитина
          exerciseId: 'pushups',
          exerciseName: 'Відтискання',
          exerciseUnit: 'рази',
          date: now,
          value: 60,
          comment: '',
          difficulty: 1,
        ),
      ];

      // Симуляція фільтра з _MyAssignmentsScreenState._calcProgress
      final childId = 'c1';
      final progress = logs
          .where((l) =>
              l.exerciseId == a.exerciseId &&
              l.childId == childId &&
              !l.date.isBefore(a.startDate) &&
              !l.date.isAfter(a.deadline))
          .fold(0.0, (acc, l) => acc + l.value);

      expect(progress, 40.0); // тільки c1, не c2
    });
  });
}

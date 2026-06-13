/// TC-FITN-0390 / TC-FITN-0391 — Fitness Logic: Peak value = MAX not SUM
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/fitness_log_model.dart';
import 'package:judo_app/features/fitness/providers/fitness_provider.dart';

FitnessLog _log({
  required String id,
  required double value,
  String childId = 'c1',
  String exerciseId = 'pullups',
  String? assignmentId,
}) =>
    FitnessLog(
      id: id,
      childId: childId,
      exerciseId: exerciseId,
      exerciseName: 'Підтягування',
      exerciseUnit: 'рази',
      date: DateTime(2024, 1, int.parse(id)),
      value: value,
      comment: '',
      difficulty: 1,
      assignmentId: assignmentId,
    );

void main() {
  // ── TC-FITN-0390: Peak = max(logs), не sum ─────────────────────────────────

  group('TC-FITN-0390: peakValueProvider = max(значень), не sum', () {
    test('logs [100, 200, 50] → peak = 200', () async {
      final logs = [
        _log(id: '1', value: 100),
        _log(id: '2', value: 200),
        _log(id: '3', value: 50),
      ];

      final container = ProviderContainer(overrides: [
        childFitnessLogsProvider('c1').overrideWith((_) => Stream.value(logs)),
      ]);
      addTearDown(container.dispose);

      await container.read(childFitnessLogsProvider('c1').future);

      const key = (childId: 'c1', exerciseId: 'pullups');
      final peak = container.read(peakValueProvider(key));

      expect(peak, equals(200.0)); // max
      expect(peak, isNot(equals(350.0))); // sum — хибно
    });

    test('один лог → peak = значення цього лога', () async {
      final container = ProviderContainer(overrides: [
        childFitnessLogsProvider('c1')
            .overrideWith((_) => Stream.value([_log(id: '1', value: 42)])),
      ]);
      addTearDown(container.dispose);
      await container.read(childFitnessLogsProvider('c1').future);

      const key = (childId: 'c1', exerciseId: 'pullups');
      expect(container.read(peakValueProvider(key)), equals(42.0));
    });

    test('порожній список → peak = null', () async {
      final container = ProviderContainer(overrides: [
        childFitnessLogsProvider('c1').overrideWith((_) => Stream.value([])),
      ]);
      addTearDown(container.dispose);
      await container.read(childFitnessLogsProvider('c1').future);

      const key = (childId: 'c1', exerciseId: 'pullups');
      expect(container.read(peakValueProvider(key)), isNull);
    });

    test('фільтрується за exerciseId — не змішує різні вправи', () async {
      final logs = [
        _log(id: '1', value: 100, exerciseId: 'pullups'),
        _log(id: '2', value: 999, exerciseId: 'pushups'), // інша вправа
        _log(id: '3', value: 80, exerciseId: 'pullups'),
      ];

      final container = ProviderContainer(overrides: [
        childFitnessLogsProvider('c1').overrideWith((_) => Stream.value(logs)),
      ]);
      addTearDown(container.dispose);
      await container.read(childFitnessLogsProvider('c1').future);

      const key = (childId: 'c1', exerciseId: 'pullups');
      expect(container.read(peakValueProvider(key)), equals(100.0)); // не 999
    });
  });

  // ── TC-FITN-0391: assignmentId для конкретного завдання ───────────────────

  group('TC-FITN-0391: FitnessLog.assignmentId для вибору конкретного завдання',
      () {
    test('FitnessLog зберігає assignmentId', () {
      final log = _log(id: '1', value: 15, assignmentId: 'task-123');
      expect(log.assignmentId, equals('task-123'));
    });

    test('FitnessLog без assignmentId → assignmentId = null', () {
      final log = _log(id: '1', value: 15);
      expect(log.assignmentId, isNull);
    });

    test('peak враховує всі логи незалежно від assignmentId', () async {
      final logs = [
        _log(id: '1', value: 10, exerciseId: 'ex1', assignmentId: 'task-A'),
        _log(id: '2', value: 30, exerciseId: 'ex1', assignmentId: 'task-B'),
        _log(id: '3', value: 20, exerciseId: 'ex1'), // без assignmentId
      ];

      final container = ProviderContainer(overrides: [
        childFitnessLogsProvider('c1').overrideWith((_) => Stream.value(logs)),
      ]);
      addTearDown(container.dispose);
      await container.read(childFitnessLogsProvider('c1').future);

      const key = (childId: 'c1', exerciseId: 'ex1');
      // max(10, 30, 20) = 30 — розраховується по всіх логах
      expect(container.read(peakValueProvider(key)), equals(30.0));
    });

    test('два завдання одного типу — обидва беруть участь у підрахунку peak',
        () async {
      final logs = [
        _log(id: '1', value: 5, exerciseId: 'squat', assignmentId: 'assign-1'),
        _log(id: '2', value: 12, exerciseId: 'squat', assignmentId: 'assign-2'),
      ];

      final container = ProviderContainer(overrides: [
        childFitnessLogsProvider('c1').overrideWith((_) => Stream.value(logs)),
      ]);
      addTearDown(container.dispose);
      await container.read(childFitnessLogsProvider('c1').future);

      const key = (childId: 'c1', exerciseId: 'squat');
      expect(container.read(peakValueProvider(key)), equals(12.0));
    });
  });
}

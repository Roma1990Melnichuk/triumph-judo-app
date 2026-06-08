import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/training_schedule_model.dart';

// ── Хелпер ────────────────────────────────────────────────────────────────────

TrainingScheduleModel makeSchedule({
  String id = 's1',
  List<int> daysOfWeek = const [1, 3, 5],
  String timeStart = '18:00',
  String timeEnd = '19:30',
  String label = 'Основне тренування',
}) =>
    TrainingScheduleModel(
      id: id,
      coachId: 'coach1',
      label: label,
      daysOfWeek: daysOfWeek,
      timeStart: timeStart,
      timeEnd: timeEnd,
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('TrainingScheduleModel.daysLabel', () {
    test('Пн, Ср, Пт для [1, 3, 5]', () {
      expect(makeSchedule(daysOfWeek: [1, 3, 5]).daysLabel, 'Пн, Ср, Пт');
    });

    test('один день', () {
      expect(makeSchedule(daysOfWeek: [2]).daysLabel, 'Вт');
    });

    test('щоденно — всі 7 днів', () {
      expect(
        makeSchedule(daysOfWeek: [1, 2, 3, 4, 5, 6, 7]).daysLabel,
        'Пн, Вт, Ср, Чт, Пт, Сб, Нд',
      );
    });

    test('Сб, Нд для вихідних [6, 7]', () {
      expect(makeSchedule(daysOfWeek: [6, 7]).daysLabel, 'Сб, Нд');
    });

    test('порожній список → порожній рядок', () {
      expect(makeSchedule(daysOfWeek: []).daysLabel, '');
    });
  });

  group('TrainingScheduleModel — поля', () {
    test('зберігає label', () {
      final s = makeSchedule(label: 'Дитяче тренування');
      expect(s.label, 'Дитяче тренування');
    });

    test('зберігає timeStart і timeEnd', () {
      final s = makeSchedule(timeStart: '10:00', timeEnd: '11:30');
      expect(s.timeStart, '10:00');
      expect(s.timeEnd, '11:30');
    });

    test('зберігає список daysOfWeek', () {
      final s = makeSchedule(daysOfWeek: [1, 4]);
      expect(s.daysOfWeek, [1, 4]);
    });
  });

  group('TrainingScheduleModel.toFirestore', () {
    test('містить усі ключові поля', () {
      final s = makeSchedule(
        daysOfWeek: [1, 3, 5],
        timeStart: '18:00',
        timeEnd: '19:30',
        label: 'Тренування',
      );
      final map = s.toFirestore();
      expect(map['coachId'], 'coach1');
      expect(map['label'], 'Тренування');
      expect(map['daysOfWeek'], [1, 3, 5]);
      expect(map['timeStart'], '18:00');
      expect(map['timeEnd'], '19:30');
    });

    test('не містить id (зберігається як docId в Firestore)', () {
      final map = makeSchedule().toFirestore();
      expect(map.containsKey('id'), isFalse);
    });
  });
}

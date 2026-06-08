import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/group_model.dart';
import 'package:judo_app/core/models/attendance_model.dart';

void main() {
  // ── GroupModel.trainingDates ──────────────────────────────────────────────

  group('GroupModel.trainingDates — генерація дат тренувань', () {
    test('Пн/Ср/Пт генерує тільки ці дні тижня', () {
      final group = GroupModel(
        id: 'g1', coachId: 'c1', name: 'Test',
        childIds: [], daysOfWeek: [1, 3, 5], // Mon, Wed, Fri
        timeStart: '18:00', timeEnd: '19:30',
      );
      final dates = group.trainingDates(2024);
      expect(dates.every((d) => [1, 3, 5].contains(d.weekday)), isTrue);
    });

    test('Сезон починається з вересня і закінчується у липні', () {
      final group = GroupModel(
        id: 'g1', coachId: 'c1', name: 'Test',
        childIds: [], daysOfWeek: [1],
        timeStart: '18:00', timeEnd: '19:30',
      );
      final dates = group.trainingDates(2024);
      expect(dates.isNotEmpty, isTrue);
      expect(dates.first.year, 2024);
      expect(dates.first.month, 9); // September
      expect(dates.last.month, 7);  // July
      expect(dates.last.year, 2025);
    });

    test('Порожній daysOfWeek → порожній список', () {
      final group = GroupModel(
        id: 'g1', coachId: 'c1', name: 'Test',
        childIds: [], daysOfWeek: [],
        timeStart: '18:00', timeEnd: '19:30',
      );
      expect(group.trainingDates(2024), isEmpty);
    });

    test('Вт (2) дає тільки вівторки', () {
      final group = GroupModel(
        id: 'g1', coachId: 'c1', name: 'Test',
        childIds: [], daysOfWeek: [2],
        timeStart: '18:00', timeEnd: '19:30',
      );
      final dates = group.trainingDates(2024);
      expect(dates.every((d) => d.weekday == 2), isTrue);
    });

    test('Щодня (1-7) дає всі дні в сезоні', () {
      final group = GroupModel(
        id: 'g1', coachId: 'c1', name: 'Test',
        childIds: [], daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
        timeStart: '09:00', timeEnd: '10:00',
      );
      final dates = group.trainingDates(2024);
      // Sep(30) + Oct(31) + Nov(30) + Dec(31) + Jan(31) + Feb(28) + Mar(31)
      // + Apr(30) + May(31) + Jun(30) + Jul(31) = 334 days
      expect(dates.length, greaterThan(330));
    });

    test('Сезон 2023 → вересень 2023 по липень 2024', () {
      final group = GroupModel(
        id: 'g1', coachId: 'c1', name: 'Test',
        childIds: [], daysOfWeek: [1],
        timeStart: '18:00', timeEnd: '19:30',
      );
      final dates = group.trainingDates(2023);
      expect(dates.first.year, 2023);
      expect(dates.first.month, 9);
      expect(dates.last.year, 2024);
      expect(dates.last.month, 7);
    });
  });

  // ── GroupModel.daysLabel ──────────────────────────────────────────────────

  group('GroupModel.daysLabel', () {
    test('Пн/Ср/Пт → "Пн, Ср, Пт"', () {
      final group = GroupModel(
        id: 'g1', coachId: 'c1', name: 'Test',
        childIds: [], daysOfWeek: [1, 3, 5],
        timeStart: '18:00', timeEnd: '19:30',
      );
      expect(group.daysLabel, 'Пн, Ср, Пт');
    });

    test('Один день → без коми', () {
      final group = GroupModel(
        id: 'g1', coachId: 'c1', name: 'Test',
        childIds: [], daysOfWeek: [2],
        timeStart: '18:00', timeEnd: '19:30',
      );
      expect(group.daysLabel, 'Вт');
    });

    test('Порожній → порожній рядок', () {
      final group = GroupModel(
        id: 'g1', coachId: 'c1', name: 'Test',
        childIds: [], daysOfWeek: [],
        timeStart: '18:00', timeEnd: '19:30',
      );
      expect(group.daysLabel, '');
    });
  });

  // ── AttendanceModel ───────────────────────────────────────────────────────

  group('AttendanceModel.isPresent', () {
    AttendanceModel makeAttendance(List<String> absent) => AttendanceModel(
      id: 'doc',
      groupId: 'g1',
      coachId: 'c1',
      date: DateTime(2024, 10, 7),
      absentChildIds: absent,
    );

    test('Дитина не в списку відсутніх → присутня (default)', () {
      final att = makeAttendance(['child2', 'child3']);
      expect(att.isPresent('child1'), isTrue);
    });

    test('Дитина в списку відсутніх → відсутня', () {
      final att = makeAttendance(['child1', 'child2']);
      expect(att.isPresent('child1'), isFalse);
    });

    test('Порожній список відсутніх → всі присутні', () {
      final att = makeAttendance([]);
      expect(att.isPresent('anyone'), isTrue);
    });
  });

  group('AttendanceModel.makeId', () {
    test('Формат "{groupId}_{YYYY-MM-DD}"', () {
      final id = AttendanceModel.makeId('group123', DateTime(2024, 9, 2));
      expect(id, 'group123_2024-09-02');
    });

    test('Місяць і день з нулем', () {
      final id = AttendanceModel.makeId('g1', DateTime(2025, 1, 5));
      expect(id, 'g1_2025-01-05');
    });
  });

  group('AttendanceModel.dateKey', () {
    test('Повертає рядок YYYY-MM-DD', () {
      expect(AttendanceModel.dateKey(DateTime(2024, 11, 15)), '2024-11-15');
    });

    test('Додає ведучі нулі', () {
      expect(AttendanceModel.dateKey(DateTime(2024, 1, 3)), '2024-01-03');
    });
  });

  // ── Coach change → group cleanup logic ───────────────────────────────────

  group('Логіка зміни тренера (GroupModel)', () {
    test('trainingDates не залежать від coachId — лише від дній тижня', () {
      final g1 = GroupModel(
        id: 'g1', coachId: 'coach_old', name: 'Old group',
        childIds: ['child1'], daysOfWeek: [1, 3],
        timeStart: '18:00', timeEnd: '19:30',
      );
      final g2 = g1.copyWith(coachId: 'coach_new');
      // Same training dates regardless of coach
      expect(g1.trainingDates(2024).length, g2.trainingDates(2024).length);
    });

    test('childIds не містить дитину після видалення', () {
      final group = GroupModel(
        id: 'g1', coachId: 'c1', name: 'Test',
        childIds: ['child1', 'child2', 'child3'],
        daysOfWeek: [1], timeStart: '18:00', timeEnd: '19:30',
      );
      final updated = group.copyWith(
        childIds: group.childIds.where((id) => id != 'child2').toList(),
      );
      expect(updated.childIds, containsAll(['child1', 'child3']));
      expect(updated.childIds, isNot(contains('child2')));
    });

    test('При зміні тренера дитина має бути видалена з gruop.childIds', () {
      // Simulate: child1 moves from coach_a to coach_b
      const childId = 'child1';
      const oldCoachId = 'coach_a';

      // Group belonging to old coach that contains child1
      final oldGroup = GroupModel(
        id: 'g_old', coachId: oldCoachId, name: 'Old coach group',
        childIds: [childId, 'child2'],
        daysOfWeek: [1, 3, 5], timeStart: '17:00', timeEnd: '18:30',
      );

      // Simulate removal
      final updatedGroup = oldGroup.copyWith(
        childIds: oldGroup.childIds.where((id) => id != childId).toList(),
      );

      expect(updatedGroup.childIds, isNot(contains(childId)));
      expect(updatedGroup.childIds, contains('child2'));
      expect(updatedGroup.coachId, oldCoachId); // coach unchanged on group
    });
  });
}

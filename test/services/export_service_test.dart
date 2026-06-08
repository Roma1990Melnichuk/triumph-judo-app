import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/core/models/individual_slot_model.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

ChildModel makeChild({
  String id = 'c1',
  String firstName = 'Олексій',
  String lastName = 'Коваленко',
  int birthYear = 2010,
  BeltLevel belt = BeltLevel.green,
  Gender? gender = Gender.male,
  String weight = '-30 кг',
  String coachName = 'Тренер',
  int totalPoints = 55,
}) =>
    ChildModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      birthYear: birthYear,
      weightCategory: weight,
      currentBelt: belt,
      coachId: 'coach1',
      coachName: coachName,
      totalPoints: totalPoints,
      createdAt: DateTime(2024),
      gender: gender,
    );

IndividualSlotModel makeSlot({
  String id = 's1',
  DateTime? date,
  String timeStart = '14:00',
  String timeEnd = '14:30',
  SlotStatus status = SlotStatus.confirmed,
  String? childName = 'Олексій Коваль',
  double? price = 300,
  String currency = 'UAH',
  bool isPaid = true,
}) =>
    IndividualSlotModel(
      id: id,
      coachId: 'c1',
      coachName: 'Тренер',
      date: date ?? DateTime(2026, 6, 10),
      timeStart: timeStart,
      timeEnd: timeEnd,
      price: price,
      currency: currency,
      status: status,
      childName: childName,
      isPaid: isPaid,
    );

// ── Row-building logic (mirrors ExportService) ─────────────────────────────

List<dynamic> athleteRow(int index, ChildModel c) => [
      index + 1,
      c.lastName,
      c.firstName,
      c.birthYear,
      c.currentBelt.displayName,
      c.gender?.displayName ?? '—',
      displayWeight(c.weightCategory),
      c.coachName,
      c.totalPoints,
    ];

List<dynamic> slotRow(int index, IndividualSlotModel s) => [
      index + 1,
      '${s.date.day.toString().padLeft(2, '0')}.${s.date.month.toString().padLeft(2, '0')}.${s.date.year}',
      s.timeStart,
      s.timeEnd,
      s.childName ?? '—',
      s.status.displayName,
      s.price != null ? '${s.price} ${s.currency}' : '—',
      s.isPaid ? 'Так' : 'Ні',
    ];

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── displayWeight helper ──────────────────────────────────────────────────

  group('displayWeight', () {
    test('прибирає "-" для до-N категорій', () {
      expect(displayWeight('-30 кг'), '30 кг');
      expect(displayWeight('-48 кг'), '48 кг');
    });

    test('зберігає "+" для понад-N категорій', () {
      expect(displayWeight('+48 кг'), '+48 кг');
      expect(displayWeight('+60 кг'), '+60 кг');
    });

    test('порожній рядок → порожній рядок', () {
      expect(displayWeight(''), '');
    });
  });

  // ── Athletes CSV row ──────────────────────────────────────────────────────

  group('Рядок CSV — спортсмен', () {
    test('правильна кількість колонок', () {
      final row = athleteRow(0, makeChild());
      expect(row.length, 9);
    });

    test('нумерація починається з 1', () {
      expect(athleteRow(0, makeChild()).first, 1);
      expect(athleteRow(4, makeChild()).first, 5);
    });

    test('прізвище перед іменем', () {
      final row = athleteRow(0, makeChild(firstName: 'Олексій', lastName: 'Коваленко'));
      expect(row[1], 'Коваленко');
      expect(row[2], 'Олексій');
    });

    test('пояс як displayName', () {
      final row = athleteRow(0, makeChild(belt: BeltLevel.yellow));
      expect(row[4], BeltLevel.yellow.displayName);
    });

    test('стать як displayName для male', () {
      final row = athleteRow(0, makeChild(gender: Gender.male));
      expect(row[5], 'Хлопчик');
    });

    test('стать як displayName для female', () {
      final row = athleteRow(0, makeChild(gender: Gender.female));
      expect(row[5], 'Дівчинка');
    });

    test('стать "—" коли null', () {
      final row = athleteRow(0, makeChild(gender: null));
      expect(row[5], '—');
    });

    test('вага відображається без "-" для до-N категорій', () {
      final row = athleteRow(0, makeChild(weight: '-30 кг'));
      expect(row[6], '30 кг');
    });

    test('вага зберігає "+" для понад-N категорій', () {
      final row = athleteRow(0, makeChild(weight: '+48 кг'));
      expect(row[6], '+48 кг');
    });

    test('бали рівні totalPoints', () {
      final row = athleteRow(0, makeChild(totalPoints: 99));
      expect(row[8], 99);
    });
  });

  // ── Individual training slot CSV row ─────────────────────────────────────

  group('Рядок CSV — індив. тренування', () {
    test('правильна кількість колонок', () {
      final row = slotRow(0, makeSlot());
      expect(row.length, 8);
    });

    test('нумерація починається з 1', () {
      expect(slotRow(0, makeSlot()).first, 1);
      expect(slotRow(9, makeSlot()).first, 10);
    });

    test('дата форматується dd.MM.yyyy', () {
      final row = slotRow(0, makeSlot(date: DateTime(2026, 6, 10)));
      expect(row[1], '10.06.2026');
    });

    test('час початку і кінця', () {
      final row = slotRow(0, makeSlot(timeStart: '10:00', timeEnd: '10:30'));
      expect(row[2], '10:00');
      expect(row[3], '10:30');
    });

    test('ім\'я спортсмена', () {
      final row = slotRow(0, makeSlot(childName: 'Аліна Іванова'));
      expect(row[4], 'Аліна Іванова');
    });

    test('ім\'я "—" коли null', () {
      final row = slotRow(0, makeSlot(childName: null));
      expect(row[4], '—');
    });

    test('статус як displayName', () {
      expect(slotRow(0, makeSlot(status: SlotStatus.confirmed))[5], 'Підтверджено');
      expect(slotRow(0, makeSlot(status: SlotStatus.cancelled))[5], 'Скасовано');
    });

    test('ціна з валютою', () {
      final row = slotRow(0, makeSlot(price: 300, currency: 'UAH'));
      expect(row[6], '300.0 UAH');
    });

    test('ціна "—" коли null', () {
      final row = slotRow(0, makeSlot(price: null));
      expect(row[6], '—');
    });

    test('оплата "Так" / "Ні"', () {
      expect(slotRow(0, makeSlot(isPaid: true))[7], 'Так');
      expect(slotRow(0, makeSlot(isPaid: false))[7], 'Ні');
    });
  });

  // ── CSV serialization ─────────────────────────────────────────────────────

  group('CSV серіалізація', () {
    test('заголовок + рядки спортсменів генерують валідний CSV', () {
      final rows = <List<dynamic>>[
        ['#', 'Прізвище', "Ім'я", 'Рік нар.', 'Пояс', 'Стать', 'Вага', 'Тренер', 'Бали'],
      ];
      for (var i = 0; i < 2; i++) {
        rows.add(athleteRow(i, makeChild(id: 'c$i', lastName: 'Прізвище$i')));
      }
      final csv = const ListToCsvConverter().convert(rows);
      expect(csv, isNotEmpty);
      expect(csv, contains('Прізвище'));
      expect(csv, contains('Прізвище0'));
      expect(csv, contains('Прізвище1'));
    });

    test('порожній список → тільки заголовок', () {
      final rows = <List<dynamic>>[
        ['#', 'Прізвище', "Ім'я"],
      ];
      final csv = const ListToCsvConverter().convert(rows);
      final lines = csv.split('\n');
      expect(lines.length, 1);
    });

    test('рядки зі слотами генерують валідний CSV', () {
      final rows = <List<dynamic>>[
        ['#', 'Дата', 'Початок', 'Кінець', 'Спортсмен', 'Статус', 'Ціна', 'Оплачено'],
        slotRow(0, makeSlot()),
      ];
      final csv = const ListToCsvConverter().convert(rows);
      expect(csv, contains('10.06.2026'));
      expect(csv, contains('Підтверджено'));
      expect(csv, contains('Так'));
    });
  });
}

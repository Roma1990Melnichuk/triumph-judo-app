/// TC-CSV — Імпорт дітей через CSV-файл.
///
/// Ключові правила:
///   1. Роздільник: якщо кількість крапок з комою > кількість ком → крапка з комою
///   2. Рік народження: видаляються всі нецифрові символи перед parse
///   3. Допустимий діапазон народження: 1990 до DateTime.now().year включно
///   4. Пояс: спочатку по BeltLevel.name, потім BeltLevel.displayName; default = white
///   5. Обов'язкові колонки: lastName/lastname, firstName/firstname, birthYear/birthyear
///   6. Порожній lastName або firstName → рядок пропускається з помилкою
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/features/team/services/csv_import_service.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

// Returns valid rows or empty list
List<CsvRow> _parse(String csv) => CsvImportService.parse(csv).valid;

List<String> _errors(String csv) => CsvImportService.parse(csv).errors;

// Header aliases recognized by the parser (lowercase match)
const _headerSemi = 'lastName;firstName;birthYear;belt;weightCategory';
const _headerComma = 'lastName,firstName,birthYear,belt,weightCategory';

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── TC-CSV-001: визначення роздільника ───────────────────────────────────

  group('TC-CSV-001: визначення роздільника', () {
    test('більше крапок з комою → роздільник = ";"', () {
      final csv = 'lastName;firstName;birthYear\nКоваль;Іван;2010';
      final result = _parse(csv);
      expect(result, hasLength(1));
      expect(result.first.lastName, equals('Коваль'));
      expect(result.first.firstName, equals('Іван'));
    });

    test('більше ком → роздільник = ","', () {
      final csv = 'lastName,firstName,birthYear\nПетренко,Олена,2012';
      final result = _parse(csv);
      expect(result, hasLength(1));
      expect(result.first.lastName, equals('Петренко'));
      expect(result.first.firstName, equals('Олена'));
    });

    test('чисто крапки з комою → правильно парситься', () {
      final csv = '$_headerSemi\nМова;Тест;2011;white;-30 кг';
      final result = _parse(csv);
      expect(result, hasLength(1));
      expect(result.first.lastName, equals('Мова'));
    });

    test('чисто коми → правильно парситься', () {
      final csv = '$_headerComma\nОлійник,Марта,2013,yellow,-32 кг';
      final result = _parse(csv);
      expect(result, hasLength(1));
      expect(result.first.lastName, equals('Олійник'));
    });
  });

  // ── TC-CSV-002: рік народження — видалення нецифрових символів ───────────

  group('TC-CSV-002: birthYear — видалення нецифрових символів', () {
    test('чистий рік "2010" → birthYear = 2010', () {
      final csv = '$_headerSemi\nКоваль;Іван;2010;;';
      final result = _parse(csv);
      expect(result.first.birthYear, equals(2010));
    });

    test('"2010р." → видаляє нецифрові → 2010', () {
      final csv = '$_headerSemi\nКоваль;Іван;2010р.;;';
      final result = _parse(csv);
      expect(result.first.birthYear, equals(2010));
    });

    test('"2010г" → видаляє "г" → 2010', () {
      final csv = '$_headerSemi\nКоваль;Іван;2010г;;';
      final result = _parse(csv);
      expect(result.first.birthYear, equals(2010));
    });

    test('"р. 2012" → видаляє нецифрові → 2012', () {
      final csv = '$_headerSemi\nКоваль;Іван;р. 2012;;';
      final result = _parse(csv);
      expect(result.first.birthYear, equals(2012));
    });

    test('якщо після видалення нецифрових — не число → рядок пропускається', () {
      final csv = '$_headerSemi\nКоваль;Іван;abc;;';
      final result = _parse(csv);
      expect(result, isEmpty, reason: 'Нечисловий рік → пропускаємо рядок');
    });
  });

  // ── TC-CSV-003: діапазон дат народження ──────────────────────────────────

  group('TC-CSV-003: допустимий діапазон birthYear = [1990, currentYear]', () {
    test('рік = 1990 → приймається', () {
      final csv = '$_headerSemi\nКоваль;Іван;1990;;';
      final result = _parse(csv);
      expect(result, hasLength(1));
      expect(result.first.birthYear, equals(1990));
    });

    test('рік = поточний рік → приймається', () {
      final currentYear = DateTime.now().year;
      final csv = '$_headerSemi\nКоваль;Іван;$currentYear;;';
      final result = _parse(csv);
      expect(result, hasLength(1));
    });

    test('рік = 1989 (до 1990) → рядок пропускається', () {
      final csv = '$_headerSemi\nКоваль;Іван;1989;;';
      final result = _parse(csv);
      expect(result, isEmpty,
          reason: '1989 < 1990 → недопустимий рік');
    });

    test('рік = наступний рік → рядок пропускається', () {
      final nextYear = DateTime.now().year + 1;
      final csv = '$_headerSemi\nКоваль;Іван;$nextYear;;';
      final result = _parse(csv);
      expect(result, isEmpty,
          reason: 'Майбутній рік → недопустимий');
    });

    test('рік = 2000 → приймається', () {
      final csv = '$_headerSemi\nКоваль;Іван;2000;;';
      final result = _parse(csv);
      expect(result, hasLength(1));
    });
  });

  // ── TC-CSV-004: розпізнавання пояса ──────────────────────────────────────

  group('TC-CSV-004: поле belt — розпізнавання за BeltLevel.name', () {
    test('belt = "white" → BeltLevel.white', () {
      final csv = '$_headerSemi\nКоваль;Іван;2010;white;';
      final result = _parse(csv);
      expect(result.first.belt, equals(BeltLevel.white));
    });

    test('belt = "yellow" → BeltLevel.yellow', () {
      final csv = '$_headerSemi\nКоваль;Іван;2010;yellow;';
      final result = _parse(csv);
      expect(result.first.belt, equals(BeltLevel.yellow));
    });

    test('belt = "black" → BeltLevel.black', () {
      final csv = '$_headerSemi\nКоваль;Іван;2010;black;';
      final result = _parse(csv);
      expect(result.first.belt, equals(BeltLevel.black));
    });

    test('belt порожній → default = BeltLevel.white', () {
      final csv = '$_headerSemi\nКоваль;Іван;2010;;';
      final result = _parse(csv);
      expect(result.first.belt, equals(BeltLevel.white));
    });

    test('belt = "невідомий" → default = BeltLevel.white', () {
      final csv = '$_headerSemi\nКоваль;Іван;2010;невідомий;';
      final result = _parse(csv);
      expect(result.first.belt, equals(BeltLevel.white));
    });
  });

  // ── TC-CSV-005: обов'язкові поля ─────────────────────────────────────────

  group('TC-CSV-005: обов\'язкові поля — відсутня колонка → всі рядки у errors', () {
    test('без колонки lastName → result.valid порожній, є errors', () {
      final csv = 'firstName;birthYear\nІван;2010';
      final result = CsvImportService.parse(csv);
      expect(result.valid, isEmpty);
      expect(result.errors, isNotEmpty);
    });

    test('без колонки firstName → result.valid порожній', () {
      final csv = 'lastName;birthYear\nКоваль;2010';
      final result = CsvImportService.parse(csv);
      expect(result.valid, isEmpty);
      expect(result.errors, isNotEmpty);
    });

    test('всі 3 обов\'язкових поля → рядок у valid', () {
      final csv = '$_headerSemi\nКоваль;Іван;2010;;';
      final result = CsvImportService.parse(csv);
      expect(result.valid, hasLength(1));
    });

    test('порожній lastName в рядку → рядок пропускається з помилкою', () {
      final csv = '$_headerSemi\n;Іван;2010;;';
      final result = CsvImportService.parse(csv);
      expect(result.valid, isEmpty);
      expect(result.errors, isNotEmpty);
    });

    test('порожній firstName в рядку → рядок пропускається з помилкою', () {
      final csv = '$_headerSemi\nКоваль;;2010;;';
      final result = CsvImportService.parse(csv);
      expect(result.valid, isEmpty);
      expect(result.errors, isNotEmpty);
    });
  });

  // ── TC-CSV-006: кілька рядків — частково невалідні ───────────────────────

  group('TC-CSV-006: файл із кількома рядками, деякі невалідні', () {
    test('2 валідних + 1 з невалідним роком → valid.length=2', () {
      final csv =
          '$_headerSemi\nКоваль;Іван;2010;;\nПетренко;Оля;1989;;\nМова;Ніна;2015;;';
      final result = CsvImportService.parse(csv);
      expect(result.valid, hasLength(2),
          reason: 'Рядок з 1989 (< 1990) пропускається');
      expect(result.errors, hasLength(1));
    });

    test('порожні рядки між даними не ламають парсер', () {
      final csv =
          '$_headerSemi\nКоваль;Іван;2010;;\n\nМова;Ніна;2015;;';
      final result = CsvImportService.parse(csv);
      expect(result.valid, hasLength(2));
    });

    test('firstName і lastName передаються точно', () {
      final csv = '$_headerSemi\nГалицька;Катерина-Марія;2011;;';
      final result = _parse(csv);
      expect(result.first.firstName, equals('Катерина-Марія'));
      expect(result.first.lastName, equals('Галицька'));
    });
  });

  // ── TC-CSV-007: weightCategory default ────────────────────────────────────

  group('TC-CSV-007: weightCategory — default значення "-30 кг"', () {
    test('порожній weightCategory → "-30 кг"', () {
      final csv = '$_headerSemi\nКоваль;Іван;2010;;';
      final result = _parse(csv);
      expect(result.first.weightCategory, equals('-30 кг'));
    });

    test('заповнений weightCategory → береться з файлу', () {
      final csv = '$_headerSemi\nКоваль;Іван;2010;;-46 кг';
      final result = _parse(csv);
      expect(result.first.weightCategory, equals('-46 кг'));
    });
  });

  // ── TC-CSV-008: порожній файл ─────────────────────────────────────────────

  group('TC-CSV-008: граничні випадки', () {
    test('порожній файл → valid порожній, є errors', () {
      final result = CsvImportService.parse('');
      expect(result.valid, isEmpty);
      expect(result.errors, isNotEmpty);
    });

    test('тільки заголовок без рядків даних → valid порожній', () {
      final csv = _headerSemi;
      final result = CsvImportService.parse(csv);
      expect(result.valid, isEmpty);
    });
  });
}

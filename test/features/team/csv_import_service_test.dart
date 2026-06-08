import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/features/team/services/csv_import_service.dart';

void main() {
  group('CsvImportService.parse — порожній/невалідний вміст', () {
    test('порожній рядок → помилка', () {
      final result = CsvImportService.parse('');
      expect(result.valid, isEmpty);
      expect(result.errors, isNotEmpty);
    });

    test('тільки пробіли → помилка', () {
      final result = CsvImportService.parse('   \n  ');
      expect(result.valid, isEmpty);
    });

    test('відсутня колонка Прізвище → помилка', () {
      const csv = "Ім'я,Рік\nОлексій,2012";
      final result = CsvImportService.parse(csv);
      expect(result.valid, isEmpty);
      expect(result.errors.first, contains('обов'));
    });
  });

  group('CsvImportService.parse — коректний CSV (кома)', () {
    const csv = "Прізвище,Ім'я,Рік,Вага,Пояс\n"
        "Коваленко,Олексій,2012,-30 кг,white\n"
        "Петренко,Марія,2011,-36 кг,yellow";

    test('парсить 2 рядки', () {
      expect(CsvImportService.parse(csv).valid, hasLength(2));
    });

    test('правильно зчитує поля першого рядка', () {
      final row = CsvImportService.parse(csv).valid.first;
      expect(row.lastName, 'Коваленко');
      expect(row.firstName, 'Олексій');
      expect(row.birthYear, 2012);
      expect(row.weightCategory, '-30 кг');
      expect(row.belt, BeltLevel.white);
    });

    test('парсить пояс другого рядка', () {
      final row = CsvImportService.parse(csv).valid[1];
      expect(row.belt, BeltLevel.yellow);
    });

    test('немає помилок', () {
      expect(CsvImportService.parse(csv).errors, isEmpty);
    });
  });

  group('CsvImportService.parse — коректний CSV (крапка з комою)', () {
    const csv = "Прізвище;Ім'я;Рік\nШевченко;Іван;2013";

    test('парсить через крапку з комою', () {
      final result = CsvImportService.parse(csv);
      expect(result.valid, hasLength(1));
      expect(result.valid.first.lastName, 'Шевченко');
    });
  });

  group('CsvImportService.parse — необов\'язкові поля', () {
    test('без колонки Вага → дефолт -30 кг', () {
      const csv = "Прізвище,Ім'я,Рік\nМороз,Дмитро,2012";
      final row = CsvImportService.parse(csv).valid.first;
      expect(row.weightCategory, '-30 кг');
    });

    test('без колонки Пояс → дефолт white', () {
      const csv = "Прізвище,Ім'я,Рік\nМороз,Дмитро,2012";
      final row = CsvImportService.parse(csv).valid.first;
      expect(row.belt, BeltLevel.white);
    });

    test('невідомий пояс → white', () {
      const csv = "Прізвище,Ім'я,Рік,Пояс\nМороз,Дмитро,2012,superblack";
      final row = CsvImportService.parse(csv).valid.first;
      expect(row.belt, BeltLevel.white);
    });
  });

  group('CsvImportService.parse — невалідні рядки', () {
    test('невірний рік → помилка + пропускається', () {
      const csv = "Прізвище,Ім'я,Рік\nКоваль,Іван,abc";
      final result = CsvImportService.parse(csv);
      expect(result.valid, isEmpty);
      expect(result.errors, isNotEmpty);
    });

    test('рік у майбутньому → помилка', () {
      final future = (DateTime.now().year + 1).toString();
      final csv = "Прізвище,Ім'я,Рік\nКоваль,Іван,$future";
      expect(CsvImportService.parse(csv).valid, isEmpty);
    });

    test('рік до 1990 → помилка', () {
      const csv = "Прізвище,Ім'я,Рік\nКоваль,Іван,1985";
      expect(CsvImportService.parse(csv).valid, isEmpty);
    });

    test('порожнє прізвище → пропускається з помилкою', () {
      const csv = "Прізвище,Ім'я,Рік\n,Іван,2012\nПетренко,Марія,2011";
      final result = CsvImportService.parse(csv);
      expect(result.valid, hasLength(1));
      expect(result.errors, isNotEmpty);
    });

    test('порожні рядки ігноруються', () {
      const csv = "Прізвище,Ім'я,Рік\nКоваль,Іван,2012\n\n   \nПетренко,Марія,2011";
      expect(CsvImportService.parse(csv).valid, hasLength(2));
    });
  });

  group('CsvImportService.parse — парсинг поясу', () {
    test('parses all BeltLevel enum names', () {
      for (final belt in BeltLevel.values) {
        final csv = "Прізвище,Ім'я,Рік,Пояс\nТест,Тест,2012,${belt.name}";
        final row = CsvImportService.parse(csv).valid.first;
        expect(row.belt, belt, reason: 'не розпарсив ${belt.name}');
      }
    });
  });
}

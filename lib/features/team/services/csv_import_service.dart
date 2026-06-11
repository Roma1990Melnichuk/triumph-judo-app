import 'package:csv/csv.dart';
import '../../../core/constants/belt_levels.dart';

class CsvRow {
  final String lastName;
  final String firstName;
  final int birthYear;
  final String weightCategory;
  final BeltLevel belt;

  const CsvRow({
    required this.lastName,
    required this.firstName,
    required this.birthYear,
    required this.weightCategory,
    required this.belt,
  });
}

class CsvParseResult {
  final List<CsvRow> valid;
  final List<String> errors;

  const CsvParseResult({required this.valid, required this.errors});
}

class CsvImportService {
  static CsvParseResult parse(String content) {
    if (content.trim().isEmpty) {
      return const CsvParseResult(valid: [], errors: ['Файл порожній']);
    }

    final firstLine = content.split('\n').first;
    final separator = _detectSeparator(firstLine);

    final rows = CsvToListConverter(fieldDelimiter: separator, eol: '\n')
        .convert(content.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));

    if (rows.isEmpty) {
      return const CsvParseResult(valid: [], errors: ['Не вдалося прочитати файл']);
    }

    final header =
        rows.first.map((e) => e.toString().trim().toLowerCase()).toList();

    final lastNameIdx = _findCol(header, ['прізвище', 'lastname', 'last_name', 'фамилия']);
    final firstNameIdx = _findCol(header, ["ім'я", 'імʼя', 'імя', 'firstname', 'first_name', 'имя']);
    final birthYearIdx = _findCol(header, ['рік', 'рік народження', 'year', 'birthyear', 'birth_year', 'год', 'год рождения']);
    final weightIdx = _findCol(header, ['вага', 'вагова категорія', 'weight', 'weightcategory', 'вес']);
    final beltIdx = _findCol(header, ['пояс', 'belt', 'currentbelt']);

    if (lastNameIdx == -1 || firstNameIdx == -1 || birthYearIdx == -1) {
      return CsvParseResult(
        valid: [],
        errors: ['Відсутні обовʼязкові колонки: Прізвище, Імʼя, Рік\nЗнайдено: ${header.join(', ')}'],
      );
    }

    final valid = <CsvRow>[];
    final errors = <String>[];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      // ERR-02 Fix: Better empty row validation to avoid RangeError
      if (row.isEmpty || row.every((e) => e == null || e.toString().trim().isEmpty)) continue;

      final lastName = _cell(row, lastNameIdx);
      final firstName = _cell(row, firstNameIdx);
      final yearStr = _cell(row, birthYearIdx);
      final weight = weightIdx != -1 ? _cell(row, weightIdx) : '';
      final beltStr = beltIdx != -1 ? _cell(row, beltIdx) : '';

      if (lastName.isEmpty || firstName.isEmpty) {
        errors.add('Рядок ${i + 1}: порожнє прізвище або імʼя');
        continue;
      }

      final year = int.tryParse(yearStr.replaceAll(RegExp(r'\D'), ''));
      if (year == null || year < 1990 || year > DateTime.now().year) {
        errors.add('Рядок ${i + 1}: невірний рік "$yearStr"');
        continue;
      }

      valid.add(CsvRow(
        lastName: lastName,
        firstName: firstName,
        birthYear: year,
        weightCategory: weight.isEmpty ? '-30 кг' : weight,
        belt: _parseBelt(beltStr),
      ));
    }

    return CsvParseResult(valid: valid, errors: errors);
  }

  static String _detectSeparator(String line) {
    final semis = ';'.allMatches(line).length;
    final commas = ','.allMatches(line).length;
    return semis > commas ? ';' : ',';
  }

  static int _findCol(List<String> headers, List<String> candidates) {
    for (var i = 0; i < headers.length; i++) {
      if (candidates.contains(headers[i])) return i;
    }
    return -1;
  }

  static String _cell(List row, int idx) =>
      idx < row.length ? row[idx].toString().trim() : '';

  static BeltLevel _parseBelt(String raw) {
    final lower = raw.toLowerCase().trim();
    for (final b in BeltLevel.values) {
      if (b.name.toLowerCase() == lower) return b;
    }
    for (final b in BeltLevel.values) {
      if (b.displayName.toLowerCase() == lower) return b;
    }
    return BeltLevel.white;
  }
}

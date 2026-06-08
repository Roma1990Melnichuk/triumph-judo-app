import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/utils/form_validators.dart';

void main() {
  // ── email ─────────────────────────────────────────────────────────────────

  group('FormValidators.email', () {
    test('null → помилка "Введіть email"', () {
      expect(FormValidators.email(null), 'Введіть email');
    });

    test('порожній рядок → помилка', () {
      expect(FormValidators.email(''), 'Введіть email');
    });

    test('без символу @ → "Невірний email"', () {
      expect(FormValidators.email('notanemail'), 'Невірний email');
    });

    test('тільки @ → null (містить @, поточна логіка не перевіряє решту)', () {
      expect(FormValidators.email('@'), isNull);
    });

    test('валідний email → null', () {
      expect(FormValidators.email('user@gmail.com'), isNull);
    });

    test('email з підdomainом → null', () {
      expect(FormValidators.email('coach@club.org.ua'), isNull);
    });

    test('email з + у локальній частині → null', () {
      expect(FormValidators.email('user+tag@mail.com'), isNull);
    });

    test('рядок пробілів без @ → "Невірний email" (не порожній, але нема @)', () {
      expect(FormValidators.email('   '), 'Невірний email');
    });
  });

  // ── password ──────────────────────────────────────────────────────────────

  group('FormValidators.password', () {
    test('null → "Введіть пароль"', () {
      expect(FormValidators.password(null), 'Введіть пароль');
    });

    test('порожній → "Введіть пароль"', () {
      expect(FormValidators.password(''), 'Введіть пароль');
    });

    test('5 символів → "Мінімум 6 символів"', () {
      expect(FormValidators.password('abc12'), 'Мінімум 6 символів');
    });

    test('1 символ → помилка', () {
      expect(FormValidators.password('a'), 'Мінімум 6 символів');
    });

    test('рівно 6 символів → null (граничне значення)', () {
      expect(FormValidators.password('abc123'), isNull);
    });

    test('7 символів → null', () {
      expect(FormValidators.password('abc1234'), isNull);
    });

    test('кирилиця 6 символів → null', () {
      expect(FormValidators.password('абвгде'), isNull);
    });

    test('пробіли без інших символів, 6 штук → null (пароль з пробілів)', () {
      expect(FormValidators.password('      '), isNull);
    });
  });

  // ── confirmPasswordWith ───────────────────────────────────────────────────

  group('FormValidators.confirmPasswordWith', () {
    test('null → "Підтвердіть пароль"', () {
      expect(FormValidators.confirmPasswordWith(null, 'abc123'), 'Підтвердіть пароль');
    });

    test('порожній → "Підтвердіть пароль"', () {
      expect(FormValidators.confirmPasswordWith('', 'abc123'), 'Підтвердіть пароль');
    });

    test('не збігається → "Паролі не збігаються"', () {
      expect(
        FormValidators.confirmPasswordWith('abc123', 'xyz789'),
        'Паролі не збігаються',
      );
    });

    test('різний регістр → "Паролі не збігаються"', () {
      expect(
        FormValidators.confirmPasswordWith('Secret1', 'secret1'),
        'Паролі не збігаються',
      );
    });

    test('збігається → null', () {
      expect(FormValidators.confirmPasswordWith('MyPass1', 'MyPass1'), isNull);
    });

    test('збігається з кирилицею → null', () {
      expect(FormValidators.confirmPasswordWith('Пароль1', 'Пароль1'), isNull);
    });
  });

  // ── fullName ──────────────────────────────────────────────────────────────

  group('FormValidators.fullName', () {
    test('null → помилка', () {
      expect(FormValidators.fullName(null), "Введіть ім'я");
    });

    test('порожній → помилка', () {
      expect(FormValidators.fullName(''), "Введіть ім'я");
    });

    test('тільки пробіли → помилка (trim)', () {
      expect(FormValidators.fullName('   '), "Введіть ім'я");
    });

    test('тільки пробіли (tab) → помилка', () {
      expect(FormValidators.fullName('\t'), "Введіть ім'я");
    });

    test('одне слово → null', () {
      expect(FormValidators.fullName('Іван'), isNull);
    });

    test('ім\'я з прізвищем → null', () {
      expect(FormValidators.fullName('Іван Коваль'), isNull);
    });

    test('з пробілами навколо → null (просто не пустий після trim)', () {
      expect(FormValidators.fullName('  Олег  '), isNull);
    });
  });

  // ── lastName ──────────────────────────────────────────────────────────────

  group('FormValidators.lastName', () {
    test('null → "Введіть прізвище"', () {
      expect(FormValidators.lastName(null), 'Введіть прізвище');
    });

    test('порожній → "Введіть прізвище"', () {
      expect(FormValidators.lastName(''), 'Введіть прізвище');
    });

    test('валідне прізвище → null', () {
      expect(FormValidators.lastName('Коваленко'), isNull);
    });

    test('прізвище з дефісом → null', () {
      expect(FormValidators.lastName('Бойко-Гончар'), isNull);
    });

    test('пробіл → null (не перевіряємо whitespace-only в lastName)', () {
      // lastName не робить trim — пробіл вважається непорожнім
      expect(FormValidators.lastName(' '), isNull);
    });
  });

  // ── firstName ─────────────────────────────────────────────────────────────

  group('FormValidators.firstName', () {
    test('null → помилка', () {
      expect(FormValidators.firstName(null), "Введіть ім'я");
    });

    test('порожній → помилка', () {
      expect(FormValidators.firstName(''), "Введіть ім'я");
    });

    test('кирилиця → null', () {
      expect(FormValidators.firstName('Олексій'), isNull);
    });

    test('латиниця → null', () {
      expect(FormValidators.firstName('Ivan'), isNull);
    });
  });

  // ── competitionName ───────────────────────────────────────────────────────

  group('FormValidators.competitionName', () {
    test('null → "Введіть назву"', () {
      expect(FormValidators.competitionName(null), 'Введіть назву');
    });

    test('порожній → "Введіть назву"', () {
      expect(FormValidators.competitionName(''), 'Введіть назву');
    });

    test('кирилична назва → null', () {
      expect(FormValidators.competitionName('Кубок міста'), isNull);
    });

    test('назва з цифрами → null', () {
      expect(FormValidators.competitionName('Чемпіонат 2026'), isNull);
    });

    test('один символ → null', () {
      expect(FormValidators.competitionName('А'), isNull);
    });
  });

  // ── place ─────────────────────────────────────────────────────────────────

  group('FormValidators.place', () {
    test('null → помилка', () {
      expect(FormValidators.place(null), 'Введіть місце (≥ 1)');
    });

    test('порожній → помилка', () {
      expect(FormValidators.place(''), 'Введіть місце (≥ 1)');
    });

    test('не число → помилка', () {
      expect(FormValidators.place('abc'), 'Введіть місце (≥ 1)');
    });

    test('0 → помилка (мінімум 1)', () {
      expect(FormValidators.place('0'), 'Введіть місце (≥ 1)');
    });

    test('від\'ємне → помилка', () {
      expect(FormValidators.place('-1'), 'Введіть місце (≥ 1)');
    });

    test('1 → null (граничне значення)', () {
      expect(FormValidators.place('1'), isNull);
    });

    test('2 → null', () {
      expect(FormValidators.place('2'), isNull);
    });

    test('999 → null', () {
      expect(FormValidators.place('999'), isNull);
    });

    test('дробове число → помилка', () {
      expect(FormValidators.place('1.5'), 'Введіть місце (≥ 1)');
    });

    test('пробіл → помилка', () {
      expect(FormValidators.place(' '), 'Введіть місце (≥ 1)');
    });
  });

  // ── points ────────────────────────────────────────────────────────────────

  group('FormValidators.points', () {
    test('null → "Введіть бали"', () {
      expect(FormValidators.points(null), 'Введіть бали');
    });

    test('порожній → "Введіть бали"', () {
      expect(FormValidators.points(''), 'Введіть бали');
    });

    test('не число → "Лише цифри"', () {
      expect(FormValidators.points('abc'), 'Лише цифри');
    });

    test('дробове → "Лише цифри"', () {
      expect(FormValidators.points('1.5'), 'Лише цифри');
    });

    test('від\'ємне ціле → "Бали ≥ 0"', () {
      expect(FormValidators.points('-1'), 'Бали ≥ 0');
    });

    test('-100 → помилка', () {
      expect(FormValidators.points('-100'), 'Бали ≥ 0');
    });

    test('0 → null (граничне значення)', () {
      expect(FormValidators.points('0'), isNull);
    });

    test('1 → null', () {
      expect(FormValidators.points('1'), isNull);
    });

    test('100 → null', () {
      expect(FormValidators.points('100'), isNull);
    });

    test('великі числа → null', () {
      expect(FormValidators.points('9999'), isNull);
    });

    test('пробіл → "Лише цифри"', () {
      expect(FormValidators.points(' '), 'Лише цифри');
    });
  });
}

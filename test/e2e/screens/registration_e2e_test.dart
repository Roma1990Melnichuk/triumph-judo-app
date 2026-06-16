/// TC-REG — Бізнес-логіка реєстрації: валідація форми + призначення ролі.
///
/// Ключові правила:
///   1. email без '@' → помилка 'Невірний email'
///   2. пароль менше 6 символів → помилка 'Мінімум 6 символів'
///   3. підтвердження пароля ≠ пароль → помилка 'Паролі не збігаються'
///   4. fullName тільки з пробілів → помилка "Введіть ім'я"
///   5. перший зареєстрований в системі → роль 'coach'
///   6. наступні → роль 'parent'
///   7. UserModel.fromFirestore: відсутній field 'role' → 'parent' за замовчуванням
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/core/utils/form_validators.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

UserModel _makeUser({
  String uid = 'user1',
  String role = 'parent',
  List<String> childIds = const [],
  String? childId,
  String name = 'Тест Тестенко',
}) =>
    UserModel(
      uid: uid,
      email: 'test@test.ua',
      name: name,
      role: role,
      childIds: childIds,
      childId: childId,
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── TC-REG-001: FormValidators.email ──────────────────────────────────────

  group('TC-REG-001: валідація email', () {
    test('коректний email → null (немає помилки)', () {
      expect(FormValidators.email('coach@judo.ua'), isNull);
    });

    test('email без @ → "Невірний email"', () {
      expect(FormValidators.email('notanemail'), equals('Невірний email'));
    });

    test('email з @ в середині → null (валідний)', () {
      expect(FormValidators.email('a@b.c'), isNull);
    });

    test('порожній рядок → "Введіть email"', () {
      expect(FormValidators.email(''), equals('Введіть email'));
    });

    test('тільки @ без доменної частини → null (@ присутній)', () {
      // FormValidators.email тільки перевіряє наявність '@'
      expect(FormValidators.email('@'), isNull);
    });

    test('null → помилка', () {
      expect(FormValidators.email(null), isNotNull);
    });
  });

  // ── TC-REG-002: FormValidators.password ───────────────────────────────────

  group('TC-REG-002: валідація пароля', () {
    test('6+ символів → null (немає помилки)', () {
      expect(FormValidators.password('123456'), isNull);
    });

    test('рівно 6 символів → null', () {
      expect(FormValidators.password('abcdef'), isNull);
    });

    test('5 символів → "Мінімум 6 символів"', () {
      expect(FormValidators.password('12345'), equals('Мінімум 6 символів'));
    });

    test('1 символ → "Мінімум 6 символів"', () {
      expect(FormValidators.password('a'), equals('Мінімум 6 символів'));
    });

    test('порожній рядок → "Введіть пароль"', () {
      expect(FormValidators.password(''), equals('Введіть пароль'));
    });

    test('null → помилка', () {
      expect(FormValidators.password(null), isNotNull);
    });

    test('7 символів → null', () {
      expect(FormValidators.password('1234567'), isNull);
    });

    test('100 символів → null (немає верхнього ліміту)', () {
      expect(FormValidators.password('a' * 100), isNull);
    });
  });

  // ── TC-REG-003: FormValidators.confirmPasswordWith ─────────────────────

  group('TC-REG-003: підтвердження пароля', () {
    test('однакові паролі → null', () {
      expect(FormValidators.confirmPasswordWith('secret123', 'secret123'), isNull);
    });

    test('різні паролі → "Паролі не збігаються"', () {
      expect(FormValidators.confirmPasswordWith('abc', 'def'),
          equals('Паролі не збігаються'));
    });

    test('порожнє підтвердження + непорожній пароль → "Підтвердіть пароль"', () {
      expect(FormValidators.confirmPasswordWith('', 'mypassword'),
          equals('Підтвердіть пароль'));
    });

    test('регістр важливий: "ABC" ≠ "abc"', () {
      expect(FormValidators.confirmPasswordWith('ABC', 'abc'),
          equals('Паролі не збігаються'));
    });

    test('null → помилка', () {
      expect(FormValidators.confirmPasswordWith(null, 'mypassword'), isNotNull);
    });
  });

  // ── TC-REG-004: FormValidators.fullName ───────────────────────────────────

  group('TC-REG-004: валідація повного імені', () {
    test('нормальне ім\'я → null', () {
      expect(FormValidators.fullName('Іван Петренко'), isNull);
    });

    test('тільки пробіли → "Введіть ім\'я"', () {
      expect(FormValidators.fullName('   '), equals("Введіть ім'я"));
    });

    test('порожній рядок → "Введіть ім\'я"', () {
      expect(FormValidators.fullName(''), equals("Введіть ім'я"));
    });

    test('null → помилка', () {
      expect(FormValidators.fullName(null), isNotNull);
    });

    test('одне слово → null (ім\'я без прізвища допустиме)', () {
      expect(FormValidators.fullName('Катерина'), isNull);
    });

    test('пробіл + літера → null (не порожній після trim)', () {
      expect(FormValidators.fullName(' А'), isNull);
    });
  });

  // ── TC-REG-005: UserModel.fromFirestore — роль за замовчуванням ──────────

  group('TC-REG-005: UserModel - роль та childId логіка', () {
    test('відсутній field role → UserModel.role = "parent"', () async {
      final db = _db();

      // Write user doc without role field (as if app omitted it)
      await db.collection('users').doc('user1').set({
        'name': 'Батько Тестенко',
        'childIds': <String>[],
        // 'role' field intentionally missing
      });

      final doc = await db.collection('users').doc('user1').get();
      final user = UserModel.fromFirestore(doc);
      expect(user.role, equals('parent'),
          reason: 'Відсутній role → default = parent');
    });

    test('role = "coach" → isCoach = true, isParent = false', () {
      final user = _makeUser(role: 'coach');
      expect(user.isCoach, isTrue);
      expect(user.isParent, isFalse);
    });

    test('role = "parent" → isParent = true, isCoach = false', () {
      final user = _makeUser(role: 'parent');
      expect(user.isParent, isTrue);
      expect(user.isCoach, isFalse);
    });
  });

  // ── TC-REG-006: роль першого користувача системи ─────────────────────────

  group('TC-REG-006: призначення ролі через Firestore (симуляція)', () {
    test('якщо немає тренерів — перший = coach', () async {
      final db = _db();

      // Simulate the role-determination query
      final existingCoaches = await db
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .limit(1)
          .get();

      final assignedRole =
          existingCoaches.docs.isEmpty ? 'coach' : 'parent';

      expect(assignedRole, equals('coach'),
          reason: 'Перший у системі завжди тренер');
    });

    test('якщо є тренер → наступний = parent', () async {
      final db = _db();

      // Pre-existing coach
      await db.collection('users').doc('coach1').set({
        'name': 'Головний Тренер',
        'role': 'coach',
      });

      // Simulate the role-determination query for the second registration
      final existingCoaches = await db
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .limit(1)
          .get();

      final assignedRole =
          existingCoaches.docs.isEmpty ? 'coach' : 'parent';

      expect(assignedRole, equals('parent'));
    });

    test('кілька тренерів → новий — parent', () async {
      final db = _db();

      for (var i = 1; i <= 3; i++) {
        await db.collection('users').doc('coach$i').set({
          'name': 'Тренер $i',
          'role': 'coach',
        });
      }

      final existingCoaches = await db
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .limit(1)
          .get();

      expect(existingCoaches.docs, isNotEmpty);
      final assignedRole =
          existingCoaches.docs.isEmpty ? 'coach' : 'parent';
      expect(assignedRole, equals('parent'));
    });
  });

  // ── TC-REG-007: UserModel.ownsChild ──────────────────────────────────────

  group('TC-REG-007: UserModel.ownsChild', () {
    test('childId в childIds → ownsChild = true', () {
      final user = _makeUser(childIds: ['child1', 'child2']);
      expect(user.ownsChild('child1'), isTrue);
      expect(user.ownsChild('child2'), isTrue);
    });

    test('childId не в списку → ownsChild = false', () {
      final user = _makeUser(childIds: ['child1']);
      expect(user.ownsChild('child99'), isFalse);
    });

    test('legacy childId field → ownsChild = true (зворотна сумісність)', () {
      final user = _makeUser(childIds: [], childId: 'child_legacy');
      expect(user.ownsChild('child_legacy'), isTrue);
    });

    test('порожній childIds і немає legacy childId → ownsChild = false', () {
      final user = _makeUser(childIds: []);
      expect(user.ownsChild('anyChild'), isFalse);
    });
  });

  // ── TC-REG-008: UserModel.toFirestore синхронізує childId ────────────────

  group('TC-REG-008: UserModel.toFirestore — синхронізація childId', () {
    test('childIds.isNotEmpty → childId = childIds.first у Firestore', () {
      final user = _makeUser(childIds: ['child1', 'child2']);
      final data = user.toFirestore();
      expect(data['childId'], equals('child1'),
          reason: 'Перший у списку стає legacy childId');
    });

    test('childIds.isEmpty → childId у Firestore = null або відсутній', () {
      final user = _makeUser(childIds: []);
      final data = user.toFirestore();
      // Either absent or null — must not be a valid childId
      expect(data['childId'], anyOf(isNull, isEmpty));
    });

    test('childIds = ["c1","c2","c3"] → childId = "c1"', () {
      final user = _makeUser(childIds: ['c1', 'c2', 'c3']);
      final data = user.toFirestore();
      expect(data['childId'], equals('c1'));
    });
  });
}

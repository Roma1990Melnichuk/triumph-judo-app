/// TC-USER-MODEL — UserModel бізнес-логіка: ownsChild, toFirestore, роль.
///
/// Ключові правила:
///   1. ownsChild(id) = childIds.contains(id) || childId == id
///   2. toFirestore(): якщо childIds.isNotEmpty → 'childId': childIds.first
///   3. fromFirestore: відсутній field 'role' → 'parent' за замовчуванням
///   4. isCoach = role == 'coach', isParent = role == 'parent'
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/user_model.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

UserModel _user({
  String uid = 'user1',
  String role = 'parent',
  List<String> childIds = const [],
  String? childId,
  String name = 'Тест Тестенко',
  String email = 'test@test.ua',
}) =>
    UserModel(
      uid: uid,
      name: name,
      role: role,
      childIds: childIds,
      childId: childId,
      email: email,
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── TC-USER-001: ownsChild via childIds ──────────────────────────────────

  group('TC-USER-001: ownsChild — перевірка через childIds', () {
    test('id в childIds → ownsChild = true', () {
      final user = _user(childIds: ['child1', 'child2']);
      expect(user.ownsChild('child1'), isTrue);
      expect(user.ownsChild('child2'), isTrue);
    });

    test('id NOT в childIds → ownsChild = false', () {
      final user = _user(childIds: ['child1']);
      expect(user.ownsChild('child99'), isFalse);
    });

    test('порожній childIds → ownsChild = false для будь-якого id', () {
      final user = _user(childIds: []);
      expect(user.ownsChild('child1'), isFalse);
      expect(user.ownsChild('any'), isFalse);
    });

    test('3 дитини — ownsChild вірний для кожної', () {
      final user = _user(childIds: ['c1', 'c2', 'c3']);
      for (final id in ['c1', 'c2', 'c3']) {
        expect(user.ownsChild(id), isTrue, reason: 'ownsChild($id) must be true');
      }
      expect(user.ownsChild('c4'), isFalse);
    });
  });

  // ── TC-USER-002: ownsChild via legacy childId ─────────────────────────────

  group('TC-USER-002: ownsChild — зворотна сумісність через legacy childId', () {
    test('legacy childId = "child_abc" → ownsChild("child_abc") = true', () {
      final user = _user(childIds: [], childId: 'child_abc');
      expect(user.ownsChild('child_abc'), isTrue);
    });

    test('legacy childId ≠ запитуваний → ownsChild = false', () {
      final user = _user(childIds: [], childId: 'child_abc');
      expect(user.ownsChild('child_xyz'), isFalse);
    });

    test('childIds = ["c1"] + legacy childId = "c_legacy" → ownsChild обох', () {
      final user = _user(childIds: ['c1'], childId: 'c_legacy');
      expect(user.ownsChild('c1'), isTrue);
      expect(user.ownsChild('c_legacy'), isTrue);
    });

    test('null legacy childId і порожній childIds → ownsChild = false', () {
      final user = _user(childIds: [], childId: null);
      expect(user.ownsChild('any'), isFalse);
    });
  });

  // ── TC-USER-003: toFirestore — синхронізація childId ─────────────────────

  group('TC-USER-003: toFirestore — childId = childIds.first', () {
    test('childIds = ["c1", "c2"] → childId = "c1" у Firestore', () {
      final user = _user(childIds: ['c1', 'c2']);
      final data = user.toFirestore();
      expect(data['childId'], equals('c1'));
    });

    test('childIds = ["only"] → childId = "only"', () {
      final user = _user(childIds: ['only']);
      final data = user.toFirestore();
      expect(data['childId'], equals('only'));
    });

    test('childIds порожній → childId = null або відсутній', () {
      final user = _user(childIds: []);
      final data = user.toFirestore();
      // Either null or absent, never a valid non-empty childId
      final childId = data['childId'];
      expect(childId == null || childId == '', isTrue,
          reason: 'Порожній childIds → не записуємо childId в Firestore');
    });

    test('toFirestore містить role', () {
      final user = _user(role: 'coach');
      final data = user.toFirestore();
      expect(data['role'], equals('coach'));
    });

    test('toFirestore містить name', () {
      final user = _user(name: 'Іван Коваль');
      final data = user.toFirestore();
      expect(data['name'], equals('Іван Коваль'));
    });
  });

  // ── TC-USER-004: fromFirestore — role за замовчуванням ───────────────────

  group('TC-USER-004: fromFirestore — role = "parent" якщо поле відсутнє', () {
    test('відсутній field role → role = "parent"', () async {
      final db = _db();
      await db.collection('users').doc('u1').set({
        'name': 'Батько',
        'childIds': <String>[],
        // no 'role' field
      });

      final doc = await db.collection('users').doc('u1').get();
      final user = UserModel.fromFirestore(doc);
      expect(user.role, equals('parent'));
    });

    test('role = "coach" в Firestore → role = "coach"', () async {
      final db = _db();
      await db.collection('users').doc('u2').set({
        'name': 'Тренер',
        'role': 'coach',
        'childIds': <String>[],
      });

      final doc = await db.collection('users').doc('u2').get();
      final user = UserModel.fromFirestore(doc);
      expect(user.role, equals('coach'));
    });

    test('null role → role = "parent"', () async {
      final db = _db();
      await db.collection('users').doc('u3').set({
        'name': 'Хтось',
        'role': null,
        'childIds': <String>[],
      });

      final doc = await db.collection('users').doc('u3').get();
      final user = UserModel.fromFirestore(doc);
      expect(user.role, equals('parent'));
    });
  });

  // ── TC-USER-005: isCoach / isParent геттери ───────────────────────────────

  group('TC-USER-005: isCoach / isParent', () {
    test('role = "coach" → isCoach=true, isParent=false', () {
      final user = _user(role: 'coach');
      expect(user.isCoach, isTrue);
      expect(user.isParent, isFalse);
    });

    test('role = "parent" → isParent=true, isCoach=false', () {
      final user = _user(role: 'parent');
      expect(user.isParent, isTrue);
      expect(user.isCoach, isFalse);
    });

    test('defaultRole з fromFirestore (без поля) → isParent=true', () async {
      final db = _db();
      await db.collection('users').doc('u_default').set({
        'name': 'Без ролі',
        'childIds': <String>[],
      });
      final doc = await db.collection('users').doc('u_default').get();
      final user = UserModel.fromFirestore(doc);
      expect(user.isParent, isTrue);
      expect(user.isCoach, isFalse);
    });
  });

  // ── TC-USER-006: roundtrip — toFirestore + fromFirestore ─────────────────

  group('TC-USER-006: toFirestore + fromFirestore roundtrip', () {
    test('UserModel зберігається і відновлюється без втрати даних', () async {
      final db = _db();
      final original = _user(
        uid: 'u_roundtrip',
        name: 'Олена Іваненко',
        role: 'coach',
        childIds: ['c1', 'c2'],
      );

      await db.collection('users').doc('u_roundtrip').set(original.toFirestore());
      final doc = await db.collection('users').doc('u_roundtrip').get();
      final restored = UserModel.fromFirestore(doc);

      expect(restored.name, equals(original.name));
      expect(restored.role, equals(original.role));
      expect(restored.isCoach, isTrue);
      expect(restored.ownsChild('c1'), isTrue);
      expect(restored.ownsChild('c2'), isTrue);
    });
  });
}

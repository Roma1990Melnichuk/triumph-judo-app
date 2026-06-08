import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/user_model.dart';

UserModel makeCoach({String uid = 'coach1', String name = 'Іван'}) =>
    UserModel(uid: uid, email: 'coach@test.com', name: name, role: 'coach');

UserModel makeParent({
  String uid = 'parent1',
  List<String> childIds = const ['child1'],
  String? legacyChildId,
}) =>
    UserModel(
      uid: uid,
      email: 'parent@test.com',
      name: 'Оксана',
      role: 'parent',
      childId: legacyChildId,
      childIds: childIds,
    );

void main() {
  // ── isCoach / isParent ────────────────────────────────────────────────────

  group('UserModel.isCoach / isParent', () {
    test('тренер: isCoach=true, isParent=false', () {
      expect(makeCoach().isCoach, isTrue);
      expect(makeCoach().isParent, isFalse);
    });

    test('батько: isParent=true, isCoach=false', () {
      expect(makeParent().isParent, isTrue);
      expect(makeParent().isCoach, isFalse);
    });
  });

  // ── ownsChild ─────────────────────────────────────────────────────────────

  group('UserModel.ownsChild', () {
    test('true для дитини в childIds', () {
      expect(makeParent(childIds: ['c1', 'c2']).ownsChild('c1'), isTrue);
      expect(makeParent(childIds: ['c1', 'c2']).ownsChild('c2'), isTrue);
    });

    test('false для чужої дитини', () {
      expect(makeParent(childIds: ['c1']).ownsChild('c99'), isFalse);
    });

    test('true через legacyChildId коли childIds порожній', () {
      final user = UserModel(
        uid: 'p1', email: '', name: '', role: 'parent',
        childId: 'legacy_kid',
        childIds: const [],
      );
      expect(user.ownsChild('legacy_kid'), isTrue);
    });

    test('false коли обидва списки не містять id', () {
      final user = UserModel(
        uid: 'p1', email: '', name: '', role: 'parent',
        childId: 'other',
        childIds: const ['another'],
      );
      expect(user.ownsChild('missing'), isFalse);
    });
  });

  // ── copyWith ──────────────────────────────────────────────────────────────

  group('UserModel.copyWith', () {
    test('змінює name', () {
      expect(makeCoach(name: 'Старий').copyWith(name: 'Новий').name, 'Новий');
    });

    test('зберігає незмінені поля', () {
      final original = makeCoach(uid: 'x1');
      final copy = original.copyWith(name: 'Нова');
      expect(copy.uid, 'x1');
      expect(copy.email, original.email);
      expect(copy.role, original.role);
    });

    test('clearPhone видаляє телефон', () {
      final user = UserModel(
        uid: 'u', email: '', name: '', role: 'coach', phone: '+380991234567',
      );
      expect(user.copyWith(clearPhone: true).phone, isNull);
    });

    test('оновлює телефон', () {
      final user = UserModel(uid: 'u', email: '', name: '', role: 'coach');
      expect(user.copyWith(phone: '+380501112233').phone, '+380501112233');
    });

    test('оновлює childIds', () {
      final parent = makeParent(childIds: ['c1']);
      final updated = parent.copyWith(childIds: ['c1', 'c2']);
      expect(updated.childIds, ['c1', 'c2']);
    });
  });

  // ── toFirestore ───────────────────────────────────────────────────────────

  group('UserModel.toFirestore', () {
    test('містить email, name, role', () {
      final map = makeCoach().toFirestore();
      expect(map['email'], 'coach@test.com');
      expect(map['name'], 'Іван');
      expect(map['role'], 'coach');
    });

    test('phone відсутній коли null', () {
      final map = makeCoach().toFirestore();
      expect(map.containsKey('phone'), isFalse);
    });

    test('phone присутній коли не null та не порожній', () {
      final user = UserModel(
        uid: 'u', email: '', name: 'А', role: 'coach', phone: '+380',
      );
      expect(user.toFirestore()['phone'], '+380');
    });

    test('childIds записується завжди', () {
      final parent = makeParent(childIds: ['c1', 'c2']);
      final map = parent.toFirestore();
      expect(map['childIds'], ['c1', 'c2']);
    });

    test('legacyChildId = перший елемент childIds', () {
      final parent = makeParent(childIds: ['c1', 'c2']);
      expect(parent.toFirestore()['childId'], 'c1');
    });

    test('legacyChildId відсутній коли childIds порожній', () {
      final user = UserModel(uid: 'u', email: '', name: '', role: 'parent');
      expect(user.toFirestore().containsKey('childId'), isFalse);
    });
  });

  // ── fromFirestore ─────────────────────────────────────────────────────────

  group('UserModel.fromFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;
    setUp(() => fakeFirestore = FakeFirebaseFirestore());

    test('зчитує всі поля коректно', () async {
      final ref = fakeFirestore.collection('users').doc('uid1');
      await ref.set({
        'email': 'test@test.com',
        'name': 'Тест',
        'role': 'coach',
        'phone': '+380',
        'childIds': <String>[],
        'clubId': 'club1',
      });
      final user = UserModel.fromFirestore(await ref.get());
      expect(user.uid, 'uid1');
      expect(user.email, 'test@test.com');
      expect(user.isCoach, isTrue);
      expect(user.phone, '+380');
      expect(user.clubId, 'club1');
    });

    test('childIds фолбек до legacyChildId коли масив відсутній', () async {
      final ref = fakeFirestore.collection('users').doc('legacy1');
      await ref.set({
        'email': '', 'name': '', 'role': 'parent',
        'childId': 'kid42',
        // childIds відсутній
      });
      final user = UserModel.fromFirestore(await ref.get());
      expect(user.childIds, ['kid42']);
      expect(user.ownsChild('kid42'), isTrue);
    });

    test('відсутні поля — значення за замовчуванням', () async {
      final ref = fakeFirestore.collection('users').doc('empty');
      await ref.set(<String, dynamic>{});
      final user = UserModel.fromFirestore(await ref.get());
      expect(user.email, '');
      expect(user.name, '');
      expect(user.role, 'parent');
      expect(user.childIds, isEmpty);
      expect(user.phone, isNull);
    });
  });
}

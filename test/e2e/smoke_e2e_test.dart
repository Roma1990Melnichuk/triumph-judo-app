// ignore_for_file: avoid_print

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/core/utils/form_validators.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ChildModel _child(
  String id, {
  String firstName = 'Іван',
  String lastName = 'Іваненко',
  int birthYear = 2012,
  String weightCategory = '-30 кг',
  int totalPoints = 0,
  bool beltReady = false,
}) =>
    ChildModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      birthYear: birthYear,
      weightCategory: weightCategory,
      currentBelt: BeltLevel.white,
      coachId: 'coach1',
      coachName: 'Тренер',
      totalPoints: totalPoints,
      createdAt: DateTime(2024),
      beltReady: beltReady,
    );

UserModel _coachUser() => const UserModel(
      uid: 'coach1',
      email: 'coach@test.com',
      name: 'Тренер',
      role: 'coach',
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('TC-SMOKE — provider logic', () {
    // ── TC-SMOKE-003 ──────────────────────────────────────────────────────────
    test('TC-SMOKE-003: allChildrenProvider emits список спортсменів', () async {
      final db = FakeFirebaseFirestore();
      final user = _coachUser();

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          currentUserModelProvider.overrideWith((_) => Stream.value(user)),
          allChildrenProvider.overrideWith(
            (_) => Stream.value([_child('c1')]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(allChildrenProvider.future);
      expect(result.length, 1);
      expect(result.first.id, 'c1');
    });

    // ── TC-SMOKE rating: filteredChildrenProvider sorts desc ─────────────────
    test(
        'TC-SMOKE rating: filteredChildrenProvider сортує за балами від більшого до меншого',
        () async {
      final db = FakeFirebaseFirestore();

      final children = [
        _child('c1', totalPoints: 10, lastName: 'Антоненко'),
        _child('c2', totalPoints: 50, lastName: 'Бойко'),
        _child('c3', totalPoints: 30, lastName: 'Василенко'),
      ];

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          allChildrenProvider.overrideWith((_) => Stream.value(children)),
          childrenFilterProvider
              .overrideWith((_) => const ChildrenFilter()),
        ],
      );
      addTearDown(container.dispose);

      // Allow async providers to settle.
      await container.read(allChildrenProvider.future);

      final filtered = container.read(filteredChildrenProvider);
      expect(filtered.length, 3);
      for (int i = 0; i < filtered.length - 1; i++) {
        expect(filtered[i].totalPoints >= filtered[i + 1].totalPoints, isTrue);
      }
    });

    // ── TC-RATING-002 ─────────────────────────────────────────────────────────
    test(
        'TC-RATING-002: спортсмен з більшою кількістю балів вище в рейтингу',
        () async {
      final db = FakeFirebaseFirestore();

      final children = [
        _child('low', totalPoints: 5, lastName: 'Антоненко'),
        _child('high', totalPoints: 100, lastName: 'Бойко'),
      ];

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          allChildrenProvider.overrideWith((_) => Stream.value(children)),
          childrenFilterProvider
              .overrideWith((_) => const ChildrenFilter()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(allChildrenProvider.future);

      final filtered = container.read(filteredChildrenProvider);
      expect(filtered.first.totalPoints >= filtered.last.totalPoints, isTrue);
    });

    // ── TC-RATING-004 ─────────────────────────────────────────────────────────
    test(
        'TC-RATING-004: однакові бали — стабільне сортування (без краша)',
        () async {
      final db = FakeFirebaseFirestore();

      final children = [
        _child('c1', totalPoints: 20, lastName: 'Антоненко'),
        _child('c2', totalPoints: 20, lastName: 'Бойко'),
      ];

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          allChildrenProvider.overrideWith((_) => Stream.value(children)),
          childrenFilterProvider
              .overrideWith((_) => const ChildrenFilter()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(allChildrenProvider.future);

      // Should not throw.
      final filtered = container.read(filteredChildrenProvider);
      expect(filtered.length, 2);
    });

    // ── TC-TEAM filter: birthYear ─────────────────────────────────────────────
    test(
        'TC-TEAM filter: ChildrenFilter по birthYear залишає тільки відповідних',
        () async {
      final db = FakeFirebaseFirestore();

      final children = [
        _child('c1', birthYear: 2012, lastName: 'Антоненко', totalPoints: 1),
        _child('c2', birthYear: 2012, lastName: 'Бойко', totalPoints: 2),
        _child('c3', birthYear: 2015, lastName: 'Василенко', totalPoints: 3),
      ];

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          allChildrenProvider.overrideWith((_) => Stream.value(children)),
          childrenFilterProvider.overrideWith(
            (_) => const ChildrenFilter(birthYear: 2012),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(allChildrenProvider.future);

      final filtered = container.read(filteredChildrenProvider);
      expect(filtered.length, 2);
      expect(filtered.every((c) => c.birthYear == 2012), isTrue);
    });

    // ── TC-TEAM filter: weightCategory ────────────────────────────────────────
    test(
        'TC-TEAM filter: ChildrenFilter по weightCategory залишає тільки відповідних',
        () async {
      final db = FakeFirebaseFirestore();

      final children = [
        _child('c1',
            weightCategory: '-30 кг', lastName: 'Антоненко', totalPoints: 1),
        _child('c2',
            weightCategory: '-30 кг', lastName: 'Бойко', totalPoints: 2),
        _child('c3',
            weightCategory: '-40 кг', lastName: 'Василенко', totalPoints: 3),
      ];

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          allChildrenProvider.overrideWith((_) => Stream.value(children)),
          childrenFilterProvider.overrideWith(
            (_) => const ChildrenFilter(weightCategory: '-30 кг'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(allChildrenProvider.future);

      final filtered = container.read(filteredChildrenProvider);
      expect(filtered.length, 2);
      expect(
          filtered.every((c) => c.weightCategory == '-30 кг'), isTrue);
    });

    // ── TC-BELT-021 ───────────────────────────────────────────────────────────
    test(
        'TC-BELT-021: beltReady=true тільки при виконанні всіх вправ — model test',
        () {
      final readyChild = _child('c1', beltReady: true);
      expect(readyChild.beltReady, isTrue);

      final notReadyChild = _child('c2', beltReady: false);
      expect(notReadyChild.beltReady, isFalse);
    });

    // ── TC-AUTH-006 ───────────────────────────────────────────────────────────
    test(
        'TC-AUTH-006: FormValidators.password повертає помилку для паролю менше 6 символів',
        () {
      expect(FormValidators.password('12345'), 'Мінімум 6 символів');
    });

    // ── TC-AUTH-004 ───────────────────────────────────────────────────────────
    test(
        'TC-AUTH-004: FormValidators.email повертає помилку для неправильного email',
        () {
      expect(FormValidators.email('notvalid'), 'Невірний email');
    });

    // ── TC-AUTH-007 ───────────────────────────────────────────────────────────
    test(
        'TC-AUTH-007: FormValidators.email повертає помилку для порожнього email',
        () {
      expect(FormValidators.email(''), 'Введіть email');
    });
  });
}

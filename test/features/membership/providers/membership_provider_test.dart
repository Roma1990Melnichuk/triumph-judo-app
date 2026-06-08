import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/membership_model.dart';
import 'package:judo_app/features/membership/providers/membership_provider.dart';

// ── Хелпери ──────────────────────────────────────────────────────────────────

MembershipModel makeActive(String athleteId) {
  final now = DateTime.now();
  return MembershipModel(
    athleteId: athleteId,
    planName: 'Безлімітний',
    startDate: now.subtract(const Duration(days: 20)),
    endDate: now.add(const Duration(days: 40)),
    amount: 1500,
  );
}

MembershipModel makeExpiringSoon(String athleteId) {
  final now = DateTime.now();
  return MembershipModel(
    athleteId: athleteId,
    planName: '2 рази на тиждень',
    startDate: now.subtract(const Duration(days: 27)),
    endDate: now.add(const Duration(days: 3)),
    amount: 900,
  );
}

MembershipModel makeExpired(String athleteId) {
  final now = DateTime.now();
  return MembershipModel(
    athleteId: athleteId,
    planName: '3 рази на тиждень',
    startDate: now.subtract(const Duration(days: 40)),
    endDate: now.subtract(const Duration(days: 10)),
    amount: 1200,
  );
}

ProviderContainer makeContainer(List<MembershipModel> memberships) =>
    ProviderContainer(
      overrides: [
        allMembershipsProvider.overrideWith(
          (ref) => Stream.value(memberships),
        ),
      ],
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── membershipStatusMapProvider ───────────────────────────────────────────

  group('membershipStatusMapProvider', () {
    test('порожня карта при відсутності абонементів', () async {
      final c = makeContainer([]);
      await c.read(allMembershipsProvider.future);

      final map = c.read(membershipStatusMapProvider);
      expect(map, isEmpty);
    });

    test('маппінг athleteId → MembershipStatus.active', () async {
      final c = makeContainer([makeActive('a1'), makeActive('a2')]);
      await c.read(allMembershipsProvider.future);

      final map = c.read(membershipStatusMapProvider);
      expect(map['a1'], MembershipStatus.active);
      expect(map['a2'], MembershipStatus.active);
    });

    test('маппінг expiringSoon і expired', () async {
      final c = makeContainer([
        makeExpiringSoon('b1'),
        makeExpired('b2'),
      ]);
      await c.read(allMembershipsProvider.future);

      final map = c.read(membershipStatusMapProvider);
      expect(map['b1'], MembershipStatus.expiringSoon);
      expect(map['b2'], MembershipStatus.expired);
    });

    test('карта містить усі три статуси одночасно', () async {
      final c = makeContainer([
        makeActive('x1'),
        makeExpiringSoon('x2'),
        makeExpired('x3'),
      ]);
      await c.read(allMembershipsProvider.future);

      final map = c.read(membershipStatusMapProvider);
      expect(map.length, 3);
      expect(map['x1'], MembershipStatus.active);
      expect(map['x2'], MembershipStatus.expiringSoon);
      expect(map['x3'], MembershipStatus.expired);
    });

    test('не містить ключів для відсутніх спортсменів', () async {
      final c = makeContainer([makeActive('only1')]);
      await c.read(allMembershipsProvider.future);

      final map = c.read(membershipStatusMapProvider);
      expect(map.containsKey('missing'), isFalse);
    });
  });

  // ── membershipSummaryProvider ─────────────────────────────────────────────

  group('membershipSummaryProvider', () {
    test('нулі при відсутності абонементів', () async {
      final c = makeContainer([]);
      await c.read(allMembershipsProvider.future);

      final s = c.read(membershipSummaryProvider);
      expect(s.active, 0);
      expect(s.expiringSoon, 0);
      expect(s.expired, 0);
    });

    test('рахує активні правильно', () async {
      final c = makeContainer([
        makeActive('a1'),
        makeActive('a2'),
        makeActive('a3'),
      ]);
      await c.read(allMembershipsProvider.future);

      final s = c.read(membershipSummaryProvider);
      expect(s.active, 3);
      expect(s.expiringSoon, 0);
      expect(s.expired, 0);
    });

    test('рахує окремо active/expiringSoon/expired', () async {
      final c = makeContainer([
        makeActive('a1'),
        makeActive('a2'),
        makeExpiringSoon('b1'),
        makeExpiringSoon('b2'),
        makeExpiringSoon('b3'),
        makeExpired('c1'),
      ]);
      await c.read(allMembershipsProvider.future);

      final s = c.read(membershipSummaryProvider);
      // expiringSoon рахується в expiringSoon, НЕ в active
      expect(s.active, 2);
      expect(s.expiringSoon, 3);
      expect(s.expired, 1);
    });

    test('всі прострочені', () async {
      final c = makeContainer([
        makeExpired('c1'),
        makeExpired('c2'),
      ]);
      await c.read(allMembershipsProvider.future);

      final s = c.read(membershipSummaryProvider);
      expect(s.active, 0);
      expect(s.expiringSoon, 0);
      expect(s.expired, 2);
    });
  });
}

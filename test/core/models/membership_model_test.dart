import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/membership_model.dart';

// ── Хелпери ──────────────────────────────────────────────────────────────────

MembershipModel makeActive({
  String athleteId = 'athlete1',
  int startDaysAgo = 30,
  int endDaysFromNow = 60,
  String planName = 'Безлімітний',
  double amount = 1500,
}) {
  final now = DateTime.now();
  return MembershipModel(
    athleteId: athleteId,
    planName: planName,
    startDate: now.subtract(Duration(days: startDaysAgo)),
    endDate: now.add(Duration(days: endDaysFromNow)),
    amount: amount,
  );
}

MembershipModel makeExpiringSoon({
  String athleteId = 'athlete2',
  int daysLeft = 3,
}) {
  final now = DateTime.now();
  return MembershipModel(
    athleteId: athleteId,
    planName: '2 рази на тиждень',
    startDate: now.subtract(const Duration(days: 27)),
    endDate: now.add(Duration(days: daysLeft)),
    amount: 900,
  );
}

MembershipModel makeExpired({
  String athleteId = 'athlete3',
  int daysAgo = 12,
}) {
  final now = DateTime.now();
  return MembershipModel(
    athleteId: athleteId,
    planName: '3 рази на тиждень',
    startDate: now.subtract(Duration(days: 30 + daysAgo)),
    endDate: now.subtract(Duration(days: daysAgo)),
    amount: 1200,
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── isActive / isExpired / isExpiringSoon ─────────────────────────────────

  group('MembershipModel.isActive', () {
    test('true коли endDate в майбутньому', () {
      expect(makeActive().isActive, isTrue);
    });

    test('false коли endDate в минулому', () {
      expect(makeExpired().isActive, isFalse);
    });

    test('false при закінченні через 3 дні теж вважається активним', () {
      expect(makeExpiringSoon().isActive, isTrue);
    });
  });

  group('MembershipModel.isExpired', () {
    test('true коли endDate в минулому', () {
      expect(makeExpired().isExpired, isTrue);
    });

    test('false коли endDate в майбутньому', () {
      expect(makeActive().isExpired, isFalse);
    });
  });

  group('MembershipModel.isExpiringSoon', () {
    test('true коли <= 7 днів і ще не прострочений', () {
      expect(makeExpiringSoon(daysLeft: 7).isExpiringSoon, isTrue);
      expect(makeExpiringSoon(daysLeft: 1).isExpiringSoon, isTrue);
    });

    test('false коли > 7 днів', () {
      expect(makeActive(endDaysFromNow: 30).isExpiringSoon, isFalse);
    });

    test('false коли вже прострочений', () {
      expect(makeExpired().isExpiringSoon, isFalse);
    });
  });

  // ── daysRemaining ─────────────────────────────────────────────────────────

  group('MembershipModel.daysRemaining', () {
    test('приблизно рівний різниці дат коли активний', () {
      final m = makeActive(endDaysFromNow: 28);
      // Tolerance of 1 for test-clock rounding
      expect(m.daysRemaining, anyOf(28, 27));
    });

    test('0 коли прострочений (не негативний)', () {
      expect(makeExpired().daysRemaining, 0);
    });
  });

  // ── daysExpiredAgo ────────────────────────────────────────────────────────

  group('MembershipModel.daysExpiredAgo', () {
    test('0 коли ще активний', () {
      expect(makeActive().daysExpiredAgo, 0);
    });

    test('приблизно рівний кількості днів з моменту закінчення', () {
      final m = makeExpired(daysAgo: 12);
      expect(m.daysExpiredAgo, anyOf(12, 11));
    });
  });

  // ── status ────────────────────────────────────────────────────────────────

  group('MembershipModel.status', () {
    test('active для звичайного активного абонемента', () {
      expect(makeActive().status, MembershipStatus.active);
    });

    test('expiringSoon коли <= 7 днів', () {
      expect(makeExpiringSoon(daysLeft: 5).status, MembershipStatus.expiringSoon);
    });

    test('expired коли прострочений', () {
      expect(makeExpired().status, MembershipStatus.expired);
    });

    test('expiringSoon пріоритетніше за active при 7 днях', () {
      expect(makeExpiringSoon(daysLeft: 7).status, MembershipStatus.expiringSoon);
    });
  });

  // ── statusLabel ───────────────────────────────────────────────────────────

  group('MembershipModel.statusLabel', () {
    test('"АКТИВНИЙ" для активного', () {
      expect(makeActive().statusLabel, 'АКТИВНИЙ');
    });

    test('"ЗАКІНЧУЄТЬСЯ" для expiringSoon', () {
      expect(makeExpiringSoon().statusLabel, 'ЗАКІНЧУЄТЬСЯ');
    });

    test('"ПРОСТРОЧЕНИЙ" для expired', () {
      expect(makeExpired().statusLabel, 'ПРОСТРОЧЕНИЙ');
    });
  });

  // ── statusColor ───────────────────────────────────────────────────────────

  group('MembershipModel.statusColor', () {
    test('зелений для активного', () {
      expect(makeActive().statusColor, const Color(0xFF27AE60));
    });

    test('помаранчевий для expiringSoon', () {
      expect(makeExpiringSoon().statusColor, const Color(0xFFFF8A00));
    });

    test('червоний для expired', () {
      expect(makeExpired().statusColor, const Color(0xFFD50000));
    });
  });

  // ── progressPercent ───────────────────────────────────────────────────────

  group('MembershipModel.progressPercent', () {
    test('між 0.0 і 1.0', () {
      final p = makeActive(startDaysAgo: 30, endDaysFromNow: 30).progressPercent;
      expect(p, greaterThanOrEqualTo(0.0));
      expect(p, lessThanOrEqualTo(1.0));
    });

    test('близько до 0.5 при рівному розподілі', () {
      final m = makeActive(startDaysAgo: 50, endDaysFromNow: 50);
      expect(m.progressPercent, closeTo(0.5, 0.02));
    });

    test('1.0 коли щойно прострочений', () {
      final m = makeExpired(daysAgo: 1);
      expect(m.progressPercent, 1.0);
    });

    test('близько до 0 на початку абонемента', () {
      final m = makeActive(startDaysAgo: 0, endDaysFromNow: 90);
      expect(m.progressPercent, closeTo(0.0, 0.02));
    });

    test('1.0 коли total = 0 (захист від ділення на 0)', () {
      final now = DateTime.now();
      final m = MembershipModel(
        athleteId: 'x',
        planName: '',
        startDate: now,
        endDate: now, // total = 0
        amount: 0,
      );
      expect(m.progressPercent, 1.0);
    });
  });

  // ── fromMap ───────────────────────────────────────────────────────────────

  group('MembershipModel.fromMap', () {
    test('зчитує всі поля коректно з рядкових дат', () {
      final map = <String, dynamic>{
        'planName': '3 рази на тиждень',
        'startDate': '2026-01-01T00:00:00.000',
        'endDate': '2026-08-31T00:00:00.000',
        'amount': 1200.0,
        'currency': 'UAH',
      };
      final m = MembershipModel.fromMap(map, 'kid42');

      expect(m.athleteId, 'kid42');
      expect(m.planName, '3 рази на тиждень');
      expect(m.startDate, DateTime(2026, 1, 1));
      expect(m.endDate, DateTime(2026, 8, 31));
      expect(m.amount, 1200.0);
      expect(m.currency, 'UAH');
    });

    test('planName за замовчуванням — порожній рядок', () {
      final m = MembershipModel.fromMap({
        'startDate': '2026-01-01T00:00:00.000',
        'endDate': '2026-12-31T00:00:00.000',
      }, 'x');
      expect(m.planName, '');
    });

    test('currency за замовчуванням — UAH', () {
      final m = MembershipModel.fromMap({
        'startDate': '2026-01-01T00:00:00.000',
        'endDate': '2026-12-31T00:00:00.000',
      }, 'x');
      expect(m.currency, 'UAH');
    });

    test('amount за замовчуванням — 0.0', () {
      final m = MembershipModel.fromMap({
        'startDate': '2026-01-01T00:00:00.000',
        'endDate': '2026-12-31T00:00:00.000',
      }, 'x');
      expect(m.amount, 0.0);
    });

    test('amount як int конвертується в double', () {
      final m = MembershipModel.fromMap({
        'startDate': '2026-01-01T00:00:00.000',
        'endDate': '2026-12-31T00:00:00.000',
        'amount': 1500,
      }, 'x');
      expect(m.amount, 1500.0);
    });
  });

  // ── Граничні сценарії ─────────────────────────────────────────────────────

  group('MembershipModel — граничні стани', () {
    test('закінчується через рівно 7 днів → expiringSoon', () {
      final now = DateTime.now();
      final m = MembershipModel(
        athleteId: 'x',
        planName: '',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.add(const Duration(days: 7)),
        amount: 0,
      );
      expect(m.isExpiringSoon, isTrue);
      expect(m.status, MembershipStatus.expiringSoon);
    });

    test('закінчується через 14 днів → active (не expiringSoon)', () {
      final now = DateTime.now();
      final m = MembershipModel(
        athleteId: 'x',
        planName: '',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.add(const Duration(days: 14)),
        amount: 0,
      );
      expect(m.isExpiringSoon, isFalse);
      expect(m.status, MembershipStatus.active);
    });
  });
}

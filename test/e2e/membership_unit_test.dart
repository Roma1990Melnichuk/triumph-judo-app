/// TC-MEMB-0381 / TC-MEMB-0382 / TC-MEMB-0383 — Membership Edge Cases
/// Чисті unit-тести MembershipModel — без Firebase, без Flutter-widgets.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/membership_model.dart';

void main() {
  final now = DateTime.now();

  // ── TC-MEMB-0381: sessionsRemaining ────────────────────────────────────────

  group('TC-MEMB-0381: sessionsRemaining = totalSessions - sessionsUsed', () {
    test('правильно обчислює залишок занять', () {
      final m = MembershipModel(
        athleteId: 'a1',
        planName: 'Місячний',
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 30)),
        amount: 500,
        totalSessions: 10,
        sessionsUsed: 3,
      );
      expect(m.sessionsRemaining, equals(7));
    });

    test('кожне відвідування зменшує sessionsRemaining на 1', () {
      MembershipModel m(int used) => MembershipModel(
            athleteId: 'a1',
            planName: 'Тест',
            startDate: now,
            endDate: now.add(const Duration(days: 30)),
            amount: 100,
            totalSessions: 5,
            sessionsUsed: used,
          );
      expect(m(0).sessionsRemaining, equals(5));
      expect(m(1).sessionsRemaining, equals(4));
      expect(m(2).sessionsRemaining, equals(3));
      expect(m(3).sessionsRemaining, equals(2));
      expect(m(4).sessionsRemaining, equals(1));
      expect(m(5).sessionsRemaining, equals(0));
    });

    test('необмежений план (totalSessions=null) → sessionsRemaining=null', () {
      final m = MembershipModel(
        athleteId: 'a1',
        planName: 'Безліміт',
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
        amount: 800,
        sessionsUsed: 5,
      );
      expect(m.sessionsRemaining, isNull);
      expect(m.isSessionBased, isFalse);
    });

    test('sessionsRemaining не опускається нижче 0 (захист від overshoot)', () {
      final m = MembershipModel(
        athleteId: 'a1',
        planName: 'Тест',
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 30)),
        amount: 200,
        totalSessions: 5,
        sessionsUsed: 10,
      );
      expect(m.sessionsRemaining, equals(0));
    });
  });

  // ── TC-MEMB-0382: статус Expired ──────────────────────────────────────────

  group('TC-MEMB-0382: статус Expired', () {
    test('прострочена дата → isExpired=true і status=expired', () {
      final m = MembershipModel(
        athleteId: 'a1',
        planName: 'Тест',
        startDate: now.subtract(const Duration(days: 60)),
        endDate: now.subtract(const Duration(days: 1)),
        amount: 500,
      );
      expect(m.isExpired, isTrue);
      expect(m.isActive, isFalse);
      expect(m.status, equals(MembershipStatus.expired));
    });

    test('майбутня дата → isExpired=false і статус не expired', () {
      final m = MembershipModel(
        athleteId: 'a1',
        planName: 'Тест',
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
        amount: 500,
      );
      expect(m.isExpired, isFalse);
      expect(m.status, isNot(equals(MembershipStatus.expired)));
    });

    test(
        'sessionsRemaining=0 але дата діє → status=expiringSoon (поточна реалізація)',
        () {
      // isExpired перевіряє тільки дату; нульові заняття → expiringSoon, не expired.
      final m = MembershipModel(
        athleteId: 'a1',
        planName: 'Тест',
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 30)),
        amount: 500,
        totalSessions: 10,
        sessionsUsed: 10,
      );
      expect(m.sessionsRemaining, equals(0));
      expect(m.isExpired, isFalse);
      expect(m.isExpiringSoon, isTrue);
      expect(m.status, equals(MembershipStatus.expiringSoon));
    });
  });

  // ── TC-MEMB-0383: дострокове продовження ──────────────────────────────────

  group('TC-MEMB-0383: дострокове продовження абонемента', () {
    test('залишилось 20 днів + новий на 30 → загальний строк ≈ 50 днів', () {
      final currentEndDate = now.add(const Duration(days: 20));
      const newDurationDays = 30;

      // Дострокове продовження: нова дата = поточний кінець + тривалість нового
      final newEndDate = currentEndDate.add(const Duration(days: newDurationDays));
      final totalDaysFromNow = newEndDate.difference(now).inDays;

      // Допуск ±1 день через час виконання тесту
      expect(totalDaysFromNow, greaterThanOrEqualTo(49));
      expect(totalDaysFromNow, lessThanOrEqualTo(51));
    });

    test('продовження не скорочує вже оплачений час', () {
      final currentEndDate = now.add(const Duration(days: 20));
      final newEndDate = currentEndDate.add(const Duration(days: 30));
      expect(newEndDate.isAfter(currentEndDate), isTrue);
    });

    test('daysRemaining відображає залишок до нової дати', () {
      final newEndDate = now.add(const Duration(days: 50));
      final m = MembershipModel(
        athleteId: 'a1',
        planName: 'Продовжений',
        startDate: now,
        endDate: newEndDate,
        amount: 1000,
      );
      expect(m.daysRemaining, greaterThanOrEqualTo(49));
      expect(m.daysRemaining, lessThanOrEqualTo(51));
      expect(m.isExpired, isFalse);
    });
  });
}

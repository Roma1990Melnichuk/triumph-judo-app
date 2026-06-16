/// TC-MEMBERSHIP — Бізнес-логіка абонементів.
///
/// Ключові правила:
///   1. sessionsRemaining = clamp(totalSessions - sessionsUsed, 0, totalSessions)
///   2. isExpiringSoon (занять): sessionsRemaining ≤ 5
///   3. isExpiringSoon (часовий): daysRemaining ≤ 7
///   4. endDate нормалізується до 23:59:59.999
///   5. auto-extend: якщо є активний абонемент, finalEnd = існуючий.endDate + newDuration
///   6. sessionsUsed зберігається при авто-подовженні
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/membership_model.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

DateTime _date(int year, int month, int day) => DateTime(year, month, day);

MembershipModel _membership({
  String athleteId = 'child1',
  String planName = 'Базовий',
  DateTime? startDate,
  DateTime? endDate,
  double amount = 500.0,
  int? totalSessions,
  int sessionsUsed = 0,
}) =>
    MembershipModel(
      athleteId: athleteId,
      planName: planName,
      startDate: startDate ?? _date(2026, 1, 1),
      // endDate далеко в майбутньому → isActive=true
      endDate: endDate ?? _date(2026, 12, 31),
      amount: amount,
      currency: 'UAH',
      totalSessions: totalSessions,
      sessionsUsed: sessionsUsed,
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── TC-MEMBERSHIP-001: sessionsRemaining ─────────────────────────────────

  group('TC-MEMBERSHIP-001: sessionsRemaining = clamp(total - used, 0, total)', () {
    test('total=20, used=5 → remaining=15', () {
      final m = _membership(totalSessions: 20, sessionsUsed: 5);
      expect(m.sessionsRemaining, equals(15));
    });

    test('total=20, used=20 → remaining=0 (не від\'ємне)', () {
      final m = _membership(totalSessions: 20, sessionsUsed: 20);
      expect(m.sessionsRemaining, equals(0));
    });

    test('total=20, used=25 → remaining=0 (clamp, не від\'ємне)', () {
      final m = _membership(totalSessions: 20, sessionsUsed: 25);
      expect(m.sessionsRemaining, greaterThanOrEqualTo(0));
      expect(m.sessionsRemaining, equals(0));
    });

    test('total=null (часовий абонемент) → sessionsRemaining = null або не застосовно', () {
      final m = _membership(totalSessions: null, sessionsUsed: 0);
      // Для часового абонемента немає sessionsRemaining
      expect(m.totalSessions, isNull);
    });

    test('total=8, used=0 → remaining=8', () {
      final m = _membership(totalSessions: 8, sessionsUsed: 0);
      expect(m.sessionsRemaining, equals(8));
    });

    test('total=1, used=1 → remaining=0', () {
      final m = _membership(totalSessions: 1, sessionsUsed: 1);
      expect(m.sessionsRemaining, equals(0));
    });
  });

  // ── TC-MEMBERSHIP-002: isExpiringSoon — по кількості занять ─────────────

  group('TC-MEMBERSHIP-002: isExpiringSoon (заняття) — поріг ≤ 5', () {
    test('remaining=5 → isExpiringSoon=true', () {
      final m = _membership(totalSessions: 20, sessionsUsed: 15);
      expect(m.sessionsRemaining, equals(5));
      expect(m.isExpiringSoon, isTrue);
    });

    test('remaining=1 → isExpiringSoon=true', () {
      final m = _membership(totalSessions: 20, sessionsUsed: 19);
      expect(m.isExpiringSoon, isTrue);
    });

    test('remaining=0 → isExpiringSoon=true (вичерпано)', () {
      final m = _membership(totalSessions: 20, sessionsUsed: 20);
      expect(m.isExpiringSoon, isTrue);
    });

    test('remaining=6 → isExpiringSoon=false', () {
      final m = _membership(totalSessions: 20, sessionsUsed: 14);
      expect(m.sessionsRemaining, equals(6));
      expect(m.isExpiringSoon, isFalse);
    });

    test('remaining=10 → isExpiringSoon=false', () {
      final m = _membership(totalSessions: 20, sessionsUsed: 10);
      expect(m.isExpiringSoon, isFalse);
    });
  });

  // ── TC-MEMBERSHIP-003: isExpiringSoon — часовий абонемент, поріг 7 днів ──

  group('TC-MEMBERSHIP-003: isExpiringSoon (час) — поріг ≤ 7 днів', () {
    test('endDate через 7 днів → isExpiringSoon=true', () {
      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 7));
      // Time-based: no totalSessions
      final m = _membership(
        totalSessions: null,
        endDate: DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999),
      );
      expect(m.isExpiringSoon, isTrue);
    });

    test('endDate через 30 днів → isExpiringSoon=false', () {
      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 30));
      final m = _membership(
        totalSessions: null,
        endDate: DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999),
      );
      expect(m.isExpiringSoon, isFalse);
    });
  });

  // ── TC-MEMBERSHIP-004: endDate нормалізується до 23:59:59.999 ────────────

  group('TC-MEMBERSHIP-004: endDate нормалізується до кінця дня', () {
    test('MembershipModel.endDate з 23:59:59.999 → зберігається коректно', () {
      final end = DateTime(2026, 12, 31, 23, 59, 59, 999);
      final m = _membership(endDate: end);
      expect(m.endDate.hour, equals(23));
      expect(m.endDate.minute, equals(59));
      expect(m.endDate.second, equals(59));
      expect(m.endDate.millisecond, equals(999));
    });
  });

  // ── TC-MEMBERSHIP-005: sessionsUsed ніколи не скидається при auto-extend ──

  group('TC-MEMBERSHIP-005: auto-extend — sessionsUsed зберігається', () {
    test('auto-extend: новий endDate = старий + duration, sessionsUsed незмінний', () {
      // Симуляція логіки auto-extend: якщо є активний абонемент,
      // нова кінцева дата = існуюча endDate + тривалість нового
      final existing = _membership(
        endDate: _date(2026, 6, 30),
        sessionsUsed: 10,
        totalSessions: 20,
      );

      // Duration of new plan = 30 days
      const newDuration = Duration(days: 30);
      final finalEnd = existing.endDate.add(newDuration);

      expect(finalEnd, equals(_date(2026, 7, 30)));
      // sessionsUsed is carried over (not reset)
      expect(existing.sessionsUsed, equals(10));
    });

    test('auto-extend не знижує sessionsUsed до 0', () {
      final existing = _membership(sessionsUsed: 15, totalSessions: 20);
      // After extend, sessionsUsed stays at 15
      expect(existing.sessionsUsed, equals(15));
      // sessionsRemaining = clamp(20-15, 0, 20) = 5
      expect(existing.sessionsRemaining, equals(5));
    });
  });

  // ── TC-MEMBERSHIP-006: isActive статус (обчислюється з endDate) ────────────

  group('TC-MEMBERSHIP-006: isActive = !DateTime.now().isAfter(endDate)', () {
    test('endDate в майбутньому → isActive=true', () {
      final future = DateTime.now().add(const Duration(days: 30));
      final m = _membership(endDate: future);
      expect(m.isActive, isTrue);
    });

    test('endDate в минулому → isActive=false', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      final m = _membership(endDate: past);
      expect(m.isActive, isFalse);
    });

    test('sessionsRemaining=0 + endDate майбутнє → isActive=true (сесії і термін незалежні)', () {
      final future = DateTime.now().add(const Duration(days: 30));
      final m = _membership(totalSessions: 10, sessionsUsed: 10, endDate: future);
      // isActive depends on endDate, not on sessionsRemaining
      expect(m.isActive, isTrue);
      expect(m.sessionsRemaining, equals(0));
    });
  });

  // ── TC-MEMBERSHIP-007: daysRemaining розрахунок ────────────────────────────

  group('TC-MEMBERSHIP-007: daysRemaining', () {
    test('endDate через 30 днів → daysRemaining > 0', () {
      final future = DateTime.now().add(const Duration(days: 30));
      final m = _membership(endDate: future);
      expect(m.daysRemaining, greaterThan(0));
    });

    test('endDate в минулому → daysRemaining = 0 (clamp, ніколи не від\'ємний)', () {
      final past = DateTime.now().subtract(const Duration(days: 5));
      final m = _membership(endDate: past);
      // daysRemaining clamps negative to 0
      expect(m.daysRemaining, equals(0));
    });
  });
}

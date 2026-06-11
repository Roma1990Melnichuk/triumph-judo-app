import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/features/membership/utils/subscription_date_utils.dart';

// ── Tests — FIN-01: subscription start date + end date calculation ─────────────

void main() {
  // ── resolveSubscriptionStart ─────────────────────────────────────────────────

  group('resolveSubscriptionStart (FIN-01)', () {
    final now = DateTime(2026, 6, 10);
    final activeEnd = DateTime(2026, 7, 5);

    test('активний абонемент → старт від endDate поточного', () {
      final start = resolveSubscriptionStart(
        now: now,
        isCurrentlyActive: true,
        currentEndDate: activeEnd,
      );
      expect(start, activeEnd);
    });

    test('немає абонементу → старт від now', () {
      final start = resolveSubscriptionStart(
        now: now,
        isCurrentlyActive: false,
        currentEndDate: null,
      );
      expect(start, now);
    });

    test('прострочений абонемент → старт від now', () {
      final expiredEnd = DateTime(2026, 5, 1);
      final start = resolveSubscriptionStart(
        now: now,
        isCurrentlyActive: false,
        currentEndDate: expiredEnd,
      );
      expect(start, now);
    });

    test('активний але endDate == null (захист) → старт від now', () {
      final start = resolveSubscriptionStart(
        now: now,
        isCurrentlyActive: true,
        currentEndDate: null,
      );
      expect(start, now);
    });

    test('продовження: новий старт = endDate старого → дні не губляться', () {
      final currentEnd = DateTime(2026, 7, 10);
      final start = resolveSubscriptionStart(
        now: now,
        isCurrentlyActive: true,
        currentEndDate: currentEnd,
      );
      expect(start.isAtSameMomentAs(currentEnd), isTrue);
      expect(start.isAfter(now), isTrue);
    });
  });

  // ── computeSubscriptionEndDate ───────────────────────────────────────────────

  group('computeSubscriptionEndDate', () {
    final start = DateTime(2026, 6, 10);

    // Разові
    test('Разове × 1 → +1 день', () {
      final end = computeSubscriptionEndDate('Разове відвідування', 1, start);
      expect(end, DateTime(2026, 6, 11));
    });

    test('Разове × 5 → +5 днів', () {
      final end = computeSubscriptionEndDate('Разове', 5, start);
      expect(end, DateTime(2026, 6, 15));
    });

    // Тиждень
    test('2 рази на тиждень × 1 → +7 днів', () {
      final end = computeSubscriptionEndDate('2 рази на тиждень', 1, start);
      expect(end, DateTime(2026, 6, 17));
    });

    test('тиждень × 2 → +14 днів', () {
      final end = computeSubscriptionEndDate('Необмежено на тиждень', 2, start);
      expect(end, DateTime(2026, 6, 24));
    });

    // Місяці
    test('1 місяць × 1 → +1 місяць', () {
      final end = computeSubscriptionEndDate('1 місяць', 1, start);
      expect(end, DateTime(2026, 7, 10));
    });

    test('1 місяць × 2 → +2 місяці', () {
      final end = computeSubscriptionEndDate('1 місяць', 2, start);
      expect(end, DateTime(2026, 8, 10));
    });

    test('3 місяці × 1 → +3 місяці', () {
      final end = computeSubscriptionEndDate('3 місяці', 1, start);
      expect(end, DateTime(2026, 9, 10));
    });

    test('6 місяців × 1 → +6 місяців', () {
      final end = computeSubscriptionEndDate('6 місяців', 1, start);
      expect(end, DateTime(2026, 12, 10));
    });

    test('12 місяців × 1 → +12 місяців (наступний рік)', () {
      final end = computeSubscriptionEndDate('12 місяців', 1, start);
      expect(end, DateTime(2027, 6, 10));
    });

    // Захист FIN-01: продовження від endDate, а не від now
    test('продовження від endDate → не з today', () {
      final existingEnd = DateTime(2026, 7, 15);
      final end = computeSubscriptionEndDate('1 місяць', 1, existingEnd);
      // повинно бути +1 місяць від existingEnd, не від start (10 червня)
      expect(end, DateTime(2026, 8, 15));
      expect(end.isAfter(DateTime(2026, 7, 10)), isTrue);
    });

    test('fallback для невідомого плану → +1 місяць (multiplier = 1)', () {
      final end = computeSubscriptionEndDate('Невідомий план', 1, start);
      expect(end, DateTime(2026, 7, 10));
    });

    test('fallback × 3 → +3 місяці', () {
      final end = computeSubscriptionEndDate('Невідомий план', 3, start);
      expect(end, DateTime(2026, 9, 10));
    });
  });
}

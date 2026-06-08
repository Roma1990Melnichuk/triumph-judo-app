import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/features/membership/screens/membership_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TariffData — конструктор і обчислення знижок
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('TariffData', () {
    test('зберігає всі поля', () {
      const t = TariffData(
        name: '1 місяць',
        description: 'Повний доступ',
        iconEmoji: '🏆',
        badge: 'Популярний',
        price: 1450,
        oldPrice: 1650,
      );

      expect(t.name, '1 місяць');
      expect(t.description, 'Повний доступ');
      expect(t.iconEmoji, '🏆');
      expect(t.badge, 'Популярний');
      expect(t.price, 1450);
      expect(t.oldPrice, 1650);
    });

    test('oldPrice за замовчуванням null', () {
      const t = TariffData(
        name: 'Разове',
        description: '',
        iconEmoji: '⭐',
        badge: '',
        price: 150,
      );

      expect(t.oldPrice, isNull);
    });
  });

  // ── Логіка знижки (відтворює _discountPct з MembershipDetailScreen) ────────

  group('Розрахунок знижки', () {
    double discountPct(double price, double oldPrice) =>
        ((oldPrice - price) / oldPrice * 100).roundToDouble();

    test('1 місяць: 1450 з 1650 → ~12%', () {
      expect(discountPct(1450, 1650), closeTo(12, 1));
    });

    test('без знижки (oldPrice == price) → 0%', () {
      expect(discountPct(550, 550), 0);
    });

    test('50% знижка', () {
      expect(discountPct(500, 1000), closeTo(50, 0.5));
    });
  });

  // ── Варіанти × 2 і × 3 (логіка з _MembershipDetailScreenState._variants) ─

  group('Пакетні варіанти', () {
    const base = 1000.0;

    test('×2 variant має 5% знижку', () {
      final price2 = base * 2 * 0.95;
      final oldPrice2 = base * 2;
      final saving = ((oldPrice2 - price2) / oldPrice2 * 100).round();
      expect(saving, 5);
    });

    test('×3 variant має 10% знижку', () {
      final price3 = base * 3 * 0.90;
      final oldPrice3 = base * 3;
      final saving = ((oldPrice3 - price3) / oldPrice3 * 100).round();
      expect(saving, 10);
    });

    test('×2 дешевше ніж ×1 × 2', () {
      final single = base;
      final bundle2 = base * 2 * 0.95;
      expect(bundle2, lessThan(single * 2));
    });

    test('×3 дешевше ніж ×1 × 3', () {
      final single = base;
      final bundle3 = base * 3 * 0.90;
      expect(bundle3, lessThan(single * 3));
    });

    test('×3 відносна економія більша за ×2', () {
      final saving2 = base * 2 - base * 2 * 0.95;
      final saving3 = base * 3 - base * 3 * 0.90;
      // Per-unit saving3/3 > saving2/2
      expect(saving3 / 3, greaterThan(saving2 / 2));
    });
  });
}

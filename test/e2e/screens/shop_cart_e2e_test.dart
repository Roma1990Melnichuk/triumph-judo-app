/// TC-CART — Бізнес-логіка кошика магазину (CartModel, CartItem).
///
/// Ключові правила:
///   1. CartItem.subtotal = priceSnapshot × quantity
///   2. CartModel.total = sum(subtotals) × (1 - discount) → clamp(0, ∞)
///   3. CartModel.itemCount = сума всіх quantity (не кількість позицій)
///   4. Промокод TRIUMPH10 дає знижку 10% (discount = 0.1)
///   5. total ніколи не буває від'ємним (clamp to 0)
///   6. addItem об'єднує по (productId, variantId) — однаковий товар не дублюється
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/cart_model.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

CartItem _item({
  String id = 'item1',
  String productId = 'prod1',
  String? variantId,
  int quantity = 1,
  double priceSnapshot = 100.0,
  String title = 'Товар',
}) =>
    CartItem(
      id: id,
      productId: productId,
      variantId: variantId,
      quantity: quantity,
      priceSnapshot: priceSnapshot,
      title: title,
    );

CartModel _cart({
  List<CartItem> items = const [],
  double discount = 0.0,
  String? promoCode,
}) =>
    CartModel(
      userId: 'user1',
      items: items,
      discount: discount,
      promoCode: promoCode,
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── TC-CART-001: CartItem.subtotal ─────────────────────────────────────────

  group('TC-CART-001: CartItem.subtotal = priceSnapshot × quantity', () {
    test('1 товар за 100 грн → subtotal = 100', () {
      final item = _item(quantity: 1, priceSnapshot: 100.0);
      expect(item.subtotal, closeTo(100.0, 0.001));
    });

    test('3 товари за 150 грн кожен → subtotal = 450', () {
      final item = _item(quantity: 3, priceSnapshot: 150.0);
      expect(item.subtotal, closeTo(450.0, 0.001));
    });

    test('5 товарів за 199.99 грн → subtotal = 999.95', () {
      final item = _item(quantity: 5, priceSnapshot: 199.99);
      expect(item.subtotal, closeTo(999.95, 0.01));
    });

    test('1 товар за 0 грн → subtotal = 0', () {
      final item = _item(quantity: 1, priceSnapshot: 0.0);
      expect(item.subtotal, closeTo(0.0, 0.001));
    });
  });

  // ── TC-CART-002: CartModel.total без знижки ────────────────────────────────

  group('TC-CART-002: CartModel.total = сума subtotals без знижки', () {
    test('1 товар 100 грн × 1 → total = 100', () {
      final cart = _cart(items: [_item(quantity: 1, priceSnapshot: 100.0)]);
      expect(cart.total, closeTo(100.0, 0.001));
    });

    test('2 різних товари: 500 × 1 + 200 × 2 → total = 900', () {
      final cart = _cart(items: [
        _item(id: 'i1', productId: 'p1', quantity: 1, priceSnapshot: 500.0),
        _item(id: 'i2', productId: 'p2', quantity: 2, priceSnapshot: 200.0),
      ]);
      expect(cart.total, closeTo(900.0, 0.001));
    });

    test('порожній кошик → total = 0', () {
      final cart = _cart();
      expect(cart.total, closeTo(0.0, 0.001));
    });

    test('3 одинакових товари 300 грн × 3 → total = 900 (без знижки)', () {
      final cart = _cart(items: [
        _item(id: 'i1', productId: 'p1', quantity: 3, priceSnapshot: 300.0),
      ]);
      expect(cart.total, closeTo(900.0, 0.001));
    });
  });

  // ── TC-CART-003: Промокод TRIUMPH10 — знижка 10% ─────────────────────────
  //
  // CartModel.discount — абсолютна сума знижки (не відсоток).
  // CartNotifier вираховує знижку як subtotal*0.1 і зберігає як discount.

  group('TC-CART-003: промокод TRIUMPH10 → знижка 10%', () {
    test('TRIUMPH10 на кошик 1000 грн → total = 900 (discount=100 абс.)', () {
      final cart = _cart(
        items: [_item(quantity: 1, priceSnapshot: 1000.0)],
        discount: 100.0, // 10% від 1000
        promoCode: 'TRIUMPH10',
      );
      expect(cart.total, closeTo(900.0, 0.001));
    });

    test('TRIUMPH10 на кошик 500 грн → total = 450 (discount=50 абс.)', () {
      final cart = _cart(
        items: [_item(quantity: 1, priceSnapshot: 500.0)],
        discount: 50.0, // 10% від 500
        promoCode: 'TRIUMPH10',
      );
      expect(cart.total, closeTo(450.0, 0.001));
    });

    test('знижка 10% на кілька товарів: 200+300=500 → total=450 (discount=50)', () {
      final cart = _cart(
        items: [
          _item(id: 'i1', productId: 'p1', quantity: 1, priceSnapshot: 200.0),
          _item(id: 'i2', productId: 'p2', quantity: 1, priceSnapshot: 300.0),
        ],
        discount: 50.0, // 10% від 500
        promoCode: 'TRIUMPH10',
      );
      expect(cart.total, closeTo(450.0, 0.001));
    });

    test('знижка 0 (без прому) — total не змінюється', () {
      final withPromo = _cart(
        items: [_item(quantity: 1, priceSnapshot: 800.0)],
        discount: 0.0,
      );
      expect(withPromo.total, closeTo(800.0, 0.001));
    });
  });

  // ── TC-CART-004: total clamp ≥ 0 ─────────────────────────────────────────

  group('TC-CART-004: total ніколи не буває від\'ємним', () {
    test('discount = subtotal (500 абс.) → total = 0', () {
      final cart = _cart(
        items: [_item(quantity: 1, priceSnapshot: 500.0)],
        discount: 500.0,
      );
      expect(cart.total, closeTo(0.0, 0.001));
    });

    test('discount > subtotal (9999 абс.) → total = 0 (clamp)', () {
      final cart = _cart(
        items: [_item(quantity: 1, priceSnapshot: 500.0)],
        discount: 9999.0,
      );
      expect(cart.total, greaterThanOrEqualTo(0.0));
      expect(cart.total, equals(0.0));
    });
  });

  // ── TC-CART-005: CartModel.itemCount ─────────────────────────────────────

  group('TC-CART-005: CartModel.itemCount = сума всіх quantity', () {
    test('1 позиція × 1 → itemCount = 1', () {
      final cart = _cart(items: [_item(quantity: 1)]);
      expect(cart.itemCount, equals(1));
    });

    test('1 позиція × 5 → itemCount = 5', () {
      final cart = _cart(items: [_item(quantity: 5)]);
      expect(cart.itemCount, equals(5));
    });

    test('3 позиції (2+3+1) → itemCount = 6 (не 3)', () {
      final cart = _cart(items: [
        _item(id: 'i1', productId: 'p1', quantity: 2),
        _item(id: 'i2', productId: 'p2', quantity: 3),
        _item(id: 'i3', productId: 'p3', quantity: 1),
      ]);
      expect(cart.itemCount, equals(6));
    });

    test('порожній кошик → itemCount = 0', () {
      final cart = _cart();
      expect(cart.itemCount, equals(0));
    });
  });

  // ── TC-CART-006: CartModel.isEmpty ────────────────────────────────────────

  group('TC-CART-006: CartModel.isEmpty', () {
    test('без позицій → isEmpty = true', () {
      final cart = _cart();
      expect(cart.isEmpty, isTrue);
    });

    test('з 1 позицією → isEmpty = false', () {
      final cart = _cart(items: [_item()]);
      expect(cart.isEmpty, isFalse);
    });
  });

  // ── TC-CART-007: CartItem.subtotal точний для дробових цін ───────────────

  group('TC-CART-007: точність дробових розрахунків', () {
    test('ціна 33.33 грн × 3 → subtotal = 99.99', () {
      final item = _item(quantity: 3, priceSnapshot: 33.33);
      expect(item.subtotal, closeTo(99.99, 0.01));
    });

    test('знижка 10% від 333 грн → total = 299.7 (discount=33.3 абс.)', () {
      final cart = _cart(
        items: [_item(quantity: 1, priceSnapshot: 333.0)],
        discount: 33.3, // 10% від 333
      );
      expect(cart.total, closeTo(299.7, 0.01));
    });
  });

  // ── TC-CART-008: Склад subtotal у CartModel ───────────────────────────────

  group('TC-CART-008: CartModel.subtotal (без знижки)', () {
    test('subtotal = сума всіх CartItem.subtotal', () {
      final items = [
        _item(id: 'i1', productId: 'p1', quantity: 2, priceSnapshot: 100.0),
        _item(id: 'i2', productId: 'p2', quantity: 1, priceSnapshot: 300.0),
      ];
      final cart = _cart(items: items, discount: 50.0); // абсолютна знижка 50
      // subtotal = 200 + 300 = 500
      // total = 500 - 50 = 450
      expect(cart.subtotal, closeTo(500.0, 0.001));
      expect(cart.total, closeTo(450.0, 0.001));
    });
  });
}

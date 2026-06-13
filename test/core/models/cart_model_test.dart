import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/cart_model.dart';

CartItem makeItem({
  String id = 'ci1',
  String productId = 'sp1',
  String? variantId,
  int quantity = 1,
  double priceSnapshot = 100.0,
  String title = 'Кімоно',
  String? size,
  String? color,
}) =>
    CartItem(
      id: id,
      productId: productId,
      variantId: variantId,
      quantity: quantity,
      priceSnapshot: priceSnapshot,
      title: title,
      size: size,
      color: color,
    );

void main() {
  // ── CartItem.subtotal ────────────────────────────────────────────────────

  group('CartItem.subtotal', () {
    test('один товар', () {
      expect(makeItem(priceSnapshot: 300, quantity: 1).subtotal, 300.0);
    });

    test('множить ціну на кількість', () {
      expect(makeItem(priceSnapshot: 250, quantity: 3).subtotal, 750.0);
    });

    test('кількість 0', () {
      expect(makeItem(priceSnapshot: 500, quantity: 0).subtotal, 0.0);
    });
  });

  // ── CartItem.copyWith ────────────────────────────────────────────────────

  group('CartItem.copyWith', () {
    test('змінює тільки quantity', () {
      final item = makeItem(quantity: 2, priceSnapshot: 200);
      final updated = item.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.priceSnapshot, 200.0);
      expect(updated.id, item.id);
      expect(updated.title, item.title);
    });

    test('без аргументів повертає ідентичний об\'єкт', () {
      final item = makeItem(quantity: 3);
      final copy = item.copyWith();
      expect(copy.quantity, 3);
      expect(copy.id, item.id);
    });
  });

  // ── CartItem toMap / fromMap round-trip ───────────────────────────────────

  group('CartItem — round-trip', () {
    test('зберігає всі поля', () {
      final item = makeItem(
        id: 'ci99',
        productId: 'sp42',
        variantId: 'sv7',
        quantity: 4,
        priceSnapshot: 999.0,
        title: 'Худі',
        size: 'XL',
        color: 'Чорний',
      );
      final restored = CartItem.fromMap(item.toMap());
      expect(restored.id, item.id);
      expect(restored.productId, item.productId);
      expect(restored.variantId, item.variantId);
      expect(restored.quantity, item.quantity);
      expect(restored.priceSnapshot, item.priceSnapshot);
      expect(restored.title, item.title);
      expect(restored.size, item.size);
      expect(restored.color, item.color);
    });

    test('null-поля зберігаються як null', () {
      final item = makeItem();
      final restored = CartItem.fromMap(item.toMap());
      expect(restored.variantId, isNull);
      expect(restored.size, isNull);
      expect(restored.color, isNull);
      expect(restored.imageUrl, isNull);
    });
  });

  // ── CartModel getters ────────────────────────────────────────────────────

  group('CartModel.subtotal', () {
    test('порожній кошик → 0', () {
      final cart = CartModel(userId: 'u1');
      expect(cart.subtotal, 0.0);
    });

    test('сума всіх позицій', () {
      final cart = CartModel(
        userId: 'u1',
        items: [
          makeItem(priceSnapshot: 200, quantity: 2),
          makeItem(id: 'ci2', priceSnapshot: 100, quantity: 3),
        ],
      );
      expect(cart.subtotal, 700.0);
    });
  });

  group('CartModel.total', () {
    test('без знижки = subtotal', () {
      final cart = CartModel(
        userId: 'u1',
        items: [makeItem(priceSnapshot: 500, quantity: 1)],
      );
      expect(cart.total, 500.0);
    });

    test('зі знижкою subtotal − discount', () {
      final cart = CartModel(
        userId: 'u1',
        items: [makeItem(priceSnapshot: 1000, quantity: 1)],
        discount: 100.0,
      );
      expect(cart.total, 900.0);
    });

    test('знижка не може бути від\'ємною (clamp)', () {
      final cart = CartModel(
        userId: 'u1',
        items: [makeItem(priceSnapshot: 50, quantity: 1)],
        discount: 200.0,
      );
      expect(cart.total, 0.0);
    });
  });

  group('CartModel.itemCount', () {
    test('порожній кошик → 0', () {
      expect(CartModel(userId: 'u1').itemCount, 0);
    });

    test('сума quantity по всіх позиціях', () {
      final cart = CartModel(
        userId: 'u1',
        items: [
          makeItem(quantity: 2),
          makeItem(id: 'ci2', quantity: 3),
        ],
      );
      expect(cart.itemCount, 5);
    });
  });

  group('CartModel.isEmpty', () {
    test('порожній кошик', () {
      expect(CartModel(userId: 'u1').isEmpty, isTrue);
    });

    test('непорожній кошик', () {
      final cart = CartModel(
        userId: 'u1',
        items: [makeItem()],
      );
      expect(cart.isEmpty, isFalse);
    });
  });

  // ── CartModel toMap / fromMap round-trip ──────────────────────────────────

  group('CartModel — round-trip', () {
    test('зберігає items, promoCode, discount', () {
      final cart = CartModel(
        userId: 'user42',
        items: [
          makeItem(id: 'a', priceSnapshot: 300, quantity: 2),
          makeItem(id: 'b', priceSnapshot: 150, quantity: 1),
        ],
        promoCode: 'TRIUMPH10',
        discount: 45.0,
      );
      final restored = CartModel.fromMap('user42', cart.toMap());
      expect(restored.userId, 'user42');
      expect(restored.items.length, 2);
      expect(restored.promoCode, 'TRIUMPH10');
      expect(restored.discount, 45.0);
    });

    test('items як не-список → порожній список', () {
      final cart = CartModel.fromMap('u1', {'items': null, 'discount': 0});
      expect(cart.items, isEmpty);
    });

    test('відсутній discount → 0', () {
      final cart = CartModel.fromMap('u1', {'items': []});
      expect(cart.discount, 0.0);
    });
  });

  // ── CartModel.copyWith ────────────────────────────────────────────────────

  group('CartModel.copyWith', () {
    test('змінює тільки вказані поля', () {
      final cart = CartModel(
        userId: 'u1',
        items: [makeItem()],
        promoCode: 'OLD',
        discount: 10.0,
      );
      final updated = cart.copyWith(promoCode: 'NEW', discount: 50.0);
      expect(updated.userId, 'u1');
      expect(updated.items.length, 1);
      expect(updated.promoCode, 'NEW');
      expect(updated.discount, 50.0);
    });
  });
}

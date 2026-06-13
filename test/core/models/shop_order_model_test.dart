import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/shop_order_model.dart';

ShopOrderItem makeOrderItem({
  String productId = 'sp1',
  String productTitle = 'Кімоно',
  int quantity = 1,
  double priceSnapshot = 500.0,
  String? variantId,
  String? size,
  String? color,
}) =>
    ShopOrderItem(
      productId: productId,
      productTitle: productTitle,
      quantity: quantity,
      priceSnapshot: priceSnapshot,
      variantId: variantId,
      size: size,
      color: color,
    );

ShopOrder makeOrder({
  String id = 'ord1',
  String userId = 'user1',
  String orderNumber = 'T-20260101-ABCD',
  ShopOrderStatus status = ShopOrderStatus.newOrder,
  List<ShopOrderItem>? items,
  double totalAmount = 500.0,
  ShopDeliveryMethod deliveryMethod = ShopDeliveryMethod.pickupAtClub,
  ShopPaymentMethod paymentMethod = ShopPaymentMethod.cashAtClub,
  String recipientName = 'Іван Тест',
  String recipientPhone = '+380991234567',
  String comment = '',
  String? adminComment,
  DateTime? createdAt,
  DateTime? updatedAt,
}) =>
    ShopOrder(
      id: id,
      userId: userId,
      orderNumber: orderNumber,
      status: status,
      items: items ?? [makeOrderItem()],
      totalAmount: totalAmount,
      currency: 'UAH',
      deliveryMethod: deliveryMethod,
      paymentMethod: paymentMethod,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      comment: comment,
      adminComment: adminComment,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      updatedAt: updatedAt ?? DateTime(2026, 1, 1),
    );

void main() {
  // ── ShopOrderStatus labels ─────────────────────────────────────────────────

  group('ShopOrderStatus.label', () {
    final cases = {
      ShopOrderStatus.newOrder: 'Нове замовлення',
      ShopOrderStatus.confirmed: 'Підтверджено',
      ShopOrderStatus.preparing: 'Готується',
      ShopOrderStatus.waitingAtClub: 'Очікує в клубі',
      ShopOrderStatus.transferredToCoach: 'Передано тренеру',
      ShopOrderStatus.delivering: 'Доставляється',
      ShopOrderStatus.completed: 'Завершено',
      ShopOrderStatus.cancelled: 'Скасовано',
    };
    cases.forEach((status, label) {
      test('$status → $label', () => expect(status.label, label));
    });
  });

  // ── ShopOrderStatus.isFinal / isActive ─────────────────────────────────────

  group('ShopOrderStatus.isFinal', () {
    test('completed → isFinal', () {
      expect(ShopOrderStatus.completed.isFinal, isTrue);
    });

    test('cancelled → isFinal', () {
      expect(ShopOrderStatus.cancelled.isFinal, isTrue);
    });

    test('newOrder → не фінальний', () {
      expect(ShopOrderStatus.newOrder.isFinal, isFalse);
    });

    test('isActive = !isFinal', () {
      for (final s in ShopOrderStatus.values) {
        expect(s.isActive, !s.isFinal);
      }
    });
  });

  // ── ShopOrderStatus.nextStatus ─────────────────────────────────────────────

  group('ShopOrderStatus.nextStatus', () {
    test('newOrder → confirmed', () {
      expect(ShopOrderStatus.newOrder.nextStatus, ShopOrderStatus.confirmed);
    });

    test('confirmed → preparing', () {
      expect(ShopOrderStatus.confirmed.nextStatus, ShopOrderStatus.preparing);
    });

    test('completed → null', () {
      expect(ShopOrderStatus.completed.nextStatus, isNull);
    });

    test('cancelled → null', () {
      expect(ShopOrderStatus.cancelled.nextStatus, isNull);
    });

    test('waitingAtClub → completed', () {
      expect(ShopOrderStatus.waitingAtClub.nextStatus, ShopOrderStatus.completed);
    });
  });

  // ── ShopOrderStatusX.fromString ────────────────────────────────────────────

  group('ShopOrderStatusX.fromString', () {
    test('розпізнає всі значення', () {
      for (final s in ShopOrderStatus.values) {
        expect(ShopOrderStatusX.fromString(s.name), s);
      }
    });

    test('невідомий рядок → newOrder (fallback)', () {
      expect(ShopOrderStatusX.fromString('unknown'), ShopOrderStatus.newOrder);
      expect(ShopOrderStatusX.fromString(null), ShopOrderStatus.newOrder);
    });
  });

  // ── ShopDeliveryMethod.label ───────────────────────────────────────────────

  group('ShopDeliveryMethod.label', () {
    final cases = {
      ShopDeliveryMethod.pickupAtClub: 'Забрати в клубі',
      ShopDeliveryMethod.fromCoach: 'Отримати у тренера',
      ShopDeliveryMethod.novaPost: 'Доставка Новою Поштою',
    };
    cases.forEach((method, label) {
      test('$method → $label', () => expect(method.label, label));
    });
  });

  group('ShopDeliveryMethodX.fromString', () {
    test('розпізнає всі значення', () {
      for (final m in ShopDeliveryMethod.values) {
        expect(ShopDeliveryMethodX.fromString(m.name), m);
      }
    });

    test('невідомий → pickupAtClub', () {
      expect(ShopDeliveryMethodX.fromString('xyz'), ShopDeliveryMethod.pickupAtClub);
      expect(ShopDeliveryMethodX.fromString(null), ShopDeliveryMethod.pickupAtClub);
    });
  });

  // ── ShopPaymentMethod.label ────────────────────────────────────────────────

  group('ShopPaymentMethod.label', () {
    final cases = {
      ShopPaymentMethod.online: 'Онлайн',
      ShopPaymentMethod.cashAtClub: 'Готівка в клубі',
      ShopPaymentMethod.cardTransfer: 'Переказ на картку',
    };
    cases.forEach((method, label) {
      test('$method → $label', () => expect(method.label, label));
    });
  });

  group('ShopPaymentMethodX.fromString', () {
    test('розпізнає всі значення', () {
      for (final m in ShopPaymentMethod.values) {
        expect(ShopPaymentMethodX.fromString(m.name), m);
      }
    });

    test('невідомий → cashAtClub', () {
      expect(ShopPaymentMethodX.fromString(null), ShopPaymentMethod.cashAtClub);
    });
  });

  // ── ShopOrderItem.subtotal ─────────────────────────────────────────────────

  group('ShopOrderItem.subtotal', () {
    test('ціна × кількість', () {
      expect(makeOrderItem(priceSnapshot: 200, quantity: 3).subtotal, 600.0);
    });
  });

  // ── ShopOrderItem toMap / fromMap ──────────────────────────────────────────

  group('ShopOrderItem — round-trip', () {
    test('зберігає всі поля', () {
      final item = makeOrderItem(
        productId: 'sp99',
        productTitle: 'Худі',
        quantity: 2,
        priceSnapshot: 750.0,
        variantId: 'sv1',
        size: 'L',
        color: 'Чорний',
      );
      final restored = ShopOrderItem.fromMap(item.toMap());
      expect(restored.productId, item.productId);
      expect(restored.productTitle, item.productTitle);
      expect(restored.quantity, item.quantity);
      expect(restored.priceSnapshot, item.priceSnapshot);
      expect(restored.variantId, item.variantId);
      expect(restored.size, item.size);
      expect(restored.color, item.color);
    });

    test('null-поля не попадають в toMap', () {
      final map = makeOrderItem().toMap();
      expect(map.containsKey('variantId'), isFalse);
      expect(map.containsKey('size'), isFalse);
      expect(map.containsKey('color'), isFalse);
      expect(map.containsKey('imageUrl'), isFalse);
    });
  });

  // ── ShopOrder.itemCount ────────────────────────────────────────────────────

  group('ShopOrder.itemCount', () {
    test('сума quantity по позиціях', () {
      final order = makeOrder(items: [
        makeOrderItem(quantity: 2),
        makeOrderItem(productId: 'sp2', quantity: 3),
      ]);
      expect(order.itemCount, 5);
    });
  });

  // ── ShopOrder.toFirestore ──────────────────────────────────────────────────

  group('ShopOrder.toFirestore', () {
    test('містить обов\'язкові поля', () {
      final map = makeOrder().toFirestore();
      expect(map['userId'], 'user1');
      expect(map['orderNumber'], 'T-20260101-ABCD');
      expect(map['status'], 'newOrder');
      expect(map['totalAmount'], 500.0);
      expect(map['currency'], 'UAH');
      expect(map['deliveryMethod'], 'pickupAtClub');
      expect(map['paymentMethod'], 'cashAtClub');
      expect(map['recipientName'], 'Іван Тест');
      expect(map['recipientPhone'], '+380991234567');
    });

    test('adminComment відсутній коли null', () {
      expect(makeOrder().toFirestore().containsKey('adminComment'), isFalse);
    });

    test('adminComment присутній коли вказаний', () {
      final map = makeOrder(adminComment: 'Є питання').toFirestore();
      expect(map['adminComment'], 'Є питання');
    });

    test('createdAt серіалізується як Timestamp', () {
      final map = makeOrder(createdAt: DateTime(2026, 3, 15)).toFirestore();
      expect(map['createdAt'], isA<Timestamp>());
      expect((map['createdAt'] as Timestamp).toDate(), DateTime(2026, 3, 15));
    });

    test('items серіалізуються як список мап', () {
      final map = makeOrder().toFirestore();
      expect(map['items'], isA<List>());
      expect((map['items'] as List).first, isA<Map>());
    });
  });

  // ── ShopOrder.fromFirestore ────────────────────────────────────────────────

  group('ShopOrder.fromFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;
    setUp(() => fakeFirestore = FakeFirebaseFirestore());

    test('зчитує всі поля коректно', () async {
      final ref = fakeFirestore.collection('shop_orders').doc('o1');
      await ref.set({
        'userId': 'u42',
        'orderNumber': 'T-20260601-BEEF',
        'status': 'confirmed',
        'items': [
          {
            'productId': 'sp1',
            'productTitle': 'Кімоно',
            'quantity': 2,
            'priceSnapshot': 2890.0,
          }
        ],
        'totalAmount': 5780.0,
        'currency': 'UAH',
        'deliveryMethod': 'fromCoach',
        'paymentMethod': 'online',
        'recipientName': 'Марія',
        'recipientPhone': '+380501234567',
        'comment': 'Привіт',
        'adminComment': 'Ок',
        'createdAt': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 6, 2)),
      });
      final order = ShopOrder.fromFirestore(await ref.get());
      expect(order.userId, 'u42');
      expect(order.orderNumber, 'T-20260601-BEEF');
      expect(order.status, ShopOrderStatus.confirmed);
      expect(order.items.length, 1);
      expect(order.items.first.quantity, 2);
      expect(order.totalAmount, 5780.0);
      expect(order.deliveryMethod, ShopDeliveryMethod.fromCoach);
      expect(order.paymentMethod, ShopPaymentMethod.online);
      expect(order.adminComment, 'Ок');
      expect(order.createdAt, DateTime(2026, 6, 1));
    });

    test('відсутні необов\'язкові поля → defaults', () async {
      final ref = fakeFirestore.collection('shop_orders').doc('o2');
      await ref.set({
        'userId': 'u1',
        'orderNumber': 'T-20260101-0000',
        'items': [],
        'totalAmount': 0.0,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
      final order = ShopOrder.fromFirestore(await ref.get());
      expect(order.currency, 'UAH');
      expect(order.deliveryMethod, ShopDeliveryMethod.pickupAtClub);
      expect(order.paymentMethod, ShopPaymentMethod.cashAtClub);
      expect(order.recipientName, '');
      expect(order.comment, '');
      expect(order.adminComment, isNull);
    });
  });

  // ── ShopOrder.copyWith ─────────────────────────────────────────────────────

  group('ShopOrder.copyWith', () {
    test('змінює тільки status та adminComment', () {
      final order = makeOrder(status: ShopOrderStatus.newOrder);
      final updated = order.copyWith(
        status: ShopOrderStatus.confirmed,
        adminComment: 'Підтверджено',
      );
      expect(updated.status, ShopOrderStatus.confirmed);
      expect(updated.adminComment, 'Підтверджено');
      expect(updated.userId, order.userId);
      expect(updated.orderNumber, order.orderNumber);
    });
  });

  // ── round-trip ShopOrder ───────────────────────────────────────────────────

  group('ShopOrder — round-trip', () {
    test('toFirestore → fromFirestore зберігає поля', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final original = makeOrder(
        id: 'rt1',
        status: ShopOrderStatus.preparing,
        totalAmount: 2890.0,
        deliveryMethod: ShopDeliveryMethod.novaPost,
        paymentMethod: ShopPaymentMethod.cardTransfer,
        adminComment: 'На відправці',
        createdAt: DateTime(2026, 5, 10),
      );
      await fakeFirestore.collection('shop_orders').doc('rt1').set(original.toFirestore());
      final doc = await fakeFirestore.collection('shop_orders').doc('rt1').get();
      final restored = ShopOrder.fromFirestore(doc);
      expect(restored.status, original.status);
      expect(restored.totalAmount, original.totalAmount);
      expect(restored.deliveryMethod, original.deliveryMethod);
      expect(restored.paymentMethod, original.paymentMethod);
      expect(restored.adminComment, original.adminComment);
      expect(restored.createdAt, original.createdAt);
    });
  });
}

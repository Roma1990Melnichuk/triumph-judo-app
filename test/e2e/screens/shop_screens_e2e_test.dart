/// E2E тести для ShopNotifier (addProduct, updateProduct, toggleActive, deleteProduct).
/// Примітка: CartNotifier та OrderNotifier використовують FirebaseAuth.instance
/// безпосередньо і не підтримують DI — їх тестування потребує окремого підходу.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/shop_product_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/shop/providers/shop_provider.dart';

// ── Хелпери ───────────────────────────────────────────────────────────────────

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

ProviderContainer _container(FakeFirebaseFirestore db) => ProviderContainer(
      overrides: [firestoreProvider.overrideWithValue(db)],
    );

ShopNotifier _notifier(FakeFirebaseFirestore db) => ShopNotifier(db);

ShopProduct _product({
  String id = 'prod1',
  String title = 'Кімоно',
  double price = 1200.0,
  bool isActive = true,
  bool isFeatured = false,
}) =>
    ShopProduct(
      id: id,
      title: title,
      description: 'Опис товару',
      price: price,
      currency: 'UAH',
      category: ShopCategory.kimono,
      imageUrls: const [],
      variants: const [],
      isActive: isActive,
      isFeatured: isFeatured,
      isNew: false,
      createdAt: DateTime(2025, 6, 15),
      updatedAt: DateTime(2025, 6, 15),
    );

Future<String> _seedProduct(
  FakeFirebaseFirestore db, {
  String id = 'prod1',
  String title = 'Товар',
  bool isActive = true,
}) async {
  await db.collection('shop_products').doc(id).set({
    'title': title,
    'description': 'Опис',
    'price': 500.0,
    'currency': 'UAH',
    'category': 'uniform',
    'imageUrls': <String>[],
    'variants': <dynamic>[],
    'isActive': isActive,
    'isFeatured': false,
    'isNew': false,
    'createdAt': Timestamp.fromDate(DateTime(2025, 6, 15)),
  });
  return id;
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── addProduct ────────────────────────────────────────────────────────────

  group('ShopNotifier — addProduct', () {
    test('зберігає товар у Firestore', () async {
      final db = _db();
      final n = _notifier(db);

      await n.addProduct(_product());

      final doc = await db.collection('shop_products').doc('prod1').get();
      expect(doc.exists, isTrue);
      expect(doc['title'], 'Кімоно');
      expect(doc['category'], 'kimono');
    });

    test('зберігає ціну і валюту', () async {
      final db = _db();
      final n = _notifier(db);

      await n.addProduct(_product(price: 2500.0));

      final doc = await db.collection('shop_products').doc('prod1').get();
      expect((doc['price'] as num).toDouble(), 2500.0);
      expect(doc['currency'], 'UAH');
    });

    test('кілька товарів — різні ID', () async {
      final db = _db();
      final n = _notifier(db);

      await n.addProduct(_product(id: 'p1', title: 'Кімоно'));
      await n.addProduct(_product(id: 'p2', title: 'Пояс'));
      await n.addProduct(_product(id: 'p3', title: 'Рюкзак'));

      final snap = await db.collection('shop_products').get();
      expect(snap.docs, hasLength(3));
    });

    test('стан = AsyncData після addProduct', () async {
      final db = _db();
      final n = _notifier(db);

      await n.addProduct(_product());
      expect(n.state, isA<AsyncData<void>>());
    });
  });

  // ── updateProduct ─────────────────────────────────────────────────────────

  group('ShopNotifier — updateProduct', () {
    test('оновлює назву товару', () async {
      final db = _db();
      await _seedProduct(db, title: 'Стара назва');
      final n = _notifier(db);

      await n.updateProduct(_product(title: 'Нова назва'));

      final doc = await db.collection('shop_products').doc('prod1').get();
      expect(doc['title'], 'Нова назва');
    });

    test('оновлює ціну', () async {
      final db = _db();
      await _seedProduct(db);
      final n = _notifier(db);

      await n.updateProduct(_product(price: 999.0));

      final doc = await db.collection('shop_products').doc('prod1').get();
      expect((doc['price'] as num).toDouble(), 999.0);
    });

    test('updateProduct не чіпає інші товари', () async {
      final db = _db();
      await _seedProduct(db, id: 'p1', title: 'Товар 1');
      await _seedProduct(db, id: 'p2', title: 'Товар 2');
      final n = _notifier(db);

      await n.updateProduct(_product(id: 'p1', title: 'Оновлений 1'));

      final doc2 = await db.collection('shop_products').doc('p2').get();
      expect(doc2['title'], 'Товар 2');
    });

    test('стан = AsyncData після updateProduct', () async {
      final db = _db();
      await _seedProduct(db);
      final n = _notifier(db);

      await n.updateProduct(_product(title: 'Оновлено'));
      expect(n.state, isA<AsyncData<void>>());
    });
  });

  // ── toggleActive ──────────────────────────────────────────────────────────

  group('ShopNotifier — toggleActive', () {
    test('деактивує активний товар (true → false)', () async {
      final db = _db();
      await _seedProduct(db, isActive: true);
      final n = _notifier(db);

      await n.toggleActive('prod1', false);

      final doc = await db.collection('shop_products').doc('prod1').get();
      expect(doc['isActive'], isFalse);
    });

    test('активує неактивний товар (false → true)', () async {
      final db = _db();
      await _seedProduct(db, isActive: false);
      final n = _notifier(db);

      await n.toggleActive('prod1', true);

      final doc = await db.collection('shop_products').doc('prod1').get();
      expect(doc['isActive'], isTrue);
    });

    test('toggleActive не чіпає інші товари', () async {
      final db = _db();
      await _seedProduct(db, id: 'p1', isActive: true);
      await _seedProduct(db, id: 'p2', isActive: true);
      final n = _notifier(db);

      await n.toggleActive('p1', false);

      final doc2 = await db.collection('shop_products').doc('p2').get();
      expect(doc2['isActive'], isTrue);
    });
  });

  // ── deleteProduct ─────────────────────────────────────────────────────────

  group('ShopNotifier — deleteProduct', () {
    test('видаляє товар з Firestore', () async {
      final db = _db();
      await _seedProduct(db);
      final n = _notifier(db);

      await n.deleteProduct('prod1');

      expect(
          (await db.collection('shop_products').doc('prod1').get()).exists,
          isFalse);
    });

    test('видаляє тільки потрібний товар', () async {
      final db = _db();
      await _seedProduct(db, id: 'p1', title: 'Видалити');
      await _seedProduct(db, id: 'p2', title: 'Залишити');
      final n = _notifier(db);

      await n.deleteProduct('p1');

      final snap = await db.collection('shop_products').get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first.id, 'p2');
    });

    test('стан = AsyncData після deleteProduct', () async {
      final db = _db();
      await _seedProduct(db);
      final n = _notifier(db);

      await n.deleteProduct('prod1');
      expect(n.state, isA<AsyncData<void>>());
    });
  });

  // ── Повний сценарій адміна магазину ──────────────────────────────────────

  group('Shop — повний сценарій', () {
    test('адмін: додає → оновлює → деактивує → видаляє', () async {
      final db = _db();
      final n = _notifier(db);

      // 1. Додати
      await n.addProduct(_product(id: 'p1', title: 'Кімоно'));
      expect((await db.collection('shop_products').doc('p1').get()).exists,
          isTrue);

      // 2. Оновити назву і ціну
      await n.updateProduct(
          _product(id: 'p1', title: 'Кімоно преміум', price: 1500.0));
      final updated = await db.collection('shop_products').doc('p1').get();
      expect(updated['title'], 'Кімоно преміум');
      expect((updated['price'] as num).toDouble(), 1500.0);

      // 3. Деактивувати
      await n.toggleActive('p1', false);
      expect(
          (await db.collection('shop_products').doc('p1').get())['isActive'],
          isFalse);

      // 4. Видалити
      await n.deleteProduct('p1');
      expect(
          (await db.collection('shop_products').doc('p1').get()).exists,
          isFalse);
    });
  });
}

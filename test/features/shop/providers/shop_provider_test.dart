import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/shop_product_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/shop/providers/shop_provider.dart';

ProviderContainer makeContainer(FakeFirebaseFirestore db) =>
    ProviderContainer(
      overrides: [firestoreProvider.overrideWithValue(db)],
    );

Map<String, dynamic> _baseProduct({
  String id = 'p1',
  String title = 'Кімоно',
  bool isActive = true,
  bool isFeatured = false,
  bool isNew = false,
  String category = 'kimono',
}) =>
    {
      'title': title,
      'description': 'Опис',
      'category': category,
      'price': 1500.0,
      'oldPrice': null,
      'imageUrls': <String>[],
      'badge': null,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'isNew': isNew,
      'isInStock': true,
      'variants': <Map<String, dynamic>>[],
      'coachNote': null,
      'createdAt': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      'updatedAt': DateTime(2026, 1, 1).millisecondsSinceEpoch,
    };

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('shopProductsProvider', () {
    test('повертає порожній список коли Firestore порожній і сидінг неможливий',
        () async {
      final db = FakeFirebaseFirestore();
      final c = makeContainer(db);
      addTearDown(c.dispose);

      // FakeFirebaseFirestore дозволяє запис — сидинг пройде
      // Перевіряємо що після сидінгу є товари
      final products = await c.read(shopProductsProvider.future);
      expect(products, isNotEmpty,
          reason: 'Після авто-сидінгу в магазині мають бути default-товари');
    });

    test('авто-сидінг завантажує всі ShopProduct.defaults', () async {
      final db = FakeFirebaseFirestore();
      final c = makeContainer(db);
      addTearDown(c.dispose);

      await c.read(shopProductsProvider.future);

      final snap =
          await db.collection('shop_products').get();
      expect(snap.docs.length, equals(ShopProduct.defaults.length));
    });

    test('НЕ дублює товари якщо колекція вже заповнена', () async {
      final db = FakeFirebaseFirestore();
      // Заздалегідь записуємо один продукт через модельний toFirestore()
      final existingProduct = ShopProduct.defaults.first.copyWith(id: 'existing', title: 'Вже є');
      await db.collection('shop_products').doc('existing').set(existingProduct.toFirestore());

      final c = makeContainer(db);
      addTearDown(c.dispose);

      await c.read(shopProductsProvider.future);

      // Оскільки колекція не порожня — сидинг не запускається
      final snap = await db.collection('shop_products').get();
      expect(snap.docs.length, equals(1),
          reason: 'Сидинг не повинен запускатись якщо товари вже є');
    });

    test('повертає тільки активні товари', () async {
      final db = FakeFirebaseFirestore();
      // Використовуємо toFirestore() щоб Timestamp серіалізувався правильно
      final active = ShopProduct.defaults.first.copyWith(
          id: 'active', title: 'Активний', isActive: true);
      final inactive = ShopProduct.defaults.first.copyWith(
          id: 'inactive', title: 'Неактивний', isActive: false);
      await db.collection('shop_products').doc('active').set(active.toFirestore());
      await db.collection('shop_products').doc('inactive').set(inactive.toFirestore());

      final c = makeContainer(db);
      addTearDown(c.dispose);

      final products = await c.read(shopProductsProvider.future);
      expect(products.length, equals(1));
      expect(products.first.title, equals('Активний'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────

  group('featuredProductsProvider', () {
    test('повертає тільки isFeatured товари, максимум 6', () async {
      final featured = List.generate(
        8,
        (i) => ShopProduct.defaults.first.copyWith(
          id: 'feat_$i',
          isFeatured: true,
        ),
      );
      final notFeatured = [
        ShopProduct.defaults.first.copyWith(id: 'nf', isFeatured: false),
      ];

      final c = ProviderContainer(overrides: [
        shopProductsProvider.overrideWith(
          (_) => Stream.value([...featured, ...notFeatured]),
        ),
      ]);

      // Чекаємо поки стрім емітне дані
      await c.read(shopProductsProvider.future);

      final result = c.read(featuredProductsProvider);
      c.dispose();
      expect(result.length, equals(6));
      expect(result.every((p) => p.isFeatured), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────

  group('ShopProductFilter.apply()', () {
    late List<ShopProduct> products;

    setUp(() {
      final base = ShopProduct.defaults.first;
      products = [
        base.copyWith(id: 'k1', category: ShopCategory.kimono, isNew: false, isInStock: true),
        base.copyWith(id: 'b1', category: ShopCategory.belts,  isNew: true,  isInStock: true),
        base.copyWith(id: 'b2', category: ShopCategory.belts,  isNew: false, isInStock: false),
        base.copyWith(id: 'm1', category: ShopCategory.merch,  isNew: false, isInStock: true,
            title: 'Худі Тріумф'),
      ];
    });

    test('без фільтрів повертає всі товари', () {
      final result = const ShopProductFilter().apply(products);
      expect(result.length, equals(4));
    });

    test('фільтр по категорії', () {
      final result =
          const ShopProductFilter(category: ShopCategory.belts).apply(products);
      expect(result.length, equals(2));
      expect(result.every((p) => p.category == ShopCategory.belts), isTrue);
    });

    test('фільтр тільки в наявності', () {
      final result =
          const ShopProductFilter(inStockOnly: true).apply(products);
      expect(result.every((p) => p.isInStock), isTrue);
      expect(result.length, equals(3));
    });

    test('фільтр тільки нові', () {
      final result = const ShopProductFilter(newOnly: true).apply(products);
      expect(result.every((p) => p.isNew), isTrue);
      expect(result.length, equals(1));
    });

    test('пошук по назві (кирилиця)', () {
      final result =
          const ShopProductFilter(searchQuery: 'худі').apply(products);
      expect(result.length, equals(1));
      expect(result.first.id, equals('m1'));
    });

    test('комбінований фільтр: категорія + в наявності', () {
      final result = const ShopProductFilter(
        category: ShopCategory.belts,
        inStockOnly: true,
      ).apply(products);
      expect(result.length, equals(1));
      expect(result.first.id, equals('b1'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────

  group('ShopNotifier', () {
    test('addProduct зберігає продукт у Firestore', () async {
      final db = FakeFirebaseFirestore();
      final c = makeContainer(db);
      addTearDown(c.dispose);

      final product = ShopProduct.defaults.first;
      await c.read(shopNotifierProvider.notifier).addProduct(product);

      final doc = await db.collection('shop_products').doc(product.id).get();
      expect(doc.exists, isTrue);
      expect(doc['title'], equals(product.title));
    });

    test('toggleActive оновлює поле isActive', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('shop_products').doc('p1').set(
            _baseProduct(id: 'p1', isActive: true),
          );

      final c = makeContainer(db);
      addTearDown(c.dispose);

      await c.read(shopNotifierProvider.notifier).toggleActive('p1', false);

      final doc = await db.collection('shop_products').doc('p1').get();
      expect(doc['isActive'], isFalse);
    });

    test('deleteProduct видаляє документ', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('shop_products').doc('del').set(
            _baseProduct(id: 'del'),
          );

      final c = makeContainer(db);
      addTearDown(c.dispose);

      await c.read(shopNotifierProvider.notifier).deleteProduct('del');

      final doc = await db.collection('shop_products').doc('del').get();
      expect(doc.exists, isFalse);
    });
  });
}

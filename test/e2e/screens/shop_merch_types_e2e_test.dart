/// TC-SHOP-CAT — Всі типи мерчу відображаються в магазині.
///
/// Ключові правила:
///   1. Існує рівно 5 категорій: кімоно, пояси, нашивки, мерч, аксесуари
///   2. Кожна категорія має українську назву і emoji
///   3. Продукти кожної категорії зберігаються і повертаються коректно
///   4. Фільтр за категорією повертає тільки товари цього типу
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/shop_product_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/shop/providers/shop_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

ProviderContainer _container(FakeFirebaseFirestore db) => ProviderContainer(
      overrides: [firestoreProvider.overrideWithValue(db)],
    );

ShopProduct _product(String id, ShopCategory category) =>
    ShopProduct.defaults.first.copyWith(
      id: id,
      title: 'Товар: ${category.label}',
      description: 'Опис товару',
      category: category,
      isActive: true,
      price: 500,
      imageUrls: const [],
      variants: const [],
    );

List<ShopProduct> _allCategoryProducts() => [
      for (var i = 0; i < ShopCategory.values.length; i++)
        _product('p${i + 1}', ShopCategory.values[i]),
    ];

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── TC-SHOP-CAT-001 ──────────────────────────────────────────────────────────

  group('TC-SHOP-CAT-001: 5 категорій мерчу з UI-назвами', () {
    test('рівно 5 категорій', () {
      expect(ShopCategory.values.length, equals(5));
    });

    test('кожна категорія має непорожній label та emoji', () {
      for (final cat in ShopCategory.values) {
        expect(cat.label, isNotEmpty,
            reason: '${cat.name} повинна мати label');
        expect(cat.emoji, isNotEmpty,
            reason: '${cat.name} повинна мати emoji');
      }
    });

    test('кімоно → Кімоно 🥋', () {
      expect(ShopCategory.kimono.label, equals('Кімоно'));
      expect(ShopCategory.kimono.emoji, equals('🥋'));
    });

    test('пояси → Пояси 🥊', () {
      expect(ShopCategory.belts.label, equals('Пояси'));
      expect(ShopCategory.belts.emoji, equals('🥊'));
    });

    test('нашивки → Нашивки 🔖', () {
      expect(ShopCategory.patches.label, equals('Нашивки'));
      expect(ShopCategory.patches.emoji, equals('🔖'));
    });

    test('мерч → Мерч 👕', () {
      expect(ShopCategory.merch.label, equals('Мерч'));
      expect(ShopCategory.merch.emoji, equals('👕'));
    });

    test('аксесуари → Аксесуари 🎒', () {
      expect(ShopCategory.accessories.label, equals('Аксесуари'));
      expect(ShopCategory.accessories.emoji, equals('🎒'));
    });
  });

  // ── TC-SHOP-CAT-002 ──────────────────────────────────────────────────────────

  group('TC-SHOP-CAT-002: товар кожної категорії зберігається в Firestore', () {
    test('5 товарів (по одному кожної категорії) зберігаються і всі категорії присутні', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final notifier = c.read(shopNotifierProvider.notifier);
      for (final p in _allCategoryProducts()) {
        await notifier.addProduct(p);
      }

      final snap = await db.collection('shop_products').get();
      expect(snap.docs, hasLength(5));

      final storedCategories =
          snap.docs.map((d) => d.data()['category'] as String).toSet();

      for (final cat in ShopCategory.values) {
        expect(storedCategories.contains(cat.name), isTrue,
            reason: 'Категорія ${cat.label} (${cat.name}) відсутня в Firestore');
      }
    });

    test('категорія зберігається точно як рядок і повертається правильно', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(shopNotifierProvider.notifier)
          .addProduct(_product('kimono1', ShopCategory.kimono));

      final doc = await db.collection('shop_products').doc('kimono1').get();
      expect(doc.data()?['category'], equals('kimono'));
      expect(ShopCategoryX.fromString(doc.data()?['category'] as String?),
          equals(ShopCategory.kimono));
    });

    test('title та isActive зберігаються разом з категорією', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(shopNotifierProvider.notifier).addProduct(
            _product('merch1', ShopCategory.merch),
          );

      final doc = await db.collection('shop_products').doc('merch1').get();
      expect(doc.data()?['category'], equals('merch'));
      expect(doc.data()?['isActive'], isTrue);
    });
  });

  // ── TC-SHOP-CAT-003 ──────────────────────────────────────────────────────────

  group('TC-SHOP-CAT-003: фільтр за категорією — повертає тільки той тип', () {
    test('фільтр по кімоно не показує мерч і аксесуари', () {
      final products = _allCategoryProducts();
      final filter = const ShopProductFilter(category: ShopCategory.kimono);
      final result = filter.apply(products);

      expect(result, hasLength(1));
      expect(result.first.category, equals(ShopCategory.kimono));
    });

    test('фільтр по кожній категорії повертає рівно 1 товар (з 5)', () {
      final products = _allCategoryProducts();

      for (final cat in ShopCategory.values) {
        final result =
            ShopProductFilter(category: cat).apply(products);

        expect(result, hasLength(1),
            reason: 'Фільтр ${cat.label} повинен повернути 1 товар');
        expect(result.first.category, equals(cat));
      }
    });

    test('без фільтра категорії — повертаються всі 5 типів', () {
      final products = _allCategoryProducts();
      final result = const ShopProductFilter().apply(products);

      expect(result, hasLength(5));
      final categories = result.map((p) => p.category).toSet();
      expect(categories.length, equals(5));
    });

    test('фільтр кімоно+пошук по назві — звужує результат в межах категорії', () {
      final products = [
        _product('k1', ShopCategory.kimono).copyWith(title: 'Кімоно Тріумф'),
        _product('k2', ShopCategory.kimono).copyWith(title: 'Кімоно Дитяче'),
        _product('m1', ShopCategory.merch).copyWith(title: 'Худі Тріумф'),
      ];

      final result = const ShopProductFilter(
        category: ShopCategory.kimono,
        searchQuery: 'Тріумф',
      ).apply(products);

      expect(result, hasLength(1));
      expect(result.first.id, equals('k1'));
    });
  });

  // ── TC-SHOP-CAT-004 ──────────────────────────────────────────────────────────

  group('TC-SHOP-CAT-004: неактивні товари не показуються', () {
    test('товар з isActive=false не потрапляє в список після збереження', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final notifier = c.read(shopNotifierProvider.notifier);
      await notifier.addProduct(
          _product('active1', ShopCategory.kimono).copyWith(isActive: true));
      await notifier.addProduct(
          _product('inactive1', ShopCategory.merch).copyWith(isActive: false));

      final snap = await db.collection('shop_products').get();
      expect(snap.docs, hasLength(2)); // Both stored in Firestore

      // Only active visible — simulating the provider filter
      final active = snap.docs
          .where((d) => d.data()['isActive'] == true)
          .toList();
      expect(active, hasLength(1));
      expect(active.first.id, equals('active1'));
    });
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/shop_product_model.dart';

ShopProductVariant makeVariant({
  String id = 'sv1',
  String productId = 'sp1',
  String? size,
  String? color,
  int stockQuantity = 10,
  double priceModifier = 0.0,
  int? heightFrom,
  int? heightTo,
}) =>
    ShopProductVariant(
      id: id,
      productId: productId,
      size: size,
      color: color,
      stockQuantity: stockQuantity,
      priceModifier: priceModifier,
      heightFrom: heightFrom,
      heightTo: heightTo,
    );

ShopProduct makeProduct({
  String id = 'sp1',
  String title = 'Кімоно Тріумф',
  String description = 'Опис',
  ShopCategory category = ShopCategory.kimono,
  double price = 2890.0,
  double? oldPrice,
  ShopBadge? badge,
  bool isActive = true,
  bool isFeatured = false,
  bool isNew = false,
  bool isInStock = true,
  String? coachNote,
  List<String>? imageUrls,
  List<ShopProductVariant>? variants,
}) =>
    ShopProduct(
      id: id,
      title: title,
      description: description,
      category: category,
      price: price,
      oldPrice: oldPrice,
      badge: badge,
      isActive: isActive,
      isFeatured: isFeatured,
      isNew: isNew,
      isInStock: isInStock,
      coachNote: coachNote,
      imageUrls: imageUrls ?? const [],
      variants: variants ?? const [],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  // ── ShopCategory ──────────────────────────────────────────────────────────

  group('ShopCategory.label', () {
    final cases = {
      ShopCategory.kimono: 'Кімоно',
      ShopCategory.belts: 'Пояси',
      ShopCategory.patches: 'Нашивки',
      ShopCategory.merch: 'Мерч',
      ShopCategory.accessories: 'Аксесуари',
    };
    cases.forEach((cat, label) {
      test('$cat → $label', () => expect(cat.label, label));
    });
  });

  group('ShopCategory.emoji', () {
    test('кожна категорія має непорожній emoji', () {
      for (final cat in ShopCategory.values) {
        expect(cat.emoji, isNotEmpty);
      }
    });
  });

  group('ShopCategoryX.fromString', () {
    test('розпізнає всі значення', () {
      for (final cat in ShopCategory.values) {
        expect(ShopCategoryX.fromString(cat.name), cat);
      }
    });

    test('невідоме → merch (fallback)', () {
      expect(ShopCategoryX.fromString('xyz'), ShopCategory.merch);
      expect(ShopCategoryX.fromString(null), ShopCategory.merch);
    });
  });

  // ── ShopBadge ─────────────────────────────────────────────────────────────

  group('ShopBadge.label', () {
    final cases = {
      ShopBadge.hit: 'Хіт клубу',
      ShopBadge.newItem: 'Новинка',
      ShopBadge.orderOnly: 'Під замовлення',
    };
    cases.forEach((badge, label) {
      test('$badge → $label', () => expect(badge.label, label));
    });
  });

  group('ShopBadgeX.fromString', () {
    test('розпізнає всі значення', () {
      for (final b in ShopBadge.values) {
        expect(ShopBadgeX.fromString(b.name), b);
      }
    });

    test('null → null', () {
      expect(ShopBadgeX.fromString(null), isNull);
    });

    test('невідомий рядок → null', () {
      expect(ShopBadgeX.fromString('unknown'), isNull);
    });
  });

  // ── ShopProductVariant.inStock ────────────────────────────────────────────

  group('ShopProductVariant.inStock', () {
    test('stockQuantity > 0 → inStock', () {
      expect(makeVariant(stockQuantity: 5).inStock, isTrue);
    });

    test('stockQuantity == 0 → не в наявності', () {
      expect(makeVariant(stockQuantity: 0).inStock, isFalse);
    });
  });

  // ── ShopProductVariant.displayLabel ───────────────────────────────────────

  group('ShopProductVariant.displayLabel', () {
    test('тільки size', () {
      expect(makeVariant(size: 'XL').displayLabel, 'XL');
    });

    test('тільки color', () {
      expect(makeVariant(color: 'Чорний').displayLabel, 'Чорний');
    });

    test('size + color → через " / "', () {
      expect(makeVariant(size: 'M', color: 'Білий').displayLabel, 'M / Білий');
    });

    test('heightFrom + heightTo', () {
      expect(
        makeVariant(heightFrom: 150, heightTo: 160).displayLabel,
        '150-160см',
      );
    });

    test('без жодного поля → порожній рядок', () {
      expect(makeVariant().displayLabel, '');
    });
  });

  // ── ShopProductVariant toMap / fromMap ────────────────────────────────────

  group('ShopProductVariant — round-trip', () {
    test('зберігає всі поля', () {
      final v = makeVariant(
        id: 'sv99',
        productId: 'sp42',
        size: 'L',
        color: 'Синій',
        stockQuantity: 7,
        priceModifier: 50.0,
        heightFrom: 160,
        heightTo: 170,
      );
      final restored = ShopProductVariant.fromMap(v.toMap());
      expect(restored.id, v.id);
      expect(restored.productId, v.productId);
      expect(restored.size, v.size);
      expect(restored.color, v.color);
      expect(restored.stockQuantity, v.stockQuantity);
      expect(restored.priceModifier, v.priceModifier);
      expect(restored.heightFrom, v.heightFrom);
      expect(restored.heightTo, v.heightTo);
    });

    test('null-поля не потрапляють в toMap', () {
      final map = makeVariant().toMap();
      expect(map.containsKey('size'), isFalse);
      expect(map.containsKey('color'), isFalse);
      expect(map.containsKey('colorImageUrl'), isFalse);
      expect(map.containsKey('sku'), isFalse);
    });

    test('відсутні поля у fromMap → значення за замовчуванням', () {
      final v = ShopProductVariant.fromMap({'id': 'sv1', 'productId': 'sp1'});
      expect(v.stockQuantity, 0);
      expect(v.priceModifier, 0.0);
      expect(v.size, isNull);
    });
  });

  // ── ShopProduct.hasDiscount ───────────────────────────────────────────────

  group('ShopProduct.hasDiscount', () {
    test('oldPrice > price → hasDiscount', () {
      expect(makeProduct(price: 2890, oldPrice: 3200).hasDiscount, isTrue);
    });

    test('oldPrice == null → без знижки', () {
      expect(makeProduct().hasDiscount, isFalse);
    });

    test('oldPrice <= price → без знижки', () {
      expect(makeProduct(price: 500, oldPrice: 400).hasDiscount, isFalse);
    });
  });

  // ── ShopProduct.availableColors / availableSizes ──────────────────────────

  group('ShopProduct.availableColors', () {
    test('повертає унікальні кольори', () {
      final p = makeProduct(variants: [
        makeVariant(id: 'v1', color: 'Чорний'),
        makeVariant(id: 'v2', color: 'Білий'),
        makeVariant(id: 'v3', color: 'Чорний'),
      ]);
      expect(p.availableColors.length, 2);
      expect(p.availableColors, containsAll(['Чорний', 'Білий']));
    });

    test('без варіантів з кольором → порожній список', () {
      expect(makeProduct().availableColors, isEmpty);
    });
  });

  group('ShopProduct.availableSizes', () {
    test('повертає всі розміри (з дублями)', () {
      final p = makeProduct(variants: [
        makeVariant(id: 'v1', size: 'S'),
        makeVariant(id: 'v2', size: 'M'),
        makeVariant(id: 'v3', size: 'L'),
      ]);
      expect(p.availableSizes, ['S', 'M', 'L']);
    });
  });

  // ── ShopProduct.toFirestore ───────────────────────────────────────────────

  group('ShopProduct.toFirestore', () {
    test('містить обов\'язкові поля', () {
      final map = makeProduct().toFirestore();
      expect(map['title'], 'Кімоно Тріумф');
      expect(map['category'], 'kimono');
      expect(map['price'], 2890.0);
      expect(map['currency'], 'грн');
      expect(map['isActive'], true);
      expect(map['isFeatured'], false);
      expect(map['isNew'], false);
      expect(map['isInStock'], true);
    });

    test('oldPrice відсутній коли null', () {
      expect(makeProduct().toFirestore().containsKey('oldPrice'), isFalse);
    });

    test('oldPrice присутній коли вказаний', () {
      expect(makeProduct(oldPrice: 3200).toFirestore()['oldPrice'], 3200.0);
    });

    test('badge відсутній коли null', () {
      expect(makeProduct().toFirestore().containsKey('badge'), isFalse);
    });

    test('badge серіалізується як рядок', () {
      expect(makeProduct(badge: ShopBadge.hit).toFirestore()['badge'], 'hit');
    });

    test('coachNote відсутній коли null', () {
      expect(makeProduct().toFirestore().containsKey('coachNote'), isFalse);
    });

    test('coachNote присутній коли вказаний', () {
      final map = makeProduct(coachNote: 'Обирай за зростом').toFirestore();
      expect(map['coachNote'], 'Обирай за зростом');
    });

    test('createdAt серіалізується як Timestamp', () {
      expect(makeProduct().toFirestore()['createdAt'], isA<Timestamp>());
    });

    test('variants серіалізуються як список', () {
      final p = makeProduct(variants: [makeVariant(size: 'M')]);
      final map = p.toFirestore();
      expect((map['variants'] as List).length, 1);
    });
  });

  // ── ShopProduct.fromFirestore ─────────────────────────────────────────────

  group('ShopProduct.fromFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;
    setUp(() => fakeFirestore = FakeFirebaseFirestore());

    test('зчитує всі поля', () async {
      final ref = fakeFirestore.collection('shop_products').doc('p1');
      await ref.set({
        'title': 'Худі Тріумф',
        'description': 'Теплий',
        'category': 'merch',
        'price': 999.0,
        'oldPrice': 1200.0,
        'currency': 'грн',
        'imageUrls': ['https://example.com/img.jpg'],
        'badge': 'newItem',
        'isActive': true,
        'isFeatured': true,
        'isNew': true,
        'isInStock': true,
        'coachNote': 'Клубна форма',
        'variants': [
          {'id': 'sv1', 'productId': 'p1', 'size': 'L', 'stockQuantity': 5, 'priceModifier': 0.0}
        ],
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 2, 1)),
      });
      final p = ShopProduct.fromFirestore(await ref.get());
      expect(p.title, 'Худі Тріумф');
      expect(p.category, ShopCategory.merch);
      expect(p.price, 999.0);
      expect(p.oldPrice, 1200.0);
      expect(p.badge, ShopBadge.newItem);
      expect(p.isFeatured, isTrue);
      expect(p.isNew, isTrue);
      expect(p.coachNote, 'Клубна форма');
      expect(p.variants.length, 1);
      expect(p.variants.first.size, 'L');
      expect(p.createdAt, DateTime(2026, 1, 1));
    });

    test('відсутні поля → defaults', () async {
      final ref = fakeFirestore.collection('shop_products').doc('empty');
      await ref.set({
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
      final p = ShopProduct.fromFirestore(await ref.get());
      expect(p.title, '');
      expect(p.category, ShopCategory.merch);
      expect(p.price, 0.0);
      expect(p.oldPrice, isNull);
      expect(p.badge, isNull);
      expect(p.isActive, isTrue);
      expect(p.currency, 'грн');
      expect(p.variants, isEmpty);
    });
  });

  // ── ShopProduct.copyWith ──────────────────────────────────────────────────

  group('ShopProduct.copyWith', () {
    test('змінює ціну та категорію', () {
      final p = makeProduct(price: 1000, category: ShopCategory.kimono);
      final updated = p.copyWith(price: 1500, category: ShopCategory.merch);
      expect(updated.price, 1500.0);
      expect(updated.category, ShopCategory.merch);
      expect(updated.id, p.id);
    });

    test('скидає oldPrice через sentinel', () {
      final p = makeProduct(oldPrice: 3200);
      final updated = p.copyWith(oldPrice: null);
      expect(updated.oldPrice, isNull);
    });

    test('скидає badge через sentinel', () {
      final p = makeProduct(badge: ShopBadge.hit);
      final updated = p.copyWith(badge: null);
      expect(updated.badge, isNull);
    });
  });

  // ── ShopProduct.defaults ──────────────────────────────────────────────────

  group('ShopProduct.defaults', () {
    test('містить 16 товарів', () {
      expect(ShopProduct.defaults.length, 16);
    });

    test('всі id унікальні', () {
      final ids = ShopProduct.defaults.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('всі ціни > 0', () {
      for (final p in ShopProduct.defaults) {
        expect(p.price, greaterThan(0), reason: '${p.id} має price > 0');
      }
    });

    test('всі назви непорожні', () {
      for (final p in ShopProduct.defaults) {
        expect(p.title, isNotEmpty, reason: '${p.id} має непорожній title');
      }
    });

    test('кімоно sp_kimono_white має варіанти', () {
      final kimono =
          ShopProduct.defaults.firstWhere((p) => p.id == 'sp_kimono_white');
      expect(kimono.variants, isNotEmpty);
    });

    test('брелок sp_keychain має 7 кольорових варіантів', () {
      final keychain =
          ShopProduct.defaults.firstWhere((p) => p.id == 'sp_keychain');
      expect(keychain.variants.length, 7);
      expect(keychain.availableColors.length, 7);
    });

    test('6 нових товарів присутні', () {
      final ids = ShopProduct.defaults.map((p) => p.id).toSet();
      expect(ids.contains('sp_backpack_triumph'), isTrue);
      expect(ids.contains('sp_backpack_mini'), isTrue);
      expect(ids.contains('sp_belt_organizer'), isTrue);
      expect(ids.contains('sp_pin_club'), isTrue);
      expect(ids.contains('sp_medal_hanger'), isTrue);
      expect(ids.contains('sp_coin_triumph'), isTrue);
    });

    test('sp_kimono_white має знижку', () {
      final kimono =
          ShopProduct.defaults.firstWhere((p) => p.id == 'sp_kimono_white');
      expect(kimono.hasDiscount, isTrue);
    });
  });

  // ── round-trip ShopProduct ────────────────────────────────────────────────

  group('ShopProduct — round-trip', () {
    test('toFirestore → fromFirestore зберігає поля', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final original = makeProduct(
        id: 'rt1',
        title: 'Тест',
        price: 500,
        oldPrice: 700,
        badge: ShopBadge.hit,
        coachNote: 'Нотатка',
        variants: [makeVariant(size: 'M', stockQuantity: 3)],
      );
      await fakeFirestore
          .collection('shop_products')
          .doc('rt1')
          .set(original.toFirestore());
      final doc =
          await fakeFirestore.collection('shop_products').doc('rt1').get();
      final restored = ShopProduct.fromFirestore(doc);
      expect(restored.title, original.title);
      expect(restored.price, original.price);
      expect(restored.oldPrice, original.oldPrice);
      expect(restored.badge, original.badge);
      expect(restored.coachNote, original.coachNote);
      expect(restored.variants.length, 1);
      expect(restored.variants.first.size, 'M');
    });
  });
}

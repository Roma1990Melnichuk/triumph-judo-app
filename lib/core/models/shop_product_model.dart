import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show Color;

enum ShopCategory { kimono, belts, patches, merch, accessories }

extension ShopCategoryX on ShopCategory {
  String get label => switch (this) {
        ShopCategory.kimono => 'Кімоно',
        ShopCategory.belts => 'Пояси',
        ShopCategory.patches => 'Нашивки',
        ShopCategory.merch => 'Мерч',
        ShopCategory.accessories => 'Аксесуари',
      };

  String get emoji => switch (this) {
        ShopCategory.kimono => '🥋',
        ShopCategory.belts => '🥊',
        ShopCategory.patches => '🔖',
        ShopCategory.merch => '👕',
        ShopCategory.accessories => '🎒',
      };

  static ShopCategory fromString(String? s) => ShopCategory.values.firstWhere(
        (e) => e.name == s,
        orElse: () => ShopCategory.merch,
      );
}

enum ShopBadge { hit, newItem, orderOnly }

extension ShopBadgeX on ShopBadge {
  String get label => switch (this) {
        ShopBadge.hit => 'Хіт клубу',
        ShopBadge.newItem => 'Новинка',
        ShopBadge.orderOnly => 'Під замовлення',
      };

  Color get color => switch (this) {
        ShopBadge.hit => const Color(0xFFD50000),
        ShopBadge.newItem => const Color(0xFF63D728),
        ShopBadge.orderOnly => const Color(0xFFFF8A00),
      };

  static ShopBadge? fromString(String? s) => s == null
      ? null
      : ShopBadge.values
          .cast<ShopBadge?>()
          .firstWhere((e) => e?.name == s, orElse: () => null);
}

class ShopProductVariant {
  final String id;
  final String productId;
  final String? size;
  final String? color;
  final String? colorImageUrl;
  final int? heightFrom;
  final int? heightTo;
  final double? weightFrom;
  final double? weightTo;
  final int stockQuantity;
  final String? sku;
  final double priceModifier;

  const ShopProductVariant({
    required this.id,
    required this.productId,
    this.size,
    this.color,
    this.colorImageUrl,
    this.heightFrom,
    this.heightTo,
    this.weightFrom,
    this.weightTo,
    this.stockQuantity = 0,
    this.sku,
    this.priceModifier = 0.0,
  });

  factory ShopProductVariant.fromMap(Map<String, dynamic> m) {
    return ShopProductVariant(
      id: m['id'] as String? ?? '',
      productId: m['productId'] as String? ?? '',
      size: m['size'] as String?,
      color: m['color'] as String?,
      colorImageUrl: m['colorImageUrl'] as String?,
      heightFrom: m['heightFrom'] as int?,
      heightTo: m['heightTo'] as int?,
      weightFrom: (m['weightFrom'] as num?)?.toDouble(),
      weightTo: (m['weightTo'] as num?)?.toDouble(),
      stockQuantity: m['stockQuantity'] as int? ?? 0,
      sku: m['sku'] as String?,
      priceModifier: (m['priceModifier'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'productId': productId,
        if (size != null) 'size': size,
        if (color != null) 'color': color,
        if (colorImageUrl != null) 'colorImageUrl': colorImageUrl,
        if (heightFrom != null) 'heightFrom': heightFrom,
        if (heightTo != null) 'heightTo': heightTo,
        if (weightFrom != null) 'weightFrom': weightFrom,
        if (weightTo != null) 'weightTo': weightTo,
        'stockQuantity': stockQuantity,
        if (sku != null) 'sku': sku,
        'priceModifier': priceModifier,
      };

  bool get inStock => stockQuantity > 0;

  String get displayLabel {
    final parts = <String>[];
    if (size != null) parts.add(size!);
    if (color != null) parts.add(color!);
    if (heightFrom != null) parts.add('$heightFrom-${heightTo}см');
    return parts.join(' / ');
  }
}

class ShopProduct {
  final String id;
  final String title;
  final String description;
  final ShopCategory category;
  final double price;
  final double? oldPrice;
  final String currency;
  final List<String> imageUrls;
  final ShopBadge? badge;
  final bool isActive;
  final bool isFeatured;
  final bool isNew;
  final bool isInStock;
  final String? coachNote;
  final List<ShopProductVariant> variants;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShopProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    this.oldPrice,
    this.currency = 'грн',
    this.imageUrls = const [],
    this.badge,
    this.isActive = true,
    this.isFeatured = false,
    this.isNew = false,
    this.isInStock = true,
    this.coachNote,
    this.variants = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShopProduct.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final variantsList = (d['variants'] as List<dynamic>? ?? [])
        .map((v) => ShopProductVariant.fromMap(v as Map<String, dynamic>))
        .toList();
    return ShopProduct(
      id: doc.id,
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      category: ShopCategoryX.fromString(d['category'] as String?),
      price: (d['price'] as num?)?.toDouble() ?? 0.0,
      oldPrice: (d['oldPrice'] as num?)?.toDouble(),
      currency: d['currency'] as String? ?? 'грн',
      imageUrls: List<String>.from(d['imageUrls'] as List<dynamic>? ?? []),
      badge: ShopBadgeX.fromString(d['badge'] as String?),
      isActive: d['isActive'] as bool? ?? true,
      isFeatured: d['isFeatured'] as bool? ?? false,
      isNew: d['isNew'] as bool? ?? false,
      isInStock: d['isInStock'] as bool? ?? true,
      coachNote: d['coachNote'] as String?,
      variants: variantsList,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'category': category.name,
        'price': price,
        if (oldPrice != null) 'oldPrice': oldPrice,
        'currency': currency,
        'imageUrls': imageUrls,
        if (badge != null) 'badge': badge!.name,
        'isActive': isActive,
        'isFeatured': isFeatured,
        'isNew': isNew,
        'isInStock': isInStock,
        if (coachNote != null) 'coachNote': coachNote,
        'variants': variants.map((v) => v.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  ShopProduct copyWith({
    String? id,
    String? title,
    String? description,
    ShopCategory? category,
    double? price,
    Object? oldPrice = _sentinel,
    String? currency,
    List<String>? imageUrls,
    Object? badge = _sentinel,
    bool? isActive,
    bool? isFeatured,
    bool? isNew,
    bool? isInStock,
    Object? coachNote = _sentinel,
    List<ShopProductVariant>? variants,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ShopProduct(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        price: price ?? this.price,
        oldPrice: oldPrice == _sentinel ? this.oldPrice : oldPrice as double?,
        currency: currency ?? this.currency,
        imageUrls: imageUrls ?? this.imageUrls,
        badge: badge == _sentinel ? this.badge : badge as ShopBadge?,
        isActive: isActive ?? this.isActive,
        isFeatured: isFeatured ?? this.isFeatured,
        isNew: isNew ?? this.isNew,
        isInStock: isInStock ?? this.isInStock,
        coachNote: coachNote == _sentinel ? this.coachNote : coachNote as String?,
        variants: variants ?? this.variants,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  List<String> get availableColors =>
      variants.where((v) => v.color != null).map((v) => v.color!).toSet().toList();

  List<String> get availableSizes =>
      variants.where((v) => v.size != null).map((v) => v.size!).toList();

  double get effectivePrice => price;

  bool get hasDiscount => oldPrice != null && oldPrice! > price;

  static List<ShopProduct> get defaults => [
        ShopProduct(
          id: 'sp_kimono_white',
          title: 'Кімоно Тріумф Competition 2.0',
          description:
              'Офіційне кімоно клубу Тріумф для тренувань і змагань. Щільна бавовняна тканина 750 г/м². Клубна нашивка вже вшита.',
          category: ShopCategory.kimono,
          price: 2890,
          oldPrice: 3200,
          currency: 'грн',
          imageUrls: ['assets/shop/kimono_white.png'],
          badge: ShopBadge.hit,
          isActive: true,
          isFeatured: true,
          isNew: false,
          isInStock: true,
          coachNote:
              'Рекомендую для всіх починаючи з жовтого пояса. Офіційне кімоно IJF.',
          variants: [
            ShopProductVariant(
                id: 'sv_k_130',
                productId: 'sp_kimono_white',
                size: '130',
                heightFrom: 120,
                heightTo: 130,
                weightFrom: 25,
                weightTo: 35,
                stockQuantity: 5),
            ShopProductVariant(
                id: 'sv_k_140',
                productId: 'sp_kimono_white',
                size: '140',
                heightFrom: 130,
                heightTo: 140,
                weightFrom: 30,
                weightTo: 40,
                stockQuantity: 8),
            ShopProductVariant(
                id: 'sv_k_150',
                productId: 'sp_kimono_white',
                size: '150',
                heightFrom: 140,
                heightTo: 150,
                weightFrom: 40,
                weightTo: 50,
                stockQuantity: 6),
            ShopProductVariant(
                id: 'sv_k_160',
                productId: 'sp_kimono_white',
                size: '160',
                heightFrom: 150,
                heightTo: 165,
                weightFrom: 50,
                weightTo: 65,
                stockQuantity: 4),
            ShopProductVariant(
                id: 'sv_k_170',
                productId: 'sp_kimono_white',
                size: '170',
                heightFrom: 163,
                heightTo: 173,
                weightFrom: 60,
                weightTo: 75,
                stockQuantity: 3),
            ShopProductVariant(
                id: 'sv_k_180',
                productId: 'sp_kimono_white',
                size: '180',
                heightFrom: 173,
                heightTo: 183,
                weightFrom: 70,
                weightTo: 90,
                stockQuantity: 2),
          ],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        ShopProduct(
          id: 'sp_hoodie_black',
          title: 'Худі Тріумф Judo Club',
          description:
              'Офіційне худі клубу. Тепле флісове підкладення, вишита клубна нашивка на рукаві.',
          category: ShopCategory.merch,
          price: 890,
          currency: 'грн',
          imageUrls: ['assets/shop/hoodie_black.png'],
          badge: ShopBadge.newItem,
          isActive: true,
          isFeatured: true,
          isNew: true,
          isInStock: true,
          variants: [
            ShopProductVariant(
                id: 'sv_h_s',
                productId: 'sp_hoodie_black',
                size: 'S',
                stockQuantity: 10,
                color: 'Чорний'),
            ShopProductVariant(
                id: 'sv_h_m',
                productId: 'sp_hoodie_black',
                size: 'M',
                stockQuantity: 15,
                color: 'Чорний'),
            ShopProductVariant(
                id: 'sv_h_l',
                productId: 'sp_hoodie_black',
                size: 'L',
                stockQuantity: 12,
                color: 'Чорний'),
            ShopProductVariant(
                id: 'sv_h_xl',
                productId: 'sp_hoodie_black',
                size: 'XL',
                stockQuantity: 8,
                color: 'Чорний'),
            ShopProductVariant(
                id: 'sv_h_xxl',
                productId: 'sp_hoodie_black',
                size: 'XXL',
                stockQuantity: 5,
                color: 'Чорний'),
          ],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        ShopProduct(
          id: 'sp_cap',
          title: 'Кепка Тріумф Judo Club',
          description:
              'Класична бейсболка з вишитою емблемою клубу. Регульований ремінець.',
          category: ShopCategory.merch,
          price: 450,
          currency: 'грн',
          imageUrls: ['assets/shop/cap_black.png'],
          isActive: true,
          isFeatured: false,
          isNew: true,
          isInStock: true,
          variants: [
            ShopProductVariant(
                id: 'sv_cap_sm',
                productId: 'sp_cap',
                size: 'S/M',
                stockQuantity: 20),
            ShopProductVariant(
                id: 'sv_cap_ml',
                productId: 'sp_cap',
                size: 'M/L',
                stockQuantity: 20),
            ShopProductVariant(
                id: 'sv_cap_xl',
                productId: 'sp_cap',
                size: 'L/XL',
                stockQuantity: 15),
          ],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        ShopProduct(
          id: 'sp_bag_sports',
          title: 'Спортивна сумка Тріумф',
          description:
              'Велика спортивна сумка для екіпіровки. Основний відсік + бічні кишені. Вишита клубна емблема.',
          category: ShopCategory.accessories,
          price: 1290,
          currency: 'грн',
          imageUrls: ['assets/shop/bag_sports.png'],
          badge: ShopBadge.hit,
          isActive: true,
          isFeatured: true,
          isNew: false,
          isInStock: true,
          variants: [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        ShopProduct(
          id: 'sp_backpack',
          title: 'Рюкзак-мішок Тріумф',
          description: 'Зручний рюкзак-мішок для тренувань. Легкий, місткий.',
          category: ShopCategory.accessories,
          price: 380,
          currency: 'грн',
          imageUrls: ['assets/shop/backpack_drawstring.png'],
          isActive: true,
          isFeatured: false,
          isNew: false,
          isInStock: true,
          variants: [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        ShopProduct(
          id: 'sp_shaker',
          title: 'Шейкер Тріумф 700мл',
          description:
              'Спортивний шейкер із фіксованою кришкою і клубним лого. BPA free.',
          category: ShopCategory.accessories,
          price: 320,
          currency: 'грн',
          imageUrls: ['assets/shop/shaker_black.png'],
          isActive: true,
          isFeatured: false,
          isNew: false,
          isInStock: true,
          variants: [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        ShopProduct(
          id: 'sp_protein',
          title: 'Протеїн Тріумф Whey 900г',
          description:
              '24 г протеїну на порцію. Смак шоколад. Вітаміни та мінерали. Виготовлено під брендом клубу.',
          category: ShopCategory.accessories,
          price: 990,
          currency: 'грн',
          imageUrls: ['assets/shop/protein_whey.png'],
          isActive: true,
          isFeatured: false,
          isNew: true,
          isInStock: true,
          variants: [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        ShopProduct(
          id: 'sp_patch_chest',
          title: 'Нашивка на груди Тріумф Ø9 см',
          description:
              'Вишита кругла нашивка для розміщення на лівій частині грудей кімоно. Для міжнародних змагань (IJF, EJU).',
          category: ShopCategory.patches,
          price: 180,
          currency: 'грн',
          imageUrls: ['assets/shop/patch_chest.png'],
          isActive: true,
          isFeatured: false,
          isNew: false,
          isInStock: true,
          variants: [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        ShopProduct(
          id: 'sp_patch_back',
          title: 'Нашивка на спину 28×32 см',
          description:
              'Велика нашивка "TRIUMPH JUDO CLUB / KYIV • UKRAINE". Преміальна вишивка, довговічне кріплення.',
          category: ShopCategory.patches,
          price: 390,
          currency: 'грн',
          imageUrls: ['assets/shop/patch_back.png'],
          isActive: true,
          isFeatured: false,
          isNew: false,
          isInStock: true,
          variants: [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        ShopProduct(
          id: 'sp_keychain',
          title: 'Брелок-пояс Тріумф',
          description:
              'Мініатюрний пояс дзюдо з вишитою нашивкою клубу. Металеве кільце. Ідеальний подарунок спортсмену. 7 кольорів.',
          category: ShopCategory.accessories,
          price: 150,
          currency: 'грн',
          imageUrls: ['assets/shop/keychain_belt.png'],
          isActive: true,
          isFeatured: true,
          isNew: false,
          isInStock: true,
          variants: [
            ShopProductVariant(
                id: 'sv_kc_white',
                productId: 'sp_keychain',
                color: 'Білий',
                stockQuantity: 20),
            ShopProductVariant(
                id: 'sv_kc_yellow',
                productId: 'sp_keychain',
                color: 'Жовтий',
                stockQuantity: 20),
            ShopProductVariant(
                id: 'sv_kc_orange',
                productId: 'sp_keychain',
                color: 'Помаранчевий',
                stockQuantity: 20),
            ShopProductVariant(
                id: 'sv_kc_green',
                productId: 'sp_keychain',
                color: 'Зелений',
                stockQuantity: 20),
            ShopProductVariant(
                id: 'sv_kc_blue',
                productId: 'sp_keychain',
                color: 'Синій',
                stockQuantity: 20),
            ShopProductVariant(
                id: 'sv_kc_brown',
                productId: 'sp_keychain',
                color: 'Коричневий',
                stockQuantity: 20),
            ShopProductVariant(
                id: 'sv_kc_black',
                productId: 'sp_keychain',
                color: 'Чорний',
                stockQuantity: 20),
          ],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        ShopProduct(
          id: 'sp_backpack_triumph',
          title: 'Рюкзак Тріумф з відділенням для ноутбука',
          description:
              'Місткий рюкзак 48×32×20 см з окремим відділенням для ноутбука до 15.6". Клубна символіка Тріумф. Міцна тканина 600D.',
          price: 1290,
          category: ShopCategory.merch,
          badge: ShopBadge.newItem,
          imageUrls: const ['assets/shop/backpack_triumph.png'],
          variants: [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        ShopProduct(
          id: 'sp_backpack_mini',
          title: 'Рюкзак-сітка Тріумф компакт',
          description:
              'Легкий складний рюкзак-сітка для швидких виходів. Поміщається в кишеню. Навантаження до 10 кг.',
          price: 349,
          category: ShopCategory.merch,
          imageUrls: const ['assets/shop/backpack_laptop.png'],
          variants: [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        ShopProduct(
          id: 'sp_belt_organizer',
          title: 'Органайзер для поясів Тріумф',
          description:
              'Настінний тримач 90×40 см для зберігання та демонстрації поясів дзюдо. Матеріал: дерево + фетр. Місткість: 12 поясів.',
          price: 890,
          category: ShopCategory.accessories,
          imageUrls: const ['assets/shop/belt_organizer.png'],
          variants: [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        ShopProduct(
          id: 'sp_pin_club',
          title: 'Значок клубу Тріумф',
          description:
              'Металевий значок Ø25 мм з логотипом клубу. Золота емаль, застібка-метелик. Ідеальний аксесуар на форму або сумку.',
          price: 129,
          category: ShopCategory.accessories,
          imageUrls: const ['assets/shop/pin_club.png'],
          variants: [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        ShopProduct(
          id: 'sp_medal_hanger',
          title: 'Медальниця Тріумф',
          description:
              'Дерев\'яна медальниця з гравіюванням логотипу клубу. Розмір 60×15 см. Кріплення для 10 медалей.',
          price: 650,
          category: ShopCategory.accessories,
          badge: ShopBadge.hit,
          imageUrls: const ['assets/shop/medal_hanger.png'],
          variants: [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        ShopProduct(
          id: 'sp_coin_triumph',
          title: 'Монета Тріумф (сувенірна)',
          description:
              'Сувенірна монета Ø40 мм з рельєфним зображенням клубного символу. Матеріал: цинк+мідне покриття. У подарунковому пакованні.',
          price: 199,
          category: ShopCategory.accessories,
          imageUrls: const ['assets/shop/coin_triumph.png'],
          variants: [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];
}

const Object _sentinel = Object();

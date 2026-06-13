class CartItem {
  final String id;
  final String productId;
  final String? variantId;
  final int quantity;
  final double priceSnapshot;
  final String title;
  final String? imageUrl;
  final String? size;
  final String? color;

  const CartItem({
    required this.id,
    required this.productId,
    this.variantId,
    required this.quantity,
    required this.priceSnapshot,
    required this.title,
    this.imageUrl,
    this.size,
    this.color,
  });

  factory CartItem.fromMap(Map<String, dynamic> m) {
    return CartItem(
      id: m['id'] as String,
      productId: m['productId'] as String,
      variantId: m['variantId'] as String?,
      quantity: (m['quantity'] as num).toInt(),
      priceSnapshot: (m['priceSnapshot'] as num).toDouble(),
      title: m['title'] as String,
      imageUrl: m['imageUrl'] as String?,
      size: m['size'] as String?,
      color: m['color'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'variantId': variantId,
      'quantity': quantity,
      'priceSnapshot': priceSnapshot,
      'title': title,
      'imageUrl': imageUrl,
      'size': size,
      'color': color,
    };
  }

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      productId: productId,
      variantId: variantId,
      quantity: quantity ?? this.quantity,
      priceSnapshot: priceSnapshot,
      title: title,
      imageUrl: imageUrl,
      size: size,
      color: color,
    );
  }

  double get subtotal => priceSnapshot * quantity;
}

class CartModel {
  final String userId;
  final List<CartItem> items;
  final String? promoCode;
  final double discount;

  const CartModel({
    required this.userId,
    this.items = const [],
    this.promoCode,
    this.discount = 0.0,
  });

  factory CartModel.fromMap(String userId, Map<String, dynamic> m) {
    final rawItems = m['items'];
    final List<CartItem> items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(CartItem.fromMap)
            .toList()
        : [];

    return CartModel(
      userId: userId,
      items: items,
      promoCode: m['promoCode'] as String?,
      discount: (m['discount'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((e) => e.toMap()).toList(),
      'promoCode': promoCode,
      'discount': discount,
    };
  }

  CartModel copyWith({
    List<CartItem>? items,
    String? promoCode,
    double? discount,
  }) {
    return CartModel(
      userId: userId,
      items: items ?? this.items,
      promoCode: promoCode ?? this.promoCode,
      discount: discount ?? this.discount,
    );
  }

  double get subtotal => items.fold(0.0, (a, b) => a + b.subtotal);
  double get total => (subtotal - discount).clamp(0.0, double.infinity);
  int get itemCount => items.fold(0, (a, b) => a + b.quantity);
  bool get isEmpty => items.isEmpty;
}

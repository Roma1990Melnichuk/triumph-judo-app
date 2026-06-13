import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show Color;

enum ShopOrderStatus { newOrder, confirmed, preparing, waitingAtClub, transferredToCoach, delivering, completed, cancelled }

extension ShopOrderStatusX on ShopOrderStatus {
  String get label => switch (this) {
        ShopOrderStatus.newOrder => 'Нове замовлення',
        ShopOrderStatus.confirmed => 'Підтверджено',
        ShopOrderStatus.preparing => 'Готується',
        ShopOrderStatus.waitingAtClub => 'Очікує в клубі',
        ShopOrderStatus.transferredToCoach => 'Передано тренеру',
        ShopOrderStatus.delivering => 'Доставляється',
        ShopOrderStatus.completed => 'Завершено',
        ShopOrderStatus.cancelled => 'Скасовано',
      };

  Color get color => switch (this) {
        ShopOrderStatus.newOrder => const Color(0xFFFF8A00),
        ShopOrderStatus.confirmed => const Color(0xFF1565C0),
        ShopOrderStatus.preparing => const Color(0xFFFF8A00),
        ShopOrderStatus.waitingAtClub => const Color(0xFFFFD21A),
        ShopOrderStatus.transferredToCoach => const Color(0xFFFFD21A),
        ShopOrderStatus.delivering => const Color(0xFF1565C0),
        ShopOrderStatus.completed => const Color(0xFF2E7D32),
        ShopOrderStatus.cancelled => const Color(0xFFD50000),
      };

  bool get isFinal => this == ShopOrderStatus.completed || this == ShopOrderStatus.cancelled;

  bool get isActive => !isFinal;

  static ShopOrderStatus fromString(String? s) => ShopOrderStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => ShopOrderStatus.newOrder,
      );

  ShopOrderStatus? get nextStatus => switch (this) {
        ShopOrderStatus.newOrder => ShopOrderStatus.confirmed,
        ShopOrderStatus.confirmed => ShopOrderStatus.preparing,
        ShopOrderStatus.preparing => ShopOrderStatus.waitingAtClub,
        ShopOrderStatus.waitingAtClub => ShopOrderStatus.completed,
        ShopOrderStatus.transferredToCoach => ShopOrderStatus.completed,
        ShopOrderStatus.delivering => ShopOrderStatus.completed,
        ShopOrderStatus.completed => null,
        ShopOrderStatus.cancelled => null,
      };
}

enum ShopDeliveryMethod { pickupAtClub, fromCoach, novaPost }

extension ShopDeliveryMethodX on ShopDeliveryMethod {
  String get label => switch (this) {
        ShopDeliveryMethod.pickupAtClub => 'Забрати в клубі',
        ShopDeliveryMethod.fromCoach => 'Отримати у тренера',
        ShopDeliveryMethod.novaPost => 'Доставка Новою Поштою',
      };

  static ShopDeliveryMethod fromString(String? s) => ShopDeliveryMethod.values.firstWhere(
        (e) => e.name == s,
        orElse: () => ShopDeliveryMethod.pickupAtClub,
      );
}

enum ShopPaymentMethod { online, cashAtClub, cardTransfer }

extension ShopPaymentMethodX on ShopPaymentMethod {
  String get label => switch (this) {
        ShopPaymentMethod.online => 'Онлайн',
        ShopPaymentMethod.cashAtClub => 'Готівка в клубі',
        ShopPaymentMethod.cardTransfer => 'Переказ на картку',
      };

  static ShopPaymentMethod fromString(String? s) => ShopPaymentMethod.values.firstWhere(
        (e) => e.name == s,
        orElse: () => ShopPaymentMethod.cashAtClub,
      );
}

class ShopOrderItem {
  final String productId;
  final String productTitle;
  final String? variantId;
  final String? size;
  final String? color;
  final int quantity;
  final double priceSnapshot;
  final String? imageUrl;

  const ShopOrderItem({
    required this.productId,
    required this.productTitle,
    this.variantId,
    this.size,
    this.color,
    required this.quantity,
    required this.priceSnapshot,
    this.imageUrl,
  });

  factory ShopOrderItem.fromMap(Map<String, dynamic> m) => ShopOrderItem(
        productId: m['productId'] as String,
        productTitle: m['productTitle'] as String,
        variantId: m['variantId'] as String?,
        size: m['size'] as String?,
        color: m['color'] as String?,
        quantity: (m['quantity'] as num).toInt(),
        priceSnapshot: (m['priceSnapshot'] as num).toDouble(),
        imageUrl: m['imageUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productTitle': productTitle,
        if (variantId != null) 'variantId': variantId,
        if (size != null) 'size': size,
        if (color != null) 'color': color,
        'quantity': quantity,
        'priceSnapshot': priceSnapshot,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

  double get subtotal => priceSnapshot * quantity;
}

class ShopOrder {
  final String id;
  final String userId;
  final String orderNumber;
  final ShopOrderStatus status;
  final List<ShopOrderItem> items;
  final double totalAmount;
  final String currency;
  final ShopDeliveryMethod deliveryMethod;
  final ShopPaymentMethod paymentMethod;
  final String recipientName;
  final String recipientPhone;
  final String comment;
  final String? adminComment;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShopOrder({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.status,
    required this.items,
    required this.totalAmount,
    required this.currency,
    required this.deliveryMethod,
    required this.paymentMethod,
    required this.recipientName,
    required this.recipientPhone,
    required this.comment,
    this.adminComment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShopOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShopOrder(
      id: doc.id,
      userId: data['userId'] as String,
      orderNumber: data['orderNumber'] as String,
      status: ShopOrderStatusX.fromString(data['status'] as String?),
      items: (data['items'] as List<dynamic>)
          .map((e) => ShopOrderItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      totalAmount: (data['totalAmount'] as num).toDouble(),
      currency: data['currency'] as String? ?? 'UAH',
      deliveryMethod: ShopDeliveryMethodX.fromString(data['deliveryMethod'] as String?),
      paymentMethod: ShopPaymentMethodX.fromString(data['paymentMethod'] as String?),
      recipientName: data['recipientName'] as String? ?? '',
      recipientPhone: data['recipientPhone'] as String? ?? '',
      comment: data['comment'] as String? ?? '',
      adminComment: data['adminComment'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'orderNumber': orderNumber,
        'status': status.name,
        'items': items.map((e) => e.toMap()).toList(),
        'totalAmount': totalAmount,
        'currency': currency,
        'deliveryMethod': deliveryMethod.name,
        'paymentMethod': paymentMethod.name,
        'recipientName': recipientName,
        'recipientPhone': recipientPhone,
        'comment': comment,
        if (adminComment != null) 'adminComment': adminComment,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  ShopOrder copyWith({ShopOrderStatus? status, String? adminComment}) => ShopOrder(
        id: id,
        userId: userId,
        orderNumber: orderNumber,
        status: status ?? this.status,
        items: items,
        totalAmount: totalAmount,
        currency: currency,
        deliveryMethod: deliveryMethod,
        paymentMethod: paymentMethod,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        comment: comment,
        adminComment: adminComment ?? this.adminComment,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  int get itemCount => items.fold(0, (a, b) => a + b.quantity);
}

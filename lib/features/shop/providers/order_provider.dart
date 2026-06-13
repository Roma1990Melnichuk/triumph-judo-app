import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:judo_app/core/models/cart_model.dart';
import 'package:judo_app/core/models/shop_order_model.dart';

final myOrdersProvider = StreamProvider<List<ShopOrder>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('shop_orders')
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ShopOrder.fromFirestore).toList());
});

final allOrdersProvider = StreamProvider<List<ShopOrder>>((ref) {
  return FirebaseFirestore.instance
      .collection('shop_orders')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(ShopOrder.fromFirestore).toList());
});

final shopOrderProvider = StreamProvider.family<ShopOrder?, String>((ref, orderId) {
  return FirebaseFirestore.instance
      .collection('shop_orders')
      .doc(orderId)
      .snapshots()
      .map((doc) => doc.exists ? ShopOrder.fromFirestore(doc) : null);
});

class OrderNotifier extends StateNotifier<AsyncValue<void>> {
  OrderNotifier() : super(const AsyncValue.data(null));

  Future<String> createOrder({
    required List<CartItem> items,
    required double totalAmount,
    required ShopDeliveryMethod delivery,
    required ShopPaymentMethod payment,
    required String recipientName,
    required String recipientPhone,
    String comment = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      final now = DateTime.now();
      final rng = Random();
      final hexChars = List.generate(4, (_) => rng.nextInt(16).toRadixString(16).toUpperCase()).join();
      final datePart = '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}';
      final orderNumber = 'T-$datePart-$hexChars';

      final orderId = const Uuid().v4();

      final orderItems = items
          .map((c) => ShopOrderItem(
                productId: c.productId,
                productTitle: c.title,
                variantId: c.variantId,
                size: c.size,
                color: c.color,
                quantity: c.quantity,
                priceSnapshot: c.priceSnapshot,
                imageUrl: c.imageUrl,
              ))
          .toList();

      final order = ShopOrder(
        id: orderId,
        userId: uid,
        orderNumber: orderNumber,
        status: ShopOrderStatus.newOrder,
        items: orderItems,
        totalAmount: totalAmount,
        currency: 'UAH',
        deliveryMethod: delivery,
        paymentMethod: payment,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        comment: comment,
        createdAt: now,
        updatedAt: now,
      );

      await FirebaseFirestore.instance
          .collection('shop_orders')
          .doc(orderId)
          .set(order.toFirestore());

      state = const AsyncValue.data(null);
      return orderId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateStatus(
    String orderId,
    ShopOrderStatus status, {
    String? adminComment,
  }) async {
    state = const AsyncValue.loading();
    try {
      final Map<String, dynamic> updates = {
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      if (adminComment != null) {
        updates['adminComment'] = adminComment;
      }
      await FirebaseFirestore.instance
          .collection('shop_orders')
          .doc(orderId)
          .update(updates);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    await updateStatus(orderId, ShopOrderStatus.cancelled);
  }
}

final orderNotifierProvider =
    StateNotifierProvider<OrderNotifier, AsyncValue<void>>(
  (_) => OrderNotifier(),
);

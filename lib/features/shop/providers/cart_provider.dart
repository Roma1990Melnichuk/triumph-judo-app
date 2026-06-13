import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:judo_app/core/models/cart_model.dart';

final cartStreamProvider = StreamProvider<CartModel>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    return Stream.value(CartModel(userId: ''));
  }
  return FirebaseFirestore.instance
      .collection('shop_carts')
      .doc(uid)
      .snapshots()
      .map((snap) {
    if (!snap.exists || snap.data() == null) {
      return CartModel(userId: uid);
    }
    return CartModel.fromMap(uid, snap.data()!);
  });
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartStreamProvider).asData?.value.itemCount ?? 0;
});

class CartNotifier extends StateNotifier<AsyncValue<void>> {
  CartNotifier() : super(const AsyncData(null));

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _cartRef() =>
      FirebaseFirestore.instance.collection('shop_carts').doc(_uid);

  Future<CartModel> _fetchCart() async {
    final uid = _uid;
    if (uid == null) return CartModel(userId: '');
    final snap = await _cartRef().get();
    if (!snap.exists || snap.data() == null) return CartModel(userId: uid);
    return CartModel.fromMap(uid, snap.data()!);
  }

  Future<void> _saveCart(CartModel cart) async {
    await _cartRef().set(cart.toMap());
  }

  Future<void> addItem(CartItem item) async {
    final uid = _uid;
    if (uid == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final cart = await _fetchCart();
      final existingIndex = cart.items.indexWhere(
        (e) => e.productId == item.productId && e.variantId == item.variantId,
      );
      List<CartItem> updated;
      if (existingIndex >= 0) {
        final existing = cart.items[existingIndex];
        updated = List<CartItem>.from(cart.items);
        updated[existingIndex] =
            existing.copyWith(quantity: existing.quantity + item.quantity);
      } else {
        updated = [...cart.items, item];
      }
      await _saveCart(cart.copyWith(items: updated));
    });
  }

  Future<void> removeItem(String itemId) async {
    final uid = _uid;
    if (uid == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final cart = await _fetchCart();
      final updated = cart.items.where((e) => e.id != itemId).toList();
      await _saveCart(cart.copyWith(items: updated));
    });
  }

  Future<void> updateQuantity(String itemId, int qty) async {
    final uid = _uid;
    if (uid == null) return;
    if (qty <= 0) {
      await removeItem(itemId);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final cart = await _fetchCart();
      final updated = cart.items.map((e) {
        if (e.id == itemId) return e.copyWith(quantity: qty);
        return e;
      }).toList();
      await _saveCart(cart.copyWith(items: updated));
    });
  }

  Future<void> clear() async {
    final uid = _uid;
    if (uid == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final cart = await _fetchCart();
      await _saveCart(cart.copyWith(items: []));
    });
  }

  Future<void> applyPromoCode(String code) async {
    final uid = _uid;
    if (uid == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final cart = await _fetchCart();
      if (code == 'TRIUMPH10') {
        final discount = cart.subtotal * 0.1;
        await _saveCart(CartModel(
          userId: cart.userId,
          items: cart.items,
          promoCode: code,
          discount: discount,
        ));
      } else {
        await _saveCart(CartModel(
          userId: cart.userId,
          items: cart.items,
          promoCode: null,
          discount: 0.0,
        ));
      }
    });
  }
}

final cartNotifierProvider =
    StateNotifierProvider<CartNotifier, AsyncValue<void>>(
  (ref) => CartNotifier(),
);

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:judo_app/core/models/shop_product_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/utils/stream_utils.dart';

final shopProductsProvider = StreamProvider<List<ShopProduct>>((ref) async* {
  final db = ref.watch(firestoreProvider);
  final col = db.collection('shop_products');

  try {
    final snap = await col.limit(1).get();
    if (snap.docs.isEmpty) {
      final batch = db.batch();
      for (final p in ShopProduct.defaults) {
        batch.set(col.doc(p.id), p.toFirestore());
      }
      await batch.commit();
    }
  } catch (_) {
    // Seeding failed (permission denied / offline) — stream starts anyway
  }

  yield* col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map(ShopProduct.fromFirestore).where((p) => p.isActive).toList())
      .fallbackOnError(const []);
});

final featuredProductsProvider = Provider<List<ShopProduct>>((ref) {
  final products = ref.watch(shopProductsProvider).valueOrNull ?? [];
  return products.where((p) => p.isFeatured).take(6).toList();
});

final newProductsProvider = Provider<List<ShopProduct>>((ref) {
  final products = ref.watch(shopProductsProvider).valueOrNull ?? [];
  return products.where((p) => p.isNew).take(6).toList();
});

final productsByCategoryProvider =
    Provider.family<List<ShopProduct>, ShopCategory>((ref, category) {
  final products = ref.watch(shopProductsProvider).valueOrNull ?? [];
  return products.where((p) => p.category == category).toList();
});

final shopProductProvider =
    StreamProvider.family<ShopProduct?, String>((ref, id) {
  final db = ref.watch(firestoreProvider);
  return db
      .collection('shop_products')
      .doc(id)
      .snapshots()
      .map((snap) => snap.exists ? ShopProduct.fromFirestore(snap) : null)
      .fallbackOnError(null);
});

class ShopProductFilter {
  final ShopCategory? category;
  final String? searchQuery;
  final String? size;
  final bool inStockOnly;
  final bool newOnly;

  const ShopProductFilter({
    this.category,
    this.searchQuery,
    this.size,
    this.inStockOnly = false,
    this.newOnly = false,
  });

  List<ShopProduct> apply(List<ShopProduct> products) {
    var result = products.toList();

    if (category != null) {
      result = result.where((p) => p.category == category).toList();
    }

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final q = searchQuery!.toLowerCase();
      result = result
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q))
          .toList();
    }

    if (size != null && size!.isNotEmpty) {
      result = result
          .where((p) =>
              p.variants.isEmpty ||
              p.variants.any((v) => v.size == size && v.inStock))
          .toList();
    }

    if (inStockOnly) {
      result = result.where((p) => p.isInStock).toList();
    }

    if (newOnly) {
      result = result.where((p) => p.isNew).toList();
    }

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return result;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopProductFilter &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          searchQuery == other.searchQuery &&
          size == other.size &&
          inStockOnly == other.inStockOnly &&
          newOnly == other.newOnly;

  @override
  int get hashCode =>
      Object.hash(category, searchQuery, size, inStockOnly, newOnly);
}

final shopFilteredProvider =
    Provider.family<List<ShopProduct>, ShopProductFilter>((ref, filter) {
  final products = ref.watch(shopProductsProvider).valueOrNull ?? [];
  return filter.apply(products);
});

class ShopNotifier extends StateNotifier<AsyncValue<void>> {
  ShopNotifier(this._db) : super(const AsyncData(null));

  final FirebaseFirestore _db;
  late final _col = _db.collection('shop_products');

  Future<void> addProduct(ShopProduct p) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _col.doc(p.id).set(p.toFirestore());
    });
  }

  Future<void> updateProduct(ShopProduct p) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _col.doc(p.id).update(p.toFirestore());
    });
  }

  Future<void> toggleActive(String id, bool isActive) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _col.doc(id).update({'isActive': isActive});
    });
  }

  Future<void> deleteProduct(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _col.doc(id).delete();
    });
  }
}

final shopNotifierProvider =
    StateNotifierProvider<ShopNotifier, AsyncValue<void>>(
  (ref) => ShopNotifier(ref.watch(firestoreProvider)),
);

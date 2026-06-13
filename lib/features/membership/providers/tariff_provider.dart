import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/tariff_plan.dart';
import '../models/promo_code.dart';

final tariffPlansProvider = StreamProvider<List<TariffPlan>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('club_settings')
      .doc('tariffs')
      .snapshots()
      .map((doc) {
    if (!doc.exists) return List<TariffPlan>.from(TariffPlan.defaults);
    final list = doc.data()?['plans'] as List<dynamic>? ?? [];
    if (list.isEmpty) return List<TariffPlan>.from(TariffPlan.defaults);
    return list
        .map((p) => TariffPlan.fromMap(p as Map<String, dynamic>))
        .toList();
  });
});

final promoCodesProvider = StreamProvider<List<PromoCode>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('club_settings')
      .doc('promo_codes')
      .snapshots()
      .map((doc) {
    if (!doc.exists) return <PromoCode>[];
    final list = doc.data()?['codes'] as List<dynamic>? ?? [];
    return list.map((c) => PromoCode.fromMap(c as Map<String, dynamic>)).toList();
  });
});

class TariffNotifier extends StateNotifier<AsyncValue<void>> {
  TariffNotifier(this._db) : super(const AsyncValue.data(null));
  final FirebaseFirestore _db;

  Future<void> savePlans(List<TariffPlan> plans) async {
    state = const AsyncValue.loading();
    try {
      await _db.collection('club_settings').doc('tariffs').set({
        'plans': plans.map((p) => p.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> savePromoCodes(List<PromoCode> codes) async {
    state = const AsyncValue.loading();
    try {
      await _db.collection('club_settings').doc('promo_codes').set({
        'codes': codes.map((c) => c.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  PromoCode? validateCode(String input, List<PromoCode> codes) {
    final normalized = input.toUpperCase().trim();
    try {
      return codes.firstWhere(
        (c) => c.code.toUpperCase() == normalized && c.isValid,
      );
    } catch (_) {
      return null;
    }
  }
}

final tariffNotifierProvider =
    StateNotifierProvider<TariffNotifier, AsyncValue<void>>((ref) {
  return TariffNotifier(ref.watch(firestoreProvider));
});

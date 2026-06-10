import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/tariff_plan.dart';

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

class TariffNotifier extends StateNotifier<AsyncValue<void>> {
  TariffNotifier(this._db) : super(const AsyncValue.data(null));
  final FirebaseFirestore _db;

  Future<void> savePlans(List<TariffPlan> plans) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db.collection('club_settings').doc('tariffs').set({
        'plans': plans.map((p) => p.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
    });
  }
}

final tariffNotifierProvider =
    StateNotifierProvider<TariffNotifier, AsyncValue<void>>((ref) {
  return TariffNotifier(ref.watch(firestoreProvider));
});

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/body_measurement_model.dart';

// ── Stream ────────────────────────────────────────────────────────────────────

final bodyMeasurementsProvider =
    StreamProvider.family<List<BodyMeasurementModel>, String>((ref, childId) {
  return FirebaseFirestore.instance
      .collection('body_measurements')
      .where('childId', isEqualTo: childId)
      .orderBy('measuredAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(BodyMeasurementModel.fromFirestore).toList());
});

// Last 12 measurements for chart
final recentMeasurementsProvider =
    Provider.family<List<BodyMeasurementModel>, String>((ref, childId) {
  final all = ref.watch(bodyMeasurementsProvider(childId)).asData?.value ?? [];
  return all.take(12).toList().reversed.toList();
});

// Latest measurement
final latestMeasurementProvider =
    Provider.family<BodyMeasurementModel?, String>((ref, childId) {
  final all = ref.watch(bodyMeasurementsProvider(childId)).asData?.value ?? [];
  return all.isEmpty ? null : all.first;
});

// ── Notifier ──────────────────────────────────────────────────────────────────

final bodyMeasurementNotifierProvider =
    StateNotifierProvider<BodyMeasurementNotifier, AsyncValue<void>>(
        (ref) => BodyMeasurementNotifier());

class BodyMeasurementNotifier extends StateNotifier<AsyncValue<void>> {
  BodyMeasurementNotifier() : super(const AsyncValue.data(null));

  final _col =
      FirebaseFirestore.instance.collection('body_measurements');

  Future<void> addMeasurement({
    required String childId,
    required DateTime date,
    double? weightKg,
    double? heightCm,
  }) async {
    if (weightKg == null && heightCm == null) return;
    state = const AsyncValue.loading();
    try {
      final ref = _col.doc();
      await ref.set(BodyMeasurementModel(
        id: ref.id, childId: childId, measuredAt: date,
        weightKg: weightKg, heightCm: heightCm,
      ).toFirestore());
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      rethrow;
    }
  }

  Future<void> deleteMeasurement(String id) async {
    await _col.doc(id).delete();
  }
}

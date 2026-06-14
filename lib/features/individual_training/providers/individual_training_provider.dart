import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/individual_slot_model.dart';
import '../../auth/providers/auth_provider.dart';

// ── FCM token storage ─────────────────────────────────────────────────────────
// Call this once after login to store the device token for push notifications.
Future<void> saveFcmToken(FirebaseFirestore db, String uid) async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await db.collection('users').doc(uid).update({'fcmToken': token});
    }
  } catch (_) {}
}

// ── Coach: all slots they created ────────────────────────────────────────────
final coachSlotsProvider =
    StreamProvider.family<List<IndividualSlotModel>, String>((ref, coachId) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('individual_slots')
      .where('coachId', isEqualTo: coachId)
      .snapshots()
      .map((s) {
        final list = s.docs.map(IndividualSlotModel.fromFirestore).toList();
        list.sort((a, b) => a.date.compareTo(b.date));
        return list;
      });
});

// ── Pending booking requests for coach ───────────────────────────────────────
final pendingBookingsCountProvider =
    Provider.family<int, String>((ref, coachId) {
  final slots = ref.watch(coachSlotsProvider(coachId)).asData?.value ?? [];
  return slots.where((s) => s.status == SlotStatus.requested).length;
});

// ── All available slots (for parents/athletes) ────────────────────────────────
final availableSlotsProvider =
    StreamProvider<List<IndividualSlotModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  final now = DateTime.now();
  final todayStart = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
  return ref
      .watch(firestoreProvider)
      .collection('individual_slots')
      .where('status', isEqualTo: SlotStatus.available.name)
      .where('date', isGreaterThanOrEqualTo: todayStart)
      .snapshots()
      .map((s) {
        final list = s.docs.map(IndividualSlotModel.fromFirestore).toList();
        list.sort((a, b) => a.date.compareTo(b.date));
        return list;
      });
});

// ── Booked / confirmed slots for a specific child ────────────────────────────
final childSlotsProvider =
    StreamProvider.family<List<IndividualSlotModel>, String>((ref, childId) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('individual_slots')
      .where('childId', isEqualTo: childId)
      .where('status', whereIn: [
        SlotStatus.requested.name,
        SlotStatus.confirmed.name,
      ])
      .snapshots()
      .map((s) {
        final list = s.docs.map(IndividualSlotModel.fromFirestore).toList();
        list.sort((a, b) => a.date.compareTo(b.date));
        return list;
      });
});

// ── Confirmed individual training count for a child ──────────────────────────
final childConfirmedTrainingCountProvider =
    Provider.family<int, String>((ref, childId) {
  return ref.watch(childSlotsProvider(childId)).maybeWhen(
    data: (slots) => slots.where((s) => s.status == SlotStatus.confirmed).length,
    orElse: () => 0,
  );
});

// ── CRUD notifier ─────────────────────────────────────────────────────────────
class IndividualTrainingNotifier extends StateNotifier<AsyncValue<void>> {
  IndividualTrainingNotifier(this._db) : super(const AsyncValue.data(null));

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  // Coach creates a slot
  Future<void> createSlot(IndividualSlotModel slot) async {
    state = const AsyncValue.loading();
    try {
      final id = _uuid.v4();
      await _db.collection('individual_slots').doc(id).set(
            IndividualSlotModel(
              id: id,
              coachId: slot.coachId,
              coachName: slot.coachName,
              date: slot.date,
              timeStart: slot.timeStart,
              timeEnd: slot.timeEnd,
              price: slot.price,
              currency: slot.currency,
              status: SlotStatus.available,
              isPaid: false,
            ).toFirestore(),
          );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // Parent/athlete requests a slot
  Future<void> requestSlot({
    required String slotId,
    required String childId,
    required String childName,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db.collection('individual_slots').doc(slotId).update({
        'status': SlotStatus.requested.name,
        'childId': childId,
        'childName': childName,
        'requestedByUserId': userId,
        'requestedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  // Coach approves
  Future<void> confirmSlot(String slotId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db.collection('individual_slots').doc(slotId).update({
        'status': SlotStatus.confirmed.name,
        'confirmedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  // Coach cancels
  Future<void> cancelSlot(String slotId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db.collection('individual_slots').doc(slotId).update({
        'status': SlotStatus.cancelled.name,
        'childId': null,
        'childName': null,
        'requestedByUserId': null,
        'requestedAt': null,
      });
    });
  }

  // Mark as paid (after parent confirms payment)
  Future<void> markPaid(String slotId) async {
    state = await AsyncValue.guard(() async {
      await _db.collection('individual_slots').doc(slotId).update({
        'isPaid': true,
      });
    });
  }

  // Coach deletes an available slot
  Future<void> deleteSlot(String slotId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db.collection('individual_slots').doc(slotId).delete();
    });
  }
}

final individualTrainingNotifierProvider =
    StateNotifierProvider<IndividualTrainingNotifier, AsyncValue<void>>((ref) {
  return IndividualTrainingNotifier(ref.watch(firestoreProvider));
});

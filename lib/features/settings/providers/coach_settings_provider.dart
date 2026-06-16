import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/payment_card_model.dart';
import '../../auth/providers/auth_provider.dart';

final coachSettingsNotifierProvider =
    StateNotifierProvider<CoachSettingsNotifier, AsyncValue<void>>((ref) {
  return CoachSettingsNotifier(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider).currentUser?.uid ?? '',
  );
});

class CoachSettingsNotifier extends StateNotifier<AsyncValue<void>> {
  CoachSettingsNotifier(this._db, this._uid)
      : super(const AsyncValue.data(null));

  final FirebaseFirestore _db;
  final String _uid;

  DocumentReference get _doc => _db.collection('users').doc(_uid);

  Future<void> updateIndividualPrice(double price) async {
    state = const AsyncValue.loading();
    try {
      await _doc.set({'individualPrice': price}, SetOptions(merge: true));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> addCard(PaymentCard card) async {
    state = const AsyncValue.loading();
    try {
      // Читаємо поточний список, щоб arrayUnion не дублював при merge
      final snap = await _doc.get();
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final existing = (data['paymentCards'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      existing.add(card.toMap());
      await _doc.set({'paymentCards': existing}, SetOptions(merge: true));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> removeCard(String cardId) async {
    state = const AsyncValue.loading();
    try {
      final snap = await _doc.get();
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final cards = (data['paymentCards'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .where((m) => m['id'] != cardId)
          .toList();
      await _doc.set({'paymentCards': cards}, SetOptions(merge: true));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Зберігає нову впорядковану послідовність карток (після перетягування).
  Future<void> reorderCards(List<PaymentCard> ordered) async {
    state = const AsyncValue.loading();
    try {
      await _doc.set(
        {'paymentCards': ordered.map((c) => c.toMap()).toList()},
        SetOptions(merge: true),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

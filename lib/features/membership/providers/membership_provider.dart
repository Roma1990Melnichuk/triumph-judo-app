import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/membership_model.dart';
import '../../auth/providers/auth_provider.dart';

// Single membership per athlete — Firestore doc ID = athleteId
final membershipByAthleteProvider =
    StreamProvider.family<MembershipModel?, String>((ref, athleteId) {
  final db = ref.watch(firestoreProvider);
  return db
      .collection('memberships')
      .doc(athleteId)
      .snapshots()
      .map((s) => s.exists && s.data() != null
          ? MembershipModel.fromMap(s.data()!, athleteId)
          : null);
});

// All memberships — for coach overview
final allMembershipsProvider = StreamProvider<List<MembershipModel>>((ref) {
  final db = ref.watch(firestoreProvider);
  return db.collection('memberships').snapshots().map((s) =>
      s.docs.map((d) => MembershipModel.fromMap(d.data(), d.id)).toList());
});

// athleteId → MembershipStatus map for team list indicators
final membershipStatusMapProvider =
    Provider<Map<String, MembershipStatus>>((ref) {
  final all = ref.watch(allMembershipsProvider).asData?.value ?? [];
  return {for (final m in all) m.athleteId: m.status};
});

// athleteId → endDate map for team list cards
final membershipEndDateMapProvider =
    Provider<Map<String, DateTime>>((ref) {
  final all = ref.watch(allMembershipsProvider).asData?.value ?? [];
  return {for (final m in all) m.athleteId: m.endDate};
});

// Counts for coach home overview card
final membershipSummaryProvider =
    Provider<({int active, int expiringSoon, int expired})>((ref) {
  final all = ref.watch(allMembershipsProvider).asData?.value ?? [];
  return (
    active: all.where((m) => m.status == MembershipStatus.active).length,
    expiringSoon: all.where((m) => m.isExpiringSoon).length,
    expired: all.where((m) => m.isExpired).length,
  );
});

// Current parent user's child membership
final myChildMembershipProvider = StreamProvider<MembershipModel?>((ref) {
  final user = ref.watch(currentUserModelProvider).asData?.value;
  if (user == null || user.isCoach) return Stream.value(null);
  final childId =
      user.childIds.isNotEmpty ? user.childIds.first : user.childId;
  if (childId == null) return Stream.value(null);
  final db = ref.watch(firestoreProvider);
  return db
      .collection('memberships')
      .doc(childId)
      .snapshots()
      .map((s) => s.exists && s.data() != null
          ? MembershipModel.fromMap(s.data()!, childId)
          : null);
});

// CRUD notifier
class MembershipNotifier extends StateNotifier<AsyncValue<void>> {
  MembershipNotifier(this._db) : super(const AsyncValue.data(null));

  final FirebaseFirestore _db;

  Future<void> setMembership({
    required String athleteId,
    required String planName,
    required DateTime startDate,
    required DateTime endDate,
    required double amount,
    int? totalSessions,
    String currency = 'UAH',
  }) async {
    state = const AsyncValue.loading();
    try {
      // FIN-01 Fix: Check for existing active membership to extend it
      final doc = await _db.collection('memberships').doc(athleteId).get();
      DateTime finalStart = startDate;
      DateTime finalEnd = endDate;

      int sessionsUsed = 0;
      if (doc.exists) {
        final existing = MembershipModel.fromMap(doc.data()!, athleteId);
        if (!existing.isExpired) {
          // Active plan: extend endDate by the new plan's duration
          final newPlanDuration = endDate.difference(startDate);
          finalStart = existing.startDate;
          finalEnd = existing.endDate.add(newPlanDuration);
          // D-09: preserve consumed sessions when extending a session-based plan
          if (existing.totalSessions != null) {
            sessionsUsed = existing.sessionsUsed;
          }
        }
      }

      // D-10: normalize endDate to end-of-day so expiry triggers at midnight, not 00:00
      finalEnd = DateTime(finalEnd.year, finalEnd.month, finalEnd.day, 23, 59, 59, 999);

      final data = <String, dynamic>{
        'athleteId': athleteId,
        'planName': planName,
        'startDate': Timestamp.fromDate(finalStart),
        'endDate': Timestamp.fromDate(finalEnd),
        'amount': amount,
        'currency': currency,
        'sessionsUsed': sessionsUsed,
      };
      if (totalSessions != null) data['totalSessions'] = totalSessions;

      await _db.collection('memberships').doc(athleteId).set(data);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final membershipNotifierProvider =
    StateNotifierProvider<MembershipNotifier, AsyncValue<void>>(
        (ref) => MembershipNotifier(ref.watch(firestoreProvider)));

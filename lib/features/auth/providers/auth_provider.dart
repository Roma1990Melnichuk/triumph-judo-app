import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final currentUserModelProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref
          .watch(firestoreProvider)
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

final allCoachesProvider = StreamProvider<List<UserModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .where('role', isEqualTo: 'coach')
      .snapshots()
      .map((snap) => snap.docs.map(UserModel.fromFirestore).toList())
      .handleError((_) {});
});

/// Returns the UserModel for a specific coach UID (derived from allCoachesProvider).
final coachByIdProvider = Provider.family<UserModel?, String>((ref, coachId) {
  final coaches = ref.watch(allCoachesProvider).asData?.value ?? [];
  return coaches.where((c) => c.uid == coachId).firstOrNull;
});

/// Returns parent/guardian users linked to a given child ID.
final parentsByChildIdProvider =
    StreamProvider.family<List<UserModel>, String>((ref, childId) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .where('childIds', arrayContains: childId)
      .snapshots()
      .map((snap) => snap.docs.map(UserModel.fromFirestore).toList())
      .handleError((_) {});
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._auth, this._firestore) : super(const AsyncValue.data(null));

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _auth.signInWithEmailAndPassword(email: email, password: password),
    );
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    String? childId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // First registered user becomes coach if no coaches exist yet
      final coachQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .limit(1)
          .get();
      final role = coachQuery.docs.isEmpty ? 'coach' : 'parent';

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = UserModel(
        uid: cred.user!.uid,
        email: email,
        name: name,
        role: role,
        childId: childId,
      );
      await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .set(user.toFirestore());
    });
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const AsyncValue.data(null);
  }

  Future<UserModel?> findUserByEmail(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return UserModel.fromFirestore(query.docs.first);
  }

  Future<void> promoteToCoach(String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update({'role': 'coach'});
  }

  Future<void> demoteToParent(String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update({'role': 'parent'});
  }

  Future<void> updateProfile({required String name, String? phone}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final data = <String, dynamic>{'name': name.trim()};
    final trimmedPhone = phone?.trim() ?? '';
    if (trimmedPhone.isNotEmpty) {
      data['phone'] = trimmedPhone;
    } else {
      data['phone'] = FieldValue.delete();
    }
    await _firestore.collection('users').doc(uid).update(data);
  }

  Future<void> linkChild(String userId, String childId) async {
    await _firestore.collection('users').doc(userId).update({
      'childIds': FieldValue.arrayUnion([childId]),
      'childId': childId, // legacy field — first linked child
    });
  }

  Future<void> unlinkChild(String userId, String childId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final current = (doc.data()?['childIds'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList();
    current.remove(childId);
    await _firestore.collection('users').doc(userId).update({
      'childIds': current,
      // Update legacy field to first remaining child, or delete it
      if (current.isNotEmpty) 'childId': current.first
      else 'childId': FieldValue.delete(),
    });
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

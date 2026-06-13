import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/message_model.dart';
import '../../auth/providers/auth_provider.dart';

final parentMessagesProvider =
    StreamProvider<List<ParentMessageModel>>((ref) {
  final user = ref.watch(currentUserModelProvider).asData?.value;
  if (user == null || !user.isCoach) return Stream.value([]);
  final db = ref.watch(firestoreProvider);
  return db
      .collection('messages')
      .where('toCoachId', isEqualTo: user.uid)
      .snapshots()
      .map((s) {
    final list = s.docs.map(ParentMessageModel.fromFirestore).toList();
    list.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return list;
  });
});

final unreadParentMessagesCountProvider = Provider<int>((ref) {
  final messages = ref.watch(parentMessagesProvider).asData?.value ?? [];
  return messages.where((m) => !m.readByCoach).length;
});

class MessageNotifier extends StateNotifier<AsyncValue<void>> {
  MessageNotifier(this._db) : super(const AsyncValue.data(null));

  final FirebaseFirestore _db;

  Future<void> send({
    required String fromParentId,
    required String fromParentName,
    required String toCoachId,
    required String body,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _db.collection('messages').add({
        'fromParentId': fromParentId,
        'fromParentName': fromParentName,
        'toCoachId': toCoachId,
        'body': body,
        'sentAt': FieldValue.serverTimestamp(),
        'readByCoach': false,
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> markRead(String messageId) async {
    await _db
        .collection('messages')
        .doc(messageId)
        .update({'readByCoach': true});
  }
}

final messageNotifierProvider =
    StateNotifierProvider<MessageNotifier, AsyncValue<void>>(
        (ref) => MessageNotifier(ref.watch(firestoreProvider)));

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/notification_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../team/providers/children_provider.dart';

final allNotificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('notifications')
      .orderBy('sentAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(NotificationModel.fromFirestore).toList());
});

/// Filters notifications relevant to the current parent/guardian's children.
final myNotificationsProvider =
    Provider<AsyncValue<List<NotificationModel>>>((ref) {
  final user = ref.watch(currentUserModelProvider).value;
  final children = ref.watch(allChildrenProvider).value ?? [];
  final notificationsAsync = ref.watch(allNotificationsProvider);

  if (user == null) return const AsyncValue.data([]);

  return notificationsAsync.whenData((notifications) {
    final myChildren = children.where((c) => user.ownsChild(c.id)).toList();

    return notifications.where((n) {
      switch (n.target) {
        case NotificationTarget.all:
          return true;
        case NotificationTarget.ageGroup:
          return myChildren
              .any((c) => n.targetValues.contains(c.birthYear.toString()));
        case NotificationTarget.belt:
          return myChildren
              .any((c) => n.targetValues.contains(c.currentBelt.name));
        case NotificationTarget.top20age:
          if (n.targetValues.isEmpty) return false;
          final year = int.tryParse(n.targetValues.first);
          if (year == null) return false;
          final yearChildren = children
              .where((c) => c.birthYear == year)
              .toList()
            ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
          final top20Ids =
              yearChildren.take(20).map((c) => c.id).toSet();
          return myChildren.any((c) => top20Ids.contains(c.id));
        case NotificationTarget.exceptTop20age:
          if (n.targetValues.isEmpty) return false;
          final year = int.tryParse(n.targetValues.first);
          if (year == null) return false;
          final yearChildren = children
              .where((c) => c.birthYear == year)
              .toList()
            ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
          final top20Ids =
              yearChildren.take(20).map((c) => c.id).toSet();
          return myChildren.any((c) => !top20Ids.contains(c.id) && c.birthYear == year);
        case NotificationTarget.personal:
          return myChildren.any((c) => n.targetValues.contains(c.id));
      }
    }).toList();
  });
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final user = ref.watch(currentUserModelProvider).value;
  if (user == null || user.isCoach) return 0;
  final notifs = ref.watch(myNotificationsProvider);
  return notifs.value
          ?.where((n) => !n.readByUserIds.contains(user.uid))
          .length ??
      0;
});

class NotificationsNotifier
    extends StateNotifier<AsyncValue<void>> {
  NotificationsNotifier(this._firestore)
      : super(const AsyncValue.data(null));

  final FirebaseFirestore _firestore;

  Future<void> send(NotificationModel notification) async {
    state = const AsyncValue.loading();
    try {
      await _firestore
          .collection('notifications')
          .add(notification.toFirestore());
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markRead(String notificationId, String uid) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'readByUserIds': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> delete(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }
}

final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, AsyncValue<void>>((ref) {
  return NotificationsNotifier(ref.watch(firestoreProvider));
});

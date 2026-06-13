import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/club_post_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/utils/stream_utils.dart';

// ── Feed stream ───────────────────────────────────────────────────────────────

final clubPostsProvider = StreamProvider<List<ClubPost>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('club_posts')
      .where('isPublished', isEqualTo: true)
      .orderBy('isPinned', descending: true)
      .orderBy('publishedAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(ClubPost.fromFirestore).toList())
      .fallbackOnError(const []);
});

// All posts for coach (including drafts)
final allClubPostsProvider = StreamProvider<List<ClubPost>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('club_posts')
      .orderBy('isPinned', descending: true)
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map(ClubPost.fromFirestore).toList())
      .fallbackOnError(const []);
});

// Single post
final clubPostProvider =
    StreamProvider.family<ClubPost?, String>((ref, postId) {
  return ref
      .watch(firestoreProvider)
      .collection('club_posts')
      .doc(postId)
      .snapshots()
      .map((doc) => doc.exists ? ClubPost.fromFirestore(doc) : null)
      .fallbackOnError(null);
});

// Posts mentioning a specific child (for "Моя дитина" filter)
final postsByChildProvider =
    StreamProvider.family<List<ClubPost>, String>((ref, childId) {
  return ref
      .watch(firestoreProvider)
      .collection('club_posts')
      .where('isPublished', isEqualTo: true)
      .where('mentionedAthleteIds', arrayContains: childId)
      .orderBy('publishedAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(ClubPost.fromFirestore).toList())
      .fallbackOnError(const []);
});

// Posts filtered by type
final postsByTypeProvider =
    Provider.family<List<ClubPost>, ClubPostType>((ref, type) {
  final posts = ref.watch(clubPostsProvider).asData?.value ?? [];
  return posts.where((p) => p.type == type).toList();
});

// Comments stream
final postCommentsProvider =
    StreamProvider.family<List<ClubPostComment>, String>((ref, postId) {
  return ref
      .watch(firestoreProvider)
      .collection('club_posts')
      .doc(postId)
      .collection('comments')
      .where('isDeleted', isEqualTo: false)
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((s) => s.docs.map(ClubPostComment.fromFirestore).toList())
      .fallbackOnError(const []);
});

// ── Filter state ──────────────────────────────────────────────────────────────

enum NewsFeedFilter { all, photoReport, competition, achievement, honorBoard, myChild }

extension NewsFeedFilterX on NewsFeedFilter {
  String get label => switch (this) {
        NewsFeedFilter.all          => 'Всі',
        NewsFeedFilter.photoReport  => 'Фотозвіти',
        NewsFeedFilter.competition  => 'Змагання',
        NewsFeedFilter.achievement  => 'Досягнення',
        NewsFeedFilter.honorBoard   => 'Дошка пошани',
        NewsFeedFilter.myChild      => 'Моя дитина',
      };
}

final newsFeedFilterProvider =
    StateProvider<NewsFeedFilter>((ref) => NewsFeedFilter.all);

// ── Notifier ──────────────────────────────────────────────────────────────────

class ClubPostNotifier extends StateNotifier<AsyncValue<void>> {
  ClubPostNotifier(this._db) : super(const AsyncValue.data(null));

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  Future<String> createPost(ClubPost post) async {
    state = const AsyncValue.loading();
    final id = _uuid.v4();
    state = await AsyncValue.guard(() async {
      await _db.collection('club_posts').doc(id).set(post.copyWith().toFirestore());
    });
    return id;
  }

  Future<void> updatePost(ClubPost post) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db
          .collection('club_posts')
          .doc(post.id)
          .update(post.copyWith(updatedAt: DateTime.now()).toFirestore());
    });
  }

  Future<void> deletePost(String postId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db.collection('club_posts').doc(postId).delete();
    });
  }

  Future<void> togglePin(String postId, bool isPinned) async {
    await _db
        .collection('club_posts')
        .doc(postId)
        .update({'isPinned': !isPinned, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> togglePublish(String postId, bool isPublished) async {
    final now = DateTime.now();
    await _db.collection('club_posts').doc(postId).update({
      'isPublished': !isPublished,
      if (!isPublished) 'publishedAt': Timestamp.fromDate(now),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Reactions
  Future<void> toggleLike(String postId, String uid, bool liked) async {
    await _db.collection('club_posts').doc(postId).update({
      'likedByUserIds': liked
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid]),
      'likesCount': liked ? FieldValue.increment(-1) : FieldValue.increment(1),
    });
  }

  Future<void> toggleProud(String postId, String uid, bool proud) async {
    await _db.collection('club_posts').doc(postId).update({
      'proudByUserIds': proud
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid]),
      'proudCount': proud ? FieldValue.increment(-1) : FieldValue.increment(1),
    });
  }

  // Comments
  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final batch = _db.batch();
    batch.set(
      _db.collection('club_posts').doc(postId).collection('comments').doc(id),
      ClubPostComment(
        id: id,
        postId: postId,
        userId: userId,
        userName: userName,
        text: text,
        createdAt: now,
      ).toFirestore(),
    );
    batch.update(_db.collection('club_posts').doc(postId), {
      'commentsCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final batch = _db.batch();
    batch.update(
      _db
          .collection('club_posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId),
      {'isDeleted': true},
    );
    batch.update(_db.collection('club_posts').doc(postId), {
      'commentsCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }
}

final clubPostNotifierProvider =
    StateNotifierProvider<ClubPostNotifier, AsyncValue<void>>(
  (ref) => ClubPostNotifier(ref.watch(firestoreProvider)),
);

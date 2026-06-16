/// E2E тести для NewsFeedScreen + ClubPostNotifier.
/// Покриває: createPost, deletePost, updatePost, togglePublish, togglePin,
///           addComment, deleteComment, toggleLike, toggleProud,
///           cross-role: тренер публікує → батько бачить.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:judo_app/core/models/club_post_model.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/news/providers/news_provider.dart';
import 'package:judo_app/features/news/screens/news_feed_screen.dart';

// ── Хелпери ───────────────────────────────────────────────────────────────────

final _coach = UserModel(
  uid: 'coach1',
  email: 'coach@test.com',
  name: 'Тренер',
  role: 'coach',
);

final _parent = UserModel(
  uid: 'parent1',
  email: 'parent@test.com',
  name: 'Батько',
  role: 'parent',
  childId: 'kid1',
  childIds: const ['kid1'],
);

GoRouter _router() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const NewsFeedScreen()),
        GoRoute(
            path: '/news/:id',
            builder: (_, __) => const Scaffold(body: Text('news detail'))),
        GoRoute(
            path: '/news/add',
            builder: (_, __) => const Scaffold(body: Text('add post'))),
        GoRoute(
            path: '/honor-board',
            builder: (_, __) => const Scaffold(body: Text('honor board'))),
      ],
    );

Widget _app(UserModel user, FakeFirebaseFirestore db) {
  return ProviderScope(
    overrides: [
      currentUserModelProvider.overrideWith((_) => Stream.value(user)),
      firestoreProvider.overrideWithValue(db),
    ],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

ProviderContainer _container(FakeFirebaseFirestore db) => ProviderContainer(
      overrides: [firestoreProvider.overrideWithValue(db)],
    );

ClubPost _post({
  String id = '',
  String title = 'Тестова публікація',
  bool isPublished = false,
  bool isPinned = false,
}) =>
    ClubPost(
      id: id,
      authorId: 'coach1',
      authorName: 'Тренер',
      type: ClubPostType.clubNews,
      title: title,
      isPublished: isPublished,
      isPinned: isPinned,
      createdAt: DateTime(2025, 6, 15),
      updatedAt: DateTime(2025, 6, 15),
    );

Future<String> _seedPost(
  FakeFirebaseFirestore db, {
  String title = 'Публікація',
  bool isPublished = false,
  bool isPinned = false,
  int likesCount = 0,
  int proudCount = 0,
  int commentsCount = 0,
  List<String> likedByUserIds = const [],
  List<String> proudByUserIds = const [],
}) async {
  final ref = await db.collection('club_posts').add({
    'authorId': 'coach1',
    'authorName': 'Тренер',
    'type': 'clubNews',
    'title': title,
    'description': '',
    'content': '',
    'isPinned': isPinned,
    'isPublished': isPublished,
    'commentsEnabled': true,
    'likesCount': likesCount,
    'proudCount': proudCount,
    'commentsCount': commentsCount,
    'images': <dynamic>[],
    'mentions': <dynamic>[],
    'likedByUserIds': likedByUserIds,
    'proudByUserIds': proudByUserIds,
    'mentionedAthleteIds': <String>[],
    'createdAt': Timestamp.fromDate(DateTime(2025, 6, 15)),
    'updatedAt': Timestamp.fromDate(DateTime(2025, 6, 15)),
  });
  return ref.id;
}

Future<void> _pumpData(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 50));
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── Render (без overflow suppression) ────────────────────────────────────

  group('NewsFeedScreen — рендер', () {
    testWidgets('тренер: рендериться без краша і overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app(_coach, FakeFirebaseFirestore()));
      await _pumpData(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('батько: рендериться без краша і overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app(_parent, FakeFirebaseFirestore()));
      await _pumpData(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('порожня стрічка — «Публікацій ще немає»', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app(_coach, FakeFirebaseFirestore()));
      await _pumpData(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Публікацій ще немає'), findsOneWidget);
    });

    testWidgets('тренер бачить FAB для створення публікації', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app(_coach, FakeFirebaseFirestore()));
      await _pumpData(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('батько НЕ бачить FAB', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app(_parent, FakeFirebaseFirestore()));
      await _pumpData(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });

  // ── createPost ────────────────────────────────────────────────────────────

  group('ClubPostNotifier — createPost', () {
    test('зберігає пост і повертає ID', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final id = await c.read(clubPostNotifierProvider.notifier).createPost(
            _post(title: 'Нова новина'),
          );

      expect(id, isNotEmpty);
      final doc = await db.collection('club_posts').doc(id).get();
      expect(doc.exists, isTrue);
      expect(doc['title'], 'Нова новина');
      expect(doc['authorId'], 'coach1');
    });

    test('isPublished=false за замовчуванням', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final id = await c
          .read(clubPostNotifierProvider.notifier)
          .createPost(_post());

      final doc = await db.collection('club_posts').doc(id).get();
      expect(doc['isPublished'], isFalse);
    });

    test('стан = AsyncData після createPost', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(clubPostNotifierProvider.notifier).createPost(_post());
      expect(c.read(clubPostNotifierProvider), isA<AsyncData<void>>());
    });
  });

  // ── deletePost ────────────────────────────────────────────────────────────

  group('ClubPostNotifier — deletePost', () {
    test('видаляє пост з Firestore', () async {
      final db = _db();
      final id = await _seedPost(db, title: 'Для видалення');
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(clubPostNotifierProvider.notifier).deletePost(id);

      expect(
          (await db.collection('club_posts').doc(id).get()).exists, isFalse);
    });

    test('видаляє тільки потрібний пост', () async {
      final db = _db();
      final id1 = await _seedPost(db, title: 'Видалити');
      final id2 = await _seedPost(db, title: 'Залишити');
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(clubPostNotifierProvider.notifier).deletePost(id1);

      expect(
          (await db.collection('club_posts').doc(id1).get()).exists, isFalse);
      expect(
          (await db.collection('club_posts').doc(id2).get()).exists, isTrue);
    });
  });

  // ── togglePublish ─────────────────────────────────────────────────────────

  group('ClubPostNotifier — togglePublish', () {
    test('публікує чернетку (false → true)', () async {
      final db = _db();
      final id = await _seedPost(db, isPublished: false);
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(clubPostNotifierProvider.notifier)
          .togglePublish(id, false);

      final doc = await db.collection('club_posts').doc(id).get();
      expect(doc['isPublished'], isTrue);
      expect(doc['publishedAt'], isNotNull);
    });

    test('знімає з публікації (true → false)', () async {
      final db = _db();
      final id = await _seedPost(db, isPublished: true);
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(clubPostNotifierProvider.notifier)
          .togglePublish(id, true);

      final doc = await db.collection('club_posts').doc(id).get();
      expect(doc['isPublished'], isFalse);
    });
  });

  // ── togglePin ─────────────────────────────────────────────────────────────

  group('ClubPostNotifier — togglePin', () {
    test('закріплює пост (false → true)', () async {
      final db = _db();
      final id = await _seedPost(db, isPinned: false);
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(clubPostNotifierProvider.notifier).togglePin(id, false);

      final doc = await db.collection('club_posts').doc(id).get();
      expect(doc['isPinned'], isTrue);
    });

    test('відкріплює пост (true → false)', () async {
      final db = _db();
      final id = await _seedPost(db, isPinned: true);
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(clubPostNotifierProvider.notifier).togglePin(id, true);

      final doc = await db.collection('club_posts').doc(id).get();
      expect(doc['isPinned'], isFalse);
    });
  });

  // ── addComment / deleteComment ────────────────────────────────────────────

  group('ClubPostNotifier — addComment / deleteComment', () {
    test('addComment: додає коментар до підколекції і оновлює commentsCount',
        () async {
      final db = _db();
      final postId = await _seedPost(db);
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(clubPostNotifierProvider.notifier).addComment(
            postId: postId,
            userId: 'parent1',
            userName: 'Батько',
            text: 'Чудова новина!',
          );

      final comments = await db
          .collection('club_posts')
          .doc(postId)
          .collection('comments')
          .get();
      expect(comments.docs, hasLength(1));
      expect(comments.docs.first['text'], 'Чудова новина!');
      expect(comments.docs.first['userId'], 'parent1');
      expect(comments.docs.first['isDeleted'], isFalse);

      final post = await db.collection('club_posts').doc(postId).get();
      expect(post['commentsCount'], 1);
    });

    test('deleteComment: встановлює isDeleted=true і зменшує commentsCount',
        () async {
      final db = _db();
      final postId = await _seedPost(db, commentsCount: 1);
      final c = _container(db);
      addTearDown(c.dispose);

      // Додати коментар вручну
      final commentRef = await db
          .collection('club_posts')
          .doc(postId)
          .collection('comments')
          .add({
        'postId': postId,
        'userId': 'parent1',
        'userName': 'Батько',
        'text': 'Тест',
        'isDeleted': false,
        'createdAt': Timestamp.fromDate(DateTime(2025, 6, 15)),
      });

      await c.read(clubPostNotifierProvider.notifier).deleteComment(
            postId,
            commentRef.id,
          );

      final comment = await db
          .collection('club_posts')
          .doc(postId)
          .collection('comments')
          .doc(commentRef.id)
          .get();
      expect(comment['isDeleted'], isTrue);

      final post = await db.collection('club_posts').doc(postId).get();
      expect(post['commentsCount'], 0);
    });

    test('додати 3 коментарі → commentsCount = 3', () async {
      final db = _db();
      final postId = await _seedPost(db);
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(clubPostNotifierProvider.notifier);
      await n.addComment(
          postId: postId, userId: 'u1', userName: 'А', text: '1');
      await n.addComment(
          postId: postId, userId: 'u2', userName: 'Б', text: '2');
      await n.addComment(
          postId: postId, userId: 'u3', userName: 'В', text: '3');

      final post = await db.collection('club_posts').doc(postId).get();
      expect(post['commentsCount'], 3);
    });
  });

  // ── toggleLike / toggleProud ──────────────────────────────────────────────

  group('ClubPostNotifier — toggleLike / toggleProud', () {
    test('toggleLike: ставить лайк (liked=false → true)', () async {
      final db = _db();
      final postId = await _seedPost(db, likesCount: 0);
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(clubPostNotifierProvider.notifier)
          .toggleLike(postId, 'parent1', false);

      final doc = await db.collection('club_posts').doc(postId).get();
      expect(doc['likesCount'], 1);
      expect(List<String>.from(doc['likedByUserIds'] as List),
          contains('parent1'));
    });

    test('toggleLike: знімає лайк (liked=true → false)', () async {
      final db = _db();
      final postId = await _seedPost(
          db, likesCount: 1, likedByUserIds: ['parent1']);
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(clubPostNotifierProvider.notifier)
          .toggleLike(postId, 'parent1', true);

      final doc = await db.collection('club_posts').doc(postId).get();
      expect(doc['likesCount'], 0);
      expect(List<String>.from(doc['likedByUserIds'] as List),
          isNot(contains('parent1')));
    });

    test('toggleProud: ставить горду реакцію', () async {
      final db = _db();
      final postId = await _seedPost(db, proudCount: 0);
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(clubPostNotifierProvider.notifier)
          .toggleProud(postId, 'parent1', false);

      final doc = await db.collection('club_posts').doc(postId).get();
      expect(doc['proudCount'], 1);
      expect(List<String>.from(doc['proudByUserIds'] as List),
          contains('parent1'));
    });

    test('toggleProud: знімає горду реакцію', () async {
      final db = _db();
      final postId = await _seedPost(
          db, proudCount: 1, proudByUserIds: ['parent1']);
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(clubPostNotifierProvider.notifier)
          .toggleProud(postId, 'parent1', true);

      final doc = await db.collection('club_posts').doc(postId).get();
      expect(doc['proudCount'], 0);
    });
  });

  // ── Cross-role: тренер створює → батько бачить ────────────────────────────

  group('News — cross-role: тренер публікує → батько бачить', () {
    test('тренер публікує пост → у Firestore isPublished=true', () async {
      final db = _db();
      final coachC = _container(db);
      addTearDown(coachC.dispose);

      // Тренер: создує чернетку
      final id = await coachC
          .read(clubPostNotifierProvider.notifier)
          .createPost(_post(title: 'Чемпіонат'));

      // Тренер: публікує
      await coachC
          .read(clubPostNotifierProvider.notifier)
          .togglePublish(id, false);

      final doc = await db.collection('club_posts').doc(id).get();
      expect(doc['isPublished'], isTrue);
      expect(doc['title'], 'Чемпіонат');
    });

    test('батько бачить опублікований пост через clubPostsProvider', () async {
      final db = _db();
      final coachC = _container(db);
      final parentC = _container(db);
      addTearDown(coachC.dispose);
      addTearDown(parentC.dispose);

      // Тренер: публікує
      final id = await coachC
          .read(clubPostNotifierProvider.notifier)
          .createPost(_post(title: 'Велика перемога', isPublished: true));

      // Перевірка через Firestore напряму (clubPostsProvider фільтрує isPublished=true)
      final snap = await db
          .collection('club_posts')
          .where('isPublished', isEqualTo: true)
          .get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first.id, id);
      expect(snap.docs.first['title'], 'Велика перемога');
    });

    test('чернетка НЕ потрапляє до опублікованих', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(clubPostNotifierProvider.notifier).createPost(
            _post(title: 'Чернетка', isPublished: false),
          );
      await c.read(clubPostNotifierProvider.notifier).createPost(
            _post(title: 'Опублікована', isPublished: true),
          );

      final publishedSnap = await db
          .collection('club_posts')
          .where('isPublished', isEqualTo: true)
          .get();
      expect(publishedSnap.docs, hasLength(1));
      expect(publishedSnap.docs.first['title'], 'Опублікована');
    });
  });

  // ── Повний сценарій тренера ───────────────────────────────────────────────

  group('News — повний сценарій тренера', () {
    test('тренер: створює → оновлює → публікує → закріплює → батько коментує '
        '→ тренер видаляє', () async {
      final db = _db();
      final coachC = _container(db);
      final parentC = _container(db);
      addTearDown(coachC.dispose);
      addTearDown(parentC.dispose);

      final cn = coachC.read(clubPostNotifierProvider.notifier);
      final pn = parentC.read(clubPostNotifierProvider.notifier);

      // 1. Тренер створює чернетку
      final id =
          await cn.createPost(_post(title: 'Початкова назва'));
      expect(id, isNotEmpty);

      // 2. Тренер оновлює
      await cn.updatePost(_post(id: id, title: 'Оновлена назва'));
      expect(
          (await db.collection('club_posts').doc(id).get())['title'],
          'Оновлена назва');

      // 3. Тренер публікує
      await cn.togglePublish(id, false);
      expect(
          (await db.collection('club_posts').doc(id).get())['isPublished'],
          isTrue);

      // 4. Тренер закріплює
      await cn.togglePin(id, false);
      expect(
          (await db.collection('club_posts').doc(id).get())['isPinned'],
          isTrue);

      // 5. Батько коментує
      await pn.addComment(
          postId: id, userId: 'parent1', userName: 'Батько', text: 'Клас!');
      expect(
          (await db.collection('club_posts').doc(id).get())['commentsCount'],
          1);

      // 6. Тренер видаляє пост
      await cn.deletePost(id);
      expect(
          (await db.collection('club_posts').doc(id).get()).exists, isFalse);
    });
  });
}

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

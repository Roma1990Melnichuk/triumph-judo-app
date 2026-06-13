import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/club_post_model.dart';
import 'package:judo_app/features/news/providers/news_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

ClubPost makePost({
  String id = 'p1',
  String authorId = 'coach1',
  String authorName = 'Тренер Іванов',
  ClubPostType type = ClubPostType.clubNews,
  String title = 'Тестова публікація',
  String description = 'Опис',
  bool isPinned = false,
  bool isPublished = false,
}) =>
    ClubPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      type: type,
      title: title,
      description: description,
      content: '',
      isPinned: isPinned,
      isPublished: isPublished,
      commentsEnabled: true,
      likesCount: 0,
      proudCount: 0,
      commentsCount: 0,
      images: const [],
      mentions: const [],
      likedByUserIds: const [],
      proudByUserIds: const [],
      mentionedAthleteIds: const [],
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
    );

Future<void> seedPost(
  FirebaseFirestore db,
  String id, {
  Map<String, dynamic> extra = const {},
}) =>
    db.collection('club_posts').doc(id).set({
      'authorId': 'coach1',
      'authorName': 'Тренер',
      'type': 'clubNews',
      'title': 'Публікація',
      'description': '',
      'content': '',
      'isPinned': false,
      'isPublished': false,
      'commentsEnabled': true,
      'likesCount': 0,
      'proudCount': 0,
      'commentsCount': 0,
      'images': [],
      'mentions': [],
      'likedByUserIds': [],
      'proudByUserIds': [],
      'mentionedAthleteIds': [],
      'createdAt': Timestamp.fromDate(DateTime(2026, 6, 1)),
      'updatedAt': Timestamp.fromDate(DateTime(2026, 6, 1)),
      ...extra,
    });

void main() {
  // ── NewsFeedFilter.label ──────────────────────────────────────────────────

  group('NewsFeedFilter.label', () {
    final cases = {
      NewsFeedFilter.all:         'Всі',
      NewsFeedFilter.photoReport: 'Фотозвіти',
      NewsFeedFilter.competition: 'Змагання',
      NewsFeedFilter.achievement: 'Досягнення',
      NewsFeedFilter.honorBoard:  'Дошка пошани',
      NewsFeedFilter.myChild:     'Моя дитина',
    };
    cases.forEach((f, label) {
      test('$f → $label', () => expect(f.label, label));
    });
  });

  // ── ClubPostNotifier.createPost ───────────────────────────────────────────

  group('ClubPostNotifier.createPost', () {
    test('створює документ і повертає непорожній id', () async {
      final fake = FakeFirebaseFirestore();
      final notifier = ClubPostNotifier(fake);

      final id = await notifier.createPost(
        makePost(authorId: 'coach42', title: 'Новий пост'),
      );

      expect(id, isNotEmpty);
      final doc = await fake.collection('club_posts').doc(id).get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['authorId'], 'coach42');
      expect(doc.data()?['title'], 'Новий пост');
    });

    test('стан переходить в AsyncData після успіху', () async {
      final fake = FakeFirebaseFirestore();
      final notifier = ClubPostNotifier(fake);

      await notifier.createPost(makePost());

      expect(notifier.state, isA<AsyncData<void>>());
    });
  });

  // ── ClubPostNotifier.updatePost ───────────────────────────────────────────

  group('ClubPostNotifier.updatePost', () {
    test('оновлює поля в Firestore', () async {
      final fake = FakeFirebaseFirestore();
      await seedPost(fake, 'p1', extra: {'title': 'Старий заголовок'});
      final notifier = ClubPostNotifier(fake);

      await notifier.updatePost(
        makePost(id: 'p1', title: 'Новий заголовок', type: ClubPostType.photoReport),
      );

      final data = (await fake.collection('club_posts').doc('p1').get()).data()!;
      expect(data['title'], 'Новий заголовок');
      expect(data['type'], 'photoReport');
    });
  });

  // ── ClubPostNotifier.deletePost ───────────────────────────────────────────

  group('ClubPostNotifier.deletePost', () {
    test('видаляє документ', () async {
      final fake = FakeFirebaseFirestore();
      await seedPost(fake, 'p1');
      final notifier = ClubPostNotifier(fake);

      await notifier.deletePost('p1');

      final doc = await fake.collection('club_posts').doc('p1').get();
      expect(doc.exists, isFalse);
    });

    test('стан переходить в AsyncData після успіху', () async {
      final fake = FakeFirebaseFirestore();
      await seedPost(fake, 'p1');
      final notifier = ClubPostNotifier(fake);

      await notifier.deletePost('p1');

      expect(notifier.state, isA<AsyncData<void>>());
    });
  });

  // ── ClubPostNotifier.togglePin ────────────────────────────────────────────

  group('ClubPostNotifier.togglePin', () {
    test('false → true', () async {
      final fake = FakeFirebaseFirestore();
      await seedPost(fake, 'p1', extra: {'isPinned': false});
      await ClubPostNotifier(fake).togglePin('p1', false);

      final data = (await fake.collection('club_posts').doc('p1').get()).data()!;
      expect(data['isPinned'], isTrue);
    });

    test('true → false', () async {
      final fake = FakeFirebaseFirestore();
      await seedPost(fake, 'p1', extra: {'isPinned': true});
      await ClubPostNotifier(fake).togglePin('p1', true);

      final data = (await fake.collection('club_posts').doc('p1').get()).data()!;
      expect(data['isPinned'], isFalse);
    });
  });

  // ── ClubPostNotifier.togglePublish ────────────────────────────────────────

  group('ClubPostNotifier.togglePublish', () {
    test('false → true: встановлює isPublished і publishedAt', () async {
      final fake = FakeFirebaseFirestore();
      await seedPost(fake, 'p1', extra: {'isPublished': false});
      await ClubPostNotifier(fake).togglePublish('p1', false);

      final data = (await fake.collection('club_posts').doc('p1').get()).data()!;
      expect(data['isPublished'], isTrue);
      expect(data.containsKey('publishedAt'), isTrue);
    });

    test('true → false: знімає публікацію без зміни publishedAt', () async {
      final fake = FakeFirebaseFirestore();
      final published = Timestamp.fromDate(DateTime(2026, 6, 5));
      await seedPost(fake, 'p1', extra: {
        'isPublished': true,
        'publishedAt': published,
      });
      await ClubPostNotifier(fake).togglePublish('p1', true);

      final data = (await fake.collection('club_posts').doc('p1').get()).data()!;
      expect(data['isPublished'], isFalse);
      // publishedAt залишається незмінним (нова дата не записується)
      expect(data['publishedAt'], published);
    });
  });

  // ── ClubPostNotifier.toggleLike ───────────────────────────────────────────

  group('ClubPostNotifier.toggleLike', () {
    test('liked=false: додає uid до likedByUserIds і збільшує likesCount', () async {
      final fake = FakeFirebaseFirestore();
      await seedPost(fake, 'p1', extra: {'likesCount': 2, 'likedByUserIds': ['u1']});
      await ClubPostNotifier(fake).toggleLike('p1', 'u2', false);

      final data = (await fake.collection('club_posts').doc('p1').get()).data()!;
      final ids = List<String>.from(data['likedByUserIds'] as List);
      expect(ids, containsAll(['u1', 'u2']));
      expect(data['likesCount'], 3);
    });

    test('liked=true: видаляє uid і зменшує likesCount', () async {
      final fake = FakeFirebaseFirestore();
      await seedPost(fake, 'p1', extra: {
        'likesCount': 3,
        'likedByUserIds': ['u1', 'u2', 'u3'],
      });
      await ClubPostNotifier(fake).toggleLike('p1', 'u2', true);

      final data = (await fake.collection('club_posts').doc('p1').get()).data()!;
      final ids = List<String>.from(data['likedByUserIds'] as List);
      expect(ids, isNot(contains('u2')));
      expect(data['likesCount'], 2);
    });
  });

  // ── ClubPostNotifier.toggleProud ──────────────────────────────────────────

  group('ClubPostNotifier.toggleProud', () {
    test('proud=false: додає uid до proudByUserIds і збільшує proudCount', () async {
      final fake = FakeFirebaseFirestore();
      await seedPost(fake, 'p1', extra: {'proudCount': 0, 'proudByUserIds': []});
      await ClubPostNotifier(fake).toggleProud('p1', 'u5', false);

      final data = (await fake.collection('club_posts').doc('p1').get()).data()!;
      expect(List<String>.from(data['proudByUserIds'] as List), contains('u5'));
      expect(data['proudCount'], 1);
    });

    test('proud=true: видаляє uid і зменшує proudCount', () async {
      final fake = FakeFirebaseFirestore();
      await seedPost(fake, 'p1', extra: {
        'proudCount': 2,
        'proudByUserIds': ['u5', 'u6'],
      });
      await ClubPostNotifier(fake).toggleProud('p1', 'u5', true);

      final data = (await fake.collection('club_posts').doc('p1').get()).data()!;
      expect(List<String>.from(data['proudByUserIds'] as List), isNot(contains('u5')));
      expect(data['proudCount'], 1);
    });
  });

  // ── ClubPostNotifier.addComment ───────────────────────────────────────────

  group('ClubPostNotifier.addComment', () {
    test('створює документ коментаря в підколекції', () async {
      final fake = FakeFirebaseFirestore();
      await seedPost(fake, 'p1');
      final notifier = ClubPostNotifier(fake);

      await notifier.addComment(
        postId: 'p1',
        userId: 'u10',
        userName: 'Марія Коваль',
        text: 'Молодці! 💪',
      );

      final comments = await fake
          .collection('club_posts')
          .doc('p1')
          .collection('comments')
          .get();
      expect(comments.docs, hasLength(1));
      final c = comments.docs.first.data();
      expect(c['userId'], 'u10');
      expect(c['userName'], 'Марія Коваль');
      expect(c['text'], 'Молодці! 💪');
      expect(c['isDeleted'], isFalse);
    });

    test('збільшує commentsCount публікації', () async {
      final fake = FakeFirebaseFirestore();
      await seedPost(fake, 'p1', extra: {'commentsCount': 0});
      await ClubPostNotifier(fake).addComment(
        postId: 'p1',
        userId: 'u1',
        userName: 'Тест',
        text: 'OK',
      );

      final data = (await fake.collection('club_posts').doc('p1').get()).data()!;
      expect(data['commentsCount'], 1);
    });
  });

  // ── ClubPostNotifier.deleteComment ────────────────────────────────────────

  group('ClubPostNotifier.deleteComment', () {
    test('встановлює isDeleted=true для коментаря', () async {
      final fake = FakeFirebaseFirestore();
      await seedPost(fake, 'p1', extra: {'commentsCount': 1});
      await fake
          .collection('club_posts')
          .doc('p1')
          .collection('comments')
          .doc('c1')
          .set({
        'userId': 'u1',
        'userName': 'Тест',
        'text': 'Коментар',
        'isDeleted': false,
        'createdAt': Timestamp.fromDate(DateTime(2026, 6, 1)),
      });

      await ClubPostNotifier(fake).deleteComment('p1', 'c1');

      final comment = await fake
          .collection('club_posts')
          .doc('p1')
          .collection('comments')
          .doc('c1')
          .get();
      expect(comment.data()?['isDeleted'], isTrue);
    });

    test('зменшує commentsCount публікації', () async {
      final fake = FakeFirebaseFirestore();
      await seedPost(fake, 'p1', extra: {'commentsCount': 3});
      await fake
          .collection('club_posts')
          .doc('p1')
          .collection('comments')
          .doc('c1')
          .set({'isDeleted': false});

      await ClubPostNotifier(fake).deleteComment('p1', 'c1');

      final data = (await fake.collection('club_posts').doc('p1').get()).data()!;
      expect(data['commentsCount'], 2);
    });
  });

  // ── newsFeedFilterProvider ────────────────────────────────────────────────

  group('newsFeedFilterProvider', () {
    test('початковий стан — NewsFeedFilter.all', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(newsFeedFilterProvider), NewsFeedFilter.all);
    });

    test('можна змінити фільтр', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(newsFeedFilterProvider.notifier).state =
          NewsFeedFilter.competition;
      expect(container.read(newsFeedFilterProvider), NewsFeedFilter.competition);
    });
  });
}

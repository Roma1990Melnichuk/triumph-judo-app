import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/club_post_model.dart';

ClubPost makePost({
  String id = 'p1',
  String authorId = 'coach1',
  String authorName = 'Іван Петренко',
  ClubPostType type = ClubPostType.clubNews,
  String title = 'Новина клубу',
  String description = 'Короткий опис',
  String content = '',
  String? coverImageUrl,
  bool isPinned = false,
  bool isPublished = false,
  bool commentsEnabled = true,
  int likesCount = 0,
  int proudCount = 0,
  int commentsCount = 0,
  List<ClubPostImage>? images,
  List<ClubPostAthleteMention>? mentions,
  List<String>? likedByUserIds,
  List<String>? proudByUserIds,
  List<String>? mentionedAthleteIds,
  String? competitionName,
  int? goldMedals,
  int? silverMedals,
  int? bronzeMedals,
  DateTime? publishedAt,
}) =>
    ClubPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      type: type,
      title: title,
      description: description,
      content: content,
      coverImageUrl: coverImageUrl,
      isPinned: isPinned,
      isPublished: isPublished,
      commentsEnabled: commentsEnabled,
      likesCount: likesCount,
      proudCount: proudCount,
      commentsCount: commentsCount,
      images: images ?? const [],
      mentions: mentions ?? const [],
      likedByUserIds: likedByUserIds ?? const [],
      proudByUserIds: proudByUserIds ?? const [],
      mentionedAthleteIds: mentionedAthleteIds ?? const [],
      competitionName: competitionName,
      goldMedals: goldMedals,
      silverMedals: silverMedals,
      bronzeMedals: bronzeMedals,
      publishedAt: publishedAt,
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
    );

void main() {
  // ── ClubPostType labels ───────────────────────────────────────────────────

  group('ClubPostType.label', () {
    final cases = {
      ClubPostType.photoReport:  'Фотозвіт',
      ClubPostType.competition:  'Змагання',
      ClubPostType.achievement:  'Досягнення',
      ClubPostType.honorBoard:   'Дошка пошани',
      ClubPostType.announcement: 'Оголошення',
      ClubPostType.clubNews:     'Новини клубу',
    };
    cases.forEach((type, label) {
      test('$type → $label', () => expect(type.label, label));
    });
  });

  group('ClubPostTypeX.fromString', () {
    test('розпізнає всі значення', () {
      for (final t in ClubPostType.values) {
        expect(ClubPostTypeX.fromString(t.name), t);
      }
    });

    test('невідоме → clubNews', () {
      expect(ClubPostTypeX.fromString(null), ClubPostType.clubNews);
      expect(ClubPostTypeX.fromString('xyz'), ClubPostType.clubNews);
    });
  });

  // ── ClubPost.photosCount ──────────────────────────────────────────────────

  group('ClubPost.photosCount', () {
    test('без фото → 0', () {
      expect(makePost().photosCount, 0);
    });

    test('дорівнює кількості images', () {
      final images = List.generate(
        3,
        (i) => ClubPostImage(
          id: 'img$i',
          postId: 'p1',
          imageUrl: 'https://example.com/$i.jpg',
          sortOrder: i,
          createdAt: DateTime(2026),
        ),
      );
      expect(makePost(images: images).photosCount, 3);
    });
  });

  // ── ClubPost.userLiked / userProud ────────────────────────────────────────

  group('ClubPost.userLiked', () {
    test('uid в списку → true', () {
      final post = makePost(likedByUserIds: ['u1', 'u2']);
      expect(post.userLiked('u1'), isTrue);
    });

    test('uid не в списку → false', () {
      expect(makePost().userLiked('u99'), isFalse);
    });
  });

  group('ClubPost.userProud', () {
    test('uid в списку → true', () {
      final post = makePost(proudByUserIds: ['u3']);
      expect(post.userProud('u3'), isTrue);
    });

    test('uid не в списку → false', () {
      expect(makePost().userProud('u3'), isFalse);
    });
  });

  // ── ClubPostImage toMap / fromMap ─────────────────────────────────────────

  group('ClubPostImage — round-trip', () {
    test('зберігає всі поля', () {
      final img = ClubPostImage(
        id: 'img1',
        postId: 'p1',
        imageUrl: 'https://cdn.example.com/photo.jpg',
        thumbnailUrl: 'https://cdn.example.com/thumb.jpg',
        caption: 'Чемпіони',
        sortOrder: 2,
        createdAt: DateTime(2026, 6, 5),
      );
      final restored = ClubPostImage.fromMap(img.toMap());
      expect(restored.id, img.id);
      expect(restored.imageUrl, img.imageUrl);
      expect(restored.thumbnailUrl, img.thumbnailUrl);
      expect(restored.caption, img.caption);
      expect(restored.sortOrder, img.sortOrder);
    });

    test('null-поля не попадають в toMap', () {
      final img = ClubPostImage(
        id: 'img2',
        postId: 'p1',
        imageUrl: 'https://example.com/a.jpg',
        createdAt: DateTime(2026),
      );
      final map = img.toMap();
      expect(map.containsKey('thumbnailUrl'), isFalse);
      expect(map.containsKey('caption'), isFalse);
    });
  });

  // ── ClubPostAthleteMention toMap / fromMap ────────────────────────────────

  group('ClubPostAthleteMention — round-trip', () {
    test('зберігає всі поля', () {
      const mention = ClubPostAthleteMention(
        id: 'mn1',
        imageId: 'img1',
        athleteId: 'a1',
        athleteName: 'Максим Іванов',
        xPosition: 0.3,
        yPosition: 0.7,
        caption: 'Перше місце',
      );
      final restored = ClubPostAthleteMention.fromMap(mention.toMap());
      expect(restored.athleteId, 'a1');
      expect(restored.athleteName, 'Максим Іванов');
      expect(restored.xPosition, 0.3);
      expect(restored.caption, 'Перше місце');
    });

    test('null-поля не попадають в toMap', () {
      const mention = ClubPostAthleteMention(
        id: 'mn2',
        athleteId: 'a2',
        athleteName: 'Тест',
      );
      final map = mention.toMap();
      expect(map.containsKey('imageId'), isFalse);
      expect(map.containsKey('xPosition'), isFalse);
      expect(map.containsKey('caption'), isFalse);
    });
  });

  // ── ClubPost.toFirestore ──────────────────────────────────────────────────

  group('ClubPost.toFirestore', () {
    test('містить обов\'язкові поля', () {
      final map = makePost().toFirestore();
      expect(map['authorId'], 'coach1');
      expect(map['type'], 'clubNews');
      expect(map['title'], 'Новина клубу');
      expect(map['isPublished'], false);
      expect(map['commentsEnabled'], true);
      expect(map['likesCount'], 0);
    });

    test('coverImageUrl відсутній коли null', () {
      expect(makePost().toFirestore().containsKey('coverImageUrl'), isFalse);
    });

    test('coverImageUrl присутній коли вказаний', () {
      final map =
          makePost(coverImageUrl: 'https://cdn.example.com/cover.jpg').toFirestore();
      expect(map['coverImageUrl'], 'https://cdn.example.com/cover.jpg');
    });

    test('competitionName відсутній коли null', () {
      expect(makePost().toFirestore().containsKey('competitionName'), isFalse);
    });

    test('медалі серіалізуються коли вказані', () {
      final map = makePost(goldMedals: 3, silverMedals: 2, bronzeMedals: 5).toFirestore();
      expect(map['goldMedals'], 3);
      expect(map['silverMedals'], 2);
      expect(map['bronzeMedals'], 5);
    });

    test('publishedAt серіалізується як Timestamp', () {
      final map =
          makePost(publishedAt: DateTime(2026, 6, 10)).toFirestore();
      expect(map['publishedAt'], isA<Timestamp>());
    });

    test('publishedAt відсутній коли null', () {
      expect(makePost().toFirestore().containsKey('publishedAt'), isFalse);
    });

    test('images серіалізуються як список мап', () {
      final img = ClubPostImage(
        id: 'img1',
        postId: 'p1',
        imageUrl: 'https://example.com/a.jpg',
        createdAt: DateTime(2026),
      );
      final map = makePost(images: [img]).toFirestore();
      expect((map['images'] as List).length, 1);
    });
  });

  // ── ClubPost.fromFirestore ────────────────────────────────────────────────

  group('ClubPost.fromFirestore', () {
    late FakeFirebaseFirestore fake;
    setUp(() => fake = FakeFirebaseFirestore());

    test('зчитує всі поля', () async {
      final ref = fake.collection('club_posts').doc('post1');
      await ref.set({
        'authorId': 'coach1',
        'authorName': 'Іван',
        'type': 'photoReport',
        'title': 'Кубок Києва',
        'description': 'Фотозвіт',
        'content': '',
        'isPinned': true,
        'isPublished': true,
        'commentsEnabled': false,
        'likesCount': 7,
        'proudCount': 3,
        'commentsCount': 2,
        'images': [],
        'mentions': [],
        'likedByUserIds': ['u1', 'u2'],
        'proudByUserIds': ['u3'],
        'mentionedAthleteIds': ['a1'],
        'competitionName': 'Кубок Києва',
        'competitionCity': 'Київ',
        'goldMedals': 2,
        'silverMedals': 1,
        'bronzeMedals': 3,
        'publishedAt': Timestamp.fromDate(DateTime(2026, 6, 10)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 6, 1)),
      });
      final post = ClubPost.fromFirestore(await ref.get());
      expect(post.type, ClubPostType.photoReport);
      expect(post.title, 'Кубок Києва');
      expect(post.isPinned, isTrue);
      expect(post.isPublished, isTrue);
      expect(post.commentsEnabled, isFalse);
      expect(post.likesCount, 7);
      expect(post.likedByUserIds, containsAll(['u1', 'u2']));
      expect(post.mentionedAthleteIds, contains('a1'));
      expect(post.goldMedals, 2);
      expect(post.publishedAt, DateTime(2026, 6, 10));
    });

    test('відсутні поля → defaults', () async {
      final ref = fake.collection('club_posts').doc('empty');
      await ref.set({
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
      final post = ClubPost.fromFirestore(await ref.get());
      expect(post.type, ClubPostType.clubNews);
      expect(post.title, '');
      expect(post.isPublished, isFalse);
      expect(post.commentsEnabled, isTrue);
      expect(post.likedByUserIds, isEmpty);
      expect(post.images, isEmpty);
      expect(post.goldMedals, isNull);
    });
  });

  // ── ClubPost.copyWith ─────────────────────────────────────────────────────

  group('ClubPost.copyWith', () {
    test('змінює тільки вказані поля', () {
      final post = makePost(title: 'Стара', isPublished: false);
      final updated = post.copyWith(title: 'Нова', isPublished: true);
      expect(updated.title, 'Нова');
      expect(updated.isPublished, isTrue);
      expect(updated.authorId, post.authorId);
    });

    test('скидає coverImageUrl через sentinel', () {
      final post = makePost(coverImageUrl: 'https://example.com/cover.jpg');
      final updated = post.copyWith(coverImageUrl: null);
      expect(updated.coverImageUrl, isNull);
    });

    test('скидає competitionName через sentinel', () {
      final post = makePost(competitionName: 'Кубок');
      final updated = post.copyWith(competitionName: null);
      expect(updated.competitionName, isNull);
    });
  });

  // ── ClubPostComment toFirestore / fromFirestore ───────────────────────────

  group('ClubPostComment — round-trip', () {
    late FakeFirebaseFirestore fake;
    setUp(() => fake = FakeFirebaseFirestore());

    test('зберігає всі поля', () async {
      final comment = ClubPostComment(
        id: 'c1',
        postId: 'p1',
        userId: 'u1',
        userName: 'Марія Ковалько',
        text: 'Молодці!',
        isDeleted: false,
        createdAt: DateTime(2026, 6, 5, 12),
      );
      final ref = fake
          .collection('club_posts')
          .doc('p1')
          .collection('comments')
          .doc('c1');
      await ref.set(comment.toFirestore());
      final restored = ClubPostComment.fromFirestore(await ref.get());
      expect(restored.userId, 'u1');
      expect(restored.userName, 'Марія Ковалько');
      expect(restored.text, 'Молодці!');
      expect(restored.isDeleted, isFalse);
      expect(restored.createdAt, DateTime(2026, 6, 5, 12));
    });
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/club_honor_board_model.dart';

ClubHonorBoardItem makeItem({
  String id = 'hb1',
  String athleteId = 'a1',
  String athleteName = 'Максим Іванов',
  int? athleteAge = 14,
  String? athleteBelt = 'Синій',
  HonorBoardType type = HonorBoardType.firstPlace,
  String title = '1 місце на Кубку Києва',
  String? description,
  String? competitionName = 'Кубок Києва',
  MedalType? medalType = MedalType.gold,
  String? imageUrl,
  String? coachComment,
  bool isPinned = false,
  bool isVisible = true,
  DateTime? publishedAt,
}) =>
    ClubHonorBoardItem(
      id: id,
      athleteId: athleteId,
      athleteName: athleteName,
      athleteAge: athleteAge,
      athleteBelt: athleteBelt,
      type: type,
      title: title,
      description: description,
      competitionName: competitionName,
      medalType: medalType,
      imageUrl: imageUrl,
      coachComment: coachComment,
      isPinned: isPinned,
      isVisible: isVisible,
      publishedAt: publishedAt ?? DateTime(2026, 6, 1),
      createdAt: DateTime(2026, 6, 1),
    );

void main() {
  // ── HonorBoardType labels / emojis ─────────────────────────────────────────

  group('HonorBoardType.label', () {
    final cases = {
      HonorBoardType.firstPlace:       '1 місце',
      HonorBoardType.secondPlace:      '2 місце',
      HonorBoardType.thirdPlace:       '3 місце',
      HonorBoardType.newBelt:          'Новий пояс',
      HonorBoardType.personalRecord:   'Особистий рекорд',
      HonorBoardType.monthAchievement: 'Досягнення місяця',
      HonorBoardType.disciplineRating: 'Рейтинг дисципліни',
      HonorBoardType.bestProgress:     'Кращий прогрес',
    };
    cases.forEach((t, label) {
      test('$t → $label', () => expect(t.label, label));
    });
  });

  group('HonorBoardType.emoji', () {
    test('кожен тип має непорожній emoji', () {
      for (final t in HonorBoardType.values) {
        expect(t.emoji, isNotEmpty);
      }
    });
  });

  group('HonorBoardType.isMedal / isBelt / isProgress', () {
    test('перші 3 місця → isMedal', () {
      expect(HonorBoardType.firstPlace.isMedal, isTrue);
      expect(HonorBoardType.secondPlace.isMedal, isTrue);
      expect(HonorBoardType.thirdPlace.isMedal, isTrue);
    });

    test('newBelt → isBelt', () {
      expect(HonorBoardType.newBelt.isBelt, isTrue);
      expect(HonorBoardType.firstPlace.isBelt, isFalse);
    });

    test('personalRecord / monthAchievement / disciplineRating / bestProgress → isProgress', () {
      final progressTypes = [
        HonorBoardType.personalRecord,
        HonorBoardType.monthAchievement,
        HonorBoardType.disciplineRating,
        HonorBoardType.bestProgress,
      ];
      for (final t in progressTypes) {
        expect(t.isProgress, isTrue, reason: '$t має бути isProgress');
        expect(t.isMedal, isFalse);
        expect(t.isBelt, isFalse);
      }
    });

    test('isMedal + isBelt + isProgress — розбивають значення без перетину', () {
      for (final t in HonorBoardType.values) {
        final count = [t.isMedal, t.isBelt, t.isProgress].where((b) => b).length;
        expect(count, 1, reason: '$t має рівно одну категорію');
      }
    });
  });

  group('HonorBoardTypeX.fromString', () {
    test('розпізнає всі значення', () {
      for (final t in HonorBoardType.values) {
        expect(HonorBoardTypeX.fromString(t.name), t);
      }
    });

    test('невідоме → monthAchievement', () {
      expect(HonorBoardTypeX.fromString(null), HonorBoardType.monthAchievement);
      expect(HonorBoardTypeX.fromString('xyz'), HonorBoardType.monthAchievement);
    });
  });

  // ── MedalType ─────────────────────────────────────────────────────────────

  group('MedalType.label', () {
    test('gold → Золото',   () => expect(MedalType.gold.label,   'Золото'));
    test('silver → Срібло', () => expect(MedalType.silver.label, 'Срібло'));
    test('bronze → Бронза', () => expect(MedalType.bronze.label, 'Бронза'));
  });

  group('MedalType.emoji', () {
    test('gold → 🥇',   () => expect(MedalType.gold.emoji,   '🥇'));
    test('silver → 🥈', () => expect(MedalType.silver.emoji, '🥈'));
    test('bronze → 🥉', () => expect(MedalType.bronze.emoji, '🥉'));
  });

  group('MedalTypeX.fromString', () {
    test('розпізнає всі значення', () {
      for (final m in MedalType.values) {
        expect(MedalTypeX.fromString(m.name), m);
      }
    });

    test('null → null', () {
      expect(MedalTypeX.fromString(null), isNull);
    });

    test('невідомий → null', () {
      expect(MedalTypeX.fromString('platinum'), isNull);
    });
  });

  // ── ClubHonorBoardItem.toFirestore ─────────────────────────────────────────

  group('ClubHonorBoardItem.toFirestore', () {
    test('містить обов\'язкові поля', () {
      final map = makeItem().toFirestore();
      expect(map['athleteId'], 'a1');
      expect(map['athleteName'], 'Максим Іванов');
      expect(map['type'], 'firstPlace');
      expect(map['title'], '1 місце на Кубку Києва');
      expect(map['isPinned'], false);
      expect(map['isVisible'], true);
    });

    test('medalType серіалізується як рядок', () {
      expect(makeItem(medalType: MedalType.silver).toFirestore()['medalType'], 'silver');
    });

    test('medalType відсутній коли null', () {
      expect(makeItem(medalType: null).toFirestore().containsKey('medalType'), isFalse);
    });

    test('imageUrl відсутній коли null', () {
      expect(makeItem(imageUrl: null).toFirestore().containsKey('imageUrl'), isFalse);
    });

    test('imageUrl присутній коли вказаний', () {
      final map = makeItem(imageUrl: 'https://cdn.example.com/athlete.jpg').toFirestore();
      expect(map['imageUrl'], 'https://cdn.example.com/athlete.jpg');
    });

    test('athleteAge та athleteBelt серіалізуються', () {
      final map = makeItem(athleteAge: 16, athleteBelt: 'Синій').toFirestore();
      expect(map['athleteAge'], 16);
      expect(map['athleteBelt'], 'Синій');
    });

    test('publishedAt серіалізується як Timestamp', () {
      expect(makeItem().toFirestore()['publishedAt'], isA<Timestamp>());
    });
  });

  // ── ClubHonorBoardItem.fromFirestore ───────────────────────────────────────

  group('ClubHonorBoardItem.fromFirestore', () {
    late FakeFirebaseFirestore fake;
    setUp(() => fake = FakeFirebaseFirestore());

    test('зчитує всі поля', () async {
      final ref = fake.collection('honor_board').doc('hb1');
      await ref.set({
        'athleteId': 'a42',
        'athleteName': 'Софія Коваленко',
        'athleteAge': 12,
        'athleteBelt': 'Зелений',
        'type': 'secondPlace',
        'title': '2 місце',
        'description': 'Чудовий результат',
        'competitionName': 'Турнір Golden Belt',
        'medalType': 'silver',
        'imageUrl': 'https://cdn.example.com/photo.jpg',
        'coachComment': 'Пишаємося!',
        'isPinned': true,
        'isVisible': true,
        'publishedAt': Timestamp.fromDate(DateTime(2026, 5, 20)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 20)),
      });
      final item = ClubHonorBoardItem.fromFirestore(await ref.get());
      expect(item.athleteId, 'a42');
      expect(item.athleteName, 'Софія Коваленко');
      expect(item.athleteAge, 12);
      expect(item.type, HonorBoardType.secondPlace);
      expect(item.medalType, MedalType.silver);
      expect(item.imageUrl, 'https://cdn.example.com/photo.jpg');
      expect(item.coachComment, 'Пишаємося!');
      expect(item.isPinned, isTrue);
      expect(item.publishedAt, DateTime(2026, 5, 20));
    });

    test('відсутні поля → defaults', () async {
      final ref = fake.collection('honor_board').doc('empty');
      await ref.set({
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'publishedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
      final item = ClubHonorBoardItem.fromFirestore(await ref.get());
      expect(item.athleteId, '');
      expect(item.type, HonorBoardType.monthAchievement);
      expect(item.medalType, isNull);
      expect(item.isPinned, isFalse);
      expect(item.isVisible, isTrue);
    });
  });

  // ── round-trip ─────────────────────────────────────────────────────────────

  group('ClubHonorBoardItem — round-trip', () {
    test('toFirestore → fromFirestore зберігає поля', () async {
      final fake = FakeFirebaseFirestore();
      final original = makeItem(
        id: 'rt1',
        type: HonorBoardType.newBelt,
        medalType: null,
        athleteAge: 15,
        coachComment: 'Зобов\'язує',
        imageUrl: 'https://cdn.example.com/belt.jpg',
        isPinned: true,
        publishedAt: DateTime(2026, 4, 1),
      );
      await fake.collection('honor_board').doc('rt1').set(original.toFirestore());
      final item = ClubHonorBoardItem.fromFirestore(
          await fake.collection('honor_board').doc('rt1').get());
      expect(item.type, HonorBoardType.newBelt);
      expect(item.medalType, isNull);
      expect(item.athleteAge, 15);
      expect(item.coachComment, original.coachComment);
      expect(item.imageUrl, original.imageUrl);
      expect(item.isPinned, isTrue);
      expect(item.publishedAt, original.publishedAt);
    });
  });
}

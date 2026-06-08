import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/notification_model.dart';

NotificationModel makeNotification({
  String id = 'n1',
  String title = 'Тренування відмінено',
  String body = 'Завтрашнє тренування скасовано.',
  NotificationTarget target = NotificationTarget.all,
  List<String> targetValues = const [],
  DateTime? sentAt,
  String coachId = 'coach1',
  String coachName = 'Тренер',
  List<String> readByUserIds = const [],
}) =>
    NotificationModel(
      id: id,
      title: title,
      body: body,
      target: target,
      targetValues: targetValues,
      sentAt: sentAt ?? DateTime(2026, 6, 1, 10, 0),
      coachId: coachId,
      coachName: coachName,
      readByUserIds: readByUserIds,
    );

void main() {
  // ── NotificationTargetX.fromString ───────────────────────────────────────

  group('NotificationTargetX.fromString', () {
    test('розпізнає всі валідні значення', () {
      expect(NotificationTargetX.fromString('all'), NotificationTarget.all);
      expect(NotificationTargetX.fromString('ageGroup'), NotificationTarget.ageGroup);
      expect(NotificationTargetX.fromString('belt'), NotificationTarget.belt);
      expect(NotificationTargetX.fromString('top20age'), NotificationTarget.top20age);
      expect(NotificationTargetX.fromString('exceptTop20age'), NotificationTarget.exceptTop20age);
    });

    test('невідоме значення → all (fallback)', () {
      expect(NotificationTargetX.fromString('unknown'), NotificationTarget.all);
      expect(NotificationTargetX.fromString(''), NotificationTarget.all);
    });
  });

  // ── NotificationTargetX.displayName ──────────────────────────────────────

  group('NotificationTargetX.displayName', () {
    test('all → Всім', () => expect(NotificationTarget.all.displayName, 'Всім'));
    test('ageGroup → За віком', () => expect(NotificationTarget.ageGroup.displayName, 'За віком'));
    test('belt → За поясом', () => expect(NotificationTarget.belt.displayName, 'За поясом'));
    test('top20age → Топ 20 (вік)', () => expect(NotificationTarget.top20age.displayName, 'Топ 20 (вік)'));
    test('exceptTop20age → Крім топ 20 (вік)', () {
      expect(NotificationTarget.exceptTop20age.displayName, 'Крім топ 20 (вік)');
    });
  });

  // ── NotificationModel.toFirestore ─────────────────────────────────────────

  group('NotificationModel.toFirestore', () {
    test('містить всі поля', () {
      final map = makeNotification(
        target: NotificationTarget.ageGroup,
        targetValues: ['2010', '2011'],
        readByUserIds: ['u1'],
      ).toFirestore();
      expect(map['title'], 'Тренування відмінено');
      expect(map['body'], isNotEmpty);
      expect(map['target'], 'ageGroup');
      expect(map['targetValues'], ['2010', '2011']);
      expect(map['coachId'], 'coach1');
      expect(map['coachName'], 'Тренер');
      expect(map['readByUserIds'], ['u1']);
    });

    test('target серіалізується як рядок (name)', () {
      final map = makeNotification(target: NotificationTarget.exceptTop20age).toFirestore();
      expect(map['target'], 'exceptTop20age');
    });

    test('sentAt серіалізується як Timestamp', () {
      final map = makeNotification(sentAt: DateTime(2026, 5, 10)).toFirestore();
      expect(map['sentAt'], isA<Timestamp>());
      expect((map['sentAt'] as Timestamp).toDate(), DateTime(2026, 5, 10));
    });

    test('id не включається', () {
      expect(makeNotification().toFirestore().containsKey('id'), isFalse);
    });
  });

  // ── NotificationModel.fromFirestore ──────────────────────────────────────

  group('NotificationModel.fromFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;
    setUp(() => fakeFirestore = FakeFirebaseFirestore());

    test('зчитує всі поля коректно', () async {
      final ref = fakeFirestore.collection('notifications').doc('notif1');
      await ref.set({
        'title': 'Увага',
        'body': 'Збір у суботу',
        'target': 'belt',
        'targetValues': ['yellow', 'orange'],
        'sentAt': Timestamp.fromDate(DateTime(2026, 6, 5)),
        'coachId': 'coach2',
        'coachName': 'Тренер Марія',
        'readByUserIds': ['user1', 'user2'],
      });
      final n = NotificationModel.fromFirestore(await ref.get());
      expect(n.id, 'notif1');
      expect(n.title, 'Увага');
      expect(n.target, NotificationTarget.belt);
      expect(n.targetValues, ['yellow', 'orange']);
      expect(n.readByUserIds, ['user1', 'user2']);
      expect(n.sentAt, DateTime(2026, 6, 5));
    });

    test('відсутні поля — значення за замовчуванням', () async {
      final ref = fakeFirestore.collection('notifications').doc('empty');
      await ref.set(<String, dynamic>{});
      final n = NotificationModel.fromFirestore(await ref.get());
      expect(n.title, '');
      expect(n.body, '');
      expect(n.target, NotificationTarget.all);
      expect(n.targetValues, isEmpty);
      expect(n.readByUserIds, isEmpty);
      expect(n.coachId, '');
    });
  });

  // ── round-trip ────────────────────────────────────────────────────────────

  group('NotificationModel — round-trip', () {
    test('toFirestore → fromFirestore зберігає всі поля', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final original = makeNotification(
        id: 'rt1',
        target: NotificationTarget.exceptTop20age,
        targetValues: ['2012'],
        sentAt: DateTime(2026, 4, 1, 9, 30),
        readByUserIds: ['uid1'],
      );
      final ref = fakeFirestore.collection('notifications').doc('rt1');
      await ref.set(original.toFirestore());
      final restored = NotificationModel.fromFirestore(await ref.get());
      expect(restored.title, original.title);
      expect(restored.target, original.target);
      expect(restored.targetValues, original.targetValues);
      expect(restored.sentAt, original.sentAt);
      expect(restored.readByUserIds, original.readByUserIds);
    });
  });
}

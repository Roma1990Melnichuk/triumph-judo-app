import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/competition_result_model.dart';

CompetitionResultModel makeResult({
  String id = 'res1',
  String childId = 'child1',
  String childName = 'Іван Тест',
  String competitionName = 'Київський турнір',
  String competitionType = 'open',
  CompetitionLevel level = CompetitionLevel.regional,
  int place = 1,
  int points = 100,
  DateTime? date,
  int seasonYear = 2026,
  String addedByCoachId = 'coach1',
  String? clubId,
  String? ruleSetVersion,
}) =>
    CompetitionResultModel(
      id: id,
      childId: childId,
      childName: childName,
      competitionName: competitionName,
      competitionType: competitionType,
      level: level,
      place: place,
      points: points,
      date: date ?? DateTime(2026, 5, 1),
      seasonYear: seasonYear,
      addedByCoachId: addedByCoachId,
      clubId: clubId,
      ruleSetVersion: ruleSetVersion,
    );

void main() {
  // ── CompetitionLevelX.displayName ─────────────────────────────────────────

  group('CompetitionLevelX.displayName', () {
    final cases = {
      CompetitionLevel.club:          'Клубний',
      CompetitionLevel.local:         'Міський',
      CompetitionLevel.district:      'Районний',
      CompetitionLevel.regional:      'Обласний',
      CompetitionLevel.national:      'Всеукраїнський',
      CompetitionLevel.european:      'Чемпіонат Європи',
      CompetitionLevel.world:         'Чемпіонат Світу',
      CompetitionLevel.international: 'Міжнародний',
    };

    cases.forEach((level, name) {
      test('$level → $name', () => expect(level.displayName, name));
    });
  });

  // ── CompetitionLevelX.fromString ──────────────────────────────────────────

  group('CompetitionLevelX.fromString', () {
    test('розпізнає всі валідні значення', () {
      for (final level in CompetitionLevel.values) {
        expect(CompetitionLevelX.fromString(level.name), level);
      }
    });

    test('невідоме значення → local (fallback)', () {
      expect(CompetitionLevelX.fromString('unknown'), CompetitionLevel.local);
      expect(CompetitionLevelX.fromString(''), CompetitionLevel.local);
    });
  });

  // ── toFirestore ───────────────────────────────────────────────────────────

  group('CompetitionResultModel.toFirestore', () {
    test('містить всі обов\'язкові поля', () {
      final map = makeResult().toFirestore();
      expect(map['childId'], 'child1');
      expect(map['childName'], 'Іван Тест');
      expect(map['competitionName'], 'Київський турнір');
      expect(map['competitionType'], 'open');
      expect(map['level'], 'regional');
      expect(map['place'], 1);
      expect(map['points'], 100);
      expect(map['seasonYear'], 2026);
      expect(map['addedByCoachId'], 'coach1');
    });

    test('date серіалізується як Timestamp', () {
      final map = makeResult(date: DateTime(2026, 3, 10)).toFirestore();
      expect(map['date'], isA<Timestamp>());
      expect((map['date'] as Timestamp).toDate(), DateTime(2026, 3, 10));
    });

    test('clubId відсутній коли null', () {
      expect(makeResult().toFirestore().containsKey('clubId'), isFalse);
    });

    test('clubId присутній коли вказаний', () {
      final map = makeResult(clubId: 'club42').toFirestore();
      expect(map['clubId'], 'club42');
    });

    test('ruleSetVersion відсутній коли null', () {
      expect(makeResult().toFirestore().containsKey('ruleSetVersion'), isFalse);
    });

    test('ruleSetVersion присутній коли вказаний', () {
      final map = makeResult(ruleSetVersion: 'v2').toFirestore();
      expect(map['ruleSetVersion'], 'v2');
    });

    test('level серіалізується як рядок (name)', () {
      final map = makeResult(level: CompetitionLevel.national).toFirestore();
      expect(map['level'], 'national');
    });
  });

  // ── fromFirestore ─────────────────────────────────────────────────────────

  group('CompetitionResultModel.fromFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;
    setUp(() => fakeFirestore = FakeFirebaseFirestore());

    test('зчитує всі поля коректно', () async {
      final ref = fakeFirestore.collection('competition_results').doc('r1');
      await ref.set({
        'childId': 'c1',
        'childName': 'Марія',
        'competitionName': 'Чемпіонат України',
        'competitionType': 'kata',
        'level': 'national',
        'place': 2,
        'points': 75,
        'date': Timestamp.fromDate(DateTime(2026, 4, 20)),
        'seasonYear': 2026,
        'addedByCoachId': 'coach1',
        'clubId': 'clubX',
        'ruleSetVersion': 'v1',
      });
      final r = CompetitionResultModel.fromFirestore(await ref.get());
      expect(r.childId, 'c1');
      expect(r.childName, 'Марія');
      expect(r.level, CompetitionLevel.national);
      expect(r.place, 2);
      expect(r.points, 75);
      expect(r.clubId, 'clubX');
      expect(r.ruleSetVersion, 'v1');
      expect(r.date, DateTime(2026, 4, 20));
    });

    test('відсутні поля — значення за замовчуванням', () async {
      final ref = fakeFirestore.collection('competition_results').doc('empty');
      await ref.set(<String, dynamic>{});
      final r = CompetitionResultModel.fromFirestore(await ref.get());
      expect(r.childId, '');
      expect(r.level, CompetitionLevel.local);
      expect(r.place, 1);
      expect(r.points, 0);
      expect(r.competitionType, '');
      expect(r.clubId, isNull);
      expect(r.ruleSetVersion, isNull);
    });

    test('place та points як double конвертуються в int', () async {
      final ref = fakeFirestore.collection('competition_results').doc('numconv');
      await ref.set({
        'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'place': 3.0,
        'points': 50.0,
        'seasonYear': 2026.0,
      });
      final r = CompetitionResultModel.fromFirestore(await ref.get());
      expect(r.place, 3);
      expect(r.points, 50);
      expect(r.seasonYear, 2026);
    });
  });

  // ── round-trip ────────────────────────────────────────────────────────────

  group('CompetitionResultModel — round-trip', () {
    test('toFirestore → fromFirestore зберігає всі поля', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final original = makeResult(
        id: 'rt1',
        level: CompetitionLevel.world,
        place: 3,
        points: 200,
        date: DateTime(2026, 7, 4),
        clubId: 'club1',
        ruleSetVersion: 'v2',
      );
      await fakeFirestore
          .collection('competition_results')
          .doc('rt1')
          .set(original.toFirestore());
      final doc = await fakeFirestore.collection('competition_results').doc('rt1').get();
      final restored = CompetitionResultModel.fromFirestore(doc);
      expect(restored.level, original.level);
      expect(restored.place, original.place);
      expect(restored.points, original.points);
      expect(restored.date, original.date);
      expect(restored.clubId, original.clubId);
      expect(restored.ruleSetVersion, original.ruleSetVersion);
    });
  });
}

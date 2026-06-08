import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/training_session_model.dart';

TrainingSessionModel makeSession({
  String id = 'sched1_2026-06-01',
  String scheduleId = 'sched1',
  String coachId = 'coach1',
  DateTime? date,
  Map<String, bool> attendance = const {},
}) =>
    TrainingSessionModel(
      id: id,
      scheduleId: scheduleId,
      coachId: coachId,
      date: date ?? DateTime(2026, 6, 1),
      attendance: attendance,
    );

void main() {
  // ── makeId ────────────────────────────────────────────────────────────────

  group('TrainingSessionModel.makeId', () {
    test('формат: scheduleId_YYYY-MM-DD', () {
      expect(
        TrainingSessionModel.makeId('sched1', DateTime(2026, 6, 1)),
        'sched1_2026-06-01',
      );
    });

    test('однозначні місяць та день доповнюються нулем', () {
      expect(
        TrainingSessionModel.makeId('s', DateTime(2026, 3, 9)),
        's_2026-03-09',
      );
    });
  });

  // ── isPresent ─────────────────────────────────────────────────────────────

  group('TrainingSessionModel.isPresent', () {
    test('true коли childId відсутній у map (default = присутній)', () {
      expect(makeSession().isPresent('anyChild'), isTrue);
    });

    test('true коли attendance[childId] = true', () {
      expect(makeSession(attendance: {'c1': true}).isPresent('c1'), isTrue);
    });

    test('false коли attendance[childId] = false', () {
      expect(makeSession(attendance: {'c1': false}).isPresent('c1'), isFalse);
    });

    test('не впливає на інших дітей', () {
      final s = makeSession(attendance: {'c1': false, 'c2': true});
      expect(s.isPresent('c1'), isFalse);
      expect(s.isPresent('c2'), isTrue);
      expect(s.isPresent('c3'), isTrue); // відсутній у map → присутній
    });
  });

  // ── toFirestore ───────────────────────────────────────────────────────────

  group('TrainingSessionModel.toFirestore', () {
    test('містить scheduleId, coachId, date, attendance', () {
      final map = makeSession(attendance: {'c1': true, 'c2': false}).toFirestore();
      expect(map['scheduleId'], 'sched1');
      expect(map['coachId'], 'coach1');
      expect(map['attendance'], {'c1': true, 'c2': false});
      expect(map['date'], isA<Timestamp>());
    });

    test('date серіалізується коректно', () {
      final map = makeSession(date: DateTime(2026, 11, 20)).toFirestore();
      expect((map['date'] as Timestamp).toDate(), DateTime(2026, 11, 20));
    });

    test('порожня map attendance серіалізується як {}', () {
      expect(makeSession().toFirestore()['attendance'], <String, bool>{});
    });
  });

  // ── fromFirestore ─────────────────────────────────────────────────────────

  group('TrainingSessionModel.fromFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;
    setUp(() => fakeFirestore = FakeFirebaseFirestore());

    test('зчитує всі поля коректно', () async {
      final ref = fakeFirestore.collection('training_sessions').doc('s1_2026-06-01');
      await ref.set({
        'scheduleId': 's1',
        'coachId': 'coach42',
        'date': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'attendance': {'c1': true, 'c2': false, 'c3': true},
      });
      final session = TrainingSessionModel.fromFirestore(await ref.get());
      expect(session.scheduleId, 's1');
      expect(session.coachId, 'coach42');
      expect(session.attendance['c1'], isTrue);
      expect(session.attendance['c2'], isFalse);
      expect(session.date, DateTime(2026, 6, 1));
    });

    test('відсутні поля — значення за замовчуванням', () async {
      final ref = fakeFirestore.collection('training_sessions').doc('empty');
      await ref.set(<String, dynamic>{});
      final session = TrainingSessionModel.fromFirestore(await ref.get());
      expect(session.scheduleId, '');
      expect(session.coachId, '');
      expect(session.attendance, isEmpty);
    });
  });

  // ── round-trip ────────────────────────────────────────────────────────────

  group('TrainingSessionModel — round-trip', () {
    test('toFirestore → fromFirestore зберігає всі поля', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final original = makeSession(
        id: 'sched2_2026-09-15',
        scheduleId: 'sched2',
        date: DateTime(2026, 9, 15),
        attendance: {'kid1': true, 'kid2': false},
      );
      final ref = fakeFirestore
          .collection('training_sessions')
          .doc('sched2_2026-09-15');
      await ref.set(original.toFirestore());
      final restored = TrainingSessionModel.fromFirestore(await ref.get());
      expect(restored.scheduleId, original.scheduleId);
      expect(restored.date, original.date);
      expect(restored.attendance, original.attendance);
      expect(restored.isPresent('kid1'), isTrue);
      expect(restored.isPresent('kid2'), isFalse);
    });
  });
}

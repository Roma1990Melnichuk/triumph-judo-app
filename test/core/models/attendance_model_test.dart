import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/attendance_model.dart';

AttendanceModel makeAttendance({
  String id = 'group1_2026-06-01',
  String groupId = 'group1',
  String coachId = 'coach1',
  DateTime? date,
  List<String> absentChildIds = const [],
}) =>
    AttendanceModel(
      id: id,
      groupId: groupId,
      coachId: coachId,
      date: date ?? DateTime(2026, 6, 1),
      absentChildIds: absentChildIds,
    );

void main() {
  // ── isPresent ─────────────────────────────────────────────────────────────

  group('AttendanceModel.isPresent', () {
    test('true для дитини, якої немає у списку відсутніх', () {
      final a = makeAttendance(absentChildIds: ['c2', 'c3']);
      expect(a.isPresent('c1'), isTrue);
    });

    test('false для дитини у списку відсутніх', () {
      final a = makeAttendance(absentChildIds: ['c1', 'c2']);
      expect(a.isPresent('c1'), isFalse);
    });

    test('true коли список відсутніх порожній', () {
      expect(makeAttendance().isPresent('anyone'), isTrue);
    });
  });

  // ── makeId ────────────────────────────────────────────────────────────────

  group('AttendanceModel.makeId', () {
    test('формат: groupId_YYYY-MM-DD', () {
      expect(AttendanceModel.makeId('group42', DateTime(2026, 6, 1)), 'group42_2026-06-01');
    });

    test('місяць і день з нулем', () {
      expect(AttendanceModel.makeId('g1', DateTime(2026, 1, 5)), 'g1_2026-01-05');
    });

    test('кінець року', () {
      expect(AttendanceModel.makeId('grp', DateTime(2025, 12, 31)), 'grp_2025-12-31');
    });
  });

  // ── dateKey ───────────────────────────────────────────────────────────────

  group('AttendanceModel.dateKey', () {
    test('формат YYYY-MM-DD', () {
      expect(AttendanceModel.dateKey(DateTime(2026, 6, 1)), '2026-06-01');
    });

    test('однозначні місяць та день мають нуль', () {
      expect(AttendanceModel.dateKey(DateTime(2026, 3, 7)), '2026-03-07');
    });
  });

  // ── toFirestore ───────────────────────────────────────────────────────────

  group('AttendanceModel.toFirestore', () {
    test('містить groupId, coachId, date, absentChildIds', () {
      final map = makeAttendance(absentChildIds: ['c5']).toFirestore();
      expect(map['groupId'], 'group1');
      expect(map['coachId'], 'coach1');
      expect(map['absentChildIds'], ['c5']);
      expect(map['date'], isA<Timestamp>());
    });

    test('date серіалізується коректно', () {
      final map = makeAttendance(date: DateTime(2026, 9, 15)).toFirestore();
      expect((map['date'] as Timestamp).toDate(), DateTime(2026, 9, 15));
    });
  });

  // ── fromFirestore ─────────────────────────────────────────────────────────

  group('AttendanceModel.fromFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;
    setUp(() => fakeFirestore = FakeFirebaseFirestore());

    test('зчитує всі поля коректно', () async {
      final ref = fakeFirestore.collection('attendance').doc('g1_2026-06-01');
      await ref.set({
        'groupId': 'g1',
        'coachId': 'coach42',
        'date': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'absentChildIds': ['child2', 'child5'],
      });
      final a = AttendanceModel.fromFirestore(await ref.get());
      expect(a.id, 'g1_2026-06-01');
      expect(a.groupId, 'g1');
      expect(a.coachId, 'coach42');
      expect(a.absentChildIds, ['child2', 'child5']);
      expect(a.date, DateTime(2026, 6, 1));
    });

    test('відсутні поля — значення за замовчуванням', () async {
      final ref = fakeFirestore.collection('attendance').doc('empty');
      await ref.set(<String, dynamic>{});
      final a = AttendanceModel.fromFirestore(await ref.get());
      expect(a.groupId, '');
      expect(a.coachId, '');
      expect(a.absentChildIds, isEmpty);
    });
  });

  // ── round-trip ────────────────────────────────────────────────────────────

  group('AttendanceModel — round-trip', () {
    test('toFirestore → fromFirestore зберігає всі поля', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final original = makeAttendance(
        id: 'g2_2026-09-10',
        groupId: 'g2',
        coachId: 'c1',
        date: DateTime(2026, 9, 10),
        absentChildIds: ['kid1', 'kid3'],
      );
      final ref = fakeFirestore.collection('attendance').doc('g2_2026-09-10');
      await ref.set(original.toFirestore());
      final restored = AttendanceModel.fromFirestore(await ref.get());
      expect(restored.groupId, original.groupId);
      expect(restored.coachId, original.coachId);
      expect(restored.date, original.date);
      expect(restored.absentChildIds, original.absentChildIds);
      expect(restored.isPresent('kid1'), isFalse);
      expect(restored.isPresent('kid2'), isTrue);
    });
  });
}

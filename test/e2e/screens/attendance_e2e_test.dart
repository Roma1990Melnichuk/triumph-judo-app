/// TC-ATTEND — Дві системи відвідуваності: A (schedule-based) і B (group-based).
///
/// Система A — ScheduleNotifier.toggleAttendance:
///   - записує в sessions/{scheduleId}_{date} → attendance.{childId} = bool
///   - відсутній ключ child у attendance = присутній (true за замовчуванням)
///
/// Система B — GroupNotifier.toggleAbsence:
///   - записує в attendance/{groupId}_{date} → absentChildIds: arrayUnion/arrayRemove
///   - перший запис дня інкрементує sessionsUsed для присутніх
///   - повторний виклик в той же день НЕ інкрементує sessionsUsed повторно
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/attendance_model.dart';
import 'package:judo_app/core/models/training_schedule_model.dart';
import 'package:judo_app/core/models/training_session_model.dart';
import 'package:judo_app/features/schedule/providers/group_provider.dart';
import 'package:judo_app/features/schedule/providers/schedule_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

final _date = DateTime(2026, 6, 16);
const _scheduleId = 'schedule1';
const _groupId = 'group1';
const _child1 = 'child1';
const _child2 = 'child2';
const _coachId = 'coach1';

// A minimal TrainingScheduleModel for tests
final _schedule = TrainingScheduleModel(
  id: _scheduleId,
  coachId: _coachId,
  label: 'Тест',
  daysOfWeek: const [1, 3, 5],
  timeStart: '18:00',
  timeEnd: '19:30',
);

// Session doc ID format: {scheduleId}_{YYYY-MM-DD}
String _sessionId(String scheduleId, DateTime date) =>
    TrainingSessionModel.makeId(scheduleId, date);

// Attendance doc ID format: {groupId}_{YYYY-MM-DD}
String _attendanceId(String groupId, DateTime date) =>
    AttendanceModel.makeId(groupId, date);

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── TC-ATTEND-001: Система A — toggleAttendance записує в Firestore ────────

  group('TC-ATTEND-001: ScheduleNotifier.toggleAttendance записує attendance', () {
    test('present=true → attendance.$_child1 = true в сесії', () async {
      final db = _db();
      final notifier = ScheduleNotifier(db);

      await notifier.toggleAttendance(
        schedule: _schedule,
        date: _date,
        childId: _child1,
        present: true,
        coachId: _coachId,
      );

      final docId = _sessionId(_scheduleId, _date);
      final doc = await db.collection('training_sessions').doc(docId).get();
      expect(doc.exists, isTrue);

      final attendance = doc.data()?['attendance'] as Map<String, dynamic>?;
      expect(attendance?[_child1], isTrue);
    });

    test('present=false → attendance.$_child1 = false в сесії', () async {
      final db = _db();
      final notifier = ScheduleNotifier(db);

      await notifier.toggleAttendance(
        schedule: _schedule,
        date: _date,
        childId: _child1,
        present: false,
        coachId: _coachId,
      );

      final docId = _sessionId(_scheduleId, _date);
      final doc = await db.collection('training_sessions').doc(docId).get();

      final attendance = doc.data()?['attendance'] as Map<String, dynamic>?;
      expect(attendance?[_child1], isFalse);
    });

    test('декілька дітей — кожен записується окремо в одній сесії', () async {
      final db = _db();
      final notifier = ScheduleNotifier(db);

      await notifier.toggleAttendance(
        schedule: _schedule, date: _date,
        childId: _child1, present: true, coachId: _coachId,
      );
      await notifier.toggleAttendance(
        schedule: _schedule, date: _date,
        childId: _child2, present: false, coachId: _coachId,
      );

      final doc = await db
          .collection('training_sessions')
          .doc(_sessionId(_scheduleId, _date))
          .get();

      final att = doc.data()?['attendance'] as Map<String, dynamic>?;
      expect(att?[_child1], isTrue);
      expect(att?[_child2], isFalse);
    });

    test('різні дати → різні документи сесій', () async {
      final db = _db();
      final notifier = ScheduleNotifier(db);
      final date2 = DateTime(2026, 6, 17);

      await notifier.toggleAttendance(
        schedule: _schedule, date: _date,
        childId: _child1, present: true, coachId: _coachId,
      );
      await notifier.toggleAttendance(
        schedule: _schedule, date: date2,
        childId: _child1, present: false, coachId: _coachId,
      );

      final id1 = _sessionId(_scheduleId, _date);
      final id2 = _sessionId(_scheduleId, date2);
      expect(id1, isNot(id2));

      final doc1 = await db.collection('training_sessions').doc(id1).get();
      final doc2 = await db.collection('training_sessions').doc(id2).get();

      expect(doc1.data()?['attendance'][_child1], isTrue);
      expect(doc2.data()?['attendance'][_child1], isFalse);
    });

    test('зміна з false → true оновлює існуючий запис', () async {
      final db = _db();
      final notifier = ScheduleNotifier(db);

      await notifier.toggleAttendance(
        schedule: _schedule, date: _date,
        childId: _child1, present: false, coachId: _coachId,
      );
      await notifier.toggleAttendance(
        schedule: _schedule, date: _date,
        childId: _child1, present: true, coachId: _coachId,
      );

      final doc = await db
          .collection('training_sessions')
          .doc(_sessionId(_scheduleId, _date))
          .get();
      expect(doc.data()?['attendance'][_child1], isTrue);
    });
  });

  // ── TC-ATTEND-002: TrainingSessionModel.isPresent — відсутній ключ = true ──

  group('TC-ATTEND-002: TrainingSessionModel.isPresent — відсутній ключ = присутній', () {
    test('ключа childId немає → isPresent = true', () {
      final session = TrainingSessionModel(
        id: 's1',
        scheduleId: _scheduleId,
        date: _date,
        attendance: {}, // empty — no record for any child
        coachId: _coachId,
      );
      expect(session.isPresent(_child1), isTrue,
          reason: 'Відсутній запис означає присутність');
    });

    test('attendance[childId] = true → isPresent = true', () {
      final session = TrainingSessionModel(
        id: 's1',
        scheduleId: _scheduleId,
        date: _date,
        attendance: {_child1: true},
        coachId: _coachId,
      );
      expect(session.isPresent(_child1), isTrue);
    });

    test('attendance[childId] = false → isPresent = false', () {
      final session = TrainingSessionModel(
        id: 's1',
        scheduleId: _scheduleId,
        date: _date,
        attendance: {_child1: false},
        coachId: _coachId,
      );
      expect(session.isPresent(_child1), isFalse);
    });
  });

  // ── TC-ATTEND-003: Система B — toggleAbsence (arrayUnion/arrayRemove) ─────

  group('TC-ATTEND-003: GroupNotifier.toggleAbsence — додає/видаляє дитину', () {
    test('absent=true → childId додається в absentChildIds', () async {
      final db = _db();
      final notifier = GroupNotifier(db);

      await notifier.toggleAbsence(
        groupId: _groupId,
        coachId: _coachId,
        date: _date,
        childId: _child1,
        absent: true,
      );

      final docId = _attendanceId(_groupId, _date);
      final doc = await db.collection('attendance').doc(docId).get();
      expect(doc.exists, isTrue);

      final absentIds =
          List<String>.from(doc.data()?['absentChildIds'] ?? []);
      expect(absentIds, contains(_child1));
    });

    test('absent=false → childId видаляється з absentChildIds', () async {
      final db = _db();
      final notifier = GroupNotifier(db);

      // First mark absent
      await notifier.toggleAbsence(
        groupId: _groupId, coachId: _coachId, date: _date,
        childId: _child1, absent: true,
      );

      // Then unmark
      await notifier.toggleAbsence(
        groupId: _groupId, coachId: _coachId, date: _date,
        childId: _child1, absent: false,
      );

      final doc = await db
          .collection('attendance')
          .doc(_attendanceId(_groupId, _date))
          .get();

      final absentIds =
          List<String>.from(doc.data()?['absentChildIds'] ?? []);
      expect(absentIds, isNot(contains(_child1)));
    });

    test('2 дитини відсутні → обидва в absentChildIds', () async {
      final db = _db();
      final notifier = GroupNotifier(db);

      await notifier.toggleAbsence(
        groupId: _groupId, coachId: _coachId, date: _date,
        childId: _child1, absent: true,
      );
      await notifier.toggleAbsence(
        groupId: _groupId, coachId: _coachId, date: _date,
        childId: _child2, absent: true,
      );

      final doc = await db
          .collection('attendance')
          .doc(_attendanceId(_groupId, _date))
          .get();

      final absentIds =
          List<String>.from(doc.data()?['absentChildIds'] ?? []);
      expect(absentIds, containsAll([_child1, _child2]));
    });

    test('різні групи → різні документи відвідуваності', () async {
      final db = _db();
      final notifier = GroupNotifier(db);

      await notifier.toggleAbsence(
        groupId: 'group1', coachId: _coachId, date: _date,
        childId: _child1, absent: true,
      );
      await notifier.toggleAbsence(
        groupId: 'group2', coachId: _coachId, date: _date,
        childId: _child1, absent: true,
      );

      final id1 = _attendanceId('group1', _date);
      final id2 = _attendanceId('group2', _date);
      expect(id1, isNot(id2));

      final docs = await db.collection('attendance').get();
      expect(docs.docs.map((d) => d.id).toSet(), containsAll([id1, id2]));
    });
  });

  // ── TC-ATTEND-004: AttendanceModel.isPresent ──────────────────────────────

  group('TC-ATTEND-004: AttendanceModel.isPresent логіка', () {
    test('дитина не в absentChildIds → isPresent = true', () {
      final model = AttendanceModel(
        id: 'a1',
        groupId: _groupId,
        date: _date,
        coachId: _coachId,
        absentChildIds: [_child2], // child1 is NOT absent
      );
      expect(model.isPresent(_child1), isTrue);
    });

    test('дитина в absentChildIds → isPresent = false', () {
      final model = AttendanceModel(
        id: 'a1',
        groupId: _groupId,
        date: _date,
        coachId: _coachId,
        absentChildIds: [_child1],
      );
      expect(model.isPresent(_child1), isFalse);
    });

    test('порожній absentChildIds → всі присутні', () {
      final model = AttendanceModel(
        id: 'a1',
        groupId: _groupId,
        date: _date,
        coachId: _coachId,
        absentChildIds: [],
      );
      expect(model.isPresent(_child1), isTrue);
      expect(model.isPresent(_child2), isTrue);
    });
  });

  // ── TC-ATTEND-005: makeId форматування ─────────────────────────────────────

  group('TC-ATTEND-005: makeId форматування ID документів', () {
    test('AttendanceModel.makeId → "{groupId}_{YYYY-MM-DD}"', () {
      final id = AttendanceModel.makeId('group1', DateTime(2026, 6, 5));
      expect(id, equals('group1_2026-06-05'));
    });

    test('TrainingSessionModel.makeId → "{scheduleId}_{YYYY-MM-DD}"', () {
      final id = TrainingSessionModel.makeId('sched1', DateTime(2026, 12, 1));
      expect(id, equals('sched1_2026-12-01'));
    });

    test('AttendanceModel.makeId — день < 10 доповнюється нулем', () {
      final id = AttendanceModel.makeId('g1', DateTime(2026, 1, 3));
      expect(id, equals('g1_2026-01-03'));
    });

    test('TrainingSessionModel.makeId — місяць < 10 доповнюється нулем', () {
      final id = TrainingSessionModel.makeId('s1', DateTime(2026, 3, 15));
      expect(id, equals('s1_2026-03-15'));
    });
  });

  // ── TC-ATTEND-006: setAbsences — перший запис дня ─────────────────────────

  group('TC-ATTEND-006: setAbsences — absentChildIds зберігається', () {
    test('setAbsences → документ в attendance з правильним absentChildIds', () async {
      final db = _db();
      final notifier = GroupNotifier(db);

      await notifier.setAbsences(
        groupId: _groupId,
        coachId: _coachId,
        date: _date,
        absentChildIds: [_child2], // child2 absent, child1 present
      );

      final attDoc = await db
          .collection('attendance')
          .doc(_attendanceId(_groupId, _date))
          .get();
      expect(attDoc.exists, isTrue);
      final absentIds =
          List<String>.from(attDoc.data()?['absentChildIds'] ?? []);
      expect(absentIds, contains(_child2));
      expect(absentIds, isNot(contains(_child1)));
    });

    test('другий виклик setAbsences в той самий день — оновлює 1 документ', () async {
      final db = _db();
      final notifier = GroupNotifier(db);

      // First call
      await notifier.setAbsences(
        groupId: _groupId,
        coachId: _coachId,
        date: _date,
        absentChildIds: [_child2],
      );
      // Second call same day (coach edits)
      await notifier.setAbsences(
        groupId: _groupId,
        coachId: _coachId,
        date: _date,
        absentChildIds: [_child1], // now child1 absent instead
      );

      // Only 1 document should exist for that day
      final snap = await db
          .collection('attendance')
          .where('groupId', isEqualTo: _groupId)
          .get();
      expect(snap.docs, hasLength(1),
          reason: 'Повторний виклик оновлює той самий документ, не створює новий');

      final absentIds =
          List<String>.from(snap.docs.first.data()['absentChildIds'] ?? []);
      expect(absentIds, contains(_child1),
          reason: 'Другий виклик перезаписує absentChildIds');
    });
  });
}

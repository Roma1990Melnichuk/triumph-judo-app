import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/group_model.dart';
import '../../../core/models/attendance_model.dart';
import '../../achievements/achievement_checker.dart';
import '../../auth/providers/auth_provider.dart';

// All groups (all coaches)
final groupsProvider = StreamProvider<List<GroupModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('groups')
      .snapshots()
      .map((s) => s.docs.map(GroupModel.fromFirestore).toList())
      .handleError((_) {});
});

// Groups that contain a specific child
final childGroupsProvider =
    Provider.family<List<GroupModel>, String>((ref, childId) {
  return ref
          .watch(groupsProvider)
          .asData
          ?.value
          .where((g) => g.childIds.contains(childId))
          .toList() ??
      [];
});

// Attendance records for a specific child's groups in a season
// Returns Map<"YYYY-MM-DD", bool> where bool = isPresent
final childAttendanceMapProvider = StreamProvider.family<Map<String, bool>,
    ({String childId, List<String> groupIds, int seasonYear})>((ref, args) async* {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null || args.groupIds.isEmpty) {
    yield {};
    return;
  }

  final seasonStart = DateTime(args.seasonYear, 9, 1);
  final seasonEnd = DateTime(args.seasonYear + 1, 7, 31, 23, 59, 59);

  // Listen to attendance docs for all groups (Firestore "in" supports up to 30 values)
  final groupIds = args.groupIds.take(10).toList(); // limit for "in" query
  final stream = ref
      .watch(firestoreProvider)
      .collection('attendance')
      .where('groupId', whereIn: groupIds)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(seasonStart))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(seasonEnd))
      .snapshots();

  await for (final snap in stream) {
    final records = snap.docs.map(AttendanceModel.fromFirestore).toList();
    // Build a map of dateKey → isPresent
    final map = <String, bool>{};
    for (final rec in records) {
      final key = AttendanceModel.dateKey(rec.date);
      // If child is in absent list → false; otherwise don't set (default = present)
      if (!rec.isPresent(args.childId)) {
        map[key] = false;
      }
    }
    yield map;
  }
});

class GroupNotifier extends StateNotifier<AsyncValue<void>> {
  GroupNotifier(this._db) : super(const AsyncValue.data(null));
  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  Future<void> createGroup(GroupModel g) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final id = _uuid.v4();
      await _db.collection('groups').doc(id).set(g.toFirestore());
    });
  }

  Future<void> updateGroup(GroupModel g) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db.collection('groups').doc(g.id).set(g.toFirestore());
    });
  }

  Future<void> deleteGroup(String groupId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _db.collection('groups').doc(groupId).delete());
  }

  Future<void> addChildToGroup(String groupId, String childId) async {
    await _db.collection('groups').doc(groupId).update({
      'childIds': FieldValue.arrayUnion([childId]),
    });
  }

  Future<void> removeChildFromGroup(String groupId, String childId) async {
    await _db.collection('groups').doc(groupId).update({
      'childIds': FieldValue.arrayRemove([childId]),
    });
  }

  /// Called when a child's coach changes.
  /// Removes the child from ALL groups that belonged to [oldCoachId]
  /// so their calendar only reflects the new coach's schedule.
  Future<void> removeChildFromCoachGroups({
    required String childId,
    required String oldCoachId,
  }) async {
    final snap = await _db
        .collection('groups')
        .where('coachId', isEqualTo: oldCoachId)
        .where('childIds', arrayContains: childId)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'childIds': FieldValue.arrayRemove([childId]),
      });
    }
    await batch.commit();
  }

  /// Toggle child absence for a specific training date.
  Future<void> toggleAbsence({
    required String groupId,
    required String coachId,
    required DateTime date,
    required String childId,
    required bool absent,
  }) async {
    final docId = AttendanceModel.makeId(groupId, date);
    final ref = _db.collection('attendance').doc(docId);
    // Ensure doc exists
    await ref.set({
      'groupId': groupId,
      'coachId': coachId,
      'date': Timestamp.fromDate(date),
      'absentChildIds': <String>[],
    }, SetOptions(merge: true));

    if (absent) {
      await ref.update({'absentChildIds': FieldValue.arrayUnion([childId])});
    } else {
      await ref.update({'absentChildIds': FieldValue.arrayRemove([childId])});
    }
  }

  /// Set absence for multiple children at once (batch mark absent).
  Future<void> setAbsences({
    required String groupId,
    required String coachId,
    required DateTime date,
    required List<String> absentChildIds,
  }) async {
    final docId = AttendanceModel.makeId(groupId, date);
    final existingDoc = await _db.collection('attendance').doc(docId).get();
    final isFirstRecord = !existingDoc.exists;

    await _db.collection('attendance').doc(docId).set({
      'groupId': groupId,
      'coachId': coachId,
      'date': Timestamp.fromDate(date),
      'absentChildIds': absentChildIds,
    });
    _runSeasonalCheck(groupId, absentChildIds).ignore();
    if (isFirstRecord) {
      _runSessionIncrement(groupId, coachId, absentChildIds).ignore();
    }
  }

  Future<void> _runSeasonalCheck(
      String groupId, List<String> absentIds) async {
    final snap = await _db.collection('groups').doc(groupId).get();
    final allIds =
        List<String>.from(snap.data()?['childIds'] as List? ?? []);
    for (final childId in allIds) {
      if (!absentIds.contains(childId)) {
        await AchievementChecker.checkSeasonalDiscipline(childId, _db);
      }
    }
  }

  Future<void> _runSessionIncrement(
      String groupId, String coachId, List<String> absentIds) async {
    final snap = await _db.collection('groups').doc(groupId).get();
    final allIds =
        List<String>.from(snap.data()?['childIds'] as List? ?? []);
    final presentIds = allIds.where((id) => !absentIds.contains(id)).toList();

    for (final childId in presentIds) {
      final membershipDoc =
          await _db.collection('memberships').doc(childId).get();
      if (!membershipDoc.exists) continue;
      final data = membershipDoc.data()!;
      final totalSessions = data['totalSessions'] as int?;
      if (totalSessions == null) continue; // unlimited plan — skip

      final newUsed = ((data['sessionsUsed'] as num?)?.toInt() ?? 0) + 1;
      await _db
          .collection('memberships')
          .doc(childId)
          .update({'sessionsUsed': newUsed});

      final remaining = totalSessions - newUsed;
      if (remaining == 5) {
        await _db.collection('notifications').add({
          'title': 'Абонемент закінчується',
          'body':
              'На балансі залишилось 5 тренувань. Зверніться до тренера для поповнення абонементу.',
          'target': 'personal',
          'targetValues': [childId],
          'sentAt': Timestamp.fromDate(DateTime.now()),
          'coachId': coachId,
          'coachName': '',
          'readByUserIds': <String>[],
        });
      }
    }
  }
}

final groupNotifierProvider =
    StateNotifierProvider<GroupNotifier, AsyncValue<void>>(
        (ref) => GroupNotifier(ref.watch(firestoreProvider)));

// ── Attendance stats for a child (% presence this season) ────────────────────
// Returns (total training days up to today, present count, percentage 0–100)
final childAttendanceStatsProvider =
    StreamProvider.family<({int total, int present, double pct}), String>(
        (ref, childId) async* {
  final groups = ref.watch(childGroupsProvider(childId));
  if (groups.isEmpty) {
    yield (total: 0, present: 0, pct: 0);
    return;
  }

  // Determine current season year (Sep–Jul)
  final now = DateTime.now();
  final seasonYear = now.month >= 9 ? now.year : now.year - 1;
  final seasonStart = DateTime(seasonYear, 9, 1);
  final today = DateTime(now.year, now.month, now.day);

  // All expected training dates up to today across child's groups (deduplicated)
  final allTrainingDates = <DateTime>{};
  for (final g in groups) {
    for (final d in g.trainingDates(seasonYear)) {
      if (!d.isAfter(today)) allTrainingDates.add(d);
    }
  }

  if (allTrainingDates.isEmpty) {
    yield (total: 0, present: 0, pct: 0);
    return;
  }

  final groupIds = groups.map((g) => g.id).toList();
  final db = ref.watch(firestoreProvider);

  final stream = db
      .collection('attendance')
      .where('groupId', whereIn: groupIds.take(10).toList())
      .where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(seasonStart))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(today))
      .snapshots();

  await for (final snap in stream) {
    final absentDates = <String>{};
    for (final doc in snap.docs) {
      final rec = AttendanceModel.fromFirestore(doc);
      if (!rec.isPresent(childId)) {
        absentDates.add(AttendanceModel.dateKey(rec.date));
      }
    }
    final total = allTrainingDates.length;
    final absent =
        allTrainingDates.where((d) => absentDates.contains(AttendanceModel.dateKey(d))).length;
    final present = total - absent;
    final pct = total > 0 ? (present / total * 100) : 0.0;
    yield (total: total, present: present, pct: pct);
  }
});

// Stream attendance doc for one group+date (for real-time UI)
final attendanceDocProvider =
    StreamProvider.family<AttendanceModel?, String>((ref, docId) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('attendance')
      .doc(docId)
      .snapshots()
      .map((d) => d.exists ? AttendanceModel.fromFirestore(d) : null)
      .handleError((_) {});
});

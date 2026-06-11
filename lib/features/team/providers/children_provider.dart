import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/child_model.dart';
import '../../../core/models/membership_model.dart';
export '../../../core/models/child_model.dart' show Gender;
import '../../auth/providers/auth_provider.dart';
import '../../achievements/achievement_checker.dart';
import '../../membership/providers/membership_provider.dart';
import '../services/csv_import_service.dart';

// ── Raw stream of all children sorted by lastName ──────────────────────────
final allChildrenProvider = StreamProvider<List<ChildModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('children')
      .orderBy('lastName')
      .limit(500)
      .snapshots()
      .map((s) => s.docs.map(ChildModel.fromFirestore).toList())
      .handleError((_) {});
});

// ── Filter state ────────────────────────────────────────────────────────────
class ChildrenFilter {
  final String lastName;
  final int? birthYear;
  final String? coachId;
  final BeltLevel? belt;
  final String? weightCategory;
  final Gender? gender;
  final bool beltReady;
  final MembershipStatus? membershipStatus;

  const ChildrenFilter({
    this.lastName = '',
    this.birthYear,
    this.coachId,
    this.belt,
    this.weightCategory,
    this.gender,
    this.beltReady = false,
    this.membershipStatus,
  });

  ChildrenFilter copyWith({
    String? lastName,
    int? birthYear,
    String? coachId,
    BeltLevel? belt,
    String? weightCategory,
    Gender? gender,
    bool? beltReady,
    MembershipStatus? membershipStatus,
    bool clearBirthYear = false,
    bool clearCoachId = false,
    bool clearBelt = false,
    bool clearWeightCategory = false,
    bool clearGender = false,
    bool clearMembershipStatus = false,
  }) =>
      ChildrenFilter(
        lastName: lastName ?? this.lastName,
        birthYear: clearBirthYear ? null : (birthYear ?? this.birthYear),
        coachId: clearCoachId ? null : (coachId ?? this.coachId),
        belt: clearBelt ? null : (belt ?? this.belt),
        weightCategory: clearWeightCategory ? null : (weightCategory ?? this.weightCategory),
        gender: clearGender ? null : (gender ?? this.gender),
        beltReady: beltReady ?? this.beltReady,
        membershipStatus: clearMembershipStatus ? null : (membershipStatus ?? this.membershipStatus),
      );
}

final childrenFilterProvider =
    StateProvider<ChildrenFilter>((ref) => const ChildrenFilter());

// ── Filtered list ───────────────────────────────────────────────────────────
final filteredChildrenProvider = Provider<List<ChildModel>>((ref) {
  final children = ref.watch(allChildrenProvider).value ?? [];
  final f = ref.watch(childrenFilterProvider);
  final membershipMap = ref.watch(membershipStatusMapProvider);

  final filtered = children.where((c) {
    if (f.lastName.isNotEmpty &&
        !c.lastName.toLowerCase().contains(f.lastName.toLowerCase()) &&
        !c.firstName.toLowerCase().contains(f.lastName.toLowerCase())) {
      return false;
    }
    if (f.birthYear != null && c.birthYear != f.birthYear) return false;
    if (f.coachId != null && c.coachName != f.coachId) return false;
    if (f.belt != null && c.currentBelt != f.belt) return false;
    if (f.weightCategory != null && c.weightCategory != f.weightCategory) return false;
    if (f.gender != null && c.gender != f.gender) return false;
    if (f.beltReady && !c.beltReady) return false;
    if (f.membershipStatus != null && membershipMap[c.id] != f.membershipStatus) return false;
    return true;
  }).toList();

  final allZero = filtered.every((c) => c.totalPoints == 0);
  if (allZero) {
    filtered.sort((a, b) => a.lastName.compareTo(b.lastName));
  } else {
    filtered.sort((a, b) {
      final cmp = b.totalPoints.compareTo(a.totalPoints);
      if (cmp != 0) return cmp;
      return a.lastName.compareTo(b.lastName);
    });
  }
  return filtered;
});

// ── Distinct coach list (grouped by coachName) ──────────────────────────────
final coachListProvider = Provider<List<({String id, String name})>>((ref) {
  final children = ref.watch(allChildrenProvider).value ?? [];
  final seen = <String>{};
  final result = <({String id, String name})>[];
  for (final c in children) {
    // Use coachName as unique key so virtual coaches (same coachId, diff name) appear separately
    if (seen.add(c.coachName)) {
      result.add((id: c.coachName, name: c.coachName));
    }
  }
  result.sort((a, b) => a.name.compareTo(b.name));
  return result;
});

// ── Distinct birth years ────────────────────────────────────────────────────
final birthYearsProvider = Provider<List<int>>((ref) {
  final children = ref.watch(allChildrenProvider).value ?? [];
  return children.map((c) => c.birthYear).toSet().toList()..sort();
});

// ── Count of children per birth year ────────────────────────────────────────
final birthYearCountsProvider = Provider<Map<int, int>>((ref) {
  final children = ref.watch(allChildrenProvider).value ?? [];
  final counts = <int, int>{};
  for (final c in children) {
    counts[c.birthYear] = (counts[c.birthYear] ?? 0) + 1;
  }
  return counts;
});

// ── Distinct weight categories present in DB ────────────────────────────────
final weightCategoriesProvider = Provider<List<String>>((ref) {
  final children = ref.watch(allChildrenProvider).value ?? [];
  final seen = <String>{};
  final result = <String>[];
  for (final c in children) {
    if (seen.add(c.weightCategory)) result.add(c.weightCategory);
  }
  // Sort by numeric value
  result.sort((a, b) {
    final aNum = int.tryParse(a.replaceAll(RegExp(r'[^\d]'), '')) ?? 999;
    final bNum = int.tryParse(b.replaceAll(RegExp(r'[^\d]'), '')) ?? 999;
    return aNum.compareTo(bNum);
  });
  return result;
});

// ── O(1) child lookup map ───────────────────────────────────────────────────
final childByIdMapProvider = Provider<Map<String, ChildModel>>((ref) {
  final children = ref.watch(allChildrenProvider).value ?? [];
  return {for (final c in children) c.id: c};
});

// ── Single child by ID ──────────────────────────────────────────────────────
final childByIdProvider =
    StreamProvider.family<ChildModel?, String>((ref, childId) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('children')
      .doc(childId)
      .snapshots()
      .map((doc) => doc.exists ? ChildModel.fromFirestore(doc) : null)
      .handleError((_) {});
});

// ── CRUD notifier ───────────────────────────────────────────────────────────
class ChildrenNotifier extends StateNotifier<AsyncValue<void>> {
  ChildrenNotifier(this._db) : super(const AsyncValue.data(null));

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  Future<void> addChild(ChildModel child) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db.collection('children').doc(child.id).set(child.toFirestore());
      AnalyticsService.childAdded();
    });
  }

  Future<void> updateChild(ChildModel child) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db.collection('children').doc(child.id).update(child.toFirestore());
      AnalyticsService.childUpdated();
    });
  }

  Future<void> deleteChild(String childId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final batch = _db.batch();
      batch.delete(_db.collection('children').doc(childId));

      // Delete competition results for this child
      final results = await _db
          .collection('competition_results')
          .where('childId', isEqualTo: childId)
          .get();
      for (final doc in results.docs) {
        batch.delete(doc.reference);
      }

      // Delete belt progress
      final progress = await _db
          .collection('belt_progress')
          .where('childId', isEqualTo: childId)
          .get();
      for (final doc in progress.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Revoke access: remove childId from all linked parent accounts
      final parentQuery = await _db
          .collection('users')
          .where('childIds', arrayContains: childId)
          .get();
      if (parentQuery.docs.isNotEmpty) {
        final parentBatch = _db.batch();
        for (final doc in parentQuery.docs) {
          final data = doc.data();
          final update = <String, dynamic>{
            'childIds': FieldValue.arrayRemove([childId]),
          };
          if (data['childId'] == childId) {
            update['childId'] = FieldValue.delete();
          }
          parentBatch.update(doc.reference, update);
        }
        await parentBatch.commit();
      }

    });
  }

  // ── Видалення всіх тестових даних ──────────────────────────────────────────
  Future<void> clearAllData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      for (final col in ['children', 'competition_results', 'belt_progress']) {
        QuerySnapshot snap;
        do {
          snap = await _db.collection(col).limit(400).get();
          if (snap.docs.isEmpty) break;
          final batch = _db.batch();
          for (final doc in snap.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        } while (snap.docs.length == 400);
      }
    });
  }

  Future<void> seedTestData(String currentCoachId, String currentCoachName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // 20 coaches × 50 athletes = 1000 total.
      // All use the real coachId (auth uid), varied coachName for filter testing.
      const coachNames = [
        'Мартін',   'Ростислав', 'Юлія',     'Ганна',
        'Олексій',  'Микола',    'Ірина',    'Тетяна',
        'Богдан',   'Сергій',    'Наталія',  'Оксана',
        'Василь',   'Андрій',    'Людмила',  'Катерина',
        'Дмитро',   'Павло',     'Вікторія', 'Яна',
      ];

      const maleNames = [
        'Олексій','Іван','Дмитро','Максим','Артем','Богдан','Владислав',
        'Андрій','Михайло','Тарас','Назар','Євген','Сергій','Юрій','Олег',
        'Василь','Павло','Роман','Степан','Ярослав','Кирило','Данило',
        'Ілля','Антон','Руслан',
      ];
      const femaleNames = [
        'Марія','Анна','Катерина','Олена','Юлія','Оксана','Тетяна',
        'Надія','Ірина','Людмила','Наталія','Вікторія','Аліна','Дарина',
        'Соломія','Христина','Уляна','Ніна','Галина','Лариса',
        'Лілія','Яна','Ольга','Поліна','Валерія',
      ];
      const lastNames = [
        'Коваленко','Петренко','Шевченко','Бондаренко','Мороз',
        'Лисенко','Кравченко','Тимошенко','Гриценко','Василенко',
        'Захаренко','Савченко','Іваненко','Романенко','Олексієнко',
        'Яценко','Ковальчук','Мельник','Дорошенко','Паращук',
        'Ільченко','Назаренко','Марченко','Горбань','Науменко',
        'Степаненко','Поліщук','Кириченко','Литвиненко','Власенко',
        'Мусієнко','Рибаченко','Тесленко','Даниленко','Харченко',
        'Бондар','Гавриленко','Нечипоренко','Пилипенко','Руденко',
        'Семенченко','Терещенко','Федоренко','Хоменко','Чорновіл',
        'Шульга','Сидоренко','Ляшенко','Коваль','Гнатенко',
      ];
      const maleWeights   = ['-30 кг','-32 кг','-36 кг','-40 кг','-44 кг','-50 кг','-55 кг','-60 кг','+60 кг'];
      const femaleWeights = ['-28 кг','-30 кг','-32 кг','-36 кг','-40 кг','-44 кг','-48 кг','+48 кг'];
      // Weighted pool: lower belts are more common (realistic club distribution).
      final belts = [
        BeltLevel.white, BeltLevel.white, BeltLevel.white,
        BeltLevel.whiteYellow, BeltLevel.whiteYellow,
        BeltLevel.yellow, BeltLevel.yellow,
        BeltLevel.yellowOrange,
        BeltLevel.orange, BeltLevel.orange,
        BeltLevel.orangeGreen,
        BeltLevel.green, BeltLevel.green,
        BeltLevel.greenBlue,
        BeltLevel.blue,
        BeltLevel.blueBrown,
        BeltLevel.brown,
        BeltLevel.black,
      ];
      const years   = [2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018];

      var batch = _db.batch();
      var count = 0;

      for (var ci = 0; ci < coachNames.length; ci++) {
        final cName = coachNames[ci];

        for (var i = 0; i < 50; i++) {
          final isMale  = i < 25;
          final gender  = isMale ? Gender.male : Gender.female;
          final fIdx    = i % (isMale ? maleNames.length : femaleNames.length);
          final lIdx    = (ci * 50 + i) % lastNames.length;
          final firstName = isMale ? maleNames[fIdx] : femaleNames[fIdx];
          final lastName  = lastNames[lIdx];
          final year      = years[(ci * 50 + i) % years.length];
          final weight    = isMale
              ? maleWeights[(ci * 50 + i) % maleWeights.length]
              : femaleWeights[(ci * 50 + i) % femaleWeights.length];
          final belt      = belts[(ci * 50 + i) % belts.length];
          // Realistic distribution: ~50% beginners (0–19), ~17% casual (20–65),
          // ~14% active (70–194), ~8% competitive (200–398), ~3% elite (450–675).
          final seed = ci * 50 + i;
          final points = seed % 33 == 0
              ? 450 + (seed ~/ 33) % 10 * 25
              : seed % 9 == 0
                  ? 200 + (seed ~/ 9)  % 12 * 18
                  : seed % 4 == 0
                      ? 70  + (seed ~/ 4)  % 18 * 7
                      : seed % 2 == 0
                          ? 20  + (seed ~/ 2)  % 16 * 3
                          : seed % 20;

          final id = _uuid.v4();
          batch.set(_db.collection('children').doc(id), {
            'firstName':    firstName,
            'lastName':     lastName,
            'birthYear':    year,
            'weightCategory': weight,
            'currentBelt':  belt.name,
            'gender':       gender.name,
            'coachId':      currentCoachId,   // реальний uid тренера
            'coachName':    cName,
            'totalPoints':  points,
            'createdAt':    FieldValue.serverTimestamp(),
          });
          count++;

          if (count % 400 == 0) {
            await batch.commit();
            batch = _db.batch();
          }
        }
      }
      if (count % 400 != 0) await batch.commit();
    });
  }

  Future<int> importFromCsv(
      List<CsvRow> rows, String coachId, String coachName) async {
    state = const AsyncValue.loading();
    try {
      const batchSize = 400;
      var batch = _db.batch();
      var batchCount = 0;

      for (final row in rows) {
        final id = _uuid.v4();
        batch.set(_db.collection('children').doc(id), {
          'firstName': row.firstName,
          'lastName': row.lastName,
          'birthYear': row.birthYear,
          'weightCategory': row.weightCategory,
          'currentBelt': row.belt.name,
          'coachId': coachId,
          'coachName': coachName,
          'totalPoints': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
        batchCount++;

        if (batchCount >= batchSize) {
          await batch.commit();
          batch = _db.batch();
          batchCount = 0;
        }
      }

      if (batchCount > 0) await batch.commit();
      state = const AsyncValue.data(null);
      return rows.length;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return 0;
    }
  }

  // Recalculate and update totalPoints cache (competition + bonus)
  Future<void> recalcPoints(String childId) async {
    final results = await _db
        .collection('competition_results')
        .where('childId', isEqualTo: childId)
        .get();
    final competitionPoints = results.docs
        .map((d) => (d.data()['points'] as num?)?.toInt() ?? 0)
        .fold(0, (a, b) => a + b);
    final childDoc = await _db.collection('children').doc(childId).get();
    final bonusPoints =
        (childDoc.data()?['bonusPoints'] as num?)?.toInt() ?? 0;
    await _db.collection('children').doc(childId).update({
      'totalPoints': competitionPoints + bonusPoints,
    });
  }

  /// Advance belt for multiple children and reset beltReady.
  Future<void> advanceBelts({
    required List<String> childIds,
    required BeltLevel newBelt,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      var batch = _db.batch();
      var count = 0;
      for (final id in childIds) {
        batch.update(_db.collection('children').doc(id), {
          'currentBelt': newBelt.name,
          'beltReady': false,
        });
        count++;
        if (count % 400 == 0) {
          await batch.commit();
          batch = _db.batch();
        }
      }
      if (count % 400 != 0) await batch.commit();
      // Auto-achievements for each athlete
      for (final id in childIds) {
        await AchievementChecker.onBeltAdvanced(id, newBelt, _db);
      }
    });
  }

  /// Set manual bonus points and refresh totalPoints.
  Future<void> setBonusPoints(String childId, int bonus) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final results = await _db
          .collection('competition_results')
          .where('childId', isEqualTo: childId)
          .get();
      final competitionPoints = results.docs
          .map((d) => (d.data()['points'] as num?)?.toInt() ?? 0)
          .fold(0, (a, b) => a + b);
      await _db.collection('children').doc(childId).update({
        'bonusPoints': bonus,
        'totalPoints': competitionPoints + bonus,
      });
    });
  }
}

final childrenNotifierProvider =
    StateNotifierProvider<ChildrenNotifier, AsyncValue<void>>((ref) {
  return ChildrenNotifier(ref.watch(firestoreProvider));
});

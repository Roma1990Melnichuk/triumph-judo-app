import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/belt_requirement_model.dart';
import '../../../core/models/belt_progress_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/utils/stream_utils.dart';

// ── Default exercises seeded on first load ───────────────────────────────────
final _defaultExercises = <BeltLevel, List<Map<String, String>>>{
  BeltLevel.whiteYellow: [
    {'id': 'wwy1', 'name': 'Укемі назад', 'description': 'Правильне падіння назад', 'category': 'technique'},
    {'id': 'wwy2', 'name': 'Укемі вбік', 'description': 'Правильне падіння вбік', 'category': 'technique'},
    {'id': 'wwy3', 'name': 'Стійка дзюдоїста', 'description': 'Сейза та шизентай', 'category': 'technique'},
    {'id': 'wwy4', 'name': 'Захват', 'description': 'Рукав + комір', 'category': 'technique'},
    {'id': 'wwy5', 'name': 'Осото-гарі', 'description': 'Підніжка ззовні', 'category': 'technique'},
    {'id': 'wwy6', 'name': 'Оучі-гарі', 'description': 'Підніжка зсередини', 'category': 'technique'},
    {'id': 'wwy7', 'name': 'Фізична підготовка', 'description': 'Базова фізична готовність', 'category': 'physical'},
    {'id': 'wwy8', 'name': 'Правила безпеки', 'description': 'Знання правил безпеки в залі', 'category': 'theory'},
  ],
  BeltLevel.yellow: [
    {'id': 'wy1', 'name': 'Укі-госі', 'description': 'Кидок через стегно'},
    {'id': 'wy2', 'name': 'Де-аші-барай', 'description': 'Підсічка'},
    {'id': 'wy3', 'name': 'Хон-кеса-гатаме', 'description': 'Утримання'},
    {'id': 'wy4', 'name': 'Неваза базова', 'description': 'Базова боротьба лежачи'},
    {'id': 'wy5', 'name': 'Осото-гарі', 'description': 'Підніжка ззовні'},
    {'id': 'wy6', 'name': 'Оучі-гарі', 'description': 'Підніжка зсередини'},
  ],
  BeltLevel.yellowOrange: [
    {'id': 'yo1', 'name': 'Сео-наге', 'description': 'Кидок через плече'},
    {'id': 'yo2', 'name': 'Косото-гарі', 'description': 'Мала підніжка ззовні'},
    {'id': 'yo3', 'name': 'Зав\'язування пояса', 'description': 'Кокура-мусубі'},
    {'id': 'yo4', 'name': 'Рандорі 2 хв', 'description': 'Вільна боротьба 2 хвилини'},
  ],
  BeltLevel.orange: [
    {'id': 'or1', 'name': 'Ката-гурума', 'description': 'Кидок через плечі'},
    {'id': 'or2', 'name': 'Харай-госі', 'description': 'Кидок підхватом'},
    {'id': 'or3', 'name': 'Комбінації кидків', 'description': '2 кидки в комбінації'},
    {'id': 'or4', 'name': 'Утримання 20 сек', 'description': 'Правильне утримання'},
    {'id': 'or5', 'name': 'Рандорі 3 хв', 'description': 'Вільна боротьба 3 хвилини'},
  ],
  BeltLevel.orangeGreen: [
    {'id': 'og1', 'name': 'Учі-мата', 'description': 'Кидок зачіпом зсередини'},
    {'id': 'og2', 'name': 'Контр-кидок', 'description': 'Базовий контр на осото-гарі'},
    {'id': 'og3', 'name': 'Неваза 2 хв', 'description': 'Боротьба лежачи 2 хвилини'},
    {'id': 'og4', 'name': 'Правила змагань', 'description': 'Знання основних правил'},
  ],
  BeltLevel.green: [
    {'id': 'gr1', 'name': 'Тані-отосі', 'description': 'Кидок з відступом'},
    {'id': 'gr2', 'name': 'Джудзі-гатаме', 'description': 'Важель ліктя'},
    {'id': 'gr3', 'name': 'Комбінація 3 кидків', 'description': '3 кидки в комбінації'},
    {'id': 'gr4', 'name': 'Рандорі 4 хв', 'description': 'Вільна боротьба 4 хвилини'},
    {'id': 'gr5', 'name': 'Суті-ваза базова', 'description': 'Кидок зі спаданням'},
  ],
  BeltLevel.greenBlue: [
    {'id': 'gb1', 'name': 'Осаекомі-ваза 3 прийоми', 'description': '3 різних утримання'},
    {'id': 'gb2', 'name': 'Шімє-ваза вступ', 'description': 'Вступ до задушень'},
    {'id': 'gb3', 'name': 'Рандорі 5 хв', 'description': 'Вільна боротьба 5 хвилин'},
  ],
  BeltLevel.blue: [
    {'id': 'bl1', 'name': 'Ашіваза 3 прийоми', 'description': '3 підніжки-підсічки'},
    {'id': 'bl2', 'name': 'Ручні кидки 3 прийоми', 'description': '3 кидки через руки'},
    {'id': 'bl3', 'name': 'Шімє-ваза 2 прийоми', 'description': '2 задушення'},
    {'id': 'bl4', 'name': 'Рандорі 5 хв', 'description': 'Вільна боротьба 5 хвилин'},
    {'id': 'bl5', 'name': 'Знання ката', 'description': 'Нагє-но-ката (перші 3 серії)'},
  ],
  BeltLevel.blueBrown: [
    {'id': 'bb1', 'name': 'Суті-ваза 2 прийоми', 'description': '2 кидки зі спаданням'},
    {'id': 'bb2', 'name': 'Комбінація стоячи+лежачи', 'description': 'Кидок + перехід в неваза'},
    {'id': 'bb3', 'name': 'Рандорі 6 хв', 'description': 'Вільна боротьба 6 хвилин'},
  ],
  BeltLevel.brown: [
    {'id': 'br1', 'name': 'Вільна техніка', 'description': 'Демонстрація 5 власних прийомів'},
    {'id': 'br2', 'name': 'Нагє-но-ката повна', 'description': 'Всі 5 серій'},
    {'id': 'br3', 'name': 'Рандорі 8 хв', 'description': 'Вільна боротьба 8 хвилин'},
    {'id': 'br4', 'name': 'Суддівство', 'description': 'Базові знання суддівства'},
  ],
};

// ── All belt requirements ─────────────────────────────────────────────────────
final beltRequirementsProvider =
    StreamProvider<Map<BeltLevel, BeltRequirementModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('belt_requirements')
      .snapshots()
      .map((snap) {
    final map = <BeltLevel, BeltRequirementModel>{};
    for (final doc in snap.docs) {
      final req = BeltRequirementModel.fromFirestore(doc);
      map[req.belt] = req;
    }
    return map;
  }).fallbackOnError({});
});

// ── Requirements for a specific belt ─────────────────────────────────────────
final beltRequirementProvider =
    Provider.family<BeltRequirementModel?, BeltLevel>((ref, belt) {
  final all = ref.watch(beltRequirementsProvider).asData?.value;
  return all?[belt];
});

// ── Progress for a specific child + belt ─────────────────────────────────────
final beltProgressProvider =
    StreamProvider.family<BeltProgressModel?, ({String childId, BeltLevel belt})>(
        (ref, args) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  final docId = '${args.childId}_${args.belt.name}';
  return ref
      .watch(firestoreProvider)
      .collection('belt_progress')
      .doc(docId)
      .snapshots()
      .map((doc) => doc.exists ? BeltProgressModel.fromFirestore(doc) : null)
      .fallbackOnError(null);
});

class BeltNotifier extends StateNotifier<AsyncValue<void>> {
  BeltNotifier(this._db) : super(const AsyncValue.data(null));

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  // Seed default requirements if not exist (called on app start by coach)
  Future<void> seedDefaultsIfEmpty(String coachId) async {
    final snap = await _db.collection('belt_requirements').limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final entry in _defaultExercises.entries) {
      final ref = _db.collection('belt_requirements').doc(entry.key.name);
      batch.set(ref, {
        'exercises': entry.value,
        'updatedAt': Timestamp.now(),
        'updatedByCoachId': coachId,
      });
    }
    // Empty requirements for belts not in defaults
    for (final belt in BeltLevel.values) {
      if (!_defaultExercises.containsKey(belt)) {
        final ref = _db.collection('belt_requirements').doc(belt.name);
        batch.set(ref, {
          'exercises': <dynamic>[],
          'updatedAt': Timestamp.now(),
          'updatedByCoachId': coachId,
        }, SetOptions(merge: true));
      }
    }
    await batch.commit();
  }

  /// Mark every exercise in [exerciseIds] as passed and sync beltReady = true.
  Future<void> markAllPassed({
    required String childId,
    required BeltLevel belt,
    required List<String> exerciseIds,
  }) async {
    if (exerciseIds.isEmpty) return;
    final docId = '${childId}_${belt.name}';
    final ref = _db.collection('belt_progress').doc(docId);
    await ref.set({'childId': childId, 'belt': belt.name}, SetOptions(merge: true));
    await ref.update({
      for (final id in exerciseIds) 'passed.$id': true,
    });
    await _db.collection('children').doc(childId).update({'beltReady': true});
    try { AnalyticsService.allExercisesApproved(belt: belt.name); } catch (_) {}
    try { AnalyticsService.beltReadyAchieved(belt: belt.name); } catch (_) {}
  }

  /// Read current progress & requirements and sync beltReady field on the child.
  Future<void> syncBeltReady(String childId, BeltLevel belt) async {
    try {
      final docId = '${childId}_${belt.name}';
      final results = await Future.wait([
        _db.collection('belt_progress').doc(docId).get(),
        _db.collection('belt_requirements').doc(belt.name).get(),
      ]);
      final progressMap =
          (results[0].data()?['passed'] as Map<String, dynamic>?) ?? {};
      final exercises =
          (results[1].data()?['exercises'] as List<dynamic>?) ?? [];
      final isReady = exercises.isNotEmpty &&
          exercises.every(
              (e) => progressMap[(e as Map<String, dynamic>)['id']] == true);
      await _db.collection('children').doc(childId).update({'beltReady': isReady});
    } catch (_) {}
  }

  Future<void> updateRequirements(
      BeltLevel belt, List<Exercise> exercises, String coachId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db.collection('belt_requirements').doc(belt.name).set({
        'exercises': exercises.map((e) => e.toMap()).toList(),
        'updatedAt': Timestamp.now(),
        'updatedByCoachId': coachId,
      });
    });
  }

  Future<void> toggleExercise({
    required String childId,
    required BeltLevel belt,
    required String exerciseId,
    required bool passed,
  }) async {
    final docId = '${childId}_${belt.name}';
    final ref = _db.collection('belt_progress').doc(docId);

    // Ensure document exists with metadata, then update only this exercise key
    // (set+merge on metadata only, then update with dot-notation to preserve other exercises)
    await ref.set(
      {'childId': childId, 'belt': belt.name},
      SetOptions(merge: true),
    );
    await ref.update({'passed.$exerciseId': passed});

    // Compute belt readiness and sync to child document
    try {
      final results = await Future.wait([
        ref.get(),
        _db.collection('belt_requirements').doc(belt.name).get(),
      ]);
      final progressMap =
          (results[0].data()?['passed'] as Map<String, dynamic>?) ?? {};
      final exercises =
          (results[1].data()?['exercises'] as List<dynamic>?) ?? [];
      final isReady = exercises.isNotEmpty &&
          exercises.every(
              (e) => progressMap[(e as Map<String, dynamic>)['id']] == true);
      await _db
          .collection('children')
          .doc(childId)
          .update({'beltReady': isReady});
      AnalyticsService.exerciseToggled(belt: belt.name, passed: passed);
      if (isReady) AnalyticsService.beltReadyAchieved(belt: belt.name);
    } catch (_) {}
  }

  /// Add a new exercise to a specific category for a belt level.
  Future<void> addExercise({
    required BeltLevel belt,
    required String name,
    required String description,
    required ExerciseCategory category,
    required String coachId,
  }) async {
    final id = _uuid.v4();
    final docRef = _db.collection('belt_requirements').doc(belt.name);
    final snap = await docRef.get();
    final existing = (snap.data()?['exercises'] as List<dynamic>? ?? [])
        .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
        .toList();
    existing.add(Exercise(
      id: id,
      name: name,
      description: description,
      category: category,
    ));
    await docRef.set(
      {
        'exercises': existing.map((e) => e.toMap()).toList(),
        'updatedAt': Timestamp.now(),
        'updatedByCoachId': coachId,
      },
      SetOptions(merge: true),
    );
    await syncAllChildrenBeltReady(belt);
  }

  /// Update an existing exercise (name/description) by id.
  Future<void> updateExercise({
    required BeltLevel belt,
    required Exercise updated,
    required String coachId,
  }) async {
    final docRef = _db.collection('belt_requirements').doc(belt.name);
    final snap = await docRef.get();
    final existing = (snap.data()?['exercises'] as List<dynamic>? ?? [])
        .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
        .map((e) => e.id == updated.id ? updated : e)
        .toList();
    await docRef.set(
      {
        'exercises': existing.map((e) => e.toMap()).toList(),
        'updatedAt': Timestamp.now(),
        'updatedByCoachId': coachId,
      },
      SetOptions(merge: true),
    );
  }

  /// Remove an exercise from a belt and re-sync beltReady for all children.
  Future<void> removeExercise({
    required BeltLevel belt,
    required String exerciseId,
    required String coachId,
  }) async {
    final docRef = _db.collection('belt_requirements').doc(belt.name);
    final snap = await docRef.get();
    final existing = (snap.data()?['exercises'] as List<dynamic>? ?? [])
        .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
        .where((e) => e.id != exerciseId)
        .toList();
    await docRef.set(
      {
        'exercises': existing.map((e) => e.toMap()).toList(),
        'updatedAt': Timestamp.now(),
        'updatedByCoachId': coachId,
      },
      SetOptions(merge: true),
    );
    await syncAllChildrenBeltReady(belt);
  }

  /// Re-evaluate beltReady for every child who has progress for [belt].
  Future<void> syncAllChildrenBeltReady(BeltLevel belt) async {
    try {
      final reqSnap =
          await _db.collection('belt_requirements').doc(belt.name).get();
      final exercises = reqSnap.data()?['exercises'] as List<dynamic>? ?? [];
      final progressSnap = await _db
          .collection('belt_progress')
          .where('belt', isEqualTo: belt.name)
          .get();
      for (final doc in progressSnap.docs) {
        final childId = doc.data()['childId'] as String?;
        if (childId == null) continue;
        final progressMap =
            (doc.data()['passed'] as Map<String, dynamic>?) ?? {};
        final isReady = exercises.isNotEmpty &&
            exercises.every(
                (e) => progressMap[(e as Map<String, dynamic>)['id']] == true);
        await _db
            .collection('children')
            .doc(childId)
            .update({'beltReady': isReady});
      }
    } catch (_) {}
  }

  Exercise newExercise(String name, String description) => Exercise(
        id: _uuid.v4(),
        name: name,
        description: description,
      );
}

final beltNotifierProvider =
    StateNotifierProvider<BeltNotifier, AsyncValue<void>>((ref) {
  return BeltNotifier(ref.watch(firestoreProvider));
});

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/meal_model.dart';
import '../../../core/models/water_log_model.dart';
import '../../../core/models/nutrition_tip_model.dart';
import '../../../core/models/food_product_model.dart';
import '../../auth/providers/auth_provider.dart';

typedef NutritionKey = ({String childId, String dateKey});

String nutritionDateKey(DateTime d) {
  final l = d.toLocal();
  return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
}

String get todayNutritionKey => nutritionDateKey(DateTime.now());

// ── Streams ────────────────────────────────────────────────────────────────────

final childMealsProvider =
    StreamProvider.family<List<MealModel>, String>((ref, childId) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('meals')
      .where('childId', isEqualTo: childId)
      .orderBy('date', descending: true)
      .limit(300)
      .snapshots()
      .map((s) => s.docs.map(MealModel.fromFirestore).toList());
});

final childWaterLogsProvider =
    StreamProvider.family<List<WaterLogModel>, String>((ref, childId) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('water_logs')
      .where('childId', isEqualTo: childId)
      .orderBy('loggedAt', descending: true)
      .limit(500)
      .snapshots()
      .map((s) => s.docs.map(WaterLogModel.fromFirestore).toList());
});

final nutritionTipsProvider = StreamProvider<List<NutritionTipModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('nutrition_tips')
      .orderBy('publishedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(NutritionTipModel.fromFirestore).toList());
});

final foodProductsProvider = StreamProvider<List<FoodProductModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('food_products')
      .snapshots()
      .map((s) {
        final list = s.docs.map(FoodProductModel.fromFirestore).toList();
        list.sort((a, b) => a.name.compareTo(b.name));
        return list;
      });
});

// ── Day-level derived providers ────────────────────────────────────────────────

final dayMealsProvider =
    Provider.family<List<MealModel>, NutritionKey>((ref, key) {
  final all = ref.watch(childMealsProvider(key.childId)).asData?.value ?? [];
  return all.where((m) => m.dateKey == key.dateKey).toList()
    ..sort((a, b) => a.type.index.compareTo(b.type.index));
});

final dayWaterMlProvider =
    Provider.family<int, NutritionKey>((ref, key) {
  final logs = ref.watch(childWaterLogsProvider(key.childId)).asData?.value ?? [];
  return logs
      .where((l) => l.dateKey == key.dateKey)
      .fold(0, (s, l) => s + l.amountMl);
});

final dayWaterLogsProvider =
    Provider.family<List<WaterLogModel>, NutritionKey>((ref, key) {
  final logs = ref.watch(childWaterLogsProvider(key.childId)).asData?.value ?? [];
  return logs.where((l) => l.dateKey == key.dateKey).toList();
});

final waterGoalMlProvider = Provider<int>((ref) => 1500);

// ── Nutrition score 0–100 ──────────────────────────────────────────────────────

final nutritionScoreProvider =
    Provider.family<double, NutritionKey>((ref, key) {
  final meals     = ref.watch(dayMealsProvider(key));
  final waterMl   = ref.watch(dayWaterMlProvider(key));
  final waterGoal = ref.watch(waterGoalMlProvider);
  final tips      = ref.watch(nutritionTipsProvider).asData?.value ?? [];

  // 40% — plate quality
  final doneMeals = meals.where((m) => m.status == MealStatus.done).toList();
  final plateScore = doneMeals.isEmpty
      ? 0.0
      : doneMeals.map((m) => m.plateScore).reduce((a, b) => a + b) /
            doneMeals.length;

  // 30% — water
  final waterScore = waterGoal > 0
      ? math.min(waterMl / waterGoal, 1.0)
      : 0.0;

  // 20% — regularity (3 main meals)
  final mainDone = meals
      .where((m) =>
          m.status == MealStatus.done &&
          (m.type == MealType.breakfast ||
              m.type == MealType.lunch ||
              m.type == MealType.dinner))
      .length;
  final regularityScore = math.min(mainDone / 3.0, 1.0);

  // 10% — tips read
  final tipsScore = tips.isEmpty
      ? 0.0
      : tips.where((t) => t.isReadBy(key.childId)).length / tips.length;

  return (plateScore * 0.4 +
          waterScore * 0.3 +
          regularityScore * 0.2 +
          tipsScore * 0.1) *
      100;
});

// ── Plate summary (5 elements) ─────────────────────────────────────────────────

class PlateSummary {
  const PlateSummary({
    required this.proteinPct,
    required this.vegetablesPct,
    required this.carbsPct,
    required this.fruitsPct,
    required this.waterPct,
  });

  final double proteinPct;
  final double vegetablesPct;
  final double carbsPct;
  final double fruitsPct;
  final double waterPct;

  double get overall =>
      (proteinPct + vegetablesPct + carbsPct + fruitsPct + waterPct) / 5.0;
}

final plateSummaryProvider =
    Provider.family<PlateSummary, NutritionKey>((ref, key) {
  final meals = ref
      .watch(dayMealsProvider(key))
      .where((m) => m.status == MealStatus.done)
      .toList();
  final waterMl   = ref.watch(dayWaterMlProvider(key));
  final waterGoal = ref.watch(waterGoalMlProvider);

  final waterPct = waterGoal > 0 ? math.min(waterMl / waterGoal, 1.0) : 0.0;

  if (meals.isEmpty) {
    return PlateSummary(
        proteinPct: 0, vegetablesPct: 0, carbsPct: 0, fruitsPct: 0,
        waterPct: waterPct);
  }

  final n = meals.length.toDouble();
  return PlateSummary(
    proteinPct:    meals.where((m) => m.hasProtein).length    / n,
    vegetablesPct: meals.where((m) => m.hasVegetables).length / n,
    carbsPct:      meals.where((m) => m.hasCarbs).length      / n,
    fruitsPct:     meals.where((m) => m.hasFruits).length     / n,
    waterPct:      waterPct,
  );
});

// ── Week stats ─────────────────────────────────────────────────────────────────

class WeekNutritionPoint {
  const WeekNutritionPoint({required this.dateKey, required this.score});
  final String dateKey;
  final double score;
}

final weekNutritionProvider =
    Provider.family<List<WeekNutritionPoint>, String>((ref, childId) {
  final result = <WeekNutritionPoint>[];
  final now = DateTime.now();
  for (int i = 6; i >= 0; i--) {
    final day = now.subtract(Duration(days: i));
    final dk  = nutritionDateKey(day);
    final key = (childId: childId, dateKey: dk);
    final score = ref.watch(nutritionScoreProvider(key));
    result.add(WeekNutritionPoint(dateKey: dk, score: score));
  }
  return result;
});

// ── Notifier ───────────────────────────────────────────────────────────────────

class NutritionNotifier extends StateNotifier<AsyncValue<void>> {
  NutritionNotifier(this._db, this._uid) : super(const AsyncValue.data(null));

  final FirebaseFirestore _db;
  final String            _uid;
  final _uuid = const Uuid();

  Future<void> addMeal({
    required String    childId,
    required MealType  type,
    required DateTime  date,
    required String    mealName,
    required bool      hasProtein,
    required bool      hasVegetables,
    required bool      hasCarbs,
    required bool      hasFruits,
    required bool      hadWater,
    int?               calories,
    String             comment = '',
    String?            photoUrl,
  }) async {
    final id = _uuid.v4();
    await _db.collection('meals').doc(id).set(
      MealModel(
        id: id, childId: childId, type: type, date: date,
        photoUrl: photoUrl, mealName: mealName,
        hasProtein: hasProtein, hasVegetables: hasVegetables,
        hasCarbs: hasCarbs, hasFruits: hasFruits, hadWater: hadWater,
        calories: calories, comment: comment, status: MealStatus.done,
        createdAt: DateTime.now(),
      ).toFirestore(),
    );
  }

  Future<void> updateMeal(MealModel meal) async {
    final data = meal.toFirestore()..remove('createdAt');
    await _db.collection('meals').doc(meal.id).update(data);
  }

  Future<void> deleteMeal(String mealId) async {
    await _db.collection('meals').doc(mealId).delete();
  }

  Future<void> logWater({required String childId, required int amountMl}) async {
    final id = _uuid.v4();
    await _db.collection('water_logs').doc(id).set(
      WaterLogModel(id: id, childId: childId, amountMl: amountMl,
          loggedAt: DateTime.now())
          .toFirestore(),
    );
  }

  Future<void> deleteWaterLog(String logId) async {
    await _db.collection('water_logs').doc(logId).delete();
  }

  Future<void> markTipRead(
      {required String tipId, required String childId}) async {
    await _db.collection('nutrition_tips').doc(tipId).update({
      'readBy': FieldValue.arrayUnion([childId]),
    });
  }

  Future<void> addTip({
    required String      title,
    required String      body,
    required TipCategory category,
    String?              imageUrl,
  }) async {
    final id = _uuid.v4();
    await _db.collection('nutrition_tips').doc(id).set(
      NutritionTipModel(
        id: id, title: title, body: body, category: category,
        imageUrl: imageUrl, publishedAt: DateTime.now(),
        coachId: _uid, readBy: [],
      ).toFirestore(),
    );
  }

  Future<void> seedProductsIfEmpty() async {
    try {
      final snap = await _db.collection('food_products').limit(1).get();
      if (snap.docs.isNotEmpty) return;
      final batch = _db.batch();
      for (final p in FoodProductModel.defaults) {
        batch.set(_db.collection('food_products').doc(p.id), p.toFirestore());
      }
      await batch.commit();
    } catch (_) {}
  }
}

final nutritionNotifierProvider =
    StateNotifierProvider<NutritionNotifier, AsyncValue<void>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid ?? '';
  return NutritionNotifier(ref.watch(firestoreProvider), uid);
});

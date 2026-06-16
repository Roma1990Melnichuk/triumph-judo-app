/// E2E тести для NutritionNotifier — повний CRUD харчування + вода + поради.
/// Покриває: addMeal, updateMeal, deleteMeal, logWater, deleteWaterLog,
///           markTipRead, addTip.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/meal_model.dart';
import 'package:judo_app/core/models/nutrition_tip_model.dart';
import 'package:judo_app/features/nutrition/providers/nutrition_provider.dart';

// ── Хелпери ───────────────────────────────────────────────────────────────────

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

NutritionNotifier _notifier(FakeFirebaseFirestore db, {String uid = 'coach1'}) =>
    NutritionNotifier(db, uid);

final _date = DateTime(2025, 6, 15, 12);

Future<void> _addMeal(
  NutritionNotifier n, {
  String childId = 'kid1',
  MealType type = MealType.lunch,
  String mealName = 'Борщ',
  bool protein = true,
  bool vegetables = true,
  bool carbs = true,
  bool fruits = false,
  bool water = true,
}) =>
    n.addMeal(
      childId: childId,
      type: type,
      date: _date,
      mealName: mealName,
      hasProtein: protein,
      hasVegetables: vegetables,
      hasCarbs: carbs,
      hasFruits: fruits,
      hadWater: water,
      calories: 350,
      comment: '',
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── addMeal ───────────────────────────────────────────────────────────────

  group('NutritionNotifier — addMeal', () {
    test('зберігає прийом їжі у Firestore', () async {
      final db = _db();
      final n = _notifier(db);

      await _addMeal(n, mealName: 'Вівсянка');

      final snap = await db.collection('meals').get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first['mealName'], 'Вівсянка');
      expect(snap.docs.first['childId'], 'kid1');
      expect(snap.docs.first['type'], 'lunch');
    });

    test('зберігає харчові компоненти правильно', () async {
      final db = _db();
      final n = _notifier(db);

      await n.addMeal(
        childId: 'kid1',
        type: MealType.dinner,
        date: _date,
        mealName: 'Риба з овочами',
        hasProtein: true,
        hasVegetables: true,
        hasCarbs: false,
        hasFruits: false,
        hadWater: true,
        comment: '',
      );

      final doc = (await db.collection('meals').get()).docs.first;
      expect(doc['hasProtein'], isTrue);
      expect(doc['hasVegetables'], isTrue);
      expect(doc['hasCarbs'], isFalse);
      expect(doc['hasFruits'], isFalse);
      expect(doc['hadWater'], isTrue);
    });

    test('кілька прийомів їжі — кожен має унікальний ID', () async {
      final db = _db();
      final n = _notifier(db);

      await _addMeal(n, type: MealType.breakfast, mealName: 'Сніданок');
      await _addMeal(n, type: MealType.lunch, mealName: 'Обід');
      await _addMeal(n, type: MealType.dinner, mealName: 'Вечеря');

      final snap = await db.collection('meals').get();
      expect(snap.docs, hasLength(3));
      final ids = snap.docs.map((d) => d.id).toSet();
      expect(ids, hasLength(3));
    });

    test('різні діти — прийоми не перетинаються', () async {
      final db = _db();
      final n = _notifier(db);

      await _addMeal(n, childId: 'kid1', mealName: 'Їжа kid1');
      await _addMeal(n, childId: 'kid2', mealName: 'Їжа kid2');

      final kid1Meals = await db
          .collection('meals')
          .where('childId', isEqualTo: 'kid1')
          .get();
      final kid2Meals = await db
          .collection('meals')
          .where('childId', isEqualTo: 'kid2')
          .get();
      expect(kid1Meals.docs, hasLength(1));
      expect(kid2Meals.docs, hasLength(1));
    });
  });

  // ── updateMeal ────────────────────────────────────────────────────────────

  group('NutritionNotifier — updateMeal', () {
    test('оновлює назву прийому їжі', () async {
      final db = _db();
      final n = _notifier(db);
      await _addMeal(n, mealName: 'Стара назва');

      final docId = (await db.collection('meals').get()).docs.first.id;
      final meal = MealModel(
        id: docId,
        childId: 'kid1',
        type: MealType.lunch,
        date: _date,
        mealName: 'Нова назва',
        hasProtein: true,
        hasVegetables: true,
        hasCarbs: true,
        hasFruits: false,
        hadWater: true,
        comment: '',
        status: MealStatus.done,
        createdAt: _date,
      );

      await n.updateMeal(meal);

      final updated = await db.collection('meals').doc(docId).get();
      expect(updated['mealName'], 'Нова назва');
    });

    test('updateMeal не торкається інших документів', () async {
      final db = _db();
      final n = _notifier(db);
      await _addMeal(n, mealName: 'Перший');
      await _addMeal(n, mealName: 'Другий');

      final docs = (await db.collection('meals').get()).docs;
      final firstId = docs[0].id;
      final secondId = docs[1].id;

      final meal = MealModel(
        id: firstId,
        childId: 'kid1',
        type: MealType.lunch,
        date: _date,
        mealName: 'Оновлений перший',
        hasProtein: true,
        hasVegetables: true,
        hasCarbs: true,
        hasFruits: false,
        hadWater: true,
        comment: '',
        status: MealStatus.done,
        createdAt: _date,
      );
      await n.updateMeal(meal);

      final second = await db.collection('meals').doc(secondId).get();
      expect(second['mealName'], 'Другий');
    });
  });

  // ── deleteMeal ────────────────────────────────────────────────────────────

  group('NutritionNotifier — deleteMeal', () {
    test('видаляє прийом їжі з Firestore', () async {
      final db = _db();
      final n = _notifier(db);
      await _addMeal(n);

      final id = (await db.collection('meals').get()).docs.first.id;
      await n.deleteMeal(id);

      expect((await db.collection('meals').doc(id).get()).exists, isFalse);
    });

    test('видаляє тільки потрібний запис', () async {
      final db = _db();
      final n = _notifier(db);
      await _addMeal(n, mealName: 'Залишити');
      await _addMeal(n, mealName: 'Видалити');

      final docs = (await db.collection('meals').get()).docs;
      final deleteId =
          docs.firstWhere((d) => d['mealName'] == 'Видалити').id;
      await n.deleteMeal(deleteId);

      final snap = await db.collection('meals').get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first['mealName'], 'Залишити');
    });
  });

  // ── logWater / deleteWaterLog ─────────────────────────────────────────────

  group('NutritionNotifier — logWater / deleteWaterLog', () {
    test('logWater зберігає запис у water_logs', () async {
      final db = _db();
      final n = _notifier(db);

      await n.logWater(childId: 'kid1', amountMl: 250);

      final snap = await db.collection('water_logs').get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first['childId'], 'kid1');
      expect(snap.docs.first['amountMl'], 250);
    });

    test('кілька записів — сума коректна', () async {
      final db = _db();
      final n = _notifier(db);

      await n.logWater(childId: 'kid1', amountMl: 250);
      await n.logWater(childId: 'kid1', amountMl: 300);
      await n.logWater(childId: 'kid1', amountMl: 500);

      final snap = await db
          .collection('water_logs')
          .where('childId', isEqualTo: 'kid1')
          .get();
      final total = snap.docs
          .map((d) => (d['amountMl'] as num).toInt())
          .reduce((a, b) => a + b);
      expect(total, 1050);
    });

    test('deleteWaterLog видаляє запис', () async {
      final db = _db();
      final n = _notifier(db);
      await n.logWater(childId: 'kid1', amountMl: 200);

      final id = (await db.collection('water_logs').get()).docs.first.id;
      await n.deleteWaterLog(id);

      expect(
          (await db.collection('water_logs').doc(id).get()).exists, isFalse);
    });

    test('deleteWaterLog видаляє тільки потрібний запис', () async {
      final db = _db();
      final n = _notifier(db);
      await n.logWater(childId: 'kid1', amountMl: 200);
      await n.logWater(childId: 'kid1', amountMl: 300);

      final docs = (await db.collection('water_logs').get()).docs;
      await n.deleteWaterLog(docs[0].id);

      final remaining = await db.collection('water_logs').get();
      expect(remaining.docs, hasLength(1));
      expect(remaining.docs.first['amountMl'], 300);
    });
  });

  // ── addTip / markTipRead ──────────────────────────────────────────────────

  group('NutritionNotifier — addTip / markTipRead', () {
    test('addTip зберігає пораду у Firestore', () async {
      final db = _db();
      final n = _notifier(db, uid: 'coach1');

      await n.addTip(
        title: 'Їж більше білка',
        body: "Білок важливий для росту м'язів",
        category: TipCategory.hydration,
      );

      final snap = await db.collection('nutrition_tips').get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first['title'], 'Їж більше білка');
      expect(snap.docs.first['category'], 'hydration');
      expect(snap.docs.first['coachId'], 'coach1');
    });

    test('markTipRead додає childId до readBy', () async {
      final db = _db();
      final n = _notifier(db);
      await n.addTip(
        title: 'Порада',
        body: 'Текст',
        category: TipCategory.general,
      );

      final tipId = (await db.collection('nutrition_tips').get()).docs.first.id;
      await n.markTipRead(tipId: tipId, childId: 'kid1');

      final doc = await db.collection('nutrition_tips').doc(tipId).get();
      expect(List<String>.from(doc['readBy'] as List), contains('kid1'));
    });

    test('markTipRead двічі — не дублює childId', () async {
      final db = _db();
      final n = _notifier(db);
      await n.addTip(title: 'Порада', body: 'Текст', category: TipCategory.general);
      final tipId = (await db.collection('nutrition_tips').get()).docs.first.id;

      await n.markTipRead(tipId: tipId, childId: 'kid1');
      await n.markTipRead(tipId: tipId, childId: 'kid1');

      final doc = await db.collection('nutrition_tips').doc(tipId).get();
      final readers = List<String>.from(doc['readBy'] as List);
      expect(readers.where((id) => id == 'kid1'), hasLength(1));
    });

    test('різні діти читають одну пораду', () async {
      final db = _db();
      final n = _notifier(db);
      await n.addTip(title: 'Порада', body: 'Текст', category: TipCategory.general);
      final tipId = (await db.collection('nutrition_tips').get()).docs.first.id;

      await n.markTipRead(tipId: tipId, childId: 'kid1');
      await n.markTipRead(tipId: tipId, childId: 'kid2');
      await n.markTipRead(tipId: tipId, childId: 'kid3');

      final doc = await db.collection('nutrition_tips').doc(tipId).get();
      final readers = List<String>.from(doc['readBy'] as List);
      expect(readers, containsAll(['kid1', 'kid2', 'kid3']));
    });
  });

  // ── Повний сценарій ───────────────────────────────────────────────────────

  group('Nutrition — повний денний сценарій', () {
    test('дитина: сніданок + обід + вечеря + вода + порада прочитана', () async {
      final db = _db();
      final n = _notifier(db, uid: 'coach1');

      // 1. Три прийоми їжі
      await n.addMeal(
          childId: 'kid1', type: MealType.breakfast, date: _date,
          mealName: 'Вівсянка', hasProtein: true, hasVegetables: false,
          hasCarbs: true, hasFruits: false, hadWater: true, comment: '');
      await n.addMeal(
          childId: 'kid1', type: MealType.lunch, date: _date,
          mealName: 'Борщ', hasProtein: true, hasVegetables: true,
          hasCarbs: true, hasFruits: false, hadWater: true, comment: '');
      await n.addMeal(
          childId: 'kid1', type: MealType.dinner, date: _date,
          mealName: 'Риба', hasProtein: true, hasVegetables: true,
          hasCarbs: false, hasFruits: false, hadWater: true, comment: '');

      final meals = await db
          .collection('meals')
          .where('childId', isEqualTo: 'kid1')
          .get();
      expect(meals.docs, hasLength(3));

      // 2. Вода (3 рази)
      await n.logWater(childId: 'kid1', amountMl: 250);
      await n.logWater(childId: 'kid1', amountMl: 250);
      await n.logWater(childId: 'kid1', amountMl: 500);

      final water = await db
          .collection('water_logs')
          .where('childId', isEqualTo: 'kid1')
          .get();
      expect(water.docs, hasLength(3));
      final totalMl = water.docs
          .map((d) => (d['amountMl'] as num).toInt())
          .reduce((a, b) => a + b);
      expect(totalMl, 1000);

      // 3. Тренер додає пораду і дитина читає її
      await n.addTip(
          title: 'Вода важлива', body: 'Пий 1.5л на день', category: TipCategory.general);
      final tipId =
          (await db.collection('nutrition_tips').get()).docs.first.id;
      await n.markTipRead(tipId: tipId, childId: 'kid1');

      final tip = await db.collection('nutrition_tips').doc(tipId).get();
      expect(List<String>.from(tip['readBy'] as List), contains('kid1'));
    });
  });
}

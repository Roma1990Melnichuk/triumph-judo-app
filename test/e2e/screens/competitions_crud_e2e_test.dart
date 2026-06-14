/// E2E тести для CompetitionsNotifier — CRUD результатів змагань і типів змагань.
/// Покриває: addResult, deleteResult, addCompetitionType, deleteCompetitionType.
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/competition_result_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/competitions/providers/competitions_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

ProviderContainer _container(FakeFirebaseFirestore db) => ProviderContainer(
      overrides: [firestoreProvider.overrideWithValue(db)],
    );

/// Seeds a children document so recalcPoints doesn't fail on update().
Future<void> _seedChild(FakeFirebaseFirestore db, String childId) async {
  await db.collection('children').doc(childId).set({
    'firstName': 'Іван',
    'lastName': 'Петренко',
    'totalPoints': 0,
    'bonusPoints': 0,
  });
}

CompetitionResultModel _result({String id = 'r1'}) => CompetitionResultModel(
      id: id,
      childId: 'kid1',
      childName: 'Іван Петренко',
      competitionName: 'Чемпіонат клубу',
      level: CompetitionLevel.club,
      place: 1,
      points: 50,
      date: DateTime(2026, 3, 15),
      seasonYear: 2026,
      addedByCoachId: 'coach1',
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('CompetitionsNotifier — addResult (тренер)', () {
    test('зберігає результат змагання у Firestore', () async {
      final db = _db();
      await _seedChild(db, 'kid1');
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(competitionsNotifierProvider.notifier).addResult(_result());

      final snap = await db.collection('competition_results').get();
      expect(snap.docs, hasLength(1));

      final data = snap.docs.first.data();
      expect(data['childId'], 'kid1');
      expect(data['competitionName'], 'Чемпіонат клубу');
      expect(data['place'], 1);
      expect(data['points'], 50);
      expect(data['seasonYear'], 2026);
    });

    test('recalcPoints оновлює totalPoints у children після addResult', () async {
      final db = _db();
      await _seedChild(db, 'kid1');
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(competitionsNotifierProvider.notifier).addResult(_result());

      final childDoc = await db.collection('children').doc('kid1').get();
      expect(childDoc['totalPoints'], 50);
    });

    test('кілька результатів — кожен зберігається окремо', () async {
      final db = _db();
      await _seedChild(db, 'kid1');
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(competitionsNotifierProvider.notifier);
      await n.addResult(_result(id: 'r1'));
      await n.addResult(_result(id: 'r2'));

      final snap = await db.collection('competition_results').get();
      expect(snap.docs, hasLength(2));
    });
  });

  group('CompetitionsNotifier — deleteResult (тренер)', () {
    test('видаляє результат змагання з Firestore', () async {
      final db = _db();
      await _seedChild(db, 'kid1');

      // Seed a result
      const rid = 'result_to_delete';
      await db.collection('competition_results').doc(rid).set(
            _result(id: rid).toFirestore(),
          );

      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(competitionsNotifierProvider.notifier)
          .deleteResult(_result(id: rid));

      final doc = await db.collection('competition_results').doc(rid).get();
      expect(doc.exists, isFalse);
    });

    test('recalcPoints оновлює totalPoints після видалення', () async {
      final db = _db();
      await _seedChild(db, 'kid1');

      const rid = 'r1';
      await db.collection('competition_results').doc(rid).set(
            _result(id: rid).toFirestore(),
          );
      // Pre-set totalPoints to 50
      await db.collection('children').doc('kid1').update({'totalPoints': 50});

      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(competitionsNotifierProvider.notifier).deleteResult(_result(id: rid));

      final childDoc = await db.collection('children').doc('kid1').get();
      expect(childDoc['totalPoints'], 0); // result removed → 0 points
    });
  });

  group('CompetitionsNotifier — типи змагань', () {
    test('addCompetitionType зберігає тип у Firestore', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(competitionsNotifierProvider.notifier)
          .addCompetitionType('Чемпіонат', 'coach1');

      final snap = await db.collection('competition_types').get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first['name'], 'Чемпіонат');
      expect(snap.docs.first['createdByCoachId'], 'coach1');
    });

    test('deleteCompetitionType видаляє тип', () async {
      final db = _db();
      const tid = 'type1';
      await db.collection('competition_types').doc(tid).set({
        'name': 'Кубок',
        'createdByCoachId': 'coach1',
      });

      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(competitionsNotifierProvider.notifier)
          .deleteCompetitionType(tid);

      final doc = await db.collection('competition_types').doc(tid).get();
      expect(doc.exists, isFalse);
    });
  });

  group('CompetitionsNotifier — повний сценарій', () {
    test('тренер додає результат → points оновлено → тренер видаляє → points 0', () async {
      final db = _db();
      await _seedChild(db, 'kid1');
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(competitionsNotifierProvider.notifier);

      // 1. Тренер додає результат (1 місце, 50 балів)
      await n.addResult(_result());

      final snap = await db.collection('competition_results').get();
      expect(snap.docs, hasLength(1));
      final resultId = snap.docs.first.id;

      // 2. totalPoints оновлено
      final childAfterAdd = await db.collection('children').doc('kid1').get();
      expect(childAfterAdd['totalPoints'], 50);

      // 3. Тренер видаляє результат
      await n.deleteResult(_result(id: resultId));

      final afterDelete = await db.collection('competition_results').get();
      expect(afterDelete.docs, isEmpty);

      // 4. totalPoints знову 0
      final childAfterDelete = await db.collection('children').doc('kid1').get();
      expect(childAfterDelete['totalPoints'], 0);
    });

    test('addResult для кількох спортсменів → кожен отримує свої points', () async {
      final db = _db();
      await _seedChild(db, 'kid1');
      await _seedChild(db, 'kid2');
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(competitionsNotifierProvider.notifier);

      await n.addResult(CompetitionResultModel(
        id: 'r1',
        childId: 'kid1',
        childName: 'Іван',
        competitionName: 'Кубок',
        level: CompetitionLevel.local,
        place: 1,
        points: 100,
        date: DateTime(2026, 3, 1),
        seasonYear: 2026,
        addedByCoachId: 'coach1',
      ));

      await n.addResult(CompetitionResultModel(
        id: 'r2',
        childId: 'kid2',
        childName: 'Петро',
        competitionName: 'Кубок',
        level: CompetitionLevel.local,
        place: 2,
        points: 70,
        date: DateTime(2026, 3, 1),
        seasonYear: 2026,
        addedByCoachId: 'coach1',
      ));

      final kid1 = await db.collection('children').doc('kid1').get();
      final kid2 = await db.collection('children').doc('kid2').get();
      expect(kid1['totalPoints'], 100);
      expect(kid2['totalPoints'], 70);
    });
  });
}

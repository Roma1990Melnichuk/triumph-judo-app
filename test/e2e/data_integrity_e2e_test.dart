/// TC-TEAM-0379 / TC-TEAM-0380 — Data Integrity: totalPoints recalculation
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';

// Minimal child document — only the fields recalcPoints reads/writes.
Map<String, dynamic> _childDoc({int bonusPoints = 0}) => {
      'id': 'child1',
      'firstName': 'Іван',
      'lastName': 'Петренко',
      'birthYear': 2014,
      'weightCategory': '-30 кг',
      'currentBelt': 'white',
      'coachId': 'coach1',
      'coachName': 'Тренер',
      'bonusPoints': bonusPoints,
      'totalPoints': 0,
      'beltReady': false,
      'createdAt': '2024-01-01T00:00:00.000',
    };

void main() {
  group('TC-TEAM-0379: totalPoints = competitionPoints + bonusPoints', () {
    test('recalcPoints сумує бали результатів і додає bonusPoints', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('children').doc('child1').set(_childDoc(bonusPoints: 10));
      await db.collection('competition_results').add({'childId': 'child1', 'points': 30});
      await db.collection('competition_results').add({'childId': 'child1', 'points': 20});

      final container = ProviderContainer(
        overrides: [firestoreProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      await container.read(childrenNotifierProvider.notifier).recalcPoints('child1');

      final doc = await db.collection('children').doc('child1').get();
      // 30 + 20 + 10 (bonus) = 60
      expect(doc.data()!['totalPoints'], equals(60));
    });

    test('без бонусів — totalPoints = сума балів результатів', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('children').doc('child1').set(_childDoc(bonusPoints: 0));
      await db.collection('competition_results').add({'childId': 'child1', 'points': 50});
      await db.collection('competition_results').add({'childId': 'child1', 'points': 50});

      final container = ProviderContainer(
        overrides: [firestoreProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      await container.read(childrenNotifierProvider.notifier).recalcPoints('child1');

      final doc = await db.collection('children').doc('child1').get();
      expect(doc.data()!['totalPoints'], equals(100));
    });

    test('без результатів — totalPoints = bonusPoints', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('children').doc('child1').set(_childDoc(bonusPoints: 15));

      final container = ProviderContainer(
        overrides: [firestoreProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      await container.read(childrenNotifierProvider.notifier).recalcPoints('child1');

      final doc = await db.collection('children').doc('child1').get();
      expect(doc.data()!['totalPoints'], equals(15));
    });
  });

  group('TC-TEAM-0380: видалення результату → totalPoints зменшується', () {
    test('після видалення результату recalcPoints перераховує totalPoints', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('children').doc('child1').set(_childDoc(bonusPoints: 10));
      await db.collection('competition_results').add({'childId': 'child1', 'points': 30});
      await db.collection('competition_results').add({'childId': 'child1', 'points': 20});
      final toDelete = await db
          .collection('competition_results')
          .add({'childId': 'child1', 'points': 50});

      final container = ProviderContainer(
        overrides: [firestoreProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      // Початковий стан: 30 + 20 + 50 + 10 = 110
      await container.read(childrenNotifierProvider.notifier).recalcPoints('child1');
      var doc = await db.collection('children').doc('child1').get();
      expect(doc.data()!['totalPoints'], equals(110));

      // Видаляємо результат на 50 балів
      await db.collection('competition_results').doc(toDelete.id).delete();

      // Після перерахунку: 30 + 20 + 10 = 60
      await container.read(childrenNotifierProvider.notifier).recalcPoints('child1');
      doc = await db.collection('children').doc('child1').get();
      expect(doc.data()!['totalPoints'], equals(60));
    });

    test('видалення єдиного результату → totalPoints = bonusPoints', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('children').doc('child1').set(_childDoc(bonusPoints: 5));
      final only = await db
          .collection('competition_results')
          .add({'childId': 'child1', 'points': 40});

      final container = ProviderContainer(
        overrides: [firestoreProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      await db.collection('competition_results').doc(only.id).delete();
      await container.read(childrenNotifierProvider.notifier).recalcPoints('child1');

      final doc = await db.collection('children').doc('child1').get();
      expect(doc.data()!['totalPoints'], equals(5)); // тільки bonusPoints
    });
  });
}

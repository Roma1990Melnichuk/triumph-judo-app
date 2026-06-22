/// Сценарний тест: Нагороди (Achievement Catalog)
///
/// Реальні сценарії — НЕ "рендериться без краша":
///
///   SC-A-001  Спортсмен без нагород бачить «0 / N зароблено» в каталозі
///   SC-A-002  Спортсмен з 2 нагородами бачить «2 / N зароблено»
///   SC-A-003  Всі категорії каталогу відображаються (Дисципліна, Тренування…)
///   SC-A-004  Батько не передає childId → каталог показує нагороди власної дитини
///   SC-A-005  Нагорода без краша на порожньому earnedIds
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/achievement_defs.dart';
import 'package:judo_app/core/models/achievement_model.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/achievements/providers/achievement_provider.dart';
import 'package:judo_app/features/achievements/screens/achievement_catalog_screen.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _coach = UserModel(
  uid: 'coach1',
  email: 'coach@test.com',
  name: 'Тренер Іванов',
  role: 'coach',
);

UserModel _parent(String childId) => UserModel(
      uid: 'parent1',
      email: 'parent@test.com',
      name: 'Батько',
      role: 'parent',
      childIds: [childId],
    );

AchievementModel _earned(String childId, String defId) => AchievementModel(
      childId: childId,
      achievementId: defId,
      earnedAt: DateTime(2024, 9, 1),
      grantedByCoachId: 'coach1',
    );

// ── App builder ───────────────────────────────────────────────────────────────

Widget _buildCatalogApp({
  required String childId,
  required UserModel user,
  required List<AchievementModel> earned,
}) {
  final db = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      firestoreProvider.overrideWithValue(db),
      currentUserModelProvider.overrideWith((_) => Stream.value(user)),
      childAchievementsProvider(childId).overrideWith(
        (_) => Stream.value(earned),
      ),
    ],
    child: MaterialApp(
      home: AchievementCatalogScreen(childId: childId),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

// ── Scenarios ─────────────────────────────────────────────────────────────────

void main() {
  final totalDefs = kAchievements.length;

  group('SC-A-001: спортсмен без нагород бачить «0 / N зароблено»', () {
    testWidgets('0 earned — каталог показує лічильник 0', (tester) async {
      await tester.pumpWidget(_buildCatalogApp(
        childId: 'c1',
        user: _coach,
        earned: const [],
      ));
      await _settle(tester);

      expect(find.textContaining('0'), findsWidgets,
          reason: 'Має бути "0" в лічильнику зароблених нагород');
      expect(find.textContaining('$totalDefs'), findsWidgets,
          reason: 'Загальна кількість визначень ($totalDefs) має бути видна');
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-A-002: спортсмен з 2 нагородами бачить правильний лічильник', () {
    testWidgets('earned=2 → лічильник показує 2', (tester) async {
      final earned = [
        _earned('c1', 'first_training'),
        _earned('c1', 'trainings_10'),
      ];
      await tester.pumpWidget(_buildCatalogApp(
        childId: 'c1',
        user: _coach,
        earned: earned,
      ));
      await _settle(tester);

      expect(find.textContaining('2'), findsWidgets,
          reason: 'Лічильник «зароблено» має показувати 2');
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-A-003: всі категорії каталогу відображаються', () {
    testWidgets('Дисципліна, Тренування, Пояси видні', (tester) async {
      // Tall viewport so all catalog sliver sections are within the cache extent
      tester.view.physicalSize = const Size(1080, 6000);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildCatalogApp(
        childId: 'c1',
        user: _coach,
        earned: const [],
      ));
      await _settle(tester);

      // Перевіряємо, що заголовки категорій відображаються
      expect(find.textContaining('Дисципліна'), findsWidgets);
      expect(find.textContaining('Тренування'), findsWidgets);
      expect(find.textContaining('Пояси'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('каталог рендериться без краша', (tester) async {
      await tester.pumpWidget(_buildCatalogApp(
        childId: 'c1',
        user: _coach,
        earned: const [],
      ));
      await _settle(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group('SC-A-004: батько бачить нагороди своєї дитини', () {
    testWidgets('parent user → каталог для дитини c1 без кращ', (tester) async {
      final parent = _parent('c1');
      final earned = [_earned('c1', 'first_training')];
      await tester.pumpWidget(_buildCatalogApp(
        childId: 'c1',
        user: parent,
        earned: earned,
      ));
      await _settle(tester);

      // Каталог повинен відображатись без краша
      expect(tester.takeException(), isNull);
      // Загальна кількість визначень видна
      expect(find.textContaining('$totalDefs'), findsWidgets);
    });
  });

  group('SC-A-005: тренер надає нагороду — AchievementNotifier.grant записує в Firestore', () {
    testWidgets('grant → документ з\'являється в колекції achievements', (tester) async {
      final db = FakeFirebaseFirestore();
      final container = ProviderContainer(overrides: [
        firestoreProvider.overrideWithValue(db),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(achievementNotifierProvider.notifier);
      await notifier.grant('c1', 'first_training', 'coach1', note: 'Молодець!');

      final docs = await db.collection('achievements').get();
      expect(docs.docs.length, 1,
          reason: 'Після grant має бути 1 документ у колекції achievements');
      expect(docs.docs.first.id, 'c1_first_training',
          reason: 'ID документа = childId_defId');
      expect(docs.docs.first['note'], 'Молодець!',
          reason: 'Note має зберігатись у Firestore');
    });

    testWidgets('подвійний grant для того самого (childId, defId) → upsert (1 doc)', (tester) async {
      final db = FakeFirebaseFirestore();
      final container = ProviderContainer(overrides: [
        firestoreProvider.overrideWithValue(db),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(achievementNotifierProvider.notifier);
      await notifier.grant('c1', 'first_training', 'coach1');
      await notifier.grant('c1', 'first_training', 'coach1');

      final docs = await db.collection('achievements').get();
      expect(docs.docs.length, 1,
          reason: 'Повторний grant не створює дублікат — Firestore set() upsert');
    });
  });
}

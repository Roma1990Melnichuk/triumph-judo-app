import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/achievement_model.dart';

void main() {
  // ── AchievementCategory ───────────────────────────────────────────────────

  group('AchievementCategory', () {
    test('усі 9 категорій мають непорожній displayName', () {
      expect(AchievementCategory.values.length, 9);
      for (final c in AchievementCategory.values) {
        expect(c.displayName, isNotEmpty);
      }
    });

    test('belts → "Пояси"', () {
      expect(AchievementCategory.belts.displayName, 'Пояси');
    });

    test('seasonal → "Сезонні"', () {
      expect(AchievementCategory.seasonal.displayName, 'Сезонні');
    });
  });

  // ── AchievementRarity ─────────────────────────────────────────────────────

  group('AchievementRarity', () {
    test('усі 5 рідкостей мають непорожній label', () {
      expect(AchievementRarity.values.length, 5);
      for (final r in AchievementRarity.values) {
        expect(r.label, isNotEmpty);
      }
    });

    test('mythic → "Міфічне"', () {
      expect(AchievementRarity.mythic.label, 'Міфічне');
    });

    test('common → "Звичайне"', () {
      expect(AchievementRarity.common.label, 'Звичайне');
    });
  });

  // ── AchievementDef ────────────────────────────────────────────────────────

  group('AchievementDef.isManual / isAuto', () {
    const auto = AchievementDef(
      id: 'a1', name: 'Н', description: 'Д', emoji: '🥋',
      category: AchievementCategory.training,
      rarity: AchievementRarity.common,
      type: AchievementType.auto,
    );

    const manual = AchievementDef(
      id: 'a2', name: 'Н', description: 'Д', emoji: '🏆',
      category: AchievementCategory.belts,
      rarity: AchievementRarity.rare,
      type: AchievementType.manual,
    );

    const both = AchievementDef(
      id: 'a3', name: 'Н', description: 'Д', emoji: '⭐',
      category: AchievementCategory.special,
      rarity: AchievementRarity.epic,
      type: AchievementType.both,
    );

    test('auto: isAuto=true, isManual=false', () {
      expect(auto.isAuto,   isTrue);
      expect(auto.isManual, isFalse);
    });

    test('manual: isManual=true, isAuto=false', () {
      expect(manual.isManual, isTrue);
      expect(manual.isAuto,   isFalse);
    });

    test('both: isManual=true, isAuto=true', () {
      expect(both.isManual, isTrue);
      expect(both.isAuto,   isTrue);
    });
  });

  // ── AchievementModel ──────────────────────────────────────────────────────

  group('AchievementModel', () {
    final earned = DateTime(2025, 3, 15);

    test('isAuto=true коли grantedByCoachId = null', () {
      final m = AchievementModel(
        childId: 'c1', achievementId: 'belt_yellow',
        earnedAt: earned,
      );
      expect(m.isAuto, isTrue);
    });

    test('isAuto=false коли grantedByCoachId задано', () {
      final m = AchievementModel(
        childId: 'c1', achievementId: 'fair_play',
        earnedAt: earned, grantedByCoachId: 'coach1',
      );
      expect(m.isAuto, isFalse);
    });

    test('toFirestore не включає null grantedByCoachId', () {
      final m = AchievementModel(
        childId: 'c1', achievementId: 'first_training',
        earnedAt: earned,
      );
      final map = m.toFirestore();
      expect(map.containsKey('grantedByCoachId'), isFalse);
    });

    test('toFirestore не включає порожній note', () {
      final m = AchievementModel(
        childId: 'c1', achievementId: 'x',
        earnedAt: earned, note: '',
      );
      expect(m.toFirestore().containsKey('note'), isFalse);
    });

    test('toFirestore включає note якщо непорожній', () {
      final m = AchievementModel(
        childId: 'c1', achievementId: 'x',
        earnedAt: earned,
        grantedByCoachId: 'coach1',
        note: 'Відмінна поведінка',
      );
      final map = m.toFirestore();
      expect(map['note'],             'Відмінна поведінка');
      expect(map['grantedByCoachId'], 'coach1');
    });

    test('toFirestore містить childId, achievementId, earnedAt', () {
      final m = AchievementModel(
        childId: 'child42', achievementId: 'belt_black',
        earnedAt: earned,
      );
      final map = m.toFirestore();
      expect(map['childId'],       'child42');
      expect(map['achievementId'], 'belt_black');
      expect(map.containsKey('earnedAt'), isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/achievement_defs.dart';
import 'package:judo_app/core/models/achievement_model.dart';

void main() {
  group('Achievement Definitions', () {
    test('all achievements have non-empty id, name, emoji, description', () {
      for (final def in kAchievements) {
        expect(def.id, isNotEmpty, reason: '${def.name}: id empty');
        expect(def.name, isNotEmpty, reason: '${def.id}: name empty');
        expect(def.emoji, isNotEmpty, reason: '${def.id}: emoji empty');
        expect(def.description, isNotEmpty, reason: '${def.id}: description empty');
      }
    });

    test('all achievement ids are unique', () {
      final ids = kAchievements.map((d) => d.id).toList();
      final unique = ids.toSet();
      expect(unique.length, equals(ids.length),
          reason: 'Duplicate achievement IDs found');
    });

    test('total achievement count is at least 50', () {
      expect(kAchievements.length, greaterThanOrEqualTo(50));
    });

    test('achievementById returns correct definition', () {
      final def = achievementById('belt_black');
      expect(def, isNotNull);
      expect(def!.id, equals('belt_black'));
      expect(def.rarity, equals(AchievementRarity.mythic));
      expect(def.type, equals(AchievementType.auto));
    });

    test('achievementById returns null for unknown id', () {
      expect(achievementById('unknown_id_xyz'), isNull);
    });

    group('Belt achievements', () {
      const beltIds = [
        'belt_white', 'belt_whiteYellow', 'belt_yellow',
        'belt_yellowOrange', 'belt_orange', 'belt_orangeGreen',
        'belt_green', 'belt_greenBlue', 'belt_blue',
        'belt_blueBrown', 'belt_brown', 'belt_black',
      ];

      for (final id in beltIds) {
        test('$id exists and is auto', () {
          final def = achievementById(id);
          expect(def, isNotNull, reason: '$id not found');
          expect(def!.type, equals(AchievementType.auto));
          expect(def.category, equals(AchievementCategory.belts));
        });
      }

      test('belt_black is mythic rarity', () {
        expect(achievementById('belt_black')!.rarity,
            equals(AchievementRarity.mythic));
      });

      test('belt_white is common rarity', () {
        expect(achievementById('belt_white')!.rarity,
            equals(AchievementRarity.common));
      });
    });

    group('Tournament achievements', () {
      test('first_tournament exists and is auto', () {
        final def = achievementById('first_tournament');
        expect(def, isNotNull);
        expect(def!.type, equals(AchievementType.auto));
        expect(def.category, equals(AchievementCategory.tournaments));
      });

      test('first_medal exists and is rare', () {
        final def = achievementById('first_medal');
        expect(def, isNotNull);
        expect(def!.rarity, equals(AchievementRarity.rare));
      });

      test('champion exists and is epic', () {
        final def = achievementById('champion');
        expect(def, isNotNull);
        expect(def!.rarity, equals(AchievementRarity.epic));
      });

      test('medals_10 and medals_20 exist', () {
        expect(achievementById('medals_10'), isNotNull);
        expect(achievementById('medals_20'), isNotNull);
      });

      test('podium_5_streak exists and is legendary', () {
        final def = achievementById('podium_5_streak');
        expect(def, isNotNull);
        expect(def!.rarity, equals(AchievementRarity.legendary));
      });

      test('tournament_3_streak exists', () {
        expect(achievementById('tournament_3_streak'), isNotNull);
      });
    });

    group('Training achievements', () {
      const trainingIds = {
        'first_training': 'common',
        'trainings_10':   'common',
        'trainings_50':   'rare',
        'trainings_100':  'epic',
        'trainings_250':  'legendary',
        'trainings_500':  'mythic',
      };

      for (final entry in trainingIds.entries) {
        test('${entry.key} exists, is auto, category=training', () {
          final def = achievementById(entry.key);
          expect(def, isNotNull, reason: '${entry.key} not found');
          expect(def!.type, equals(AchievementType.auto));
          expect(def.category, equals(AchievementCategory.training));
        });
      }

      test('trainings_500 is mythic', () {
        expect(achievementById('trainings_500')!.rarity,
            equals(AchievementRarity.mythic));
      });
    });

    group('Discipline/Streak achievements', () {
      test('streak_7 exists and is auto', () {
        final def = achievementById('streak_7');
        expect(def, isNotNull);
        expect(def!.type, equals(AchievementType.auto));
      });

      test('streak_14 exists', () {
        expect(achievementById('streak_14'), isNotNull);
      });

      test('streak_30 exists and is hidden', () {
        final def = achievementById('streak_30');
        expect(def, isNotNull);
        expect(def!.isHidden, isTrue);
      });

      test('streak_100 is legendary', () {
        expect(achievementById('streak_100')!.rarity,
            equals(AchievementRarity.legendary));
      });

      test('year_no_miss is mythic', () {
        expect(achievementById('year_no_miss')!.rarity,
            equals(AchievementRarity.mythic));
      });
    });

    group('Behavior achievements (manual)', () {
      const ids = [
        'friend_of_team', 'team_leader', 'team_support',
        'fair_play', 'respect',
      ];

      for (final id in ids) {
        test('$id is manual and behavior category', () {
          final def = achievementById(id);
          expect(def, isNotNull);
          expect(def!.isManual, isTrue);
          expect(def.category, equals(AchievementCategory.behavior));
        });
      }
    });

    group('Technique achievements (manual)', () {
      const ids = [
        'throw_master', 'hold_master', 'pain_master',
        'counter_master', 'technician_of_year',
      ];

      for (final id in ids) {
        test('$id is manual and technique category', () {
          final def = achievementById(id);
          expect(def, isNotNull);
          expect(def!.isManual, isTrue);
          expect(def.category, equals(AchievementCategory.technique));
        });
      }

      test('technician_of_year is legendary', () {
        expect(achievementById('technician_of_year')!.rarity,
            equals(AchievementRarity.legendary));
      });
    });

    group('Theory achievements (manual)', () {
      const ids = ['judo_expert', 'judo_historian', 'judo_code', 'terminology_master'];

      for (final id in ids) {
        test('$id is manual and theory category', () {
          final def = achievementById(id);
          expect(def, isNotNull);
          expect(def!.isManual, isTrue);
          expect(def.category, equals(AchievementCategory.theory));
        });
      }
    });

    group('Special achievements', () {
      test('senseis_chosen is manual and legendary', () {
        final def = achievementById('senseis_chosen');
        expect(def, isNotNull);
        expect(def!.isManual, isTrue);
        expect(def.rarity, equals(AchievementRarity.legendary));
      });

      test('triumph_legend is manual and mythic', () {
        final def = achievementById('triumph_legend');
        expect(def, isNotNull);
        expect(def!.rarity, equals(AchievementRarity.mythic));
      });

      test('secret_technique is hidden', () {
        expect(achievementById('secret_technique')!.isHidden, isTrue);
      });

      test('club_pride is legendary', () {
        expect(achievementById('club_pride')!.rarity,
            equals(AchievementRarity.legendary));
      });
    });

    group('Seasonal achievements (manual)', () {
      const ids = ['autumn_champion', 'winter_warrior', 'spring_breakthrough', 'summer_champion'];

      for (final id in ids) {
        test('$id is manual and seasonal category', () {
          final def = achievementById(id);
          expect(def, isNotNull);
          expect(def!.isManual, isTrue);
          expect(def.category, equals(AchievementCategory.seasonal));
        });
      }

      test('golden_era is mythic', () {
        expect(achievementById('golden_era')!.rarity,
            equals(AchievementRarity.mythic));
      });
    });

    group('manualAchievementsByCategory', () {
      test('contains only manual achievements', () {
        final grouped = manualAchievementsByCategory;
        for (final defs in grouped.values) {
          for (final def in defs) {
            expect(def.isManual, isTrue,
                reason: '${def.id} should be manual');
          }
        }
      });

      test('contains behavior, technique, theory, special, seasonal categories', () {
        final grouped = manualAchievementsByCategory;
        expect(grouped.keys, contains(AchievementCategory.behavior));
        expect(grouped.keys, contains(AchievementCategory.technique));
        expect(grouped.keys, contains(AchievementCategory.theory));
        expect(grouped.keys, contains(AchievementCategory.special));
        expect(grouped.keys, contains(AchievementCategory.seasonal));
      });
    });
  });
}

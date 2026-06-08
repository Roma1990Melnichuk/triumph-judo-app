import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/competition_result_model.dart';
import '../../competitions/providers/competitions_provider.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../team/providers/children_provider.dart';

typedef AchProgressEntry = ({int current, int target});
typedef AchProgressMap = Map<String, AchProgressEntry>;

// ── Training stats for any child (total sessions + current streak) ────────────

final childTrainingStatsProvider =
    Provider.family<({int total, int streak}), String>((ref, childId) {
  const empty = (total: 0, streak: 0);

  final allChildren = ref.watch(allChildrenProvider).value ?? [];
  final child = allChildren.where((c) => c.id == childId).firstOrNull;
  if (child == null) return empty;

  // sessions sorted DESC (most-recent first) — same as streakDataProvider
  final sessions =
      ref.watch(coachSessionsProvider(child.coachId)).value ?? [];

  int total = 0;
  int streak = 0;
  bool streakBroken = false;

  for (final session in sessions) {
    final present = session.isPresent(childId);
    if (present) {
      total++;
      if (!streakBroken) streak++;
    } else {
      streakBroken = true;
    }
  }

  return (total: total, streak: streak);
});

// ── Progress toward each auto achievement ─────────────────────────────────────

/// Returns progress for every auto achievement that is in-flight
/// (current > 0 && current < target).
/// Caller should subtract already-earned achievements before rendering.
final achievementProgressProvider =
    Provider.family<AchProgressMap, String>((ref, childId) {
  final stats = ref.watch(childTrainingStatsProvider(childId));
  final results =
      ref.watch(childResultsProvider(childId)).value ?? <CompetitionResultModel>[];

  final total = stats.total;
  final streak = stats.streak;
  final medals = results.where((r) => r.place <= 3).length;
  final comps = results.length;

  // Most-recent 5: count consecutive podiums from the front
  final podiumStreak = results.take(5).where((r) => r.place <= 3).length;

  final AchProgressMap map = {};

  // Training count
  _add(map, 'first_training',  total,   1);
  _add(map, 'trainings_10',    total,  10);
  _add(map, 'trainings_50',    total,  50);
  _add(map, 'trainings_100',   total, 100);
  _add(map, 'trainings_250',   total, 250);
  _add(map, 'trainings_500',   total, 500);

  // Streak
  _add(map, 'streak_7',   streak,   7);
  _add(map, 'streak_14',  streak,  14);
  _add(map, 'streak_30',  streak,  30);
  _add(map, 'streak_100', streak, 100);

  // Competitions
  _add(map, 'first_tournament',    comps,  1);
  _add(map, 'tournament_3_streak', comps,  3);
  _add(map, 'first_medal',         medals, 1);
  _add(map, 'medals_10',           medals, 10);
  _add(map, 'medals_20',           medals, 20);
  _add(map, 'podium_5_streak',     podiumStreak, 5);

  return map;
});

void _add(AchProgressMap map, String id, int current, int target) {
  if (current > 0 && current < target) {
    map[id] = (current: current, target: target);
  }
}

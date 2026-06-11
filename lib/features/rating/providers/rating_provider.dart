import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/child_model.dart';
import '../../competitions/providers/competitions_provider.dart';
import '../../team/providers/children_provider.dart';

class RatingFilter {
  final String lastName;
  final int? birthYear;
  final String? weightCategory;
  final Gender? gender;
  final bool top20Only;
  final int? competitionYear;

  const RatingFilter({
    this.lastName = '',
    this.birthYear,
    this.weightCategory,
    this.gender,
    this.top20Only = false,
    this.competitionYear,
  });

  RatingFilter copyWith({
    String? lastName,
    int? birthYear,
    String? weightCategory,
    Gender? gender,
    bool? top20Only,
    int? competitionYear,
    bool clearBirthYear = false,
    bool clearWeightCategory = false,
    bool clearGender = false,
    bool clearCompetitionYear = false,
  }) =>
      RatingFilter(
        lastName: lastName ?? this.lastName,
        birthYear: clearBirthYear ? null : (birthYear ?? this.birthYear),
        weightCategory: clearWeightCategory ? null : (weightCategory ?? this.weightCategory),
        gender: clearGender ? null : (gender ?? this.gender),
        top20Only: top20Only ?? this.top20Only,
        competitionYear: clearCompetitionYear ? null : (competitionYear ?? this.competitionYear),
      );
}

final ratingFilterProvider =
    StateProvider<RatingFilter>((ref) => const RatingFilter());

class CoachRanking {
  const CoachRanking({
    required this.coachId,
    required this.coachName,
    required this.athleteCount,
    required this.totalPoints,
  });
  final String coachId;
  final String coachName;
  final int athleteCount;
  final int totalPoints;
}

final coachRankingProvider = Provider<List<CoachRanking>>((ref) {
  final children = ref.watch(allChildrenProvider).asData?.value ?? [];
  final map = <String, List<ChildModel>>{};
  for (final c in children) {
    if (c.coachId.isNotEmpty) (map[c.coachId] ??= []).add(c);
  }
  final list = map.entries.map((e) => CoachRanking(
    coachId: e.key,
    coachName: e.value.first.coachName,
    athleteCount: e.value.length,
    totalPoints: e.value.fold(0, (s, a) => s + a.totalPoints),
  )).toList()
    ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
  return list;
});

// Points per child for the selected competition year (empty if no year selected)
final yearPointsProvider = Provider<Map<String, int>>((ref) {
  final f = ref.watch(ratingFilterProvider);
  if (f.competitionYear == null) return const {};
  final results = ref.watch(allResultsProvider).asData?.value ?? [];
  final map = <String, int>{};
  for (final r in results.where((r) => r.seasonYear == f.competitionYear)) {
    map[r.childId] = (map[r.childId] ?? 0) + r.points;
  }
  return map;
});

// Available competition season years from results data
final competitionSeasonYearsProvider = Provider<List<int>>((ref) {
  final results = ref.watch(allResultsProvider).asData?.value ?? [];
  final years = results.map((r) => r.seasonYear).toSet().toList()
    ..sort((a, b) => b.compareTo(a));
  if (years.isEmpty) return [DateTime.now().year];
  return years;
});

// Full sorted list without top-20 cap.
// Used both by ratedChildrenProvider (which slices) and by the parent windowed view.
final allRatedSortedProvider = Provider<List<ChildModel>>((ref) {
  final children = ref.watch(allChildrenProvider).asData?.value ?? [];
  final f = ref.watch(ratingFilterProvider);
  final yearPoints = ref.watch(yearPointsProvider);

  final filtered = children.where((c) {
    if (f.lastName.isNotEmpty &&
        !c.lastName.toLowerCase().contains(f.lastName.toLowerCase()) &&
        !c.firstName.toLowerCase().contains(f.lastName.toLowerCase())) {
      return false;
    }
    if (f.birthYear != null && c.birthYear != f.birthYear) return false;
    if (f.weightCategory != null && c.weightCategory != f.weightCategory) return false;
    if (f.gender != null && c.gender != f.gender) return false;
    if (f.competitionYear != null && !yearPoints.containsKey(c.id)) return false;
    return true;
  }).toList();

  if (f.competitionYear != null) {
    filtered.sort((a, b) {
      final cmp = (yearPoints[b.id] ?? 0).compareTo(yearPoints[a.id] ?? 0);
      if (cmp != 0) return cmp;
      return a.lastName.compareTo(b.lastName);
    });
  } else {
    filtered.sort((a, b) {
      final cmp = b.totalPoints.compareTo(a.totalPoints);
      if (cmp != 0) return cmp;
      return a.lastName.compareTo(b.lastName);
    });
  }
  return filtered;
});

// Top-20 slice — default view for coaches and parents whose child is in top 20.
final ratedChildrenProvider = Provider<List<ChildModel>>((ref) {
  final all = ref.watch(allRatedSortedProvider);
  final f = ref.watch(ratingFilterProvider);
  if (f.top20Only) return all.take(20).toList();
  return all;
});

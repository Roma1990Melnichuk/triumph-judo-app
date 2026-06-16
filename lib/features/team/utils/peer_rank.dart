import '../../../core/models/child_model.dart';

class PeerRanks {
  final Map<String, int> yearRanks;    // childId → місце серед однолітків
  final Map<int, int> yearTotals;      // birthYear → загальна кількість
  final Map<String, int> weightRanks;  // childId → місце в категорії ваги
  final Map<String, int> weightTotals; // 'year/weight' → загальна кількість

  const PeerRanks({
    required this.yearRanks,
    required this.yearTotals,
    required this.weightRanks,
    required this.weightTotals,
  });
}

/// Обчислює місця серед однолітків (за роком народження) та у ваговій
/// категорії. Сортування: більше балів = краще місце; при рівних балах —
/// за прізвищем (алфавітний порядок = краще місце).
PeerRanks computePeerRanks(List<ChildModel> children) {
  final sorted = [...children]..sort((a, b) {
      final cmp = b.totalPoints.compareTo(a.totalPoints);
      if (cmp != 0) return cmp;
      return a.lastName.compareTo(b.lastName);
    });

  final yearRanks = <String, int>{};
  final yearTotals = <int, int>{};
  final weightRanks = <String, int>{};
  final weightTotals = <String, int>{};
  final yrCounter = <int, int>{};
  final wtCounter = <String, int>{};

  for (final c in sorted) {
    yearTotals[c.birthYear] = (yearTotals[c.birthYear] ?? 0) + 1;
    yrCounter[c.birthYear] = (yrCounter[c.birthYear] ?? 0) + 1;
    yearRanks[c.id] = yrCounter[c.birthYear]!;

    final wk = '${c.birthYear}/${c.weightCategory}';
    weightTotals[wk] = (weightTotals[wk] ?? 0) + 1;
    wtCounter[wk] = (wtCounter[wk] ?? 0) + 1;
    weightRanks[c.id] = wtCounter[wk]!;
  }

  return PeerRanks(
    yearRanks: yearRanks,
    yearTotals: yearTotals,
    weightRanks: weightRanks,
    weightTotals: weightTotals,
  );
}

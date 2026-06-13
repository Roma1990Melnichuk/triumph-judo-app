import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/child_model.dart';
import '../../../core/models/competition_result_model.dart';
import '../../competitions/providers/competitions_provider.dart';
import '../../team/providers/children_provider.dart';
import '../../../shared/widgets/triumph_icon.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Medal Stats Model
// ─────────────────────────────────────────────────────────────────────────────

class MedalStats {
  final int gold;
  final int silver;
  final int bronze;

  const MedalStats({this.gold = 0, this.silver = 0, this.bronze = 0});

  int get total => gold + silver + bronze;

  MedalStats operator +(MedalStats o) =>
      MedalStats(gold: gold + o.gold, silver: silver + o.silver, bronze: bronze + o.bronze);

  static MedalStats fromResults(List<CompetitionResultModel> r) {
    int g = 0, s = 0, b = 0;
    for (final x in r) {
      if (x.place == 1) g++;
      else if (x.place == 2) s++;
      else if (x.place == 3) b++;
    }
    return MedalStats(gold: g, silver: s, bronze: b);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full Medal Tracker Screen
// ─────────────────────────────────────────────────────────────────────────────

class MedalTrackerScreen extends ConsumerStatefulWidget {
  const MedalTrackerScreen({super.key});

  @override
  ConsumerState<MedalTrackerScreen> createState() => _MedalTrackerScreenState();
}

class _MedalTrackerScreenState extends ConsumerState<MedalTrackerScreen> {
  int? _season = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allResultsProvider);
    final childrenAsync = ref.watch(allChildrenProvider);

    return allAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Помилка: $e')),
      data: (all) {
        final children = childrenAsync.asData?.value ?? [];
        final results = _season == null
            ? all
            : all.where((r) => r.seasonYear == _season).toList();
        final medals = results.where((r) => r.place <= 3).toList();
        final teamStats = MedalStats.fromResults(medals);

        final seasons = all.map((r) => r.seasonYear).toSet().toList()
          ..sort((a, b) => b.compareTo(a));

        // Top athletes by medals
        final athleteResults = <String, List<CompetitionResultModel>>{};
        for (final r in medals) {
          athleteResults.putIfAbsent(r.childId, () => []).add(r);
        }
        final topAthletes = athleteResults.entries
            .map((e) => (
                  child: children.firstWhere(
                    (c) => c.id == e.key,
                    orElse: () => ChildModel(
                      id: e.key,
                      firstName: e.value.first.childName.split(' ').first,
                      lastName: e.value.first.childName.split(' ').last,
                      birthYear: 0,
                      weightCategory: '',
                      currentBelt: BeltLevel.white,
                      totalPoints: 0,
                      coachId: '',
                      coachName: '',
                      createdAt: DateTime(2024),
                    ),
                  ),
                  stats: MedalStats.fromResults(e.value),
                ))
            .toList()
          ..sort((a, b) => b.stats.total.compareTo(a.stats.total));

        // Recent tournament results (grouped by tournament)
        final byTournament = <String, List<CompetitionResultModel>>{};
        for (final r in results.where((r) => r.place <= 3)) {
          byTournament.putIfAbsent(r.competitionName, () => []).add(r);
        }
        final recentTournaments = byTournament.entries.toList()
          ..sort((a, b) =>
              (b.value.first.date).compareTo(a.value.first.date));

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // ── Season selector ─────────────────────────────────────────────
            _SeasonSelector(
              seasons: seasons,
              selected: _season,
              onChanged: (y) => setState(() => _season = y),
            ),
            const SizedBox(height: 20),

            // ── Section 1: Top summary ──────────────────────────────────────
            _SectionHeader(
              title: 'Загальна статистика',
              subtitle: _season == null ? 'Весь час' : 'Сезон $_season',
            ),
            const SizedBox(height: 10),
            _TopSummaryCard(stats: teamStats),
            const SizedBox(height: 24),

            // ── Section 2: Season overview ──────────────────────────────────
            _SectionHeader(
              title: 'Огляд сезону',
              subtitle: 'Медалі по рівнях змагань',
            ),
            const SizedBox(height: 10),
            _LevelBreakdown(results: medals),
            const SizedBox(height: 24),

            // ── Section 3: Top athletes ─────────────────────────────────────
            if (topAthletes.isNotEmpty) ...[
              _SectionHeader(
                title: 'Топ спортсмени',
                subtitle: 'За кількістю медалей',
              ),
              const SizedBox(height: 10),
              ...topAthletes.take(10).map((a) => _AthleteRow(
                    name: a.child.fullName,
                    stats: a.stats,
                  )),
              const SizedBox(height: 24),
            ],

            // ── Section 4: Recent tournaments ───────────────────────────────
            if (recentTournaments.isNotEmpty) ...[
              _SectionHeader(
                title: 'Останні турніри',
                subtitle: 'Результати по змаганнях',
              ),
              const SizedBox(height: 10),
              ...recentTournaments.take(8).map((e) => _TournamentCard(
                    name: e.key,
                    results: e.value,
                  )),
            ],

            const SizedBox(height: 60),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard compact card (used on Home screen)
// ─────────────────────────────────────────────────────────────────────────────

class MedalTrackerDashboardCard extends ConsumerWidget {
  const MedalTrackerDashboardCard({super.key, this.onViewDetails});
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allResultsProvider);
    final season = DateTime.now().year;

    return allAsync.when(
      loading: () => _DashboardCardSkeleton(),
      error: (_, __) => const SizedBox(),
      data: (all) {
        final medals = all
            .where((r) => r.seasonYear == season && r.place <= 3)
            .toList();
        final stats = MedalStats.fromResults(medals);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.surface3),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.06),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.ctaGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.emoji_events_rounded,
                          size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Трекер медалей',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Результати сезону $season',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (stats.total > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppColors.ctaGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${stats.total} медалей',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Medal counters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(child: _MedalCounter(
                        emoji: '🥇', label: 'Золото',
                        count: stats.gold, color: AppColors.goldMedal)),
                    const SizedBox(width: 8),
                    Expanded(child: _MedalCounter(
                        emoji: '🥈', label: 'Срібло',
                        count: stats.silver, color: AppColors.silverMedal)),
                    const SizedBox(width: 8),
                    Expanded(child: _MedalCounter(
                        emoji: '🥉', label: 'Бронза',
                        count: stats.bronze, color: AppColors.bronzeMedal)),
                  ],
                ),
              ),

              // Distribution bar
              if (stats.total > 0) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        if (stats.gold > 0)
                          Expanded(flex: stats.gold,
                              child: Container(height: 5, color: AppColors.goldMedal)),
                        if (stats.silver > 0)
                          Expanded(flex: stats.silver,
                              child: Container(height: 5, color: AppColors.silverMedal)),
                        if (stats.bronze > 0)
                          Expanded(flex: stats.bronze,
                              child: Container(height: 5, color: AppColors.bronzeMedal)),
                      ],
                    ),
                  ),
                ),
              ],

              // CTA
              if (onViewDetails != null) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                TextButton(
                  onPressed: onViewDetails,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'Детальніше →',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ] else
                const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surface3),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Athlete medal block (used in Profile screen)
// ─────────────────────────────────────────────────────────────────────────────

class AthleteMedalBlock extends ConsumerWidget {
  const AthleteMedalBlock({super.key, required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(childResultsProvider(childId));

    return resultsAsync.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (results) {
        final medals = results.where((r) => r.place <= 3).toList();
        if (medals.isEmpty) return const SizedBox();

        final stats = MedalStats.fromResults(medals);
        final best = medals.firstWhere(
          (r) => r.place == 1,
          orElse: () => medals.first,
        );
        final recent = medals.first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Медалі',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surface3),
              ),
              child: Column(
                children: [
                  // Medal counts row
                  Row(
                    children: [
                      Expanded(child: _MedalCounter(
                          emoji: '🥇', label: 'Золото',
                          count: stats.gold, color: AppColors.goldMedal)),
                      const SizedBox(width: 8),
                      Expanded(child: _MedalCounter(
                          emoji: '🥈', label: 'Срібло',
                          count: stats.silver, color: AppColors.silverMedal)),
                      const SizedBox(width: 8),
                      Expanded(child: _MedalCounter(
                          emoji: '🥉', label: 'Бронза',
                          count: stats.bronze, color: AppColors.bronzeMedal)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Best result
                  _ResultInfoRow(
                    icon: const ColorFiltered(
                      colorFilter: ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
                      child: TriumphIcon(TIcon.trophy, size: 16),
                    ),
                    label: 'Найкращий результат',
                    value: '${best.competitionName} — ${_placeLabel(best.place)}',
                  ),
                  const SizedBox(height: 8),

                  // Recent tournament
                  _ResultInfoRow(
                    icon: const ColorFiltered(
                      colorFilter: ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn),
                      child: TriumphIcon(TIcon.calendar, size: 16),
                    ),
                    label: 'Останній турнір',
                    value: '${recent.competitionName} — ${_placeLabel(recent.place)}',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static String _placeLabel(int p) =>
      p == 1 ? '1 місце 🥇' : p == 2 ? '2 місце 🥈' : '3 місце 🥉';
}

class _ResultInfoRow extends StatelessWidget {
  const _ResultInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final Widget icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared components
// ─────────────────────────────────────────────────────────────────────────────

class _MedalCounter extends StatelessWidget {
  const _MedalCounter({
    required this.emoji,
    required this.label,
    required this.count,
    required this.color,
  });

  final String emoji;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: count > 0 && color == AppColors.goldMedal
              ? [BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 12,
                )]
              : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
}

class _TopSummaryCard extends StatelessWidget {
  const _TopSummaryCard({required this.stats});
  final MedalStats stats;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surface3),
        ),
        child: Column(
          children: [
            // Total medals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Всього медалей',
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: AppColors.ctaGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${stats.total}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _MedalCounter(
                    emoji: '🥇', label: 'Золото',
                    count: stats.gold, color: AppColors.goldMedal)),
                const SizedBox(width: 10),
                Expanded(child: _MedalCounter(
                    emoji: '🥈', label: 'Срібло',
                    count: stats.silver, color: AppColors.silverMedal)),
                const SizedBox(width: 10),
                Expanded(child: _MedalCounter(
                    emoji: '🥉', label: 'Бронза',
                    count: stats.bronze, color: AppColors.bronzeMedal)),
              ],
            ),
            if (stats.total > 0) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    if (stats.gold > 0)
                      Expanded(flex: stats.gold,
                          child: Container(height: 8, color: AppColors.goldMedal)),
                    if (stats.silver > 0)
                      Expanded(flex: stats.silver,
                          child: Container(height: 8, color: AppColors.silverMedal)),
                    if (stats.bronze > 0)
                      Expanded(flex: stats.bronze,
                          child: Container(height: 8, color: AppColors.bronzeMedal)),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
}

class _SeasonSelector extends StatelessWidget {
  const _SeasonSelector({
    required this.seasons,
    required this.selected,
    required this.onChanged,
  });

  final List<int> seasons;
  final int? selected;
  final void Function(int?) onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [null, ...seasons].map((y) {
          final active = y == selected;
          return GestureDetector(
            onTap: () => onChanged(y),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: active ? AppColors.ctaGradient : null,
                color: active ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active ? Colors.transparent : AppColors.surface3),
              ),
              child: Text(
                y == null ? 'Весь час' : '$y',
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      );
}

class _AthleteRow extends StatelessWidget {
  const _AthleteRow({required this.name, required this.stats});
  final String name;
  final MedalStats stats;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surface3),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary)),
            ),
            Text('🥇${stats.gold}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldMedal)),
            const SizedBox(width: 8),
            Text('🥈${stats.silver}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.silverMedal)),
            const SizedBox(width: 8),
            Text('🥉${stats.bronze}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.bronzeMedal)),
            const SizedBox(width: 12),
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: AppColors.ctaGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text('${stats.total}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ),
          ],
        ),
      );
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({required this.name, required this.results});
  final String name;
  final List<CompetitionResultModel> results;

  @override
  Widget build(BuildContext context) {
    final stats = MedalStats.fromResults(results);
    final date = results.first.date;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surface3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(
                  DateFormat('dd MMMM yyyy', 'uk').format(date),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Team: 🥇${stats.gold} / 🥈${stats.silver} / 🥉${stats.bronze}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${stats.total}',
              style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBreakdown extends StatelessWidget {
  const _LevelBreakdown({required this.results});
  final List<CompetitionResultModel> results;

  @override
  Widget build(BuildContext context) {
    final byLevel = <CompetitionLevel, List<CompetitionResultModel>>{};
    for (final r in results) {
      byLevel.putIfAbsent(r.level, () => []).add(r);
    }
    if (byLevel.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surface3),
        ),
        child: const Center(
          child: Text('Немає даних за цей сезон',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    final levels = CompetitionLevel.values.where(byLevel.containsKey).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surface3),
      ),
      child: Column(
        children: levels.asMap().entries.map((e) {
          final level = e.value;
          final stats = MedalStats.fromResults(byLevel[level]!);
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Expanded(
                  child: Text(level.displayName,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                ),
                Text('🥇${stats.gold} 🥈${stats.silver} 🥉${stats.bronze}',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 10),
                Text('= ${stats.total}',
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ]),
            ),
            if (e.key < levels.length - 1) const Divider(height: 1, indent: 14),
          ]);
        }).toList(),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/models/child_model.dart' show displayWeight, Gender, ChildModel, weightCategories;
import '../../../features/team/providers/children_provider.dart' show allChildrenProvider, birthYearsProvider, birthYearCountsProvider;
import '../providers/rating_provider.dart';
import '../../../shared/animations/app_animations.dart';
import '../../../shared/widgets/belt_badge.dart';
import '../../../shared/widgets/default_avatar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/triumph_icon.dart';
import 'medal_tracker_screen.dart';

class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({super.key});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

enum _RatingTab { general, team, medals }
enum _RatingPeriod { month, quarter, year, allTime }

extension _PeriodLabel on _RatingPeriod {
  String get label {
    switch (this) {
      case _RatingPeriod.month:   return 'Місяць';
      case _RatingPeriod.quarter: return 'Квартал';
      case _RatingPeriod.year:    return 'Рік';
      case _RatingPeriod.allTime: return 'Весь час';
    }
  }
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  final _searchCtrl = TextEditingController();
  bool _filtersExpanded = true;
  _RatingTab _tab = _RatingTab.general;
  _RatingPeriod _period = _RatingPeriod.allTime;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    ref.read(ratingFilterProvider.notifier).update(
      (s) => s.copyWith(lastName: _searchCtrl.text),
    );
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(ratingFilterProvider);
    final birthYears = ref.watch(birthYearsProvider);
    final birthYearCounts = ref.watch(birthYearCountsProvider);
    final user = ref.watch(currentUserModelProvider).value;
    final isCoach = user?.isCoach ?? false;
    final allAsync = ref.watch(allChildrenProvider);
    final coachRankings = ref.watch(coachRankingProvider);
    final seasonYears = ref.watch(competitionSeasonYearsProvider);
    final yearPoints = ref.watch(yearPointsProvider);

    // ── Top-20 / windowed view logic — ERR-04 Fix ─────────────────────────
    final allRated = ref.watch(allRatedSortedProvider);
    final myChildId = isCoach ? null : user?.childIds.firstOrNull;

    List<ChildModel> children;
    int rankOffset = 0;
    bool isWindowed = false;
    int? myActualRank;

    if (!isCoach && myChildId != null) {
      final myRank = allRated.indexWhere((c) => c.id == myChildId);
      if (myRank >= 20 && !filter.top20Only) {
        // Child is outside top 20: center window on child
        isWindowed = true;
        myActualRank = myRank + 1;
        int start = (myRank - 5).clamp(0, allRated.length - 1);
        int end   = (start + 11).clamp(0, allRated.length);
        rankOffset = start;
        children = allRated.sublist(start, end);
      } else {
        myActualRank = myRank >= 0 ? myRank + 1 : null;
        children = allRated.take(20).toList();
      }
    } else {
      children = allRated.take(20).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Рейтинг',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _filtersExpanded = !_filtersExpanded),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _filtersExpanded
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _filtersExpanded
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : AppColors.surface3,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _filtersExpanded
                            ? Icons.filter_list_off
                            : Icons.filter_list,
                        color: _filtersExpanded
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab row ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: _RatingTab.values.map((t) {
                  final active = t == _tab;
                  return GestureDetector(
                    onTap: () => setState(() => _tab = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: active ? AppColors.ctaGradient : null,
                        color: active ? null : AppColors.surface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              active ? Colors.transparent : AppColors.surface3,
                        ),
                      ),
                      child: Text(
                        t == _RatingTab.general
                            ? 'Загальний'
                            : t == _RatingTab.team
                                ? 'Командний'
                                : '🏅 Медалі',
                        style: TextStyle(
                          color:
                              active ? Colors.white : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight:
                              active ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Period chips ─────────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: _RatingPeriod.values.map((p) {
                  final active = p == _period;
                  return GestureDetector(
                    onTap: () => setState(() => _period = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : AppColors.surface2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: active
                              ? AppColors.accent.withValues(alpha: 0.5)
                              : AppColors.surface3,
                        ),
                      ),
                      child: Text(
                        p.label,
                        style: TextStyle(
                          color: active
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight:
                              active ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: AmbientBackground(
        child: _tab == _RatingTab.medals
          ? const MedalTrackerScreen()
          : _tab == _RatingTab.team
              ? _TeamRatingView(rankings: coachRankings)
              : Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              keyboardType: TextInputType.name,
              decoration: InputDecoration(
                hintText: 'Пошук за прізвищем...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: filter.lastName.isNotEmpty ? null : Colors.transparent,
                  ),
                  onPressed: filter.lastName.isNotEmpty
                      ? () {
                          _searchCtrl.clear();
                          ref.read(ratingFilterProvider.notifier)
                              .update((s) => s.copyWith(lastName: ''));
                        }
                      : null,
                ),
              ),
            ),
          ),

          // Filter chips (collapsible)
          if (_filtersExpanded) ...[
            const Divider(height: 1),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Top 20 toggle — always first
                  _RatingChip(
                    label: 'Топ 20',
                    selected: filter.top20Only,
                    tIcon: TIcon.trophy,
                    onTap: () => ref.read(ratingFilterProvider.notifier).state =
                        filter.copyWith(top20Only: !filter.top20Only),
                    onClear: null,
                  ),
                  const SizedBox(width: 8),
                  _RatingChip(
                    label: filter.birthYear?.toString() ?? 'Рік народження',
                    selected: filter.birthYear != null,
                    onTap: () => _showYearPicker(context, ref, filter, birthYears, birthYearCounts),
                    onClear: filter.birthYear != null
                        ? () => ref.read(ratingFilterProvider.notifier).state =
                            filter.copyWith(clearBirthYear: true)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  _RatingChip(
                    label: filter.weightCategory != null
                        ? displayWeight(filter.weightCategory!)
                        : 'Вага',
                    selected: filter.weightCategory != null,
                    onTap: () => _showWeightPicker(context, ref, filter, weightCategories),
                    onClear: filter.weightCategory != null
                        ? () => ref.read(ratingFilterProvider.notifier).state =
                            filter.copyWith(clearWeightCategory: true)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  _RatingChip(
                    label: filter.gender?.displayName ?? 'Стать',
                    selected: filter.gender != null,
                    onTap: () => _showGenderPicker(context, ref, filter),
                    onClear: filter.gender != null
                        ? () => ref.read(ratingFilterProvider.notifier).state =
                            filter.copyWith(clearGender: true)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  _RatingChip(
                    label: filter.competitionYear != null
                        ? 'Сезон ${filter.competitionYear}'
                        : 'Сезон',
                    selected: filter.competitionYear != null,
                    tIcon: TIcon.trophy,
                    onTap: () => _showSeasonYearPicker(context, ref, filter, seasonYears),
                    onClear: filter.competitionYear != null
                        ? () => ref.read(ratingFilterProvider.notifier).state =
                            filter.copyWith(clearCompetitionYear: true)
                        : null,
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 1),

          // Windowed view banner — shown when parent's child is outside top 20
          if (isWindowed && myActualRank != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  ColorFiltered(
                    colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                    child: TriumphIcon(TIcon.athlete, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ваше місце: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '#$myActualRank',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

          // Top 3 — 3D podium: 3rd→2nd→1st sequential entry
          if (!isWindowed && children.length >= 3)
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _PodiumItem(child: children[1], place: 2, color: AppColors.silverMedal, entryDelay: 700),
                  const SizedBox(width: 6),
                  _PodiumItem(child: children[0], place: 1, color: AppColors.goldMedal, entryDelay: 1400),
                  const SizedBox(width: 6),
                  _PodiumItem(child: children[2], place: 3, color: AppColors.bronzeMedal, entryDelay: 0),
                ],
              ),
            ),

          // Full list
          Expanded(
            child: allAsync.isLoading
                ? const Center(child: CircularProgressIndicator())
                : children.isEmpty
                    ? const EmptyState(
                        tIcon: TIcon.trophy,
                        message: 'Поки що немає результатів',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
                        itemCount: children.length,
                        itemBuilder: (context, i) {
                          final child = children[i];
                          final isOwn = user?.ownsChild(child.id) ?? false;
                          final canOpen = isCoach || isOwn;
                          final rank = rankOffset + i;
                          final isTopThree = rank < 3;
                          final medalColor = rank == 0
                              ? AppColors.goldMedal
                              : rank == 1
                                  ? AppColors.silverMedal
                                  : AppColors.bronzeMedal;

                          return Card(
                              shape: isTopThree
                                  ? RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: medalColor.withValues(alpha: 0.35),
                                        width: 1,
                                      ),
                                    )
                                  : null,
                            child: ListTile(
                              onTap: canOpen
                                  ? () => context.push('/team/${child.id}')
                                  : null,
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '#${rank + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: rank < 3
                                            ? [
                                                AppColors.goldMedal,
                                                AppColors.silverMedal,
                                                AppColors.bronzeMedal
                                              ][rank]
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  child.photoUrl != null
                                      ? CircleAvatar(
                                          radius: 20,
                                          backgroundImage:
                                              CachedNetworkImageProvider(
                                                  child.photoUrl!),
                                        )
                                      : DefaultAvatarCircle(
                                          gender: child.gender,
                                          radius: 20,
                                        ),
                                ],
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    child.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  if (isOwn && !isCoach) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Ви',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: BeltBadge(
                                          belt: child.currentBelt,
                                          size: BeltBadgeSize.small),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${child.birthYear} р.н.',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  CountUpText(
                                    filter.competitionYear != null
                                        ? (yearPoints[child.id] ?? 0)
                                        : child.totalPoints,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                    duration: const Duration(milliseconds: 700),
                                  ),
                                  Text(
                                    filter.competitionYear != null
                                        ? '${filter.competitionYear} р.'
                                        : 'балів',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      ),
            ),
          ],
        ),
      ),
    );
  }

  void _showYearPicker(BuildContext context, WidgetRef ref, RatingFilter filter,
      List<int> years, Map<int, int> counts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Рік народження',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: years.map((y) {
                    final count = counts[y];
                    return ListTile(
                      title: Text(y.toString()),
                      trailing: count != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('$count',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary)),
                            )
                          : null,
                      selected: filter.birthYear == y,
                      selectedColor: AppColors.primary,
                      onTap: () {
                        ref.read(ratingFilterProvider.notifier).state =
                            filter.copyWith(birthYear: y);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showGenderPicker(BuildContext context, WidgetRef ref, RatingFilter filter) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Стать',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...Gender.values.map((g) {
              final selected = filter.gender == g;
              return ListTile(
                leading: Text(g.icon, style: const TextStyle(fontSize: 22)),
                title: Text(g.displayName),
                trailing: selected
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                selected: selected,
                selectedColor: AppColors.primary,
                onTap: () {
                  ref.read(ratingFilterProvider.notifier).state =
                      filter.copyWith(gender: g);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSeasonYearPicker(BuildContext context, WidgetRef ref,
      RatingFilter filter, List<int> years) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Сезон (рік змагань)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...years.map((y) => ListTile(
                  leading: ColorFiltered(
                    colorFilter: const ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn),
                    child: TriumphIcon(TIcon.trophy, size: 20),
                  ),
                  title: Text('$y'),
                  trailing: filter.competitionYear == y
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  selected: filter.competitionYear == y,
                  selectedColor: AppColors.primary,
                  onTap: () {
                    ref.read(ratingFilterProvider.notifier).state =
                        filter.copyWith(competitionYear: y);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showWeightPicker(BuildContext context, WidgetRef ref,
      RatingFilter filter, List<String> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Вагова категорія',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: categories.map((w) {
                    final selected = filter.weightCategory == w;
                    return ListTile(
                      leading: const Icon(Icons.scale,
                          size: 20, color: AppColors.textSecondary),
                      title: Text(displayWeight(w)),
                      trailing: selected
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      selected: selected,
                      selectedColor: AppColors.primary,
                      onTap: () {
                        ref.read(ratingFilterProvider.notifier).state =
                            filter.copyWith(weightCategory: w);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

}

// ── Team (coach) rating view ──────────────────────────────────────────────────

class _TeamRatingView extends StatelessWidget {
  const _TeamRatingView({required this.rankings});
  final List<CoachRanking> rankings;

  @override
  Widget build(BuildContext context) {
    if (rankings.isEmpty) {
      return const Center(
        child: Text('Немає даних',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: rankings.length,
      itemBuilder: (ctx, i) {
        final r = rankings[i];
        final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : null;
        final rankColor = i == 0
            ? AppColors.goldMedal
            : i == 1
                ? AppColors.silverMedal
                : i == 2
                    ? AppColors.bronzeMedal
                    : AppColors.textSecondary;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: i < 3
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                      color: rankColor.withValues(alpha: 0.4), width: 1),
                )
              : null,
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    medal ?? '#${i + 1}',
                    style: TextStyle(
                      fontSize: medal != null ? 20 : 13,
                      fontWeight: FontWeight.bold,
                      color: rankColor,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: rankColor.withValues(alpha: 0.18),
                  child: Text(
                    r.coachName.isNotEmpty ? r.coachName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: rankColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            title: Text(r.coachName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${r.athleteCount} спортсменів',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${r.totalPoints}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                  ),
                ),
                const Text('балів',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── One-shot entry animation for list items ───────────────────────────────────
// TweenAnimationBuilder re-runs on every rebuild — this widget animates once.

class _AnimatedListItem extends StatefulWidget {
  const _AnimatedListItem({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 40 * widget.index.clamp(0, 10));
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Opacity(
        opacity: _anim.value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - _anim.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

// ── Animated 3D podium item ───────────────────────────────────────────────────

class _PodiumItem extends StatefulWidget {
  const _PodiumItem({
    required this.child,
    required this.place,
    required this.color,
    this.entryDelay = 0,
  });

  final ChildModel child;
  final int place;
  final Color color;
  final int entryDelay; // ms before entry animation starts

  @override
  State<_PodiumItem> createState() => _PodiumItemState();
}

class _PodiumItemState extends State<_PodiumItem>
    with TickerProviderStateMixin {
  late final AnimationController _glow;
  late final AnimationController _entry;
  late final Animation<double> _glowAnim;
  late final Animation<double> _entryOpacity;
  late final Animation<double> _entrySlide;


  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _glowAnim = Tween<double>(begin: 0.10, end: 0.32).animate(
      CurvedAnimation(parent: _glow, curve: Curves.easeInOut),
    );
    _entryOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entry, curve: Curves.easeOut),
    );
    _entrySlide = Tween(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic),
    );
    if (widget.place == 1) {
      _glow.repeat(reverse: true);
    }
    Future.delayed(Duration(milliseconds: widget.entryDelay), () {
      if (mounted) _entry.forward();
    });
  }

  @override
  void dispose() {
    _glow.dispose();
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFirst = widget.place == 1;
    final avatarRadius = isFirst ? 32.0 : 24.0;

    return Expanded(
      child: AnimatedBuilder(
        animation: Listenable.merge([_glow, _entry]),
        builder: (_, __) {
          return Opacity(
            opacity: _entryOpacity.value,
            child: Transform.translate(
              offset: Offset(0, _entrySlide.value),
              child: _buildContent(isFirst, avatarRadius),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(bool isFirst, double avatarRadius) {
    final ringWidth = isFirst ? 3.5 : 2.5;
    final badgeSize = isFirst ? 24.0 : 20.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown icon for 1st place (full-color, no tint)
        if (isFirst)
          const TriumphIcon(TIcon.crown, size: 40)
        else
          const SizedBox(height: 40),

        const SizedBox(height: 6),

        // Avatar with ring + place badge
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Animated glow ring
            Container(
              width: avatarRadius * 2 + ringWidth * 2 + 8,
              height: avatarRadius * 2 + ringWidth * 2 + 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.color, width: ringWidth),
                color: widget.color.withValues(
                  alpha: isFirst ? _glowAnim.value : 0.10,
                ),
              ),
            ),
            // Avatar
            widget.child.photoUrl != null
                ? CircleAvatar(
                    radius: avatarRadius,
                    backgroundImage:
                        CachedNetworkImageProvider(widget.child.photoUrl!),
                  )
                : DefaultAvatarCircle(
                    gender: widget.child.gender,
                    radius: avatarRadius,
                    seed: widget.child.id,
                  ),
            // Place badge at bottom of ring
            Positioned(
              bottom: -(badgeSize / 2 - 4),
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.place}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isFirst ? 11 : 9,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: badgeSize / 2 + 8),

        // Name
        Text(
          widget.child.lastName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: isFirst ? 13 : 11,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 4),

        // Points — gold for all positions
        CountUpText(
          widget.child.totalPoints,
          suffix: '',
          style: TextStyle(
            color: AppColors.goldMedal,
            fontWeight: FontWeight.w800,
            fontSize: isFirst ? 18 : 15,
          ),
          duration: const Duration(milliseconds: 700),
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onClear,
    this.tIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final TIcon? tIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.redGoldGradient : null,
          color: selected ? null : AppColors.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.surface3,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tIcon != null) ...[
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  selected ? Colors.white : AppColors.textSecondary,
                  BlendMode.srcIn,
                ),
                child: TriumphIcon(tIcon!, size: 14),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (selected && onClear != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close,
                    size: 16, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

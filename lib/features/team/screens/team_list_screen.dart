import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/child_model.dart' show displayWeight;
import '../../../core/models/membership_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/competitions/providers/competitions_provider.dart';
import '../../../features/membership/providers/membership_provider.dart';
import '../../../services/export_service.dart';
import '../providers/children_provider.dart';
import '../widgets/child_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/triumph_icon.dart';

class TeamListScreen extends ConsumerStatefulWidget {
  const TeamListScreen({super.key});

  @override
  ConsumerState<TeamListScreen> createState() => _TeamListScreenState();
}

enum _TeamFilter { all, boys, girls }

class _TeamListScreenState extends ConsumerState<TeamListScreen> {
  final _searchCtrl = TextEditingController();
  bool _filtersExpanded = true;
  _TeamFilter _quickFilter = _TeamFilter.all;
  bool _coachFilterInitialized = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    ref.read(childrenFilterProvider.notifier).update(
      (state) => state.copyWith(lastName: _searchCtrl.text),
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
    final user = ref.watch(currentUserModelProvider).asData?.value;
    final isCoach = user?.isCoach ?? false;
    final allChildren = ref.watch(allChildrenProvider);
    // Parents see only their own children
    final children = isCoach
        ? ref.watch(filteredChildrenWithMedalsProvider)
        : (allChildren.value ?? []).where((c) => user?.ownsChild(c.id) ?? false).toList();
    final membershipMap = ref.watch(membershipStatusMapProvider);
    final membershipEndDateMap = isCoach ? ref.watch(membershipEndDateMapProvider) : <String, DateTime>{};
    final filter = ref.watch(childrenFilterProvider);

    if (!_coachFilterInitialized && isCoach && user != null) {
      _coachFilterInitialized = true;
      if (filter.coachId == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(childrenFilterProvider.notifier).update(
            (s) => s.copyWith(coachId: user.name),
          );
        });
      }
    }

    final birthYears = ref.watch(birthYearsProvider);
    final birthYearCounts = ref.watch(birthYearCountsProvider);
    final coaches = ref.watch(coachListProvider);
    final weightCategories = ref.watch(weightCategoriesProvider);

    final total = isCoach ? (allChildren.value?.length ?? 0) : children.length;

    // Apply quick filter
    final quickFiltered = allChildren.isLoading
        ? <dynamic>[]
        : children.where((c) {
            switch (_quickFilter) {
              case _TeamFilter.all:   return true;
              case _TeamFilter.boys:  return c.gender == Gender.male;
              case _TeamFilter.girls: return c.gender == Gender.female;
            }
          }).toList();

    // Compute peer ranks from ALL athletes (not filtered subset) so every
    // athlete sees their true academy-wide position.
    final allForRanks = [...(allChildren.value ?? [])]..sort((a, b) {
      final cmp = b.totalPoints.compareTo(a.totalPoints);
      if (cmp != 0) return cmp;
      return a.lastName.compareTo(b.lastName);
    });
    final yearTotals = <int, int>{};
    final yearCounters = <int, int>{};
    final sameYearRanks = <String, int>{};
    final weightTotals = <String, int>{};
    final weightCounters = <String, int>{};
    final sameWeightRanks = <String, int>{};
    for (final c in allForRanks) {
      yearTotals[c.birthYear] = (yearTotals[c.birthYear] ?? 0) + 1;
      yearCounters[c.birthYear] = (yearCounters[c.birthYear] ?? 0) + 1;
      sameYearRanks[c.id] = yearCounters[c.birthYear]!;
      final wKey = '${c.birthYear}/${c.weightCategory}';
      weightTotals[wKey] = (weightTotals[wKey] ?? 0) + 1;
      weightCounters[wKey] = (weightCounters[wKey] ?? 0) + 1;
      sameWeightRanks[c.id] = weightCounters[wKey]!;
    }

    final filterWidget = _FilterSection(
      isCoach: isCoach,
      filter: filter,
      quickFilter: _quickFilter,
      filtersExpanded: _filtersExpanded,
      searchCtrl: _searchCtrl,
      coaches: coaches,
      birthYears: birthYears,
      birthYearCounts: birthYearCounts,
      weightCategories: weightCategories,
      onQuickFilterChanged: (f) => setState(() => _quickFilter = f),
      onToggleFilters: () => setState(() => _filtersExpanded = !_filtersExpanded),
      onShowBeltPicker: () => _showBeltPicker(context, filter),
      onShowYearPicker: () => _showYearPicker(context, filter, birthYears, birthYearCounts),
      onShowCoachPicker: () => _showCoachPicker(context, filter, coaches),
      onShowWeightPicker: () => _showWeightPicker(context, filter, weightCategories),
      onShowGenderPicker: () => _showGenderPicker(context, filter),
      onShowMembershipPicker: () => _showMembershipPicker(context, filter),
      onShowMedalPicker: () => _showMedalPicker(context, filter),
      ref: ref,
    );

    final textScale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 2.0);
    final appBarExpandedHeight = 80.0 + textScale * 60.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Sliver app bar with title ──────────────────────────────────
          SliverAppBar(
            expandedHeight: appBarExpandedHeight,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                color: AppColors.background,
                child: SafeArea(
                  // Stack+Positioned avoids RenderFlex overflow at large textScale
                  child: Stack(
                    children: [
                      Positioned(
                        left: 20,
                        right: 16,
                        bottom: 8,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Команда',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '$total спортсменів',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCoach) ...[
                              GestureDetector(
                                onTap: () {
                                  final filtered = ref.read(filteredChildrenProvider);
                                  ExportService.exportAthletes(context, filtered);
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface2,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.surface3),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.download_outlined,
                                      color: AppColors.textSecondary, size: 20),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
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
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Sticky filter bar ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Material(
              color: AppColors.background,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: filterWidget,
              ),
            ),
          ),

          // ── Main list ─────────────────────────────────────────────────
          if (allChildren.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (quickFiltered.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                tIcon: TIcon.team,
                message: isCoach
                    ? 'Команда порожня\nДодайте першого спортсмена або\nімпортуйте список з CSV у Налаштуваннях'
                    : 'Список порожній',
                action: isCoach ? () => context.push('/team/add') : null,
                actionLabel: 'Додати спортсмена',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final child = quickFiltered[i];
                    final isOwn = user?.ownsChild(child.id) ?? false;
                    return ChildCard(
                      child: child,
                      rank: i + 1,
                      sameYearRank: sameYearRanks[child.id],
                      sameYearTotal: yearTotals[child.birthYear],
                      sameWeightRank: sameWeightRanks[child.id],
                      sameWeightTotal: weightTotals['${child.birthYear}/${child.weightCategory}'],
                      isOwn: !isCoach && isOwn,
                      membershipStatus: isCoach ? membershipMap[child.id] : null,
                      membershipEndDate: isCoach ? membershipEndDateMap[child.id] : null,
                      showAttendance: isCoach,
                      onTap: () => ctx.push('/team/${child.id}'),
                    );
                  },
                  childCount: quickFiltered.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: isCoach
          ? FloatingActionButton(
              onPressed: () => context.push('/team/add'),
              tooltip: 'Додати спортсмена',
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            )
          : null,
    );
  }

  void _showBeltPicker(BuildContext context, ChildrenFilter filter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final selected = {...filter.belts};
        return StatefulBuilder(
          builder: (ctx, setS) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Оберіть пояс',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      if (selected.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setS(() => selected.clear());
                          },
                          child: const Text('Скинути'),
                        ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: BeltLevel.values.map((b) {
                        final isSel = selected.contains(b);
                        return ListTile(
                          leading: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: b.color,
                              shape: BoxShape.circle,
                              border: b == BeltLevel.white
                                  ? Border.all(color: Colors.grey.shade300)
                                  : null,
                            ),
                          ),
                          title: Text(b.displayName),
                          trailing: isSel
                              ? const Icon(Icons.check,
                                  color: AppColors.primary)
                              : null,
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          onTap: () => setS(() {
                            if (isSel) selected.remove(b);
                            else selected.add(b);
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton(
                    onPressed: () {
                      ref.read(childrenFilterProvider.notifier).update(
                            (s) => s.copyWith(
                              belts: Set.from(selected),
                              clearBelts: selected.isEmpty,
                            ),
                          );
                      Navigator.pop(context);
                    },
                    child: const Text('Застосувати'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showYearPicker(BuildContext context, ChildrenFilter filter,
      List<int> dbYears, Map<int, int> counts) {
    final currentYear = DateTime.now().year;
    final allYears = List.generate(16, (i) => currentYear - 5 - i);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final selected = {...filter.birthYears};
        return StatefulBuilder(
          builder: (ctx, setS) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Рік народження',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      if (selected.isNotEmpty)
                        TextButton(
                          onPressed: () => setS(() => selected.clear()),
                          child: const Text('Скинути'),
                        ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: allYears.map((y) {
                        final count = counts[y];
                        final isSel = selected.contains(y);
                        return ListTile(
                          title: Text(y.toString()),
                          trailing: count != null
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary),
                                      ),
                                    ),
                                    if (isSel) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.check,
                                          color: AppColors.primary),
                                    ],
                                  ],
                                )
                              : null,
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          onTap: count != null
                              ? () => setS(() {
                                    if (isSel) selected.remove(y);
                                    else selected.add(y);
                                  })
                              : null,
                          enabled: count != null,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton(
                    onPressed: () {
                      ref.read(childrenFilterProvider.notifier).update(
                            (s) => s.copyWith(
                              birthYears: Set.from(selected),
                              clearBirthYears: selected.isEmpty,
                            ),
                          );
                      Navigator.pop(context);
                    },
                    child: const Text('Застосувати'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCoachPicker(BuildContext context, ChildrenFilter filter,
      List<({String id, String name})> coaches) {
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
              child: Text(
                'Тренер',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: coaches
                      .map(
                        (c) => ListTile(
                          title: Text(c.name),
                          onTap: () {
                            ref.read(childrenFilterProvider.notifier).state =
                                filter.copyWith(coachId: c.id);
                            Navigator.pop(context);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showWeightPicker(BuildContext context, ChildrenFilter filter,
      List<String> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final selected = {...filter.weightCats};
        return StatefulBuilder(
          builder: (ctx, setS) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Вагова категорія',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      if (selected.isNotEmpty)
                        TextButton(
                          onPressed: () => setS(() => selected.clear()),
                          child: const Text('Скинути'),
                        ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: categories.map((w) {
                        final isSel = selected.contains(w);
                        return ListTile(
                          leading: const Icon(Icons.scale,
                              size: 20, color: AppColors.textSecondary),
                          title: Text(displayWeight(w)),
                          trailing: isSel
                              ? const Icon(Icons.check,
                                  color: AppColors.primary)
                              : null,
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          onTap: () => setS(() {
                            if (isSel) selected.remove(w);
                            else selected.add(w);
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton(
                    onPressed: () {
                      ref.read(childrenFilterProvider.notifier).update(
                            (s) => s.copyWith(
                              weightCats: Set.from(selected),
                              clearWeightCats: selected.isEmpty,
                            ),
                          );
                      Navigator.pop(context);
                    },
                    child: const Text('Застосувати'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGenderPicker(BuildContext context, ChildrenFilter filter) {
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
                  ref
                      .read(childrenFilterProvider.notifier)
                      .update((s) => s.copyWith(gender: g));
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

  void _showMedalPicker(BuildContext context, ChildrenFilter filter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final selected = {...filter.medalPlaces};
        const places = [
          (1, 'Перше місце'),
          (2, 'Друге місце'),
          (3, 'Третє місце'),
        ];
        return StatefulBuilder(
          builder: (ctx, setS) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Місця на змаганнях',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      if (selected.isNotEmpty)
                        TextButton(
                          onPressed: () => setS(() => selected.clear()),
                          child: const Text('Скинути'),
                        ),
                    ],
                  ),
                ),
                ...places.map((entry) {
                  final (place, label) = entry;
                  final isSel = selected.contains(place);
                  return ListTile(
                    title: Text(label),
                    trailing: isSel
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    onTap: () => setS(() {
                      if (isSel) selected.remove(place);
                      else selected.add(place);
                    }),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton(
                    onPressed: () {
                      ref.read(childrenFilterProvider.notifier).update(
                            (s) => s.copyWith(
                              medalPlaces: Set.from(selected),
                              clearMedalPlaces: selected.isEmpty,
                            ),
                          );
                      Navigator.pop(context);
                    },
                    child: const Text('Застосувати'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMembershipPicker(BuildContext context, ChildrenFilter filter) {
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
              child: Text(
                'Статус абонементу',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ...MembershipStatus.values.map((s) {
              final selected = filter.membershipStatus == s;
              return ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _membershipStatusColor(s),
                  ),
                ),
                title: Text(_membershipStatusLabel(s)),
                trailing: selected
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                selected: selected,
                selectedColor: AppColors.primary,
                onTap: () {
                  ref
                      .read(childrenFilterProvider.notifier)
                      .update((fs) => fs.copyWith(membershipStatus: s));
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
}

// ── Filter section widget ─────────────────────────────────────────────────────

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.isCoach,
    required this.filter,
    required this.quickFilter,
    required this.filtersExpanded,
    required this.searchCtrl,
    required this.coaches,
    required this.birthYears,
    required this.birthYearCounts,
    required this.weightCategories,
    required this.onQuickFilterChanged,
    required this.onToggleFilters,
    required this.onShowBeltPicker,
    required this.onShowYearPicker,
    required this.onShowCoachPicker,
    required this.onShowWeightPicker,
    required this.onShowGenderPicker,
    required this.onShowMembershipPicker,
    required this.onShowMedalPicker,
    required this.ref,
  });

  final bool isCoach;
  final ChildrenFilter filter;
  final _TeamFilter quickFilter;
  final bool filtersExpanded;
  final TextEditingController searchCtrl;
  final List<({String id, String name})> coaches;
  final List<int> birthYears;
  final Map<int, int> birthYearCounts;
  final List<String> weightCategories;
  final ValueChanged<_TeamFilter> onQuickFilterChanged;
  final VoidCallback onToggleFilters;
  final VoidCallback onShowBeltPicker;
  final VoidCallback onShowYearPicker;
  final VoidCallback onShowCoachPicker;
  final VoidCallback onShowWeightPicker;
  final VoidCallback onShowGenderPicker;
  final VoidCallback onShowMembershipPicker;
  final VoidCallback onShowMedalPicker;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Quick filter tabs — coaches only ──────────────────────────
        if (isCoach)
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickFilterChip(
                    label: 'Всі',
                    active: quickFilter == _TeamFilter.all,
                    onTap: () => onQuickFilterChanged(_TeamFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _QuickFilterChip(
                    label: 'Юнаки',
                    active: quickFilter == _TeamFilter.boys,
                    onTap: () => onQuickFilterChanged(_TeamFilter.boys),
                  ),
                  const SizedBox(width: 8),
                  _QuickFilterChip(
                    label: 'Дівчата',
                    active: quickFilter == _TeamFilter.girls,
                    onTap: () => onQuickFilterChanged(_TeamFilter.girls),
                  ),
                ],
              ),
            ),
          ),

        // ── Search bar — coaches only ──────────────────────────────────
        if (isCoach)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchCtrl,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: 'Пошук за прізвищем...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: filter.lastName.isNotEmpty
                        ? null
                        : Colors.transparent,
                  ),
                  onPressed: filter.lastName.isNotEmpty
                      ? () {
                          searchCtrl.clear();
                          ref
                              .read(childrenFilterProvider.notifier)
                              .update((s) => s.copyWith(lastName: ''));
                        }
                      : null,
                ),
              ),
            ),
          ),

        // ── Advanced filter chips ──────────────────────────────────────
        if (filtersExpanded) ...[
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Belt filter (multi-select)
                _FilterChip(
                  label: filter.belts.length > 1
                      ? 'Пояс (${filter.belts.length})'
                      : filter.belts.length == 1
                          ? filter.belts.first.displayName
                          : filter.belt?.displayName ?? 'Пояс',
                  selected: filter.belts.isNotEmpty || filter.belt != null,
                  onTap: onShowBeltPicker,
                  onClear: (filter.belts.isNotEmpty || filter.belt != null)
                      ? () => ref
                          .read(childrenFilterProvider.notifier)
                          .update((s) =>
                              s.copyWith(clearBelt: true, clearBelts: true))
                      : null,
                ),
                const SizedBox(width: 8),
                // Year filter (multi-select)
                _FilterChip(
                  label: filter.birthYears.length > 1
                      ? 'Рік (${filter.birthYears.length})'
                      : filter.birthYears.length == 1
                          ? filter.birthYears.first.toString()
                          : filter.birthYear?.toString() ?? 'Рік н.',
                  selected:
                      filter.birthYears.isNotEmpty || filter.birthYear != null,
                  onTap: onShowYearPicker,
                  onClear:
                      (filter.birthYears.isNotEmpty || filter.birthYear != null)
                          ? () => ref
                              .read(childrenFilterProvider.notifier)
                              .update((s) => s.copyWith(
                                  clearBirthYear: true, clearBirthYears: true))
                          : null,
                ),
                const SizedBox(width: 8),
                // Coach filter
                if (coaches.isNotEmpty) ...[
                  _FilterChip(
                    label: coaches
                            .where((c) => c.id == filter.coachId)
                            .firstOrNull
                            ?.name ??
                        'Тренер',
                    selected: filter.coachId != null,
                    onTap: onShowCoachPicker,
                    onClear: filter.coachId != null
                        ? () => ref
                            .read(childrenFilterProvider.notifier)
                            .state = filter.copyWith(clearCoachId: true)
                        : null,
                  ),
                  const SizedBox(width: 8),
                ],
                // Weight filter (multi-select)
                if (weightCategories.isNotEmpty) ...[
                  _FilterChip(
                    label: filter.weightCats.length > 1
                        ? 'Вага (${filter.weightCats.length})'
                        : filter.weightCats.length == 1
                            ? displayWeight(filter.weightCats.first)
                            : filter.weightCategory != null
                                ? displayWeight(filter.weightCategory!)
                                : 'Вага',
                    selected: filter.weightCats.isNotEmpty ||
                        filter.weightCategory != null,
                    onTap: onShowWeightPicker,
                    onClear:
                        (filter.weightCats.isNotEmpty ||
                                filter.weightCategory != null)
                            ? () => ref
                                .read(childrenFilterProvider.notifier)
                                .update((s) => s.copyWith(
                                    clearWeightCategory: true,
                                    clearWeightCats: true))
                            : null,
                  ),
                  const SizedBox(width: 8),
                ],
                // Gender filter
                _FilterChip(
                  label: filter.gender?.displayName ?? 'Стать',
                  selected: filter.gender != null,
                  onTap: onShowGenderPicker,
                  onClear: filter.gender != null
                      ? () => ref
                          .read(childrenFilterProvider.notifier)
                          .update((s) => s.copyWith(clearGender: true))
                      : null,
                ),
                const SizedBox(width: 8),
                // Belt ready filter
                _FilterChip(
                  label: 'Допущені до пояса',
                  selected: filter.beltReady,
                  onTap: () => ref
                      .read(childrenFilterProvider.notifier)
                      .update((s) => s.copyWith(beltReady: !s.beltReady)),
                  onClear: filter.beltReady
                      ? () => ref
                          .read(childrenFilterProvider.notifier)
                          .update((s) => s.copyWith(beltReady: false))
                      : null,
                ),
                if (isCoach) ...[
                  const SizedBox(width: 8),
                  // Membership status filter (coach only — parents bypass filteredChildrenProvider)
                  _FilterChip(
                    label: filter.membershipStatus != null
                        ? _membershipStatusLabel(filter.membershipStatus!)
                        : 'Абонемент',
                    selected: filter.membershipStatus != null,
                    onTap: onShowMembershipPicker,
                    onClear: filter.membershipStatus != null
                        ? () => ref
                            .read(childrenFilterProvider.notifier)
                            .update(
                                (s) => s.copyWith(clearMembershipStatus: true))
                        : null,
                  ),
                  const SizedBox(width: 8),
                  // Medal filter (coach only — parents bypass filteredChildrenWithMedalsProvider)
                  _FilterChip(
                    label: filter.medalPlaces.length == 1
                        ? _medalPlaceLabel(filter.medalPlaces.first)
                        : filter.medalPlaces.length > 1
                            ? 'Медалі (${filter.medalPlaces.length})'
                            : 'Медалі',
                    selected: filter.medalPlaces.isNotEmpty,
                    onTap: onShowMedalPicker,
                    onClear: filter.medalPlaces.isNotEmpty
                        ? () => ref
                            .read(childrenFilterProvider.notifier)
                            .update((s) => s.copyWith(clearMedalPlaces: true))
                        : null,
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _medalPlaceLabel(int place) {
  switch (place) {
    case 1: return 'Перше місце';
    case 2: return 'Друге місце';
    case 3: return 'Третє місце';
    default: return '$place місце';
  }
}

String _membershipStatusLabel(MembershipStatus s) {
  switch (s) {
    case MembershipStatus.active:       return 'Активний';
    case MembershipStatus.expiringSoon: return 'Закінчується';
    case MembershipStatus.expired:      return 'Прострочений';
  }
}

Color _membershipStatusColor(MembershipStatus s) {
  switch (s) {
    case MembershipStatus.active:       return const Color(0xFF27AE60);
    case MembershipStatus.expiringSoon: return const Color(0xFFFF8A00);
    case MembershipStatus.expired:      return const Color(0xFFD50000);
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? null : AppColors.surface2,
          gradient: selected ? AppColors.redGoldGradient : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.surface3,
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Quick filter chip ─────────────────────────────────────────────────────────

class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          gradient: active ? AppColors.ctaGradient : null,
          color: active ? null : AppColors.surface3,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

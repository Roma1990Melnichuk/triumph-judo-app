import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/child_model.dart' show displayWeight;
import '../../../core/models/membership_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
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

enum _TeamFilter { all, children, boys, girls }

class _TeamListScreenState extends ConsumerState<TeamListScreen> {
  final _searchCtrl = TextEditingController();
  bool _filtersExpanded = true;
  _TeamFilter _quickFilter = _TeamFilter.all;

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
    final user = ref.watch(currentUserModelProvider).value;
    final isCoach = user?.isCoach ?? false;
    final allChildren = ref.watch(allChildrenProvider);
    // Parents see only their own children
    final children = isCoach
        ? ref.watch(filteredChildrenProvider)
        : (allChildren.value ?? []).where((c) => user?.ownsChild(c.id) ?? false).toList();
    final membershipMap = ref.watch(membershipStatusMapProvider);
    final membershipEndDateMap = isCoach ? ref.watch(membershipEndDateMapProvider) : <String, DateTime>{};
    final filter = ref.watch(childrenFilterProvider);
    final birthYears = ref.watch(birthYearsProvider);
    final birthYearCounts = ref.watch(birthYearCountsProvider);
    final coaches = ref.watch(coachListProvider);
    final weightCategories = ref.watch(weightCategoriesProvider);

    final total = isCoach ? (allChildren.value?.length ?? 0) : children.length;

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Команда',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$total спортсменів',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCoach)
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
          // ── Quick filter tabs — coaches only ─────────────────────────
          if (isCoach)
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _QuickFilterChip(
                    label: 'Всі',
                    active: _quickFilter == _TeamFilter.all,
                    onTap: () => setState(() => _quickFilter = _TeamFilter.all)),
                const SizedBox(width: 8),
                _QuickFilterChip(
                    label: 'Діти',
                    active: _quickFilter == _TeamFilter.children,
                    onTap: () => setState(() => _quickFilter = _TeamFilter.children)),
                const SizedBox(width: 8),
                _QuickFilterChip(
                    label: 'Юнаки',
                    active: _quickFilter == _TeamFilter.boys,
                    onTap: () => setState(() => _quickFilter = _TeamFilter.boys)),
                const SizedBox(width: 8),
                _QuickFilterChip(
                    label: 'Дівчата',
                    active: _quickFilter == _TeamFilter.girls,
                    onTap: () => setState(() => _quickFilter = _TeamFilter.girls)),
              ],
            ),
          ),

          // Search bar — coaches only
          if (isCoach)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
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
                          _searchCtrl.clear();
                          ref
                              .read(childrenFilterProvider.notifier)
                              .update((s) => s.copyWith(lastName: ''));
                        }
                      : null,
                ),
              ),
            ),
          ),

          // Filter chips
          if (_filtersExpanded) ...[
            const Divider(height: 1),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Belt filter
                  _FilterChip(
                    label: filter.belt?.displayName ?? 'Пояс',
                    selected: filter.belt != null,
                    onTap: () => _showBeltPicker(context, filter),
                    onClear: filter.belt != null
                        ? () => ref
                            .read(childrenFilterProvider.notifier)
                            .state = filter.copyWith(clearBelt: true)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  // Year filter
                  _FilterChip(
                    label: filter.birthYear?.toString() ?? 'Рік н.',
                    selected: filter.birthYear != null,
                    onTap: () => _showYearPicker(context, filter, birthYears, birthYearCounts),
                    onClear: filter.birthYear != null
                        ? () => ref
                            .read(childrenFilterProvider.notifier)
                            .state =
                            filter.copyWith(clearBirthYear: true)
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
                      onTap: () =>
                          _showCoachPicker(context, filter, coaches),
                      onClear: filter.coachId != null
                          ? () => ref
                              .read(childrenFilterProvider.notifier)
                              .state =
                              filter.copyWith(clearCoachId: true)
                          : null,
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Weight filter
                  if (weightCategories.isNotEmpty) ...[
                    _FilterChip(
                      label: filter.weightCategory != null
                          ? displayWeight(filter.weightCategory!)
                          : 'Вага',
                      selected: filter.weightCategory != null,
                      onTap: () => _showWeightPicker(context, filter, weightCategories),
                      onClear: filter.weightCategory != null
                          ? () => ref
                              .read(childrenFilterProvider.notifier)
                              .state = filter.copyWith(clearWeightCategory: true)
                          : null,
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Gender filter
                  _FilterChip(
                    label: filter.gender?.displayName ?? 'Стать',
                    selected: filter.gender != null,
                    onTap: () => _showGenderPicker(context, filter),
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
                  const SizedBox(width: 8),
                  // Membership status filter
                  _FilterChip(
                    label: filter.membershipStatus != null
                        ? _membershipStatusLabel(filter.membershipStatus!)
                        : 'Абонемент',
                    selected: filter.membershipStatus != null,
                    onTap: () => _showMembershipPicker(context, filter),
                    onClear: filter.membershipStatus != null
                        ? () => ref
                            .read(childrenFilterProvider.notifier)
                            .update((s) => s.copyWith(clearMembershipStatus: true))
                        : null,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],

          // Children list
          Expanded(
            child: allChildren.isLoading
                ? const Center(child: CircularProgressIndicator())
                : children.isEmpty
                    ? EmptyState(
                        tIcon: TIcon.team,
                        message: isCoach
                            ? 'Команда порожня\nДодайте першого спортсмена або\nімпортуйте список з CSV у Налаштуваннях'
                            : 'Список порожній',
                        action: isCoach
                            ? () => context.push('/team/add')
                            : null,
                        actionLabel: 'Додати спортсмена',
                      )
                    : Builder(builder: (_) {
                        // Apply quick filter
                        final _kChildrenMaxYear = DateTime.now().year - 7;
                        final _kChildrenMinYear = DateTime.now().year - 11;
                        final quickFiltered = children.where((c) {
                          switch (_quickFilter) {
                            case _TeamFilter.all:      return true;
                            case _TeamFilter.children: return c.birthYear >= _kChildrenMinYear && c.birthYear <= _kChildrenMaxYear;
                            case _TeamFilter.boys:     return c.gender == Gender.male;
                            case _TeamFilter.girls:    return c.gender == Gender.female;
                          }
                        }).toList();

                        // Peer ranks computed from the same set that drives rank: i+1
                        final quickSorted = [...quickFiltered]..sort((a, b) {
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
                        for (final c in quickSorted) {
                          yearTotals[c.birthYear] =
                              (yearTotals[c.birthYear] ?? 0) + 1;
                          yearCounters[c.birthYear] =
                              (yearCounters[c.birthYear] ?? 0) + 1;
                          sameYearRanks[c.id] = yearCounters[c.birthYear]!;
                          final wKey = '${c.birthYear}/${c.weightCategory}';
                          weightTotals[wKey] = (weightTotals[wKey] ?? 0) + 1;
                          weightCounters[wKey] = (weightCounters[wKey] ?? 0) + 1;
                          sameWeightRanks[c.id] = weightCounters[wKey]!;
                        }
                        return ListView.builder(
                          padding:
                              const EdgeInsets.only(top: 4, bottom: 80),
                          itemCount: quickFiltered.length,
                          itemBuilder: (context, i) {
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
                              membershipStatus: isCoach
                                  ? membershipMap[child.id]
                                  : null,
                              membershipEndDate: isCoach
                                  ? membershipEndDateMap[child.id]
                                  : null,
                              showAttendance: isCoach,
                              onTap: () => context.push('/team/${child.id}'),
                            );
                          },
                        );
                      }),
          ),
        ],
        ),
      ),
      floatingActionButton: isCoach
          ? FloatingActionButton(
              onPressed: () => context.push('/team/add'),
              tooltip: 'Додати спортсмена',
              child: const ColorFiltered(colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn), child: TriumphIcon(TIcon.add, size: 24)),
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
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Оберіть пояс',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: BeltLevel.values.map(
                    (b) => ListTile(
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
                      onTap: () {
                        ref.read(childrenFilterProvider.notifier).state =
                            filter.copyWith(belt: b);
                        Navigator.pop(context);
                      },
                    ),
                  ).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
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
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Рік народження',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: allYears.map((y) {
                    final count = counts[y];
                    return ListTile(
                      title: Text(y.toString()),
                      trailing: count != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                            )
                          : null,
                      selected: filter.birthYear == y,
                      selectedColor: AppColors.primary,
                      onTap: count != null
                          ? () {
                              ref.read(childrenFilterProvider.notifier).state =
                                  filter.copyWith(birthYear: y);
                              Navigator.pop(context);
                            }
                          : null,
                      enabled: count != null,
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

  void _showCoachPicker(BuildContext context, ChildrenFilter filter,
      List<({String id, String name})> coaches) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Тренер',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ...coaches.map(
            (c) => ListTile(
              title: Text(c.name),
              onTap: () {
                ref.read(childrenFilterProvider.notifier).state =
                    filter.copyWith(coachId: c.id);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
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
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Вагова категорія',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: categories.map((w) {
                    final selected = filter.weightCategory == w;
                    return ListTile(
                      leading: const Icon(Icons.scale, size: 20,
                          color: AppColors.textSecondary),
                      title: Text(displayWeight(w)),
                      trailing: selected
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      selected: selected,
                      selectedColor: AppColors.primary,
                      onTap: () {
                        ref.read(childrenFilterProvider.notifier).state =
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
              child: Text('Стать', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...Gender.values.map((g) {
              final selected = filter.gender == g;
              return ListTile(
                leading: Text(g.icon, style: const TextStyle(fontSize: 22)),
                title: Text(g.displayName),
                trailing: selected ? const Icon(Icons.check, color: AppColors.primary) : null,
                selected: selected,
                selectedColor: AppColors.primary,
                onTap: () {
                  ref.read(childrenFilterProvider.notifier)
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

String _membershipStatusLabel(MembershipStatus s) {
  switch (s) {
    case MembershipStatus.active:      return 'Активний';
    case MembershipStatus.expiringSoon: return 'Закінчується';
    case MembershipStatus.expired:     return 'Прострочений';
  }
}

Color _membershipStatusColor(MembershipStatus s) {
  switch (s) {
    case MembershipStatus.active:      return const Color(0xFF27AE60);
    case MembershipStatus.expiringSoon: return const Color(0xFFFF8A00);
    case MembershipStatus.expired:     return const Color(0xFFD50000);
  }
}

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
            color: selected
                ? Colors.transparent
                : AppColors.surface3,
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

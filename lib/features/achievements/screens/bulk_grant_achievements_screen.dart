import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/achievement_defs.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/achievement_model.dart';
import '../../../core/models/child_model.dart';
import '../../../core/models/group_model.dart';
import '../../../shared/widgets/achievement_badge.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../schedule/providers/group_provider.dart';
import '../../team/providers/children_provider.dart';
import '../providers/achievement_provider.dart';

/// Returns athletes who pass all active filters (AND between types)
/// OR are individually added via [extraChildIds].
/// An empty filter category imposes no restriction.
List<ChildModel> bulkAchievementsMatchedAthletes({
  required List<ChildModel> all,
  required List<GroupModel> groups,
  required Set<String> selectedGroupIds,
  required Set<int> selectedYears,
  required Set<BeltLevel> selectedBelts,
  required Set<String> extraChildIds,
}) {
  return all.where((c) {
    if (extraChildIds.contains(c.id)) { return true; }
    if (selectedGroupIds.isEmpty &&
        selectedYears.isEmpty &&
        selectedBelts.isEmpty) { return false; }
    if (selectedGroupIds.isNotEmpty) {
      final inGroup = groups
          .where((g) => selectedGroupIds.contains(g.id))
          .any((g) => g.childIds.contains(c.id));
      if (!inGroup) { return false; }
    }
    if (selectedYears.isNotEmpty &&
        !selectedYears.contains(c.birthYear)) { return false; }
    if (selectedBelts.isNotEmpty &&
        !selectedBelts.contains(c.currentBelt)) { return false; }
    return true;
  }).toList();
}

class BulkGrantAchievementsScreen extends ConsumerStatefulWidget {
  const BulkGrantAchievementsScreen({super.key});

  @override
  ConsumerState<BulkGrantAchievementsScreen> createState() =>
      _BulkGrantAchievementsScreenState();
}

class _BulkGrantAchievementsScreenState
    extends ConsumerState<BulkGrantAchievementsScreen> {
  // ── Athlete selection ──────────────────────────────────────────────────────
  final Set<String> _selectedGroupIds = {};
  final Set<int> _selectedYears = {};
  final Set<BeltLevel> _selectedBelts = {};
  final Set<String> _extraChildIds = {}; // individually added
  bool _showIndividuals = false;

  // ── Achievement selection ──────────────────────────────────────────────────
  final Set<String> _selectedDefIds = {};
  AchievementCategory? _catFilter;

  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  List<ChildModel> _matched(List<ChildModel> all, List<GroupModel> groups) =>
      bulkAchievementsMatchedAthletes(
        all: all,
        groups: groups,
        selectedGroupIds: _selectedGroupIds,
        selectedYears: _selectedYears,
        selectedBelts: _selectedBelts,
        extraChildIds: _extraChildIds,
      );

  List<AchievementDef> get _visibleDefs => kAchievements
      .where((d) => _catFilter == null || d.category == _catFilter)
      .toList();

  Future<void> _grant(List<ChildModel> matched) async {
    if (matched.isEmpty || _selectedDefIds.isEmpty) return;
    final total = _selectedDefIds.length * matched.length;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Підтвердити видачу?'),
        content: Text(
          'Видати ${_selectedDefIds.length} досягнень для ${matched.length} '
          'спортсменів ($total операцій)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Видати'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _saving = true);
    try {
      final coachId = ref.read(currentUserModelProvider).value?.uid ?? '';
      final note = _noteCtrl.text.trim();
      await ref.read(achievementNotifierProvider.notifier).grantBulk(
        childIds: matched.map((c) => c.id).toList(),
        defIds: _selectedDefIds.toList(),
        coachId: coachId,
        note: note.isEmpty ? null : note,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Видано $total досягнень'),
          backgroundColor: AppColors.success,
        ));
        setState(() {
          _selectedDefIds.clear();
          _noteCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Помилка: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(allChildrenProvider).value ?? [];
    final groups = ref.watch(groupsProvider).value ?? [];
    final birthYears =
        children.map((c) => c.birthYear).toSet().toList()..sort();
    final matched = _matched(children, groups);
    final visibleDefs = _visibleDefs;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Масова видача досягнень')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _athleteCard(children, groups, birthYears, matched),
          const SizedBox(height: 16),
          _achievementsCard(visibleDefs),
          const SizedBox(height: 16),
          _SurfaceCard(
            child: TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration.collapsed(
                  hintText: 'Нотатка (необов\'язково)…'),
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            onPressed: (!_saving &&
                    matched.isNotEmpty &&
                    _selectedDefIds.isNotEmpty)
                ? () => _grant(matched)
                : null,
            isLoading: _saving,
            child: Text(
              matched.isEmpty
                  ? 'Оберіть спортсменів'
                  : _selectedDefIds.isEmpty
                      ? 'Оберіть досягнення'
                      : 'Видати ${_selectedDefIds.length} досягнень '
                          '→ ${matched.length} спортсменів',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Athlete card ───────────────────────────────────────────────────────────

  Widget _athleteCard(List<ChildModel> allChildren, List<GroupModel> groups,
      List<int> birthYears, List<ChildModel> matched) {
    // Ids matched by filters only (excluding extraChildIds)
    final filterMatchedIds = <String>{};
    for (final c in matched) {
      if (!_extraChildIds.contains(c.id)) filterMatchedIds.add(c.id);
    }

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('Спортсмени',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              if (matched.isNotEmpty) ...[
                const SizedBox(width: 8),
                _CountBadge(matched.length),
              ],
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Фільтри поєднуються як "І". Ручний вибір додається незалежно.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Groups
          if (groups.isNotEmpty) ...[
            _FilterHeader(
              label: 'Групи',
              count: _selectedGroupIds.length,
              onClear: _selectedGroupIds.isEmpty
                  ? null
                  : () {
                      _selectedGroupIds.clear();
                      setState(() {});
                    },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: groups
                  .map((g) => _Chip(
                        label: g.name,
                        selected: _selectedGroupIds.contains(g.id),
                        onTap: () => setState(() {
                          _selectedGroupIds.contains(g.id)
                              ? _selectedGroupIds.remove(g.id)
                              : _selectedGroupIds.add(g.id);
                        }),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Years
          _FilterHeader(
            label: 'Рік народження',
            count: _selectedYears.length,
            onClear: _selectedYears.isEmpty
                ? null
                : () {
                    _selectedYears.clear();
                    setState(() {});
                  },
          ),
          const SizedBox(height: 8),
          birthYears.isEmpty
              ? const Text('Немає даних',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13))
              : Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: birthYears
                      .map((y) => _Chip(
                            label: '$y',
                            selected: _selectedYears.contains(y),
                            onTap: () => setState(() {
                              _selectedYears.contains(y)
                                  ? _selectedYears.remove(y)
                                  : _selectedYears.add(y);
                            }),
                          ))
                      .toList(),
                ),
          const SizedBox(height: 16),

          // Belts
          _FilterHeader(
            label: 'Пояс',
            count: _selectedBelts.length,
            onClear: _selectedBelts.isEmpty
                ? null
                : () {
                    _selectedBelts.clear();
                    setState(() {});
                  },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: BeltLevel.values
                .where((b) => b != BeltLevel.white)
                .map((b) => _Chip(
                      label: b.displayName,
                      selected: _selectedBelts.contains(b),
                      onTap: () => setState(() {
                        _selectedBelts.contains(b)
                            ? _selectedBelts.remove(b)
                            : _selectedBelts.add(b);
                      }),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // Individual selection
          const Divider(),
          const SizedBox(height: 4),
          InkWell(
            onTap: () =>
                setState(() => _showIndividuals = !_showIndividuals),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    _showIndividuals
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Вибрати вручну',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _extraChildIds.isNotEmpty
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (_extraChildIds.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _CountBadge(_extraChildIds.length),
                  ],
                ],
              ),
            ),
          ),
          if (_showIndividuals) ...[
            const SizedBox(height: 10),
            allChildren.isEmpty
                ? const Text('Список спортсменів порожній',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13))
                : Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: allChildren.map((c) {
                      final isExtra = _extraChildIds.contains(c.id);
                      final isFilter = filterMatchedIds.contains(c.id);

                      Color bg;
                      Color fg;
                      if (isExtra) {
                        bg = AppColors.primary;
                        fg = Colors.white;
                      } else if (isFilter) {
                        bg = AppColors.primary.withValues(alpha: 0.12);
                        fg = AppColors.primary;
                      } else {
                        bg = AppColors.surface3;
                        fg = AppColors.textSecondary;
                      }

                      return GestureDetector(
                        onTap: () => setState(() {
                          isExtra
                              ? _extraChildIds.remove(c.id)
                              : _extraChildIds.add(c.id);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 130),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (isExtra || isFilter)
                                  ? AppColors.primary
                                      .withValues(alpha: 0.35)
                                  : AppColors.surface3,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isExtra)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.check,
                                      size: 11, color: Colors.white),
                                ),
                              Text(
                                c.fullName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: (isExtra || isFilter)
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: fg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),

          // Summary pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: matched.isEmpty
                  ? AppColors.surface3
                  : AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: matched.isEmpty
                    ? AppColors.surface3
                    : AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              matched.isEmpty
                  ? 'Спортсменів не обрано'
                  : 'Обрано: ${matched.length} спортсменів',
              style: TextStyle(
                color: matched.isEmpty
                    ? AppColors.textSecondary
                    : AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Achievements card ──────────────────────────────────────────────────────

  Widget _achievementsCard(List<AchievementDef> visibleDefs) {
    final allVisibleSelected =
        visibleDefs.isNotEmpty &&
        visibleDefs.every((d) => _selectedDefIds.contains(d.id));

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('Досягнення',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              if (_selectedDefIds.isNotEmpty) ...[
                const SizedBox(width: 8),
                _CountBadge(_selectedDefIds.length),
              ],
              const Spacer(),
              if (visibleDefs.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() {
                    if (allVisibleSelected) {
                      for (final d in visibleDefs) {
                        _selectedDefIds.remove(d.id);
                      }
                    } else {
                      for (final d in visibleDefs) {
                        _selectedDefIds.add(d.id);
                      }
                    }
                  }),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(60, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    allVisibleSelected ? 'Зняти всі' : 'Вибрати всі',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CatChip(
                  label: 'Усі',
                  selected: _catFilter == null,
                  onTap: () => setState(() => _catFilter = null),
                ),
                ...AchievementCategory.values.map((cat) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _CatChip(
                        label: cat.displayName,
                        selected: _catFilter == cat,
                        onTap: () => setState(() =>
                            _catFilter = _catFilter == cat ? null : cat),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),

          // Achievement list
          if (visibleDefs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Немає досягнень',
                  style:
                      TextStyle(color: AppColors.textSecondary)),
            )
          else
            ...visibleDefs.map((def) {
              final selected = _selectedDefIds.contains(def.id);
              return InkWell(
                onTap: () => setState(() => selected
                    ? _selectedDefIds.remove(def.id)
                    : _selectedDefIds.add(def.id)),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 7, horizontal: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: AchievementIcon(def: def, size: 26),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    def.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                if (def.isAuto && !def.isManual)
                                  Container(
                                    margin:
                                        const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface3,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: const Text('авто',
                                        style: TextStyle(
                                            fontSize: 9,
                                            color:
                                                AppColors.textSecondary)),
                                  ),
                              ],
                            ),
                            Text(
                              def.description,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: selected
                            ? AppColors.primary
                            : AppColors.surface3,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Shared small widgets ───────────────────────────────────────────────────────

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surface3),
        ),
        child: child,
      );
}

class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count);
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$count',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold),
        ),
      );
}

class _FilterHeader extends StatelessWidget {
  const _FilterHeader(
      {required this.label, required this.count, this.onClear});
  final String label;
  final int count;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textSecondary)),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10)),
              child: Text('$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ],
          const Spacer(),
          if (onClear != null)
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Очистити',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ),
        ],
      );
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface3,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.surface3.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w400,
              color:
                  selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      );
}

class _CatChip extends StatelessWidget {
  const _CatChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.15)
                : AppColors.surface3,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.5)
                  : AppColors.surface3,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? AppColors.accent
                  : AppColors.textSecondary,
            ),
          ),
        ),
      );
}

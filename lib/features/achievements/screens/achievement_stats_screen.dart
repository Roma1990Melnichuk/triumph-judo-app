import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/achievement_defs.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/achievement_model.dart';
import '../../../core/models/child_model.dart';
import '../../../features/team/providers/children_provider.dart';
import '../providers/achievement_provider.dart';
import '../../../shared/widgets/achievement_badge.dart';
import '../../../shared/widgets/triumph_icon.dart';
import '../../../shared/widgets/default_avatar.dart';

class AchievementStatsScreen extends ConsumerStatefulWidget {
  const AchievementStatsScreen({super.key});

  @override
  ConsumerState<AchievementStatsScreen> createState() =>
      _AchievementStatsScreenState();
}

class _AchievementStatsScreenState
    extends ConsumerState<AchievementStatsScreen> {
  bool _onlyUngranted = false;

  @override
  Widget build(BuildContext context) {
    final allGranted = ref.watch(allGrantedAchievementsProvider).value ?? [];
    final allChildren = ref.watch(allChildrenProvider).value ?? [];
    final childMap = {for (final c in allChildren) c.id: c};

    final statsMap = <String, List<AchievementModel>>{};
    for (final a in allGranted) {
      (statsMap[a.achievementId] ??= []).add(a);
    }

    final totalGrants = allGranted.length;
    final uniqueAthletes = allGranted.map((a) => a.childId).toSet().length;
    final neverCount =
        kAchievements.where((d) => !statsMap.containsKey(d.id)).length;

    final grouped = allAchievementsByCategory;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Статистика нагород')),
      body: Column(
        children: [
          // ── Summary chips ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _StatChip(
                  tIcon: TIcon.trophy,
                  label: 'Видано',
                  value: '$totalGrants',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  tIcon: TIcon.team,
                  label: 'Спортсменів',
                  value: '$uniqueAthletes',
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  tIcon: TIcon.achievements,
                  label: 'Не видавались',
                  value: '$neverCount',
                  color:
                      neverCount == 0 ? AppColors.success : AppColors.error,
                ),
              ],
            ),
          ),
          // ── Filter ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Всі'),
                  selected: !_onlyUngranted,
                  onSelected: (_) => setState(() => _onlyUngranted = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Не видавались ($neverCount)'),
                  selected: _onlyUngranted,
                  onSelected: (_) => setState(() => _onlyUngranted = true),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                for (final entry in grouped.entries)
                  ..._buildCategory(entry, statsMap, childMap, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategory(
    MapEntry<AchievementCategory, List<AchievementDef>> entry,
    Map<String, List<AchievementModel>> statsMap,
    Map<String, ChildModel> childMap,
    BuildContext context,
  ) {
    final defs = _onlyUngranted
        ? entry.value.where((d) => !statsMap.containsKey(d.id)).toList()
        : entry.value;
    if (defs.isEmpty) return [];

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Text(
          entry.key.displayName.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ),
      for (final def in defs)
        _AchievementStatsTile(
          def: def,
          earned: statsMap[def.id] ?? [],
          onTap: () {
            final sorted = <AchievementModel>[...(statsMap[def.id] ?? [])]
              ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
            _showAthleteSheet(context, def, sorted, childMap);
          },
        ),
    ];
  }

  void _showAthleteSheet(
    BuildContext context,
    AchievementDef def,
    List<AchievementModel> earned,
    Map<String, ChildModel> childMap,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surface3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  AchievementIcon(def: def, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(def.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(def.rarity.label,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(def.description,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '${earned.length}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            if (earned.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline,
                          size: 40, color: AppColors.textSecondary),
                      SizedBox(height: 8),
                      Text(
                        'Ще ніхто не отримав цю нагороду',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: earned.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final a = earned[i];
                    final child = childMap[a.childId];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: child != null
                          ? DefaultAvatarCircle(
                              gender: child.gender,
                              radius: 18,
                              seed: child.id,
                            )
                          : const CircleAvatar(
                              radius: 18,
                              child: ColorFiltered(
                                colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                child: TriumphIcon(TIcon.athlete, size: 16),
                              ),
                            ),
                      title: Text(
                        child?.fullName ?? a.childId,
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: Text(
                        DateFormat('dd.MM.yyyy').format(a.earnedAt),
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.tIcon,
    required this.label,
    required this.value,
    required this.color,
  });

  final TIcon tIcon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              child: TriumphIcon(tIcon, size: 18),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Achievement row ───────────────────────────────────────────────────────────

class _AchievementStatsTile extends StatelessWidget {
  const _AchievementStatsTile({
    required this.def,
    required this.earned,
    required this.onTap,
  });

  final AchievementDef def;
  final List<AchievementModel> earned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasAny = earned.isNotEmpty;
    return ListTile(
      onTap: onTap,
      leading: AchievementIcon(def: def, size: 36),
      title: Text(
        def.name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: hasAny ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
      subtitle: Text(
        def.rarity.label,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: hasAny
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasAny ? AppColors.accent : AppColors.surface3,
          ),
        ),
        child: Text(
          '${earned.length}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: hasAny ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

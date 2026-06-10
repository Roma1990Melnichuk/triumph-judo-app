import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/achievement_defs.dart';
import '../../../core/models/achievement_model.dart';
import '../../../shared/widgets/achievement_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/achievement_provider.dart';

class AchievementCatalogScreen extends ConsumerWidget {
  /// Pass childId explicitly; if null, inferred from current user.
  const AchievementCatalogScreen({super.key, this.childId});

  final String? childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider).value;
    final effectiveChildId =
        childId ?? user?.childIds.firstOrNull ?? user?.childId ?? '';

    final earnedAsync =
        ref.watch(childAchievementsProvider(effectiveChildId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: earnedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Помилка: $e')),
        data: (earned) {
          final earnedIds = earned.map((a) => a.achievementId).toSet();
          return _CatalogBody(earnedIds: earnedIds);
        },
      ),
    );
  }
}

class _CatalogBody extends StatelessWidget {
  const _CatalogBody({required this.earnedIds});

  final Set<String> earnedIds;

  static const _categoryOrder = [
    AchievementCategory.discipline,
    AchievementCategory.training,
    AchievementCategory.belts,
    AchievementCategory.tournaments,
    AchievementCategory.technique,
    AchievementCategory.theory,
    AchievementCategory.behavior,
    AchievementCategory.special,
    AchievementCategory.seasonal,
  ];

  Map<AchievementCategory, List<AchievementDef>> get _byCategory {
    final map = <AchievementCategory, List<AchievementDef>>{};
    for (final cat in _categoryOrder) {
      map[cat] = kAchievements.where((d) => d.category == cat).toList();
    }
    return map;
  }

  int get _totalEarned =>
      kAchievements.where((d) => earnedIds.contains(d.id)).length;

  @override
  Widget build(BuildContext context) {
    final byCategory = _byCategory;
    final total = kAchievements.length;
    final earned = _totalEarned;

    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _Header(earned: earned, total: total),
        ),

        // ── Categories ──────────────────────────────────────────────────────
        for (final cat in _categoryOrder)
          SliverToBoxAdapter(
            child: _CategorySection(
              category: cat,
              defs: byCategory[cat] ?? [],
              earnedIds: earnedIds,
            ),
          ),

        // ── Rarity legend ────────────────────────────────────────────────────
        const SliverToBoxAdapter(child: _RarityLegend()),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.earned, required this.total});

  final int earned;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? earned / total : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 48, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0808), Color(0xFF2A0A0A), Color(0xFF0D0D0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'УСІ ДОСЯГНЕННЯ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Клубу «Тріумф»",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor:
                        Colors.white.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$earned / $total',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'досягнень отримано',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category section ─────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.defs,
    required this.earnedIds,
  });

  final AchievementCategory category;
  final List<AchievementDef> defs;
  final Set<String> earnedIds;

  int get _earned => defs.where((d) => earnedIds.contains(d.id)).length;

  @override
  Widget build(BuildContext context) {
    if (defs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Row(
            children: [
              Expanded(
                child: Text(
                  category.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _earned > 0
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : AppColors.surface3,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_earned / ${defs.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _earned > 0
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: defs.length,
            itemBuilder: (_, i) {
              final def = defs[i];
              final isEarned = earnedIds.contains(def.id);
              return _AchievementCell(
                def: def,
                isEarned: isEarned,
                onTap: () => _showDetail(context, def, isEarned),
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.surface3, height: 1),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, AchievementDef def, bool isEarned) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AchievementDetailSheet(
          def: def, isEarned: isEarned),
    );
  }
}

// ── Achievement cell ─────────────────────────────────────────────────────────

class _AchievementCell extends StatelessWidget {
  const _AchievementCell({
    required this.def,
    required this.isEarned,
    required this.onTap,
  });

  final AchievementDef def;
  final bool isEarned;
  final VoidCallback onTap;

  Color get _rarityColor {
    switch (def.rarity) {
      case AchievementRarity.common:
        return const Color(0xFF9E9E9E);
      case AchievementRarity.rare:
        return const Color(0xFF2196F3);
      case AchievementRarity.epic:
        return const Color(0xFF9C27B0);
      case AchievementRarity.legendary:
        return AppColors.accent;
      case AchievementRarity.mythic:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHiddenLocked = def.isHidden && !isEarned;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Badge container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isEarned
                      ? _rarityColor.withValues(alpha: 0.6)
                      : AppColors.surface3,
                  width: isEarned ? 1.5 : 1,
                ),
                boxShadow: isEarned
                    ? [
                        BoxShadow(
                          color: _rarityColor.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isHiddenLocked
                    ? const Text('❓',
                        style: TextStyle(fontSize: 28))
                    : Opacity(
                        opacity: isEarned ? 1.0 : 0.35,
                        child: AchievementIcon(def: def, size: 44),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Name
          Text(
            isHiddenLocked ? '???' : def.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isEarned
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail bottom sheet ───────────────────────────────────────────────────────

class _AchievementDetailSheet extends StatelessWidget {
  const _AchievementDetailSheet({
    required this.def,
    required this.isEarned,
  });

  final AchievementDef def;
  final bool isEarned;

  static const _rarityColors = {
    AchievementRarity.common: Color(0xFF9E9E9E),
    AchievementRarity.rare: Color(0xFF2196F3),
    AchievementRarity.epic: Color(0xFF9C27B0),
    AchievementRarity.legendary: AppColors.accent,
    AchievementRarity.mythic: AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final rarityColor =
        _rarityColors[def.rarity] ?? AppColors.textSecondary;
    final isHiddenLocked = def.isHidden && !isEarned;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surface3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Badge
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                  color: isEarned
                      ? rarityColor.withValues(alpha: 0.7)
                      : AppColors.surface3,
                  width: 2),
              boxShadow: isEarned
                  ? [
                      BoxShadow(
                        color: rarityColor.withValues(alpha: 0.25),
                        blurRadius: 16,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isHiddenLocked
                  ? const Text('❓',
                      style: TextStyle(fontSize: 36))
                  : Opacity(
                      opacity: isEarned ? 1.0 : 0.4,
                      child: AchievementIcon(def: def, size: 52),
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // Name
          Text(
            isHiddenLocked ? '???' : def.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // Rarity chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              def.rarity.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: rarityColor,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Description
          Text(
            isHiddenLocked
                ? 'Отримай це досягнення, щоб дізнатися більше'
                : def.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isEarned
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isEarned ? AppColors.success : AppColors.surface3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isEarned ? Icons.check_circle : Icons.lock_outline,
                  size: 16,
                  color: isEarned ? AppColors.success : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  isEarned ? 'Отримано' : 'Не отримано',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isEarned ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rarity legend ─────────────────────────────────────────────────────────────

class _RarityLegend extends StatelessWidget {
  const _RarityLegend();

  @override
  Widget build(BuildContext context) {
    const items = [
      (label: 'Звичайне', color: Color(0xFF9E9E9E), pct: '40%'),
      (label: 'Рідкісне', color: Color(0xFF2196F3), pct: '30%'),
      (label: 'Епічне', color: Color(0xFF9C27B0), pct: '20%'),
      (label: 'Легендарне', color: AppColors.accent, pct: '8%'),
      (label: 'Міфічне', color: AppColors.primary, pct: '2%'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Рідкісність досягнень',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: items.map((item) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${item.label} ${item.pct}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

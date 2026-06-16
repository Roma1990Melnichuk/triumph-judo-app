import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/achievement_defs.dart';
import '../../../core/models/achievement_model.dart';
import '../../../shared/widgets/achievement_badge.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/achievement_provider.dart';

class AchievementCatalogScreen extends ConsumerWidget {
  /// Pass childId explicitly; if null, inferred from current user.
  const AchievementCatalogScreen({super.key, this.childId});

  final String? childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider).asData?.value;
    final effectiveChildId =
        childId ?? user?.childIds.firstOrNull ?? user?.childId ?? '';

    // Guard: no child resolved
    if (effectiveChildId.isEmpty && user != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: AppBackButton(onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : null),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Профіль спортсмена не знайдено',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
    final topPad = MediaQuery.of(context).padding.top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        Padding(
          padding: EdgeInsets.fromLTRB(12, topPad + 8, 12, 0),
          child: AppBackButton(onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : null),
        ),
        Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
    ),
      ],
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
              crossAxisCount: 3,
              childAspectRatio: 0.72,
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
                onTap: () => _showDetail(context, defs, earnedIds, i),
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

  void _showDetail(BuildContext context, List<AchievementDef> defs, Set<String> earnedIds, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _AchievementPageDialog(
        defs: defs,
        earnedIds: earnedIds,
        initialIndex: index,
      ),
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

  @override
  Widget build(BuildContext context) {
    final isHiddenLocked = def.isHidden && !isEarned;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: isHiddenLocked
                  ? const Text('❓', style: TextStyle(fontSize: 32))
                  : Opacity(
                      opacity: isEarned ? 1.0 : 0.28,
                      child: AchievementIcon(def: def, size: 72),
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
              fontSize: 11,
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

// ── Swipeable full-screen detail dialog ──────────────────────────────────────

class _AchievementPageDialog extends StatefulWidget {
  const _AchievementPageDialog({
    required this.defs,
    required this.earnedIds,
    required this.initialIndex,
  });

  final List<AchievementDef> defs;
  final Set<String> earnedIds;
  final int initialIndex;

  @override
  State<_AchievementPageDialog> createState() => _AchievementPageDialogState();
}

class _AchievementPageDialogState extends State<_AchievementPageDialog> {
  late final PageController _controller;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _rarityColors = {
    AchievementRarity.common: Color(0xFF9E9E9E),
    AchievementRarity.rare: Color(0xFF2196F3),
    AchievementRarity.epic: Color(0xFF9C27B0),
    AchievementRarity.legendary: AppColors.accent,
    AchievementRarity.mythic: AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black87,
          child: SafeArea(
            child: Column(
              children: [
                // Close + counter row
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.close, size: 20, color: Colors.white),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_current + 1} / ${widget.defs.length}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),

                // PageView
                Expanded(
                  child: GestureDetector(
                    onTap: () {}, // prevent dialog close when tapping content
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: widget.defs.length,
                      onPageChanged: (i) => setState(() => _current = i),
                      itemBuilder: (_, i) {
                        final def = widget.defs[i];
                        final isEarned = widget.earnedIds.contains(def.id);
                        final rarityColor = _rarityColors[def.rarity] ?? AppColors.textSecondary;
                        final isHiddenLocked = def.isHidden && !isEarned;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Large badge
                              Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  color: AppColors.surface.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isEarned
                                        ? rarityColor.withValues(alpha: 0.8)
                                        : Colors.white24,
                                    width: 2.5,
                                  ),
                                  boxShadow: isEarned
                                      ? [
                                          BoxShadow(
                                            color: rarityColor.withValues(alpha: 0.4),
                                            blurRadius: 40,
                                            spreadRadius: 4,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: isHiddenLocked
                                      ? const Text('❓', style: TextStyle(fontSize: 60))
                                      : Opacity(
                                          opacity: isEarned ? 1.0 : 0.35,
                                          child: AchievementIcon(def: def, size: 110),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Name
                              Text(
                                isHiddenLocked ? '???' : def.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Rarity chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(
                                  color: rarityColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: rarityColor.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  def.rarity.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: rarityColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Description
                              Text(
                                isHiddenLocked
                                    ? 'Отримай це досягнення, щоб дізнатися більше'
                                    : def.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  height: 1.55,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Status chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isEarned
                                      ? AppColors.success.withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isEarned
                                        ? AppColors.success.withValues(alpha: 0.5)
                                        : Colors.white24,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isEarned ? Icons.check_circle : Icons.lock_outline,
                                      size: 18,
                                      color: isEarned ? AppColors.success : Colors.white54,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isEarned ? 'Отримано' : 'Не отримано',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isEarned ? AppColors.success : Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Dot indicators (max 10 dots to avoid overflow)
                if (widget.defs.length <= 15)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.defs.length, (i) {
                        final active = i == _current;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active ? AppColors.accent : Colors.white24,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),

                // Swipe hint
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    '← Гортайте →',
                    style: TextStyle(color: Colors.white30, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
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

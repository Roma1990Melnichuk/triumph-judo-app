import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../shared/widgets/triumph_icon.dart';
import '../../../core/models/belt_requirement_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../team/providers/children_provider.dart';
import '../providers/belt_provider.dart';
import '../../../shared/widgets/belt_sprite_icon.dart';
import '../../../shared/widgets/video_player_dialog.dart';

class BeltOverviewScreen extends ConsumerStatefulWidget {
  const BeltOverviewScreen({super.key});

  @override
  ConsumerState<BeltOverviewScreen> createState() => _BeltOverviewScreenState();
}

class _BeltOverviewScreenState extends ConsumerState<BeltOverviewScreen> {
  BeltLevel _selected = BeltLevel.whiteYellow;

  static const _beltDescriptions = <BeltLevel, String>{
    BeltLevel.whiteYellow:   'Базові техніки падіння та перші кроки на шляху майстра',
    BeltLevel.yellow:        'Базові кидки та утримання — основа класичного дзюдо',
    BeltLevel.yellowOrange:  'Розвиток технічного арсеналу та комбінацій',
    BeltLevel.orange:        'Вдосконалення техніки, тактики та фізичної підготовки',
    BeltLevel.orangeGreen:   'Перші кроки до змагальної практики',
    BeltLevel.green:         'Стабілізація техніки та тактичне мислення',
    BeltLevel.greenBlue:     'Складні комбінації та спеціалізація',
    BeltLevel.blue:          'Майстерність і знання ката',
    BeltLevel.blueBrown:     'Поглиблена спеціалізація та суддівство',
    BeltLevel.brown:         'Рівень майстра — передостанній крок',
    BeltLevel.black:         'Вища майстерність — Дан',
  };

  static const _beltLevels = <BeltLevel, String>{
    BeltLevel.whiteYellow:   '9 кю',
    BeltLevel.yellow:        '8 кю',
    BeltLevel.yellowOrange:  '7 кю',
    BeltLevel.orange:        '6 кю',
    BeltLevel.orangeGreen:   '5 кю',
    BeltLevel.green:         '4 кю',
    BeltLevel.greenBlue:     '3 кю',
    BeltLevel.blue:          '2 кю',
    BeltLevel.blueBrown:     '1 кю',
    BeltLevel.brown:         '1 дан',
    BeltLevel.black:         '2+ дан',
  };

  @override
  Widget build(BuildContext context) {
    final user        = ref.watch(currentUserModelProvider).value;
    final isCoach     = user?.isCoach ?? false;
    final allReqs     = ref.watch(beltRequirementsProvider);
    final req         = allReqs.value?[_selected];
    final belts       = BeltLevel.values.where((b) => b != BeltLevel.white).toList();

    // For parent — show their child's progress
    String? childId;
    if (user?.isParent == true) {
      final children = ref.watch(allChildrenProvider).value ?? [];
      final myChild = children
          .where((c) => user?.ownsChild(c.id) ?? false)
          .firstOrNull;
      childId = myChild?.id;
    }

    final progressAsync = childId != null
        ? ref.watch(beltProgressProvider((childId: childId, belt: _selected)))
        : null;
    final progress = progressAsync?.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Система поясів'),
        actions: [
          if (isCoach)
            IconButton(
              icon: TriumphIcon(TIcon.team, size: 24),
              tooltip: 'Масова здача',
              onPressed: () => context.push('/bulk-belt'),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Belt level selector ───────────────────────────────────────────
          Container(
            height: 72,
            color: AppColors.surface,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: belts.length,
              itemBuilder: (context, i) {
                final b = belts[i];
                final isActive = b == _selected;
                return GestureDetector(
                  onTap: () => setState(() => _selected = b),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isActive
                          ? b.color.withValues(alpha: 0.2)
                          : AppColors.surface2,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? b.color : AppColors.surface3,
                        width: isActive ? 2.5 : 1,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: b.color.withValues(alpha: 0.4),
                                blurRadius: 8,
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: BeltSpriteIcon(belt: b, size: 36),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: allReqs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Помилка: $e')),
              data: (_) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Belt hero card ──────────────────────────────────────
                    _BeltHeroCard(
                      belt: _selected,
                      description: _beltDescriptions[_selected] ?? '',
                      level: _beltLevels[_selected] ?? '',
                      exercises: req?.exercises ?? [],
                      progress: progress,
                    ),
                    const SizedBox(height: 16),

                    // ── Category breakdown ──────────────────────────────────
                    if (req != null && req.exercises.isNotEmpty)
                      _CategoryBreakdown(
                        req: req,
                        progress: progress,
                        isCoach: isCoach,
                        belt: _selected,
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surface3),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.4),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Тренер ще не додав вимоги до цього поясу',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (isCoach) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Редагувати вимоги'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: const BorderSide(color: AppColors.accent),
                          minimumSize: const Size(double.infinity, 44),
                        ),
                        onPressed: () => context.push('/belts/edit'),
                      ),
                    ],
                    const SizedBox(height: 80),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Belt hero card
// ─────────────────────────────────────────────────────────────────────────────

class _BeltHeroCard extends StatelessWidget {
  const _BeltHeroCard({
    required this.belt,
    required this.description,
    required this.level,
    required this.exercises,
    required this.progress,
  });

  final BeltLevel belt;
  final String description;
  final String level;
  final List<Exercise> exercises;
  final dynamic progress;

  int get _passed {
    if (progress == null) return 0;
    final p = progress!.passed as Map<String, bool>;
    return p.values.where((v) => v).length;
  }

  int get _total => exercises.length;

  double get _pct => _total > 0 ? _passed / _total : 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: belt.color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: belt.color.withValues(alpha: 0.12),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Belt icon + name + level
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: belt.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: belt.color.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: BeltSpriteIcon(belt: belt, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${belt.displayName} пояс',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      level,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          if (description.isNotEmpty)
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),

          if (_total > 0 && progress != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Загальна готовність',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${(_pct * 100).round()}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _pct == 1.0 ? AppColors.success : AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _pct,
                minHeight: 8,
                backgroundColor: AppColors.surface3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _pct == 1.0 ? AppColors.success : AppColors.accent,
                ),
              ),
            ),
          ] else if (_total > 0) ...[
            const SizedBox(height: 12),
            Text(
              '$_total вправ',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category breakdown
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({
    required this.req,
    required this.progress,
    required this.isCoach,
    required this.belt,
  });

  final BeltRequirementModel req;
  final dynamic progress;
  final bool isCoach;
  final BeltLevel belt;

  static const _categoryIcons = <ExerciseCategory, TIcon>{
    ExerciseCategory.technique:   TIcon.training,
    ExerciseCategory.physical:    TIcon.experience,
    ExerciseCategory.theory:      TIcon.info,
    ExerciseCategory.competition: TIcon.tournament,
  };

  @override
  Widget build(BuildContext context) {
    final byCategory = req.byCategory;
    if (byCategory.isEmpty) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: byCategory.entries.toList().asMap().entries.map((outer) {
          final i = outer.key;
          final cat = outer.value.key;
          final exercises = outer.value.value;
          final total = exercises.length;

          int passed = 0;
          if (progress != null) {
            final p = progress!.passed as Map<String, bool>;
            passed = exercises.where((e) => p[e.id] == true).length;
          }

          final isDone = progress != null && passed == total;
          final icon = _categoryIcons[cat] ?? TIcon.training;
          final hasAnyVideo = exercises.any((e) => e.videoUrl.isNotEmpty);

          Widget? trailingWidget;
          if (isDone) {
            trailingWidget =
                const Icon(Icons.check_circle, color: AppColors.success, size: 22);
          } else if (progress != null) {
            trailingWidget = Text(
              '${(passed / total * 100).round()}%',
              style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            );
          }

          return Column(
            children: [
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  iconColor: AppColors.textSecondary,
                  collapsedIconColor: AppColors.textSecondary,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (isDone ? AppColors.success : AppColors.accent)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        isDone ? AppColors.success : AppColors.accent,
                        BlendMode.srcIn,
                      ),
                      child: TriumphIcon(icon, size: 22),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(cat.displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: AppColors.textPrimary)),
                      if (hasAnyVideo) ...[
                        const SizedBox(width: 6),
                        const ColorFiltered(
                          colorFilter: ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
                          child: TriumphIcon(TIcon.video, size: 13),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    progress != null ? '$passed з $total' : '$total вправ',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: trailingWidget,
                  children: exercises.map((ex) {
                    final isPassed = progress != null &&
                        (progress!.passed as Map<String, bool>)[ex.id] ==
                            true;
                    final hasVideo = ex.videoUrl.isNotEmpty;
                    return ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.fromLTRB(72, 0, 8, 0),
                      title: Text(
                        ex.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          fontWeight: isPassed
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: ex.description.isNotEmpty
                          ? Text(ex.description,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary))
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasVideo)
                            GestureDetector(
                              onTap: () => VideoPlayerDialog.show(
                                  context, ex.videoUrl,
                                  title: ex.name),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.35)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.play_arrow,
                                        color: AppColors.accent,
                                        size: 13),
                                    SizedBox(width: 3),
                                    Text('Відео',
                                        style: TextStyle(
                                            color: AppColors.accent,
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          if (isPassed) ...[
                            if (hasVideo) const SizedBox(width: 6),
                            const Icon(Icons.check_circle,
                                color: AppColors.success, size: 16),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (i < byCategory.length - 1)
                const Divider(height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }
}

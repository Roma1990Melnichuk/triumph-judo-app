import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/belt_levels.dart';
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
    BeltLevel.whiteYellow:  'Базові техніки падіння та перші кроки на шляху майстра',
    BeltLevel.yellow:       'Базові кидки та утримання — основа класичного дзюдо',
    BeltLevel.yellowOrange: 'Розвиток технічного арсеналу та комбінацій',
    BeltLevel.orange:       'Вдосконалення техніки, тактики та фізичної підготовки',
    BeltLevel.orangeGreen:  'Перші кроки до змагальної практики',
    BeltLevel.green:        'Стабілізація техніки та тактичне мислення',
    BeltLevel.greenBlue:    'Складні комбінації та спеціалізація',
    BeltLevel.blue:         'Майстерність і знання ката',
    BeltLevel.blueBrown:    'Поглиблена спеціалізація та суддівство',
    BeltLevel.brown:        'Рівень майстра — передостанній крок',
    BeltLevel.black:        'Вища майстерність — Дан',
  };

  static const _beltLevels = <BeltLevel, String>{
    BeltLevel.whiteYellow:  '9 кю',
    BeltLevel.yellow:       '8 кю',
    BeltLevel.yellowOrange: '7 кю',
    BeltLevel.orange:       '6 кю',
    BeltLevel.orangeGreen:  '5 кю',
    BeltLevel.green:        '4 кю',
    BeltLevel.greenBlue:    '3 кю',
    BeltLevel.blue:         '2 кю',
    BeltLevel.blueBrown:    '1 кю',
    BeltLevel.brown:        '1 дан',
    BeltLevel.black:        '2+ дан',
  };

  @override
  Widget build(BuildContext context) {
    final user      = ref.watch(currentUserModelProvider).asData?.value;
    final isCoach   = user?.isCoach ?? false;
    final allReqs   = ref.watch(beltRequirementsProvider);
    final req       = allReqs.asData?.value[_selected];
    final belts     = BeltLevel.values.where((b) => b != BeltLevel.white).toList();

    String? childId;
    if (user?.isParent == true) {
      final children = ref.watch(allChildrenProvider).asData?.value ?? [];
      final myChild  = children
          .where((c) => user?.ownsChild(c.id) ?? false)
          .firstOrNull;
      childId = myChild?.id;
    }

    final progressAsync = childId != null
        ? ref.watch(beltProgressProvider((childId: childId, belt: _selected)))
        : null;
    final progress = progressAsync?.asData?.value;

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
                      'Система поясів',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/exercise-library'),
                    child: Container(
                      width: 44, height: 44,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.orange.withValues(alpha: 0.3)),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.fitness_center_rounded,
                          color: AppColors.orange, size: 20),
                    ),
                  ),
                  if (isCoach)
                    GestureDetector(
                      onTap: () => context.push('/bulk-belt'),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surface3),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.people_outline_rounded,
                          size: 22,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Belt selector ────────────────────────────────────────────────
            SizedBox(
              height: 84,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                itemCount: belts.length,
                itemBuilder: (context, i) {
                  final b        = belts[i];
                  final isActive = b == _selected;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = b),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 10),
                      width: 56,
                      decoration: BoxDecoration(
                        color: isActive
                            ? b.color.withValues(alpha: 0.15)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isActive ? b.color : AppColors.surface3,
                          width: isActive ? 2 : 1,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: b.color.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BeltSpriteIcon(belt: b, size: 38),
                          const SizedBox(height: 2),
                          Text(
                            b.abbreviation,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? b.color
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Content ──────────────────────────────────────────────────────
            Expanded(
              child: allReqs.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Помилка: $e')),
                data: (_) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    _BeltHeroCard(
                      belt:        _selected,
                      description: _beltDescriptions[_selected] ?? '',
                      level:       _beltLevels[_selected] ?? '',
                      exercises:   req?.exercises ?? [],
                      progress:    progress,
                    ),
                    const SizedBox(height: 16),

                    if (isCoach || (req != null && req.exercises.isNotEmpty))
                      _CategoryBreakdown(
                        req: req ??
                            BeltRequirementModel(
                              belt: _selected,
                              exercises: const [],
                              updatedAt: DateTime(2024),
                              updatedByCoachId: '',
                            ),
                        progress: progress,
                        isCoach: isCoach,
                        belt: _selected,
                        coachId: user?.uid,
                      )
                    else
                      Container(
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
                          minimumSize: const Size(double.infinity, 48),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => context.push('/belts/edit'),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
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
  final String    description;
  final String    level;
  final List<Exercise> exercises;
  final dynamic   progress;

  int get _passed {
    if (progress == null) return 0;
    final p = progress!.passed as Map<String, bool>;
    return p.values.where((v) => v).length;
  }

  int    get _total => exercises.length;
  double get _pct   => _total > 0 ? _passed / _total : 0;

  @override
  Widget build(BuildContext context) {
    final beltColor = belt.color;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: beltColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: beltColor.withValues(alpha: 0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Hero top section ───────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  beltColor.withValues(alpha: 0.22),
                  beltColor.withValues(alpha: 0.04),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: beltColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: beltColor.withValues(alpha: 0.30),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: BeltSpriteIcon(belt: belt, size: 72),
                ),
                const SizedBox(height: 14),
                Text(
                  '${belt.displayName} пояс',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: beltColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: beltColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: beltColor == const Color(0xFF212121)
                          ? AppColors.textSecondary
                          : beltColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Description + progress ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
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
                          color: _pct == 1.0
                              ? AppColors.success
                              : AppColors.accent,
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
                        _pct == 1.0
                            ? AppColors.success
                            : AppColors.accent,
                      ),
                    ),
                  ),
                ] else if (_total > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    '$_total вправ',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category breakdown
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryBreakdown extends ConsumerWidget {
  const _CategoryBreakdown({
    required this.req,
    required this.progress,
    required this.isCoach,
    required this.belt,
    required this.coachId,
  });

  final BeltRequirementModel req;
  final dynamic progress;
  final bool      isCoach;
  final BeltLevel belt;
  final String?   coachId;

  static const _categoryIcons = <ExerciseCategory, IconData>{
    ExerciseCategory.technique:   Icons.sports_kabaddi,
    ExerciseCategory.physical:    Icons.fitness_center,
    ExerciseCategory.theory:      Icons.menu_book_outlined,
    ExerciseCategory.competition: Icons.emoji_events_outlined,
  };

  Future<void> _showEditDialog(
      BuildContext ctx, WidgetRef ref, Exercise ex) async {
    final result = await showDialog<({String name, String desc})>(
      context: ctx,
      builder: (_) => _EditExerciseDialog(exercise: ex),
    );
    if (result == null) return;
    final updated = Exercise(
      id: ex.id,
      name: result.name,
      description: result.desc,
      category: ex.category,
      videoUrl: ex.videoUrl,
    );
    await ref.read(beltNotifierProvider.notifier).updateExercise(
          belt: belt,
          updated: updated,
          coachId: coachId ?? '',
        );
  }

  Future<void> _confirmDelete(
      BuildContext ctx, WidgetRef ref, Exercise ex) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Видалити вправу?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(ex.name,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Скасувати',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Видалити',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(beltNotifierProvider.notifier).removeExercise(
          belt: belt,
          exerciseId: ex.id,
          coachId: coachId ?? '',
        );
  }

  Future<void> _showAddDialog(
      BuildContext ctx, WidgetRef ref, ExerciseCategory cat) async {
    final result = await showDialog<({String name, String desc})>(
      context: ctx,
      builder: (_) => _AddTaskDialog(category: cat),
    );
    if (result == null) return;
    await ref.read(beltNotifierProvider.notifier).addExercise(
          belt: belt,
          name: result.name,
          description: result.desc,
          category: cat,
          coachId: coachId ?? '',
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Coaches see all 4 categories (even empty) so they can add tasks.
    // Athletes/parents only see categories that have exercises.
    final allCategories = req.byCategory;
    final displayCategories = isCoach
        ? allCategories
        : Map.fromEntries(
            allCategories.entries.where((e) => e.value.isNotEmpty));

    if (displayCategories.isEmpty) return const SizedBox();

    final entries = displayCategories.entries.toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: entries.asMap().entries.map((outer) {
          final i         = outer.key;
          final cat       = outer.value.key;
          final exercises = outer.value.value;
          final total     = exercises.length;

          int passed = 0;
          if (progress != null) {
            final p = progress!.passed as Map<String, bool>;
            passed = exercises.where((e) => p[e.id] == true).length;
          }

          // Empty category: never mark as done
          final isDone      = progress != null && total > 0 && passed == total;
          final icon        = _categoryIcons[cat] ?? Icons.fitness_center;
          final hasAnyVideo = exercises.any((e) => e.videoUrl.isNotEmpty);

          Widget? trailingWidget;
          if (isDone) {
            trailingWidget = const Icon(
                Icons.check_circle, color: AppColors.success, size: 22);
          } else if (progress != null && total > 0) {
            trailingWidget = Text(
              '${(passed / total * 100).round()}%',
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            );
          }

          return Column(
            children: [
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  iconColor: AppColors.textSecondary,
                  collapsedIconColor: AppColors.textSecondary,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (isDone
                              ? AppColors.success
                              : AppColors.accent)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: isDone ? AppColors.success : AppColors.accent,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        cat.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (hasAnyVideo) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.play_circle_outline,
                            size: 14, color: AppColors.accent),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    total == 0
                        ? 'немає завдань'
                        : (progress != null
                            ? '$passed з $total'
                            : '$total вправ'),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: trailingWidget,
                  children: [
                    ...exercises.map((ex) {
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
                            ? Text(
                                ex.description,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              )
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
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.play_arrow,
                                          color: AppColors.accent,
                                          size: 13),
                                      SizedBox(width: 3),
                                      Text(
                                        'Відео',
                                        style: TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (isPassed) ...[
                              if (hasVideo) const SizedBox(width: 6),
                              const Icon(Icons.check_circle,
                                  color: AppColors.success, size: 16),
                            ],
                            if (isCoach) ...[
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _showEditDialog(context, ref, ex),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.edit_outlined,
                                      size: 16,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _confirmDelete(context, ref, ex),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.delete_outline,
                                      size: 16,
                                      color: AppColors.error),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                    if (isCoach)
                      InkWell(
                        onTap: () => _showAddDialog(context, ref, cat),
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(72, 8, 16, 10),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle_outline,
                                  color: AppColors.accent, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Додати завдання',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (i < entries.length - 1)
                const Divider(height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit exercise dialog
// ─────────────────────────────────────────────────────────────────────────────

class _EditExerciseDialog extends StatefulWidget {
  const _EditExerciseDialog({required this.exercise});
  final Exercise exercise;

  @override
  State<_EditExerciseDialog> createState() => _EditExerciseDialogState();
}

class _EditExerciseDialogState extends State<_EditExerciseDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.exercise.name);
    _descCtrl = TextEditingController(text: widget.exercise.description);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Редагувати вправу',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Назва',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.surface3),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Опис',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.surface3),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Скасувати',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, (name: name, desc: _descCtrl.text.trim()));
          },
          child: const Text('Зберегти',
              style: TextStyle(color: AppColors.accent)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add task dialog
// ─────────────────────────────────────────────────────────────────────────────

class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog({required this.category});
  final ExerciseCategory category;

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Додати — ${widget.category.displayName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Назва завдання *',
              hintText: 'Введіть назву',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Опис',
              hintText: 'Необов\'язково',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Скасувати'),
        ),
        TextButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
                context, (name: name, desc: _descCtrl.text.trim()));
          },
          child: const Text('Додати'),
        ),
      ],
    );
  }
}

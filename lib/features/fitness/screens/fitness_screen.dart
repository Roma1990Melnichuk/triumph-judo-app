import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/fitness_exercise_model.dart';
import '../../../core/models/fitness_log_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/fitness_provider.dart';
import '../providers/fitness_assignment_provider.dart';
import '../../../shared/widgets/triumph_icon.dart';

class FitnessScreen extends ConsumerStatefulWidget {
  const FitnessScreen({super.key, required this.childId, this.childName = ''});

  final String childId;
  final String childName;

  @override
  ConsumerState<FitnessScreen> createState() => _FitnessScreenState();
}

class _FitnessScreenState extends ConsumerState<FitnessScreen> {
  bool _seeding = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(fitnessNotifierProvider.notifier).seedDefaultsIfEmpty();
      if (mounted) setState(() => _seeding = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCoach =
        ref.watch(currentUserModelProvider).asData?.value?.isCoach ?? false;
    final exercisesAsync = ref.watch(fitnessExercisesProvider);
    final logsAsync = ref.watch(childFitnessLogsProvider(widget.childId));

    final exercises = exercisesAsync.asData?.value ?? [];
    final logs = logsAsync.asData?.value ?? [];

    // Build stats per exercise: latestLog, previousLog, total count
    final statsMap = <String, _ExStat>{};
    for (final ex in exercises) {
      final exLogs =
          logs.where((l) => l.exerciseId == ex.id).toList(); // desc
      statsMap[ex.id] = _ExStat(
        last: exLogs.isNotEmpty ? exLogs.first : null,
        prev: exLogs.length > 1 ? exLogs[1] : null,
        count: exLogs.length,
      );
    }

    final loading = _seeding || exercisesAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn),
                          child: TriumphIcon(TIcon.back, size: 22),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Фізична підготовка',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (widget.childName.isNotEmpty)
                          Text(
                            widget.childName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : exercises.isEmpty
                      ? const Center(
                          child: Text(
                            'Немає вправ',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : _FitnessBody(
                          childId: widget.childId,
                          childName: widget.childName,
                          exercises: exercises,
                          statsMap: statsMap,
                          logs: logs,
                          isCoach: isCoach,
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: isCoach
          ? FloatingActionButton(
              onPressed: () => _showAddExerciseDialog(context),
              tooltip: 'Нова вправа',
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            )
          : null,
    );
  }

  void _showAddExerciseDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddExerciseDialog(
        onCreate: (name, unit) =>
            ref.read(fitnessNotifierProvider.notifier).addExercise(name, unit),
      ),
    );
  }
}

// ── Body: assignments banner + exercise grid ──────────────────────────────────

class _FitnessBody extends ConsumerWidget {
  const _FitnessBody({
    required this.childId,
    required this.childName,
    required this.exercises,
    required this.statsMap,
    required this.logs,
    required this.isCoach,
  });

  final String childId;
  final String childName;
  final List<FitnessExercise> exercises;
  final Map<String, _ExStat> statsMap;
  final List<FitnessLog> logs;
  final bool isCoach;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAssignments =
        ref.watch(activeChildAssignmentsProvider(childId));

    return CustomScrollView(
      slivers: [
        // ── Active assignments ───────────────────────────────────────────
        if (activeAssignments.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  ColorFiltered(
                    colorFilter: const ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
                    child: TriumphIcon(TIcon.tasks, size: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Активні завдання (${activeAssignments.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AssignmentCard(
                    assignment: activeAssignments[i],
                    logs: logs,
                    childId: childId,
                  ),
                ),
                childCount: activeAssignments.length,
              ),
            ),
          ),
        ],

        // ── Personal logs (coach view only) ─────────────────────────────
        if (isCoach) ..._personalLogsSection(logs),

        // ── Exercise grid ────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.05,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final ex = exercises[i];
                return _ExerciseCard(
                  exercise: ex,
                  stat: statsMap[ex.id] ?? const _ExStat(),
                  onTap: () => context.push(
                    '/fitness/$childId/exercise/${ex.id}',
                    extra: {
                      'name': ex.name,
                      'unit': ex.unit,
                      'childName': childName,
                    },
                  ),
                );
              },
              childCount: exercises.length,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _personalLogsSection(List<FitnessLog> logs) {
    final personal = logs
        .where((l) => l.assignmentId == null || l.assignmentId!.isEmpty)
        .toList();
    if (personal.isEmpty) return [];

    final recent = personal.take(5).toList();
    final fmt = (double v) =>
        v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
          child: Row(
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn),
                child: TriumphIcon(TIcon.training, size: 16),
              ),
              const SizedBox(width: 6),
              Text(
                'Особисті тренування (${personal.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final log = recent[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surface3),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        log.exerciseName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${fmt(log.value)} ${log.exerciseUnit}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${log.date.day}.${log.date.month.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            },
            childCount: recent.length,
          ),
        ),
      ),
    ];
  }
}

// ── Single assignment progress card ──────────────────────────────────────────

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.logs,
    required this.childId,
  });

  final dynamic assignment; // FitnessAssignment
  final List<FitnessLog> logs;
  final String childId;

  @override
  Widget build(BuildContext context) {
    final progress = assignmentProgress(logs, assignment, childId);
    final target = assignment.targetValue as double;
    final pct = (target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0);
    final done = pct >= 1.0;

    final daysLeft = assignment.deadline.difference(DateTime.now()).inDays;
    final daysLabel = daysLeft == 0
        ? 'Сьогодні дедлайн'
        : daysLeft == 1
            ? 'Залишився 1 день'
            : 'Залишилося $daysLeft д.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: done
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.surface3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  assignment.title as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              if (done)
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${_fmt(progress)} / ${_fmt(target)} ${assignment.exerciseUnit}',
                style: TextStyle(
                  color: done ? AppColors.success : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                done ? 'Виконано ✅' : daysLabel,
                style: TextStyle(
                  color: done
                      ? AppColors.success
                      : daysLeft <= 1
                          ? AppColors.error
                          : AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.surface3,
              valueColor: AlwaysStoppedAnimation(
                done ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

// ── Per-exercise stats helper ─────────────────────────────────────────────────

class _ExStat {
  const _ExStat({this.last, this.prev, this.count = 0});
  final FitnessLog? last;
  final FitnessLog? prev;
  final int count;
}

// ── Exercise grid card ────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.stat,
    required this.onTap,
  });

  final FitnessExercise exercise;
  final _ExStat stat;
  final VoidCallback onTap;

  Color get _accentColor {
    // Deterministic hue from exercise id
    final hues = [0.0, 30.0, 60.0, 120.0, 180.0, 240.0, 270.0, 300.0];
    final idx = exercise.id.codeUnits.fold(0, (a, b) => a + b) % hues.length;
    return HSLColor.fromAHSL(1.0, hues[idx], 0.65, 0.52).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final last = stat.last;
    final prev = stat.prev;

    double? delta;
    if (last != null && prev != null) {
      delta = last.value - prev.value;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surface3),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                exercise.name[0].toUpperCase(),
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              exercise.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            if (last != null) ...[
              Row(
                children: [
                  Text(
                    _fmt(last.value),
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    exercise.unit,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  if (delta != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          delta > 0
                              ? Icons.trending_up
                              : delta < 0
                                  ? Icons.trending_down
                                  : Icons.trending_flat,
                          size: 16,
                          color: delta > 0
                              ? AppColors.success
                              : delta < 0
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                        ),
                      ],
                    ),
                ],
              ),
              Text(
                '${stat.count} записів',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10),
              ),
            ] else
              const Text(
                'Немає записів',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

// ── Add exercise dialog ───────────────────────────────────────────────────────

class _AddExerciseDialog extends StatefulWidget {
  const _AddExerciseDialog({required this.onCreate});
  final void Function(String name, String unit) onCreate;

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _nameCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'рази');

  static const _unitSuggestions = [
    'рази', 'секунди', 'хвилини', 'кг', 'метри', 'км', 'кроки',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final unit = _unitCtrl.text.trim();
    if (name.isEmpty || unit.isEmpty) return;
    widget.onCreate(name, unit);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Нова вправа'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Назва вправи'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _unitCtrl,
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Одиниця виміру',
              hintText: 'напр. рази, секунди, кг…',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _unitSuggestions.map((u) {
              final selected = _unitCtrl.text.trim() == u;
              return GestureDetector(
                onTap: () => setState(() => _unitCtrl.text = u),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : AppColors.surface3,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.surface3,
                    ),
                  ),
                  child: Text(
                    u,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Скасувати'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text(
            'Додати',
            style: TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

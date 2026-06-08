
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/fitness_assignment_model.dart';
import '../../../core/models/fitness_exercise_model.dart';
import '../../../core/models/fitness_log_model.dart';
import '../providers/fitness_provider.dart';
import '../providers/fitness_assignment_provider.dart';

class MyAssignmentsScreen extends ConsumerStatefulWidget {
  const MyAssignmentsScreen({super.key, required this.childId});
  final String childId;

  @override
  ConsumerState<MyAssignmentsScreen> createState() =>
      _MyAssignmentsScreenState();
}

class _MyAssignmentsScreenState extends ConsumerState<MyAssignmentsScreen> {
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
    final assignmentsAsync = ref.watch(allAssignmentsProvider);
    final logsAsync = ref.watch(childFitnessLogsProvider(widget.childId));
    final exercisesAsync = ref.watch(fitnessExercisesProvider);

    final assignments = assignmentsAsync.value ?? [];
    final logs = logsAsync.value ?? [];
    final exercises = exercisesAsync.value ?? [];

    final now = DateTime.now();
    final active = assignments
        .where((a) =>
            a.assignedChildIds.contains(widget.childId) &&
            a.status != AssignmentStatus.draft &&
            a.deadline.isAfter(now))
        .toList();

    final loading = _seeding || assignmentsAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Column(
          children: [
            const Text('Мої завдання'),
            if (active.isNotEmpty)
              Text(
                'Активні ${active.length}',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            onPressed: () {},
            tooltip: 'Фільтр',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                if (active.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Row(
                        children: [
                          const Text(
                            'Активні завдання',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(width: 8),
                          _Badge(active.length),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final a = active[i];
                          final progress =
                              _calcProgress(logs, a, widget.childId);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ActiveAssignmentCard(
                              assignment: a,
                              progress: progress,
                              childId: widget.childId,
                              logs: logs,
                            ),
                          );
                        },
                        childCount: active.length,
                      ),
                    ),
                  ),
                ],

                // Exercises section
                if (exercises.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Вправи',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.zero),
                            child: const Text(
                              'Додати вправу',
                              style: TextStyle(
                                  color: AppColors.accent, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.9,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _ExerciseGridCard(
                          exercise: exercises[i],
                          logs: logs
                              .where((l) =>
                                  l.exerciseId == exercises[i].id)
                              .toList(),
                        ),
                        childCount: exercises.length,
                      ),
                    ),
                  ),
                ],

                if (active.isEmpty && exercises.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Немає активних завдань',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  double _calcProgress(
    List<FitnessLog> logs,
    FitnessAssignment a,
    String childId,
  ) {
    return logs
        .where((l) =>
            l.exerciseId == a.exerciseId &&
            l.childId == childId &&
            !l.date.isBefore(a.startDate) &&
            !l.date.isAfter(a.deadline))
        .fold(0.0, (acc, l) => acc + l.value);
  }
}

// ── Active assignment card (stat_1.png style) ─────────────────────────────────

class _ActiveAssignmentCard extends StatelessWidget {
  const _ActiveAssignmentCard({
    required this.assignment,
    required this.progress,
    required this.childId,
    required this.logs,
  });

  final FitnessAssignment assignment;
  final double progress;
  final String childId;
  final List<FitnessLog> logs;

  @override
  Widget build(BuildContext context) {
    final target = assignment.targetValue;
    final pct = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;
    final pctInt = (pct * 100).round();
    final daysLeft = assignment.deadline.difference(DateTime.now()).inDays;

    final fmtVal = (double v) => v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(1);

    return GestureDetector(
      onTap: () => context.push(
        '/my-assignments/${assignment.id}',
        extra: {'childId': childId},
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surface3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ExerciseIconCircle(name: assignment.exerciseName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_fmtShort(assignment.startDate)} – ${_fmtShort(assignment.deadline)}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _CircularProgress(pct: pct, pctInt: pctInt),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmtVal(progress),
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent),
                ),
                Text(
                  ' / ${fmtVal(target)} ${assignment.exerciseUnit}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.schedule_outlined,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  daysLeft <= 0
                      ? 'Дедлайн минув'
                      : 'Залишилось $daysLeft ${_dayWord(daysLeft)}',
                  style: TextStyle(
                    color: daysLeft <= 3
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.push(
                '/my-assignments/${assignment.id}/add-result',
                extra: {
                  'childId': childId,
                  'exerciseName': assignment.exerciseName,
                  'exerciseUnit': assignment.exerciseUnit,
                  'exerciseId': assignment.exerciseId,
                },
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: AppColors.ctaGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Додати результат',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _dayWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'день';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
      return 'дні';
    }
    return 'днів';
  }
}

// ── Circular progress indicator ───────────────────────────────────────────────

class _CircularProgress extends StatelessWidget {
  const _CircularProgress({required this.pct, required this.pctInt});
  final double pct;
  final int pctInt;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 52,
        height: 52,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: pct,
              strokeWidth: 5,
              backgroundColor: AppColors.surface3,
              valueColor: AlwaysStoppedAnimation(
                pct >= 0.8
                    ? AppColors.success
                    : pct >= 0.5
                        ? AppColors.accent
                        : AppColors.primary,
              ),
            ),
            Text(
              '$pctInt%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
}

// ── Exercise icon circle ──────────────────────────────────────────────────────

class _ExerciseIconCircle extends StatelessWidget {
  const _ExerciseIconCircle({required this.name});
  final String name;

  Color get _color {
    final hues = [0.0, 30.0, 60.0, 120.0, 180.0, 240.0, 270.0, 300.0];
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % hues.length;
    return HSLColor.fromAHSL(1.0, hues[idx], 0.7, 0.5).toColor();
  }

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style:
              TextStyle(color: _color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
}

// ── Exercise grid card (bottom section stat_1.png) ────────────────────────────

class _ExerciseGridCard extends StatelessWidget {
  const _ExerciseGridCard({required this.exercise, required this.logs});
  final FitnessExercise exercise;
  final List<FitnessLog> logs;

  Color get _color {
    final hues = [0.0, 30.0, 60.0, 120.0, 180.0, 240.0, 270.0, 300.0];
    final idx = exercise.id.codeUnits.fold(0, (a, b) => a + b) % hues.length;
    return HSLColor.fromAHSL(1.0, hues[idx], 0.65, 0.52).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final last = logs.isNotEmpty ? logs.first : null;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surface3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              exercise.name.isNotEmpty
                  ? exercise.name[0].toUpperCase()
                  : '?',
              style: TextStyle(
                  color: _color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            exercise.name,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          if (last != null)
            Text(
              '${_fmt(last.value)} ${exercise.unit}',
              style: TextStyle(
                  color: _color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            )
          else
            Text(
              logs.isEmpty ? '—' : '${logs.length} р.',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11),
            ),
        ],
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

// ── Badge ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge(this.count);
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

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtShort(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

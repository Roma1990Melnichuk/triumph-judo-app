import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/fitness_assignment_model.dart';
import '../../../shared/widgets/triumph_icon.dart';
import '../providers/fitness_assignment_provider.dart';

class CoachAssignmentsScreen extends ConsumerStatefulWidget {
  const CoachAssignmentsScreen({super.key});

  @override
  ConsumerState<CoachAssignmentsScreen> createState() =>
      _CoachAssignmentsScreenState();
}

class _CoachAssignmentsScreenState extends ConsumerState<CoachAssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeAssignmentsProvider);
    final drafts = ref.watch(draftAssignmentsProvider);
    final completed = ref.watch(completedAssignmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 20, 8),
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
                  const SizedBox(width: 16),
                  const Text(
                    'Завдання тренера',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tab,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Активні'),
                      if (active.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _Badge(active.length),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Чернетки'),
                      if (drafts.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _Badge(drafts.length),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Завершені'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _AssignmentsList(
                    assignments: active,
                    emptyText: 'Немає активних завдань',
                  ),
                  _AssignmentsList(
                    assignments: drafts,
                    emptyText: 'Немає чернеток',
                  ),
                  _AssignmentsList(
                    assignments: completed,
                    emptyText: 'Немає завершених завдань',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/assignments/create'),
        backgroundColor: AppColors.fabBg,
        foregroundColor: AppColors.fabIcon,
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.count);
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$count',
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      );
}

// ── Assignments list tab ──────────────────────────────────────────────────────

class _AssignmentsList extends ConsumerWidget {
  const _AssignmentsList({
    required this.assignments,
    required this.emptyText,
  });

  final List<FitnessAssignment> assignments;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (assignments.isEmpty) {
      return _EmptyState(text: emptyText);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: assignments.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i == assignments.length) {
          return _TipCard();
        }
        return _CoachAssignmentCard(assignment: assignments[i]);
      },
    );
  }
}

// ── Coach assignment card ─────────────────────────────────────────────────────

class _CoachAssignmentCard extends ConsumerWidget {
  const _CoachAssignmentCard({required this.assignment});
  final FitnessAssignment assignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(assignmentLogsProvider(assignment.id));
    final logs = logsAsync.value ?? [];

    final totalProgress = logs.fold<double>(0.0, (acc, l) => acc + l.value);
    final pct = assignment.targetValue > 0
        ? (totalProgress / assignment.targetValue).clamp(0.0, 1.0)
        : 0.0;
    final pctInt = (pct * 100).round();

    final daysLeft = assignment.deadline.difference(DateTime.now()).inDays;
    final daysLabel = daysLeft < 0
        ? 'Завершено'
        : daysLeft == 0
            ? 'Сьогодні дедлайн'
            : 'Залишилось $daysLeft д.';

    final Color statusColor;
    if (assignment.status == AssignmentStatus.draft) {
      statusColor = AppColors.textSecondary;
    } else if (pct >= 0.8) {
      statusColor = AppColors.success;
    } else if (pct >= 0.5) {
      statusColor = AppColors.accent;
    } else {
      statusColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface3),
      ),
      child: InkWell(
        onTap: () => context.push('/assignments/${assignment.id}/progress'),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ExerciseIcon(name: assignment.exerciseName),
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
                        '${_fmtDate(assignment.startDate)} – ${_fmtDate(assignment.deadline)}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '· ${assignment.assignedChildIds.length} спортсменів',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$pctInt%',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Text(
                      'прогрес',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textSecondary, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showCardMenu(context, ref, assignment),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: AppColors.surface3,
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: daysLeft < 0
                        ? AppColors.surface3
                        : daysLeft <= 3
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.surface3,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    daysLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: daysLeft < 0
                          ? AppColors.textSecondary
                          : daysLeft <= 3
                              ? AppColors.primary
                              : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCardMenu(
      BuildContext context, WidgetRef ref, FitnessAssignment a) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.surface3,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: ColorFiltered(
                colorFilter: const ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
                child: TriumphIcon(TIcon.statistics, size: 22),
              ),
              title: const Text('Переглянути прогрес'),
              onTap: () {
                Navigator.pop(sheetCtx);
                context.push('/assignments/${a.id}/progress');
              },
            ),
            ListTile(
              leading: ColorFiltered(
                colorFilter: const ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn),
                child: TriumphIcon(TIcon.team, size: 22),
              ),
              title: const Text('Список спортсменів'),
              onTap: () {
                Navigator.pop(sheetCtx);
                context.push('/assignments/${a.id}/athletes');
              },
            ),
            if (a.status == AssignmentStatus.active)
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                title: const Text('Завершити завдання'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  ref
                      .read(assignmentNotifierProvider.notifier)
                      .completeAssignment(a.id);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
              title: const Text('Видалити',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(sheetCtx);
                ref
                    .read(assignmentNotifierProvider.notifier)
                    .deleteAssignment(a.id);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Exercise icon ─────────────────────────────────────────────────────────────

class _ExerciseIcon extends StatelessWidget {
  const _ExerciseIcon({required this.name});
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
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style:
              TextStyle(color: _color, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );
}

// ── Tip card ──────────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
              child: TriumphIcon(TIcon.motivation, size: 18),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Регулярно перевіряйте прогрес\nКоригуйте навантаження та давайте спортсменам зворотній зв\'язок.',
                style: TextStyle(
                    color: AppColors.accent, fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                AppColors.textSecondary.withValues(alpha: 0.35),
                BlendMode.srcIn,
              ),
              child: TriumphIcon(TIcon.tasks, size: 56),
            ),
            const SizedBox(height: 12),
            Text(text,
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

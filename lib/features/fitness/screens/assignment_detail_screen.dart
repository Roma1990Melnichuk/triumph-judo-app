import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/fitness_assignment_model.dart';
import '../../../core/models/fitness_log_model.dart';
import '../providers/fitness_provider.dart';
import '../providers/fitness_assignment_provider.dart';
import '../../../shared/widgets/triumph_icon.dart';

final _dateFmt = DateFormat('dd.MM.yy');
final _shortFmt = DateFormat('dd.MM');

class AssignmentDetailScreen extends ConsumerWidget {
  const AssignmentDetailScreen({
    super.key,
    required this.assignmentId,
    required this.childId,
  });

  final String assignmentId;
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignment = ref.watch(assignmentByIdProvider(assignmentId));
    final logsAsync = ref.watch(childFitnessLogsProvider(childId));
    final logs = logsAsync.value ?? [];

    if (assignment == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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
                    const Text('Завдання', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text('Завдання не знайдено',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Filter logs for this assignment
    final assignmentLogs = logs
        .where((l) =>
            l.exerciseId == assignment.exerciseId &&
            l.childId == childId &&
            !l.date.isBefore(assignment.startDate) &&
            !l.date.isAfter(assignment.deadline))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final totalProgress = assignmentLogs.isEmpty
        ? 0.0
        : assignment.isCumulative
            ? assignmentLogs.fold<double>(0.0, (acc, l) => acc + l.value)
            : assignmentLogs.map((l) => l.value).reduce(max);
    final target = assignment.targetValue;
    final pct = target > 0 ? (totalProgress / target).clamp(0.0, 1.0) : 0.0;
    final pctInt = (pct * 100).round();

    final now = DateTime.now();
    final daysLeft = assignment.deadline.difference(now).inDays;
    final totalDays = assignment.deadline
        .difference(assignment.startDate)
        .inDays
        .clamp(1, 99999);
    final daysElapsed = now.difference(assignment.startDate).inDays.clamp(0, totalDays);
    final expectedPct = daysElapsed / totalDays;
    final diffPct = pct - expectedPct;
    final fmtVal = (double v) => v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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
                    child: Text(
                      assignment.exerciseName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showOptions(context, ref, assignment),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.more_vert, size: 22, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
        children: [
          // ── Hero card ───────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.heroCardGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignment.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${fmtVal(target)} ${assignment.exerciseUnit} · '
                                  '${_dateFmt.format(assignment.startDate)} – ${_dateFmt.format(assignment.deadline)}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  assignment.isCumulative ? 'СУМА' : 'РЕКОРД',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _CircularPct(pct: pct, pctInt: pctInt),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${fmtVal(totalProgress)} / ${fmtVal(target)} ${assignment.exerciseUnit}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // ── Chart ───────────────────────────────────────────────────────
          if (assignmentLogs.isNotEmpty)
            _ProgressChart(
              logs: assignmentLogs,
              assignment: assignment,
              totalProgress: totalProgress,
            ),

          // ── Stats row ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                    child: _StatCard(
                  label: assignment.isCumulative ? 'Поточний прогрес' : 'Найкращий результат',
                  value: '${fmtVal(totalProgress)}',
                  unit: assignment.exerciseUnit,
                  color: AppColors.primary,
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatCard(
                  label: 'Залишилось',
                  value: '${daysLeft.clamp(0, 9999)}',
                  unit: 'днів',
                  color: daysLeft <= 3 ? AppColors.error : AppColors.accent,
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatCard(
                  label: diffPct >= 0
                      ? 'Випереджає план'
                      : 'Відстає від плану',
                  value: '${(diffPct.abs() * 100).round()}%',
                  unit: '',
                  color: diffPct >= 0 ? AppColors.success : AppColors.error,
                )),
              ],
            ),
          ),

          // ── Coach comment ────────────────────────────────────────────────
          if (assignment.coachComment.isNotEmpty)
            _CoachComment(comment: assignment.coachComment),

          // ── History ─────────────────────────────────────────────────────
          if (assignmentLogs.isNotEmpty)
            _HistorySection(
              logs: assignmentLogs.reversed.toList(),
              unit: assignment.exerciseUnit,
            ),
        ],
      ),
    ),
  ],
),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          '/my-assignments/$assignmentId/add-result',
          extra: {
            'childId': childId,
            'exerciseName': assignment.exerciseName,
            'exerciseUnit': assignment.exerciseUnit,
            'exerciseId': assignment.exerciseId,
          },
        ),
        backgroundColor: AppColors.primary,
        icon: const ColorFiltered(colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn), child: TriumphIcon(TIcon.add, size: 24)),
        label: const Text('Додати результат',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showOptions(
    BuildContext context,
    WidgetRef ref,
    FitnessAssignment assignment,
  ) {
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
              leading: const Icon(Icons.info_outline,
                  color: AppColors.textSecondary),
              title: Text(assignment.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${assignment.exerciseName} · ${assignment.exerciseUnit}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            const Divider(color: AppColors.surface3),
            ListTile(
              leading: const Icon(Icons.add_circle_outline,
                  color: AppColors.primary),
              title: const Text('Додати результат'),
              onTap: () {
                Navigator.pop(sheetCtx);
                context.push(
                  '/my-assignments/$assignmentId/add-result',
                  extra: {
                    'childId': childId,
                    'exerciseName': assignment.exerciseName,
                    'exerciseUnit': assignment.exerciseUnit,
                    'exerciseId': assignment.exerciseId,
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined,
                  color: AppColors.textSecondary),
              title: const Text('Поділитись прогресом'),
              onTap: () {
                Navigator.pop(sheetCtx);
                final pct = assignment.targetValue > 0
                    ? (assignmentLogs(ref, assignment) /
                            assignment.targetValue *
                            100)
                        .round()
                    : 0;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      '${assignment.title}: $pct% виконано'),
                  backgroundColor: AppColors.surface2,
                ));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  double assignmentLogs(WidgetRef ref, FitnessAssignment assignment) {
    final logs = ref.read(childFitnessLogsProvider(childId)).value ?? [];
    final relevant = logs
        .where((l) =>
            l.exerciseId == assignment.exerciseId &&
            l.childId == childId &&
            !l.date.isBefore(assignment.startDate) &&
            !l.date.isAfter(assignment.deadline))
        .toList();
    if (relevant.isEmpty) return 0.0;
    if (assignment.isCumulative) {
      return relevant.fold(0.0, (acc, l) => acc + l.value);
    } else {
      return relevant.map((l) => l.value).reduce(max);
    }
  }
}

// ── Circular % ────────────────────────────────────────────────────────────────

class _CircularPct extends StatelessWidget {
  const _CircularPct({required this.pct, required this.pctInt});
  final double pct;
  final int pctInt;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: pct,
              strokeWidth: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
            Text(
              '$pctInt%',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
}

// ── Progress chart ────────────────────────────────────────────────────────────

class _ProgressChart extends StatelessWidget {
  const _ProgressChart({
    required this.logs,
    required this.assignment,
    required this.totalProgress,
  });

  final List<FitnessLog> logs;
  final FitnessAssignment assignment;
  final double totalProgress;

  @override
  Widget build(BuildContext context) {
    final start = assignment.startDate;
    final end = assignment.deadline;
    final totalDays = end.difference(start).inDays.clamp(1, 99999);

    // Build progress points — cumulative sum or individual peak values
    final progressSpots = <FlSpot>[];
    final peakValue = logs.map((l) => l.value).reduce(max);
    if (assignment.isCumulative) {
      double cumulative = 0;
      for (final log in logs) {
        cumulative += log.value;
        final dayX = log.date.difference(start).inDays.toDouble().clamp(0.0, totalDays.toDouble());
        progressSpots.add(FlSpot(dayX, cumulative));
      }
    } else {
      for (final log in logs) {
        final dayX = log.date.difference(start).inDays.toDouble().clamp(0.0, totalDays.toDouble());
        progressSpots.add(FlSpot(dayX, log.value));
      }
    }

    // Target line
    final targetSpots = assignment.isCumulative
        ? [const FlSpot(0, 0), FlSpot(totalDays.toDouble(), assignment.targetValue)]
        : [FlSpot(0, assignment.targetValue), FlSpot(totalDays.toDouble(), assignment.targetValue)];

    final maxY = max(assignment.targetValue, totalProgress) * 1.1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Прогрес',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _LegendDot(color: AppColors.primary, label: 'Прогрес'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.accent, label: 'Ціль'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.surface3,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (val, _) => Text(
                        _fmtAxis(val),
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (val, _) {
                        final date = start
                            .add(Duration(days: val.round()));
                        return Text(
                          _shortFmt.format(date),
                          style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary),
                        );
                      },
                      interval: (totalDays / 4).ceilToDouble(),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: totalDays.toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  // Actual progress
                  LineChartBarData(
                    spots: progressSpots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: !assignment.isCumulative,
                      getDotPainter: (spot, _, __, ___) {
                        final isPeak = spot.y == peakValue;
                        return FlDotCirclePainter(
                          radius: isPeak ? 5.5 : 3,
                          color: isPeak ? AppColors.goldMedal : AppColors.primary,
                          strokeWidth: isPeak ? 2 : 1.5,
                          strokeColor: AppColors.background,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  // Target line
                  LineChartBarData(
                    spots: targetSpots,
                    isCurved: false,
                    color: AppColors.accent,
                    barWidth: 1.5,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtAxis(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toInt().toString();
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      );
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label,
      required this.value,
      required this.unit,
      required this.color});

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surface3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  height: 1.3),
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (unit.isNotEmpty)
              Text(unit,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
      );
}

// ── Coach comment ─────────────────────────────────────────────────────────────

class _CoachComment extends StatelessWidget {
  const _CoachComment({required this.comment});
  final String comment;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Коментар тренера',
                style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                comment,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      );
}

// ── History section ───────────────────────────────────────────────────────────

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.logs, required this.unit});
  final List<FitnessLog> logs;
  final String unit;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Історія результатів',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            ...logs.map((log) => _LogRow(log: log, unit: unit)),
          ],
        ),
      );
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.log, required this.unit});
  final FitnessLog log;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final diff = FitnessDifficultyX.fromInt(log.difficulty);
    final diffColor = diff == FitnessdifficultY.easy
        ? AppColors.success
        : diff == FitnessdifficultY.medium
            ? AppColors.accent
            : AppColors.primary;

    final fmtVal = log.value == log.value.truncateToDouble()
        ? log.value.toInt().toString()
        : log.value.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface3),
      ),
      child: Row(
        children: [
          Text(
            _dateFmt.format(log.date),
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(width: 12),
          Text(
            '$fmtVal $unit',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: diffColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              diff.label,
              style: TextStyle(
                  color: diffColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ),
          if (log.comment.isNotEmpty) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: log.comment,
              child: const Icon(Icons.chat_bubble_outline,
                  size: 14, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

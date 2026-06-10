import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';

import '../../../core/models/fitness_assignment_model.dart';
import '../../../core/models/fitness_log_model.dart';
import '../../team/providers/children_provider.dart';
import '../providers/fitness_assignment_provider.dart';
import '../../../shared/widgets/triumph_icon.dart';

final _shortFmt = DateFormat('dd.MM');
final _fullFmt = DateFormat('dd.MM.yyyy');

// ── Status categories ─────────────────────────────────────────────────────────

enum _AthleteStatus { onTrack, onWay, lagging, notStarted }


_AthleteStatus _statusFromPct(double pct) {
  if (pct >= 0.8) return _AthleteStatus.onTrack;
  if (pct >= 0.5) return _AthleteStatus.onWay;
  if (pct > 0) return _AthleteStatus.lagging;
  return _AthleteStatus.notStarted;
}

// ── Group status ──────────────────────────────────────────────────────────────

enum _GroupStatus { onPlan, risk, failing }

_GroupStatus _groupStatus(double avgPct, double expectedPct, int laggingCount, int total) {
  final diff = avgPct - expectedPct;
  final laggingRatio = total > 0 ? laggingCount / total : 0.0;
  if (diff < -0.2 || laggingRatio > 0.4) return _GroupStatus.failing;
  if (diff < -0.1) return _GroupStatus.risk;
  return _GroupStatus.onPlan;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AssignmentGroupProgressScreen extends ConsumerWidget {
  const AssignmentGroupProgressScreen({
    super.key,
    required this.assignmentId,
  });

  final String assignmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignment = ref.watch(assignmentByIdProvider(assignmentId));
    final logsAsync = ref.watch(assignmentLogsProvider(assignmentId));
    final childrenAsync = ref.watch(allChildrenProvider);

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
                    const Text('Прогрес групи', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
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

    final logs = logsAsync.value ?? [];
    final children = childrenAsync.value ?? [];
    final assignedChildren = children
        .where((c) => assignment.assignedChildIds.contains(c.id))
        .toList();

    // Per-athlete progress — FIT-01 Fix: Use centralized helper for Peak/Cumulative logic
    final Map<String, double> athleteProgress = {};
    for (final childId in assignment.assignedChildIds) {
      athleteProgress[childId] = assignmentProgress(logs, assignment, childId);
    }

    final target = assignment.targetValue;
    final totalAthletes = assignedChildren.length;

    final now = DateTime.now();
    final totalDays = assignment.deadline
        .difference(assignment.startDate)
        .inDays
        .clamp(1, 99999);
    final daysElapsed =
        now.difference(assignment.startDate).inDays.clamp(0, totalDays);
    final expectedPct = daysElapsed / totalDays;

    // Group stats
    final List<double> pcts = assignedChildren
        .map((c) =>
            target > 0 ? (athleteProgress[c.id] ?? 0) / target : 0.0)
        .toList();
    final avgPct = pcts.isEmpty ? 0.0 : pcts.reduce((a, b) => a + b) / pcts.length;

    int onTrack = 0, onWay = 0, lagging = 0, notStarted = 0;
    for (final p in pcts) {
      switch (_statusFromPct(p)) {
        case _AthleteStatus.onTrack:
          onTrack++;
        case _AthleteStatus.onWay:
          onWay++;
        case _AthleteStatus.lagging:
          lagging++;
        case _AthleteStatus.notStarted:
          notStarted++;
      }
    }

    final gStatus = _groupStatus(avgPct, expectedPct, lagging + notStarted, totalAthletes);

    // Daily rate needed to meet target
    final daysLeft = assignment.deadline.difference(now).inDays.clamp(0, 99999);
    final avgProgress = pcts.isEmpty
        ? 0.0
        : assignedChildren
                .map((c) => athleteProgress[c.id] ?? 0.0)
                .reduce((a, b) => a + b) /
            assignedChildren.length;
    final remaining = target - avgProgress;
    final dailyRate =
        daysElapsed > 0 ? avgProgress / daysElapsed : 0.0;
    final requiredRate = daysLeft > 0 ? remaining / daysLeft : 0.0;
    final forecastCompletion = dailyRate > 0
        ? (remaining / dailyRate).round()
        : -1;

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
                  const Text(
                    'Прогрес групи',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ── Assignment card ─────────────────────────────────────────────
          _AssignmentSummaryCard(
            assignment: assignment,
            avgPct: avgPct,
            gStatus: gStatus,
          ),

          // ── Group summary ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _GroupSummaryCard(
              onTrack: onTrack,
              onWay: onWay,
              lagging: lagging,
              notStarted: notStarted,
              total: totalAthletes,
            ),
          ),

          // ── Chart ───────────────────────────────────────────────────────
          if (logs.isNotEmpty)
            _GroupProgressChart(
              logs: logs,
              assignment: assignment,
              assignedIds: assignment.assignedChildIds,
              avgProgress: avgProgress,
            ),

          // ── Analytics card ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _AnalyticsCard(
              avgPct: avgPct,
              expectedPct: expectedPct,
              dailyRate: dailyRate,
              requiredRate: requiredRate,
              forecastDays: forecastCompletion,
              unit: assignment.exerciseUnit,
              gStatus: gStatus,
            ),
          ),

          // ── Group lagging warning ────────────────────────────────────────
          if (gStatus == _GroupStatus.failing)
            _LaggingWarning(
              laggingCount: lagging + notStarted,
              noActivity: dailyRate == 0,
              requiredRateIncrease: dailyRate > 0
                  ? ((requiredRate - dailyRate) / dailyRate * 100)
                      .round()
                      .clamp(1, 999)
                  : 0,
            ),

          // ── Actions ─────────────────────────────────────────────────────
          if (gStatus != _GroupStatus.onPlan)
            _CoachActionsCard(
              assignment: assignment,
              ref: ref,
              context: context,
            ),

          // ── View athletes button ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.push('/assignments/$assignmentId/athletes'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.people_outline),
              label: const Text('Переглянути спортсменів'),
            ),
          ),
        ],
      ),
    ),
  ],
),
      ),
    );
  }
}

// ── Assignment summary card ───────────────────────────────────────────────────

class _AssignmentSummaryCard extends StatelessWidget {
  const _AssignmentSummaryCard({
    required this.assignment,
    required this.avgPct,
    required this.gStatus,
  });

  final FitnessAssignment assignment;
  final double avgPct;
  final _GroupStatus gStatus;

  Color get _statusColor {
    switch (gStatus) {
      case _GroupStatus.onPlan:
        return AppColors.success;
      case _GroupStatus.risk:
        return AppColors.accent;
      case _GroupStatus.failing:
        return AppColors.primary;
    }
  }

  String get _statusLabel {
    switch (gStatus) {
      case _GroupStatus.onPlan:
        return 'Виконує план';
      case _GroupStatus.risk:
        return 'Ризик невиконання';
      case _GroupStatus.failing:
        return 'Не справляється';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pctInt = (avgPct * 100).round();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.heroCardGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            assignment.title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${_fullFmt.format(assignment.startDate)} – ${_fullFmt.format(assignment.deadline)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$pctInt%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold),
                    ),
                    const Text('Середній прогрес групи',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: _statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: avgPct,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(_statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Group summary card ────────────────────────────────────────────────────────

class _GroupSummaryCard extends StatelessWidget {
  const _GroupSummaryCard({
    required this.onTrack,
    required this.onWay,
    required this.lagging,
    required this.notStarted,
    required this.total,
  });

  final int onTrack, onWay, lagging, notStarted, total;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surface3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Зведення групи · $total спортсменів',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _SummaryCell(
                        count: onTrack,
                        label: 'Виконують план (>80%)',
                        color: AppColors.success)),
                Expanded(
                    child: _SummaryCell(
                        count: onWay,
                        label: 'На шляху до цілі (50–79%)',
                        color: AppColors.accent)),
                Expanded(
                    child: _SummaryCell(
                        count: lagging,
                        label: 'Відстають (1–49%)',
                        color: AppColors.warning)),
                Expanded(
                    child: _SummaryCell(
                        count: notStarted,
                        label: 'Не почали (0%)',
                        color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      );
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell(
      {required this.count, required this.label, required this.color});
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 9, height: 1.3),
          ),
        ],
      );
}

// ── Group progress chart ──────────────────────────────────────────────────────

class _GroupProgressChart extends StatelessWidget {
  const _GroupProgressChart({
    required this.logs,
    required this.assignment,
    required this.assignedIds,
    required this.avgProgress,
  });

  final List<FitnessLog> logs;
  final FitnessAssignment assignment;
  final List<String> assignedIds;
  final double avgProgress;

  @override
  Widget build(BuildContext context) {
    final start = assignment.startDate;
    final end = assignment.deadline;
    final totalDays = end.difference(start).inDays.clamp(1, 99999);
    final athleteCount = assignedIds.length.clamp(1, 99999);

    // Build daily cumulative average
    final dailyTotals = <int, double>{};
    for (final log in logs) {
      final day = log.date.difference(start).inDays.clamp(0, totalDays);
      dailyTotals[day] = (dailyTotals[day] ?? 0) + log.value;
    }

    double cumulative = 0;
    final progressSpots = <FlSpot>[];
    for (int i = 0; i <= totalDays; i++) {
      cumulative += (dailyTotals[i] ?? 0) / athleteCount;
      if (dailyTotals[i] != null || i == 0 || i == totalDays) {
        progressSpots.add(FlSpot(i.toDouble(), cumulative));
      }
    }

    final targetSpots = [
      const FlSpot(0, 0),
      FlSpot(totalDays.toDouble(), assignment.targetValue),
    ];

    final maxY = max(assignment.targetValue, avgProgress) * 1.1;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Прогрес групи',
              style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            children: [
              _LegendDot(
                  color: AppColors.primary, label: 'Фактичний прогрес'),
              const SizedBox(width: 16),
              _LegendDot(
                  color: AppColors.accent, label: 'Цільовий прогрес'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AppColors.surface3, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (val, _) {
                        final date = start.add(Duration(days: val.round()));
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
                  LineChartBarData(
                    spots: progressSpots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                  ),
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
                  color: AppColors.textSecondary, fontSize: 10)),
        ],
      );
}

// ── Analytics card ────────────────────────────────────────────────────────────

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.avgPct,
    required this.expectedPct,
    required this.dailyRate,
    required this.requiredRate,
    required this.forecastDays,
    required this.unit,
    required this.gStatus,
  });

  final double avgPct, expectedPct, dailyRate, requiredRate;
  final int forecastDays;
  final String unit;
  final _GroupStatus gStatus;

  String get _forecastLabel {
    if (forecastDays < 0) return 'Недостатньо даних';
    if (forecastDays == 0) return 'Виконано ✅';
    if (forecastDays > 365) return '> 1 року при такому темпі';
    return 'Ще $forecastDays ${_dayWord(forecastDays)}';
  }

  @override
  Widget build(BuildContext context) {
    final pctDiff = ((avgPct - expectedPct) * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Аналітика',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          _AnalyticsRow(
            label: 'Середній прогрес групи',
            value: '${(avgPct * 100).round()}%',
            color: AppColors.textPrimary,
          ),
          _AnalyticsRow(
            label: 'Поточний темп (на день)',
            value:
                '${dailyRate.toStringAsFixed(1)} $unit',
            color: AppColors.textPrimary,
          ),
          _AnalyticsRow(
            label: 'Необхідний темп для цілі',
            value:
                '${requiredRate.toStringAsFixed(1)} $unit',
            color: requiredRate > dailyRate * 1.3
                ? AppColors.primary
                : AppColors.textPrimary,
          ),
          _AnalyticsRow(
            label: 'Прогноз виконання',
            value: _forecastLabel,
            color: forecastDays < 0
                ? AppColors.textSecondary
                : forecastDays == 0
                    ? AppColors.success
                    : AppColors.accent,
          ),
          const Divider(color: AppColors.surface3, height: 20),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: gStatus == _GroupStatus.onPlan
                      ? AppColors.success
                      : gStatus == _GroupStatus.risk
                          ? AppColors.accent
                          : AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                gStatus == _GroupStatus.onPlan
                    ? 'Статус: Виконує план'
                    : gStatus == _GroupStatus.risk
                        ? 'Статус: Ризик невиконання'
                        : 'Статус: Не виконує план',
                style: TextStyle(
                  color: gStatus == _GroupStatus.onPlan
                      ? AppColors.success
                      : gStatus == _GroupStatus.risk
                          ? AppColors.accent
                          : AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              if (pctDiff != 0)
                Text(
                  pctDiff > 0 ? '+$pctDiff%' : '$pctDiff%',
                  style: TextStyle(
                    color: pctDiff > 0 ? AppColors.success : AppColors.primary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  const _AnalyticsRow(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      );
}

// ── Lagging warning ───────────────────────────────────────────────────────────

class _LaggingWarning extends StatelessWidget {
  const _LaggingWarning({
    required this.laggingCount,
    required this.requiredRateIncrease,
    required this.noActivity,
  });
  final int laggingCount;
  final int requiredRateIncrease;
  final bool noActivity;

  @override
  Widget build(BuildContext context) {
    final message = noActivity
        ? 'Група ще не розпочала виконання завдання. '
            'Нагадайте спортсменам про завдання.'
        : 'Група відстає від плану. Для досягнення цілі необхідно '
            'збільшити темп виконання на $requiredRateIncrease%.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_outlined,
                color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    color: AppColors.primary, fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coach actions card ────────────────────────────────────────────────────────

class _CoachActionsCard extends StatelessWidget {
  const _CoachActionsCard({
    required this.assignment,
    required this.ref,
    required this.context,
  });

  final FitnessAssignment assignment;
  final WidgetRef ref;
  final BuildContext context;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
              const Text('Дії тренера',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.campaign_outlined,
                label: 'Підбодрити групу',
                subtitle:
                    'Надіслати повідомлення всім учасникам',
                color: AppColors.success,
                onTap: () =>
                    _sendNotification(context, toAll: true),
              ),
              _ActionTile(
                icon: Icons.person_search_outlined,
                label: 'Написати відстаючим',
                subtitle:
                    'Повідомлення тільки спортсменам зі статусом "Відстає"',
                color: AppColors.accent,
                onTap: () =>
                    _sendNotification(context, toAll: false),
              ),
              _ActionTile(
                icon: Icons.edit_outlined,
                label: 'Скоригувати ціль',
                subtitle: 'Змінити цільове значення або термін',
                color: AppColors.info,
                onTap: () => _editGoal(context),
              ),
              _ActionTile(
                icon: Icons.stop_circle_outlined,
                label: 'Завершити завдання достроково',
                subtitle: 'Закрити активне завдання',
                color: AppColors.primary,
                onTap: () => _completeEarly(context),
                isDestructive: true,
              ),
            ],
          ),
        ),
      );

  void _sendNotification(BuildContext ctx, {required bool toAll}) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(toAll
          ? 'Повідомлення надіслано всій групі'
          : 'Повідомлення надіслано відстаючим'),
      backgroundColor: AppColors.success,
    ));
  }

  void _editGoal(BuildContext ctx) {
    showDialog<void>(
      context: ctx,
      builder: (dialogCtx) => _EditGoalDialog(assignment: assignment, ref: ref),
    );
  }

  void _completeEarly(BuildContext ctx) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Завершити завдання?'),
        content: const Text(
            'Завдання буде позначено як завершене для всіх спортсменів.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Скасувати')),
          TextButton(
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Завершити'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(assignmentNotifierProvider.notifier)
          .completeAssignment(assignment.id);
      if (ctx.mounted) ctx.pop();
    }
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDestructive
                                ? AppColors.primary
                                : AppColors.textPrimary)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 18),
            ],
          ),
        ),
      );
}

// ── Edit goal dialog ──────────────────────────────────────────────────────────

class _EditGoalDialog extends StatefulWidget {
  const _EditGoalDialog({required this.assignment, required this.ref});
  final FitnessAssignment assignment;
  final WidgetRef ref;

  @override
  State<_EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<_EditGoalDialog> {
  late TextEditingController _valueCtrl;
  late DateTime _deadline;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _valueCtrl = TextEditingController(
        text: widget.assignment.targetValue.toInt().toString());
    _deadline = widget.assignment.deadline;
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Скоригувати ціль'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _valueCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Нова ціль',
                suffixText: widget.assignment.exerciseUnit,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _deadline,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now()
                      .add(const Duration(days: 365 * 2)),
                );
                if (picked != null) setState(() => _deadline = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Новий дедлайн'),
                child: Text(
                    '${_deadline.day}.${_deadline.month}.${_deadline.year}'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Скасувати')),
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    final v = double.tryParse(
                        _valueCtrl.text.trim().replaceAll(',', '.'));
                    if (v == null || v <= 0) return;
                    setState(() => _saving = true);
                    await widget.ref
                        .read(assignmentNotifierProvider.notifier)
                        .updateAssignment(
                          widget.assignment.id,
                          targetValue: v,
                          deadline: _deadline,
                        );
                    if (context.mounted) Navigator.pop(context);
                  },
            child: const Text('Зберегти'),
          ),
        ],
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _dayWord(int n) {
  if (n % 10 == 1 && n % 100 != 11) return 'день';
  if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
    return 'дні';
  }
  return 'днів';
}

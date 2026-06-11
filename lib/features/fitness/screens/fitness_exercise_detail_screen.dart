import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/fitness_goal_model.dart';
import '../../../core/models/fitness_log_model.dart';
import '../../../shared/widgets/triumph_icon.dart';
import '../providers/fitness_provider.dart';

final _dateFmt = DateFormat('dd.MM.yyyy');
final _shortFmt = DateFormat('dd.MM');

class FitnessExerciseDetailScreen extends ConsumerWidget {
  const FitnessExerciseDetailScreen({
    super.key,
    required this.childId,
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseUnit,
  });

  final String childId;
  final String exerciseId;
  final String exerciseName;
  final String exerciseUnit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (childId: childId, exerciseId: exerciseId);
    final logs = ref.watch(exerciseLogsProvider(key)); // asc by date
    final goalAsync = ref.watch(exerciseGoalProvider(key));
    final goal = goalAsync.asData?.value;

    final best = logs.isEmpty
        ? null
        : logs.map((l) => l.value).reduce(max);
    final latest = logs.isNotEmpty ? logs.last : null;
    final prev = logs.length > 1 ? logs[logs.length - 2] : null;
    final delta = (latest != null && prev != null)
        ? latest.value - prev.value
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
                      exerciseName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showGoalDialog(context, ref, goal),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.flag_outlined, size: 22, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: logs.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(AppColors.textSecondary.withValues(alpha: 0.4), BlendMode.srcIn),
                    child: const TriumphIcon(TIcon.training, size: 56),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ще немає записів',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Натисніть + щоб додати перший результат',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 90),
              children: [
                // ── Stats row ────────────────────────────────────────────
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 14),
                  child: Row(
                    children: [
                      _StatCell(
                        label: 'Найкращий',
                        value:
                            best != null ? '${_fmt(best)} $exerciseUnit' : '—',
                        tIcon: TIcon.trophy,
                        color: AppColors.goldMedal,
                      ),
                      _divider(),
                      _StatCell(
                        label: 'Останній',
                        value: latest != null
                            ? '${_fmt(latest.value)} $exerciseUnit'
                            : '—',
                        icon: Icons.access_time,
                        color: AppColors.primary,
                      ),
                      _divider(),
                      _StatCell(
                        label: 'Приріст',
                        value: delta != null
                            ? '${delta >= 0 ? '+' : ''}${_fmt(delta)}'
                            : '—',
                        icon: delta == null
                            ? Icons.trending_flat
                            : delta > 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                        color: delta == null
                            ? AppColors.textSecondary
                            : delta > 0
                                ? AppColors.success
                                : AppColors.error,
                      ),
                    ],
                  ),
                ),

                // ── Goal card ─────────────────────────────────────────────
                if (goal != null) ...[
                  _GoalCard(
                    goal: goal,
                    latest: latest?.value,
                    unit: exerciseUnit,
                    onDelete: () => ref
                        .read(fitnessNotifierProvider.notifier)
                        .deleteGoal(childId, exerciseId),
                  ),
                ],

                // ── Chart ─────────────────────────────────────────────────
                if (logs.length >= 2) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(
                      'Прогрес',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textSecondary
                            .withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  _ProgressChart(
                    logs: logs,
                    goal: goal,
                    unit: exerciseUnit,
                    peakValue: best,
                  ),
                ],

                // ── History list ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    'Записи (${logs.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color:
                          AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                ...logs.reversed.map((log) => _LogTile(
                      log: log,
                      unit: exerciseUnit,
                      isBest: best != null && log.value == best,
                      onDelete: () => ref
                          .read(fitnessNotifierProvider.notifier)
                          .deleteLog(log.id),
                    )),
              ],
            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLogDialog(context, ref),
        tooltip: 'Додати результат',
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: AppColors.surface3,
      );

  void _showAddLogDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddLogSheet(
        exerciseUnit: exerciseUnit,
        onSave: ({required date, required value, required difficulty, required comment}) =>
            ref.read(fitnessNotifierProvider.notifier).addLog(
              childId: childId,
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              exerciseUnit: exerciseUnit,
              date: date,
              value: value,
              difficulty: difficulty,
              comment: comment,
            ),
      ),
    );
  }

  void _showGoalDialog(BuildContext context, WidgetRef ref, FitnessGoal? current) {
    showDialog<void>(
      context: context,
      builder: (_) => _SetGoalDialog(
        current: current,
        unit: exerciseUnit,
        onSave: (targetValue, deadline) =>
            ref.read(fitnessNotifierProvider.notifier).setGoal(
              childId: childId,
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              exerciseUnit: exerciseUnit,
              targetValue: targetValue,
              deadline: deadline,
            ),
      ),
    );
  }
}

String _fmt(double v) =>
    v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

// ── Stat cell ─────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    this.icon,
    this.tIcon,
    required this.color,
  }) : assert(icon != null || tIcon != null);

  final String label;
  final String value;
  final IconData? icon;
  final TIcon? tIcon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          if (tIcon != null)
            ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              child: TriumphIcon(tIcon!, size: 18),
            )
          else
            Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Goal card ─────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.latest,
    required this.unit,
    required this.onDelete,
  });

  final FitnessGoal goal;
  final double? latest;
  final String unit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final progress =
        latest != null ? (latest! / goal.targetValue).clamp(0.0, 1.0) : 0.0;
    final daysLeft = goal.deadline.difference(DateTime.now()).inDays;
    final deadlineStr = _dateFmt.format(goal.deadline);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: goal.isAchieved
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.accent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                goal.isAchieved ? Icons.check_circle : Icons.flag_outlined,
                size: 16,
                color: goal.isAchieved ? AppColors.success : AppColors.accent,
              ),
              const SizedBox(width: 6),
              Text(
                goal.isAchieved ? 'Ціль досягнута!' : 'Ціль',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: goal.isAchieved
                      ? AppColors.success
                      : AppColors.accent,
                ),
              ),
              const Spacer(),
              Text(
                '${_fmt(goal.targetValue)} $unit',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close,
                    size: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surface3,
              valueColor: AlwaysStoppedAnimation<Color>(
                goal.isAchieved ? AppColors.success : AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                goal.isAchieved
                    ? 'Виконано ✓'
                    : daysLeft > 0
                        ? 'до $deadlineStr ($daysLeft дн.)'
                        : 'Термін: $deadlineStr',
                style: TextStyle(
                  fontSize: 11,
                  color: daysLeft < 0 && !goal.isAchieved
                      ? AppColors.error
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Progress chart ────────────────────────────────────────────────────────────

class _ProgressChart extends StatelessWidget {
  const _ProgressChart({
    required this.logs,
    required this.goal,
    required this.unit,
    required this.peakValue,
  });

  final List<FitnessLog> logs;
  final FitnessGoal? goal;
  final String unit;
  final double? peakValue;

  @override
  Widget build(BuildContext context) {
    // Use last 30 entries
    final chartLogs =
        logs.length > 30 ? logs.sublist(logs.length - 30) : logs;
    final spots = chartLogs
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    final minY = spots.map((s) => s.y).reduce(min);
    final maxY = spots.map((s) => s.y).reduce(max);
    final range = (maxY - minY).abs();
    final paddedMin = (minY - range * 0.15).clamp(0, double.infinity);
    final paddedMax = maxY + range * 0.2;

    final goalY = goal?.targetValue;

    return SizedBox(
      height: 180,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
        child: LineChart(
          LineChartData(
            minY: paddedMin.toDouble(),
            maxY: paddedMax > paddedMin ? paddedMax : paddedMin + 1,
            clipData: const FlClipData.all(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppColors.surface3.withValues(alpha: 0.6),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.surface2,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((s) {
                    final idx = s.x.toInt();
                    if (idx < 0 || idx >= chartLogs.length) return null;
                    final log = chartLogs[idx];
                    return LineTooltipItem(
                      '${_fmt(log.value)} $unit\n${_shortFmt.format(log.date)}',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    );
                  }).toList();
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.min || value == meta.max) {
                      return Text(
                        _fmt(value),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textSecondary),
                        textAlign: TextAlign.right,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= chartLogs.length) {
                      return const SizedBox.shrink();
                    }
                    if (idx != 0 && idx != chartLogs.length - 1) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _shortFmt.format(chartLogs[idx].date),
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.textSecondary),
                      ),
                    );
                  },
                ),
              ),
            ),
            extraLinesData: goalY != null
                ? ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: goalY,
                        color: AppColors.accent.withValues(alpha: 0.7),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          labelResolver: (_) =>
                              'Ціль: ${_fmt(goalY)}',
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  )
                : null,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: AppColors.primary,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, __, ___) {
                    final isPeak = peakValue != null && spot.y == peakValue;
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
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Log tile ──────────────────────────────────────────────────────────────────

class _LogTile extends StatelessWidget {
  const _LogTile({
    required this.log,
    required this.unit,
    required this.isBest,
    required this.onDelete,
  });

  final FitnessLog log;
  final String unit;
  final bool isBest;
  final VoidCallback onDelete;

  static const _diffColors = [
    AppColors.success,
    AppColors.warning,
    AppColors.error,
  ];

  @override
  Widget build(BuildContext context) {
    final diff = FitnessDifficultyX.fromInt(log.difficulty);
    final diffColor = _diffColors[log.difficulty - 1];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBest
              ? AppColors.goldMedal.withValues(alpha: 0.4)
              : AppColors.surface3,
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: isBest
            ? const ColorFiltered(
                colorFilter: ColorFilter.mode(AppColors.goldMedal, BlendMode.srcIn),
                child: TriumphIcon(TIcon.trophy, size: 20),
              )
            : ColorFiltered(
                colorFilter: ColorFilter.mode(AppColors.textSecondary.withValues(alpha: 0.5), BlendMode.srcIn),
                child: const TriumphIcon(TIcon.training, size: 18),
              ),
        title: Row(
          children: [
            Text(
              '${_fmt(log.value)} $unit',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isBest ? AppColors.goldMedal : null,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: diffColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: diffColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                diff.label,
                style:
                    TextStyle(fontSize: 10, color: diffColor),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dateFmt.format(log.date),
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
            if (log.comment.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                log.comment,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Видалити запис?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Скасувати'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.error),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Видалити'),
                  ),
                ],
              ),
            );
            if (ok == true) onDelete();
          },
        ),
      ),
    );
  }
}

// ── Add log bottom sheet ──────────────────────────────────────────────────────

class _AddLogSheet extends StatefulWidget {
  const _AddLogSheet({required this.exerciseUnit, required this.onSave});

  final String exerciseUnit;
  final Future<void> Function({
    required DateTime date,
    required double value,
    required int difficulty,
    required String comment,
  }) onSave;

  @override
  State<_AddLogSheet> createState() => _AddLogSheetState();
}

class _AddLogSheetState extends State<_AddLogSheet> {
  final _valueCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  int _difficulty = 1;
  bool _loading = false;

  @override
  void dispose() {
    _valueCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = double.tryParse(_valueCtrl.text.replaceAll(',', '.'));
    if (raw == null || raw <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введіть коректне значення')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.onSave(
        date: _date,
        value: raw,
        difficulty: _difficulty,
        comment: _commentCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _dateFmt.format(_date);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Новий результат',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Value + unit
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _valueCtrl,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[\d,\.]')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Результат (${widget.exerciseUnit})',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date picker row
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    locale: const Locale('uk'),
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Дата',
                    suffixIcon: ColorFiltered(
                      colorFilter: const ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn),
                      child: TriumphIcon(TIcon.calendar, size: 18),
                    ),
                  ),
                  child: Text(dateStr),
                ),
              ),
              const SizedBox(height: 12),

              // Difficulty
              const Text(
                'Складність:',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Row(
                children: [1, 2, 3].map((d) {
                  final labels = ['Легко', 'Середньо', 'Важко'];
                  final colors = [
                    AppColors.success,
                    AppColors.warning,
                    AppColors.error
                  ];
                  final selected = _difficulty == d;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _difficulty = d),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? colors[d - 1].withValues(alpha: 0.18)
                              : AppColors.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? colors[d - 1]
                                : AppColors.surface3,
                          ),
                        ),
                        child: Text(
                          labels[d - 1],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selected
                                ? colors[d - 1]
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Comment
              TextField(
                controller: _commentCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Коментар (необов\'язково)',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white),
                        )
                      : const Text('Зберегти'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Set goal dialog ───────────────────────────────────────────────────────────

class _SetGoalDialog extends StatefulWidget {
  const _SetGoalDialog({
    required this.unit,
    required this.onSave,
    this.current,
  });

  final String unit;
  final FitnessGoal? current;
  final Future<void> Function(double targetValue, DateTime deadline) onSave;

  @override
  State<_SetGoalDialog> createState() => _SetGoalDialogState();
}

class _SetGoalDialogState extends State<_SetGoalDialog> {
  late final TextEditingController _valueCtrl;
  late DateTime _deadline;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _valueCtrl = TextEditingController(
      text: widget.current != null
          ? _fmt(widget.current!.targetValue)
          : '',
    );
    _deadline = widget.current?.deadline ??
        DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Поставити ціль'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _valueCtrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
            ],
            decoration:
                InputDecoration(labelText: 'Ціль (${widget.unit})'),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                locale: const Locale('uk'),
                initialDate: _deadline,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (picked != null) setState(() => _deadline = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Дедлайн',
                suffixIcon:
                    Icon(Icons.calendar_today_outlined, size: 18),
              ),
              child: Text(_dateFmt.format(_deadline)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed:
              _loading ? null : () => Navigator.pop(context),
          child: const Text('Скасувати'),
        ),
        TextButton(
          onPressed: _loading
              ? null
              : () async {
                  final raw = double.tryParse(
                      _valueCtrl.text.replaceAll(',', '.'));
                  if (raw == null || raw <= 0) return;
                  setState(() => _loading = true);
                  try {
                    await widget.onSave(raw, _deadline);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Помилка: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text(
                  'Зберегти',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }
}

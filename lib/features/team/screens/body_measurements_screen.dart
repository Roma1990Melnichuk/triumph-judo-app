import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/body_measurement_model.dart';
import '../../../core/models/child_model.dart' show ChildModel, displayWeight;
import '../providers/body_measurement_provider.dart';
import '../providers/children_provider.dart';
import '../../../shared/widgets/gradient_button.dart';

class BodyMeasurementsScreen extends ConsumerWidget {
  const BodyMeasurementsScreen({super.key, required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync      = ref.watch(childByIdProvider(childId));
    final measurements    = ref.watch(recentMeasurementsProvider(childId));
    final latest          = ref.watch(latestMeasurementProvider(childId));

    final child = childAsync.asData?.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.textPrimary, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text(child?.fullName ?? 'Вага та ріст',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.orange),
                onPressed: () => _showAddDialog(context, ref),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Weight category card ─────────────────────────────────────
                if (child != null)
                  _WeightCategoryCard(
                      child: child, latestKg: latest?.weightKg),

                // ── Latest values ────────────────────────────────────────────
                if (latest != null)
                  _LatestCard(measurement: latest),

                // ── Weight chart ─────────────────────────────────────────────
                if (measurements.isNotEmpty)
                  _WeightChart(measurements: measurements),

                // ── Height chart ─────────────────────────────────────────────
                if (measurements.any((m) => m.heightCm != null))
                  _HeightChart(measurements: measurements),

                // ── Log ──────────────────────────────────────────────────────
                if (measurements.isNotEmpty) ...[
                  _SectionHeader(title: 'Журнал вимірювань'),
                  ...measurements.reversed.map((m) =>
                      _MeasurementTile(m: m, ref: ref)),
                ] else
                  _EmptyState(onAdd: () => _showAddDialog(context, ref)),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final weightCtrl = TextEditingController();
    final heightCtrl = TextEditingController();
    DateTime date = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              const Text('Додати вимірювання',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              TextField(
                controller: weightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Вага (кг)',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                    suffixText: 'кг'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: heightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Зріст (см)',
                    prefixIcon: Icon(Icons.height_rounded),
                    suffixText: 'см'),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (_, child) => Theme(
                      data: ThemeData.dark(),
                      child: child!,
                    ),
                  );
                  if (picked != null) setModal(() => date = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2C2C2C)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18,
                          color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('d MMMM yyyy', 'uk').format(date),
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: () async {
                  final kg = double.tryParse(
                      weightCtrl.text.trim().replaceAll(',', '.'));
                  final cm = double.tryParse(
                      heightCtrl.text.trim().replaceAll(',', '.'));
                  if (kg == null && cm == null) return;
                  await ref
                      .read(bodyMeasurementNotifierProvider.notifier)
                      .addMeasurement(
                        childId:  childId,
                        date:     date,
                        weightKg: kg,
                        heightCm: cm,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Зберегти',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Weight category card ──────────────────────────────────────────────────────

class _WeightCategoryCard extends StatelessWidget {
  const _WeightCategoryCard({required this.child, this.latestKg});
  final ChildModel child;
  final double?    latestKg;

  @override
  Widget build(BuildContext context) {
    final catLabel = displayWeight(child.weightCategory);

    final diff = latestKg != null
        ? _categoryMax(child.weightCategory) - latestKg!
        : null;

    Color indicatorColor = AppColors.success;
    String diffText = '';
    if (diff != null) {
      if (diff < 0) {
        indicatorColor = AppColors.error;
        diffText = '+${(-diff).toStringAsFixed(1)} кг понад категорію';
      } else {
        indicatorColor = AppColors.success;
        diffText = 'залишилось ${diff.toStringAsFixed(1)} кг до ліміту';
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF222222)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: indicatorColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text('⚖️', style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Вагова категорія',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(catLabel,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  if (diffText.isNotEmpty)
                    Text(diffText,
                        style: TextStyle(
                            fontSize: 11, color: indicatorColor)),
                ],
              ),
            ),
            if (latestKg != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${latestKg!.toStringAsFixed(1)}',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: indicatorColor)),
                  const Text('кг',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  double _categoryMax(String cat) {
    final n = double.tryParse(cat.replaceAll(RegExp(r'[^\d.]'), ''));
    return n ?? double.infinity;
  }
}

// ── Latest values ─────────────────────────────────────────────────────────────

class _LatestCard extends StatelessWidget {
  const _LatestCard({required this.measurement});
  final BodyMeasurementModel measurement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          if (measurement.weightKg != null)
            Expanded(
              child: _StatBox(
                label: 'Остання вага',
                value: '${measurement.weightKg!.toStringAsFixed(1)} кг',
                icon: Icons.monitor_weight_outlined,
                color: AppColors.orange,
                date: measurement.measuredAt,
              ),
            ),
          if (measurement.weightKg != null && measurement.heightCm != null)
            const SizedBox(width: 10),
          if (measurement.heightCm != null)
            Expanded(
              child: _StatBox(
                label: 'Останній зріст',
                value: '${measurement.heightCm!.toStringAsFixed(0)} см',
                icon: Icons.height_rounded,
                color: const Color(0xFF4FC3F7),
                date: measurement.measuredAt,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.date,
  });

  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
          Text(DateFormat('d MMM', 'uk').format(date),
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Charts ────────────────────────────────────────────────────────────────────

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.measurements});
  final List<BodyMeasurementModel> measurements;

  @override
  Widget build(BuildContext context) {
    final pts = measurements
        .where((m) => m.weightKg != null)
        .toList();
    if (pts.isEmpty) return const SizedBox.shrink();

    final spots = List.generate(pts.length, (i) {
      return FlSpot(i.toDouble(), pts[i].weightKg!);
    });
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;

    return _ChartCard(
      title: 'Динаміка ваги',
      child: LineChart(
        LineChartData(
          minY: minY, maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= pts.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    DateFormat('d MMM', 'uk').format(pts[i].measuredAt),
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.textSecondary),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.orange,
              barWidth: 2.5,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.orange.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeightChart extends StatelessWidget {
  const _HeightChart({required this.measurements});
  final List<BodyMeasurementModel> measurements;

  @override
  Widget build(BuildContext context) {
    final pts = measurements
        .where((m) => m.heightCm != null)
        .toList();
    if (pts.isEmpty) return const SizedBox.shrink();

    final spots = List.generate(pts.length, (i) {
      return FlSpot(i.toDouble(), pts[i].heightCm!);
    });
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 3;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 3;

    return _ChartCard(
      title: 'Динаміка зросту',
      child: LineChart(
        LineChartData(
          minY: minY, maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= pts.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    DateFormat('d MMM', 'uk').format(pts[i].measuredAt),
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.textSecondary),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF4FC3F7),
              barWidth: 2.5,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color:
                    const Color(0xFF4FC3F7).withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF222222)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ),
            SizedBox(height: 140, child: child),
          ],
        ),
      ),
    );
  }
}

// ── Log tile ──────────────────────────────────────────────────────────────────

class _MeasurementTile extends ConsumerWidget {
  const _MeasurementTile({required this.m, required this.ref});
  final BodyMeasurementModel m;
  final WidgetRef            ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF222222)),
        ),
        child: Row(
          children: [
            Text(
              DateFormat('d MMM yyyy', 'uk').format(m.measuredAt),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            const Spacer(),
            if (m.weightKg != null)
              Text('${m.weightKg!.toStringAsFixed(1)} кг',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.orange)),
            if (m.weightKg != null && m.heightCm != null)
              const Text(' · ',
                  style:
                      TextStyle(color: AppColors.textSecondary)),
            if (m.heightCm != null)
              Text('${m.heightCm!.toStringAsFixed(0)} см',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF4FC3F7))),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => ref
                  .read(bodyMeasurementNotifierProvider.notifier)
                  .deleteMeasurement(m.id),
              child: const Icon(Icons.close_rounded,
                  size: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty ─────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Text('⚖️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          const Text('Вимірювань ще немає',
              style:
                  TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.4)),
              ),
              child: const Text('Додати перше вимірювання',
                  style: TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.1)),
    );
  }
}

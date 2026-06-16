import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../providers/nutrition_provider.dart';
import '../widgets/nutrition_widgets.dart';

class WaterScreen extends ConsumerWidget {
  const WaterScreen({super.key, required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dk      = todayNutritionKey;
    final key     = (childId: childId, dateKey: dk);
    final waterMl = ref.watch(dayWaterMlProvider(key));
    final logs    = ref.watch(dayWaterLogsProvider(key));
    final goal    = ref.watch(waterGoalMlProvider);
    final weekPts = ref.watch(weekNutritionProvider(childId));

    final pct    = (waterMl / goal).clamp(0.0, 1.0);
    final filled = pct >= 1.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: AppBackButton(onPressed: () => context.pop()),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0A1A2A), AppColors.background],
                    begin: Alignment.topCenter,
                    end:   Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment:  MainAxisAlignment.end,
                      children: const [
                        Text('💧 Водний режим',
                            style: TextStyle(fontSize: 24,
                                fontWeight: FontWeight.w800, color: Colors.white)),
                        Text('Стеж за гідратацією',
                            style: TextStyle(fontSize: 13,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
              title: const Text('Вода',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Big progress ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color:        AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border:       Border.all(color: const Color(0xFF222222)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              (waterMl / 1000).toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w800,
                                color: filled
                                    ? AppColors.success
                                    : const Color(0xFF4FC3F7),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Text(' / ',
                                  style: TextStyle(fontSize: 20,
                                      color: AppColors.textSecondary)),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text('${(goal / 1000).toStringAsFixed(1)} л',
                                  style: const TextStyle(fontSize: 20,
                                      color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: pct),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOut,
                          builder: (_, v, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: v,
                              minHeight: 10,
                              backgroundColor: const Color(0xFF2A2A2A),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                filled
                                    ? AppColors.success
                                    : const Color(0xFF4FC3F7),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          filled
                              ? '🎉 Ціль досягнуто!'
                              : 'Залишилось ${((goal - waterMl) / 1000).toStringAsFixed(2)} л',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                filled ? AppColors.success : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Quick add buttons ─────────────────────────────────────────
                const NutritionSectionHeader(title: 'Додати воду'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [100, 200, 300, 500].map((ml) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _WaterAddButton(
                              childId: childId, amountMl: ml),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // ── Weekly chart ──────────────────────────────────────────────
                const NutritionSectionHeader(title: 'Гідратація за тиждень'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Container(
                    height: 160,
                    padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                    decoration: BoxDecoration(
                      color:        AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border:       Border.all(color: const Color(0xFF222222)),
                    ),
                    child: BarChart(
                      BarChartData(
                        maxY: goal.toDouble(),
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
                              getTitlesWidget: (v, _) {
                                final idx = v.toInt();
                                if (idx < 0 || idx >= weekPts.length) {
                                  return const SizedBox.shrink();
                                }
                                final dk2 = weekPts[idx].dateKey;
                                final day = dk2.split('-').last;
                                return Text(day,
                                    style: const TextStyle(fontSize: 10,
                                        color: AppColors.textSecondary));
                              },
                              reservedSize: 18,
                            ),
                          ),
                        ),
                        barGroups: List.generate(weekPts.length, (i) {
                          final dayKey = weekPts[i].dateKey;
                          final nKey   = (childId: childId, dateKey: dayKey);
                          final ml     = ref.watch(dayWaterMlProvider(nKey));
                          final v      = ml.toDouble().clamp(0.0, goal.toDouble());
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: v,
                                width: 16,
                                borderRadius: BorderRadius.circular(4),
                                gradient: LinearGradient(
                                  colors: v >= goal
                                      ? [AppColors.success, AppColors.success]
                                      : [
                                          const Color(0xFF4FC3F7).withValues(alpha: 0.7),
                                          const Color(0xFF4FC3F7),
                                        ],
                                  begin: Alignment.bottomCenter,
                                  end:   Alignment.topCenter,
                                ),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: goal.toDouble(),
                                  color: const Color(0xFF222222),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),

                // ── Today's log ────────────────────────────────────────────────
                if (logs.isNotEmpty) ...[
                  const NutritionSectionHeader(title: 'Записи сьогодні'),
                  ...logs.map((log) => _WaterLogTile(log: log)),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterAddButton extends ConsumerWidget {
  const _WaterAddButton({required this.childId, required this.amountMl});
  final String childId;
  final int    amountMl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(nutritionNotifierProvider.notifier)
          .logWater(childId: childId, amountMl: amountMl),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(
              color: const Color(0xFF4FC3F7).withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Text('💧', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text('+$amountMl мл',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: Color(0xFF4FC3F7))),
          ],
        ),
      ),
    );
  }
}

class _WaterLogTile extends ConsumerWidget {
  const _WaterLogTile({required this.log});
  final dynamic log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = log.loggedAt as DateTime;
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return NutritionCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Text('💧', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text('+${log.amountMl} мл',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: Color(0xFF4FC3F7))),
          const Spacer(),
          Text(timeStr,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ref.read(nutritionNotifierProvider.notifier)
                .deleteWaterLog(log.id as String),
            child: const Icon(Icons.close_rounded, size: 16,
                color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

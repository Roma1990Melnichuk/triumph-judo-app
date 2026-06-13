import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/nutrition_provider.dart';
import '../widgets/nutrition_widgets.dart';

class NutritionStatsScreen extends ConsumerWidget {
  const NutritionStatsScreen({super.key, required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dk      = todayNutritionKey;
    final todayKey = (childId: childId, dateKey: dk);
    final todayScore  = ref.watch(nutritionScoreProvider(todayKey));
    final todayWater  = ref.watch(dayWaterMlProvider(todayKey));
    final todayMeals  = ref.watch(dayMealsProvider(todayKey));
    final weekPts     = ref.watch(weekNutritionProvider(childId));

    final avgScore = weekPts.isEmpty
        ? 0.0
        : weekPts.map((p) => p.score).reduce((a, b) => a + b) / weekPts.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.textPrimary, size: 20),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1400), AppColors.background],
                    begin: Alignment.topCenter,
                    end:   Alignment.bottomCenter,
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment:  MainAxisAlignment.end,
                      children: [
                        Text('📊 Статистика харчування',
                            style: TextStyle(fontSize: 22,
                                fontWeight: FontWeight.w800, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
              title: const Text('Статистика',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Today summary ─────────────────────────────────────────────
                const NutritionSectionHeader(title: 'Сьогодні'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(child: _StatCard(
                          label: 'Індекс дня',
                          value: '${todayScore.round()}',
                          unit:  '/ 100',
                          color: AppColors.orange)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(
                          label: 'Вода',
                          value: (todayWater / 1000).toStringAsFixed(2),
                          unit:  'л',
                          color: const Color(0xFF4FC3F7))),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(
                          label: 'Прийоми',
                          value: '${todayMeals.length}',
                          unit:  'запис.',
                          color: AppColors.success)),
                    ],
                  ),
                ),

                // ── Week avg ──────────────────────────────────────────────────
                const NutritionSectionHeader(title: 'Середнє за тиждень'),
                NutritionCard(
                  child: Row(
                    children: [
                      NutritionScoreGauge(
                          score: avgScore, size: 80, strokeWidth: 8,
                          child: Text('${avgScore.round()}',
                              style: const TextStyle(fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary))),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Середній Nutrition Score',
                                style: TextStyle(fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text(
                              avgScore >= 75
                                  ? 'Відмінний результат! 🏆'
                                  : avgScore >= 50
                                      ? 'Хороший прогрес 👍'
                                      : 'Є що покращити 💪',
                              style: const TextStyle(fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Week chart ────────────────────────────────────────────────
                const NutritionSectionHeader(title: 'Динаміка за 7 днів'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 180,
                    padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                    decoration: BoxDecoration(
                      color:        AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border:       Border.all(color: const Color(0xFF222222)),
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          getDrawingHorizontalLine: (_) => const FlLine(
                              color: Color(0xFF2A2A2A), strokeWidth: 1),
                          getDrawingVerticalLine: (_) => const FlLine(
                              color: Colors.transparent),
                        ),
                        borderData: FlBorderData(show: false),
                        minY: 0,
                        maxY: 100,
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: 25,
                              getTitlesWidget: (v, _) => Text(
                                  v.toInt().toString(),
                                  style: const TextStyle(fontSize: 9,
                                      color: AppColors.textSecondary)),
                            ),
                          ),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 18,
                              getTitlesWidget: (v, _) {
                                final i = v.toInt();
                                if (i < 0 || i >= weekPts.length) {
                                  return const SizedBox.shrink();
                                }
                                final day = weekPts[i].dateKey.split('-').last;
                                return Text(day,
                                    style: const TextStyle(fontSize: 9,
                                        color: AppColors.textSecondary));
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: weekPts.asMap().entries.map((e) =>
                                FlSpot(e.key.toDouble(), e.value.score)).toList(),
                            isCurved: true,
                            color: AppColors.orange,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.orange.withValues(alpha: 0.25),
                                  AppColors.orange.withValues(alpha: 0.0),
                                ],
                                begin: Alignment.topCenter,
                                end:   Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Formula breakdown ─────────────────────────────────────────
                const NutritionSectionHeader(title: 'Як рахується індекс'),
                NutritionCard(
                  child: Column(
                    children: const [
                      _FormulaRow(pct: '40%', label: 'Якість тарілки',
                          desc: 'Білок, овочі, вуглеводи, фрукти, вода'),
                      Divider(height: 16, color: Color(0xFF2A2A2A)),
                      _FormulaRow(pct: '30%', label: 'Водний режим',
                          desc: 'Факт / ціль 1.5 л'),
                      Divider(height: 16, color: Color(0xFF2A2A2A)),
                      _FormulaRow(pct: '20%', label: 'Регулярність',
                          desc: 'Сніданок + обід + вечеря'),
                      Divider(height: 16, color: Color(0xFF2A2A2A)),
                      _FormulaRow(pct: '10%', label: 'Рекомендації',
                          desc: 'Прочитані поради тренера'),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                      color: color)),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(unit,
                    style: const TextStyle(fontSize: 10,
                        color: AppColors.textSecondary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormulaRow extends StatelessWidget {
  const _FormulaRow({
    required this.pct,
    required this.label,
    required this.desc,
  });

  final String pct;
  final String label;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:        AppColors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(pct,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.orange)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text(desc,
                  style: const TextStyle(fontSize: 11,
                      color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

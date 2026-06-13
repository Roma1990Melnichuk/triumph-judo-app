import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/nutrition_provider.dart';
import '../widgets/nutrition_widgets.dart';

class MyPlateScreen extends ConsumerWidget {
  const MyPlateScreen({
    super.key,
    required this.childId,
    this.dateKey,
  });

  final String  childId;
  final String? dateKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dk    = dateKey ?? todayNutritionKey;
    final key   = (childId: childId, dateKey: dk);
    final plate = ref.watch(plateSummaryProvider(key));

    final overall  = plate.overall;
    final elements = [
      (emoji: '🥩', label: 'Білок',         pct: plate.proteinPct,
        tip: 'Додай ще одну порцію білка — м\'ясо, рибу або яйця.'),
      (emoji: '🥦', label: 'Овочі',          pct: plate.vegetablesPct,
        tip: 'Додай порцію овочів — броколі, шпинат або томати.'),
      (emoji: '🌾', label: 'Складні вуглеводи', pct: plate.carbsPct,
        tip: 'Включи гречку, вівсянку або бурий рис у наступний прийом.'),
      (emoji: '🍎', label: 'Фрукти',          pct: plate.fruitsPct,
        tip: 'З\'їж яблуко або банан — природні цукри та клітковина.'),
      (emoji: '💧', label: 'Вода',            pct: plate.waterPct,
        tip: 'Ціль — 1.5 л на день. Випий ще стакан води зараз.'),
    ];

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
                    colors: [Color(0xFF1A1200), AppColors.background],
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
                        Text('🍽 Моя тарілка',
                            style: TextStyle(fontSize: 24,
                                fontWeight: FontWeight.w800, color: Colors.white)),
                        Text('П\'ять елементів здорового харчування',
                            style: TextStyle(fontSize: 13,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
              title: const Text('Моя тарілка',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Overall score ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: NutritionScoreGauge(
                      score: overall * 100,
                      size:  150,
                      strokeWidth: 12,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${(overall * 100).round()}%',
                              style: const TextStyle(fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary)),
                          const Text('Тарілка',
                              style: TextStyle(fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Element rows ──────────────────────────────────────────────
                NutritionCard(
                  child: Column(
                    children: elements.map((e) =>
                        PlateElementRow(
                            label: e.label,
                            emoji: e.emoji,
                            pct:   e.pct)).toList(),
                  ),
                ),

                // ── Tips for elements < 80% ───────────────────────────────────
                const NutritionSectionHeader(title: 'Рекомендації'),
                ...elements
                    .where((e) => e.pct < 0.8)
                    .map((e) => _TipCard(emoji: e.emoji, label: e.label, tip: e.tip)),

                if (elements.every((e) => e.pct >= 0.8))
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: const [
                        Text('🏆', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 8),
                        Text('Ідеальна тарілка!',
                            style: TextStyle(fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.orange)),
                        SizedBox(height: 4),
                        Text('Всі елементи виконані',
                            style: TextStyle(fontSize: 13,
                                color: AppColors.textSecondary)),
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

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.emoji,
    required this.label,
    required this.tip,
  });

  final String emoji;
  final String label;
  final String tip;

  @override
  Widget build(BuildContext context) {
    return NutritionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color:        AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji,
                style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.orange)),
                const SizedBox(height: 3),
                Text(tip,
                    style: const TextStyle(fontSize: 13,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

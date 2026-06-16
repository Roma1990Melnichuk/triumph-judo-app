import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/meal_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../team/providers/children_provider.dart';
import '../providers/nutrition_provider.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../widgets/nutrition_widgets.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider).asData?.value;
    if (user == null) return const SizedBox.shrink();

    if (user.isCoach) {
      return const _CoachNutritionOverview();
    }

    final childId = ref.watch(effectiveChildIdProvider) ?? '';
    if (childId.isEmpty) return const SizedBox.shrink();
    return NutritionDashboard(childId: childId);
  }
}

// ── Coach overview ─────────────────────────────────────────────────────────────

class _CoachNutritionOverview extends ConsumerWidget {
  const _CoachNutritionOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final athletes = ref.watch(allChildrenProvider).asData?.value ?? [];
    final dk       = todayNutritionKey;

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
            automaticallyImplyLeading: false,
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
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment:  MainAxisAlignment.end,
                      children: [
                        const Text('Харчування команди',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        Text(DateFormat('d MMMM', 'uk').format(DateTime.now()),
                            style: const TextStyle(fontSize: 13,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (athletes.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('Немає спортсменів',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final child = athletes[i];
                    final key   = (childId: child.id, dateKey: dk);
                    final score = ref.watch(nutritionScoreProvider(key));
                    return _AthleteNutritionCard(
                      child:   child,
                      score:   score,
                      onTap: () => context.push(
                          '/nutrition/child/${child.id}',
                          extra: {'name': child.fullName}),
                    );
                  },
                  childCount: athletes.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AthleteNutritionCard extends ConsumerWidget {
  const _AthleteNutritionCard({
    required this.child,
    required this.score,
    required this.onTap,
  });

  final dynamic       child;
  final double        score;
  final VoidCallback  onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dk      = todayNutritionKey;
    final key     = (childId: child.id as String, dateKey: dk);
    final waterMl = ref.watch(dayWaterMlProvider(key));
    final meals   = ref.watch(dayMealsProvider(key));
    final doneMeals = meals.where((m) => m.status == MealStatus.done).length;
    final scoreInt  = score.round();

    Color scoreColor = AppColors.error;
    if (scoreInt >= 70) scoreColor = AppColors.success;
    else if (scoreInt >= 45) scoreColor = AppColors.orange;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF222222)),
        ),
        child: Row(
          children: [
            // Score badge
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:  scoreColor.withValues(alpha: 0.1),
                border: Border.all(color: scoreColor.withValues(alpha: 0.4), width: 2),
              ),
              child: Center(
                child: Text('$scoreInt',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                        color: scoreColor)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(child.fullName as String,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _Chip('🍽 $doneMeals прийомів'),
                      const SizedBox(width: 6),
                      _Chip('💧 ${(waterMl / 1000).toStringAsFixed(1)} л'),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color:        const Color(0xFF242424),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    );
  }
}

// ── Athlete / parent dashboard ─────────────────────────────────────────────────

class NutritionDashboard extends ConsumerStatefulWidget {
  const NutritionDashboard({
    super.key,
    required this.childId,
    this.childName,
    this.showBackButton = false,
  });

  final String  childId;
  final String? childName;
  final bool    showBackButton;

  @override
  ConsumerState<NutritionDashboard> createState() => _NutritionDashboardState();
}

class _NutritionDashboardState extends ConsumerState<NutritionDashboard> {
  DateTime _selectedDate = DateTime.now();

  String get _dk => nutritionDateKey(_selectedDate);

  void _shiftDate(int delta) {
    final next = _selectedDate.add(Duration(days: delta));
    if (next.isAfter(DateTime.now())) return;
    setState(() => _selectedDate = next);
  }

  @override
  Widget build(BuildContext context) {
    final key     = (childId: widget.childId, dateKey: _dk);
    final score   = ref.watch(nutritionScoreProvider(key));
    final meals   = ref.watch(dayMealsProvider(key));
    final waterMl = ref.watch(dayWaterMlProvider(key));
    final waterGoal = ref.watch(waterGoalMlProvider);
    final plate   = ref.watch(plateSummaryProvider(key));
    final tips    = ref.watch(nutritionTipsProvider).asData?.value ?? [];

    final breakfast = meals.where((m) => m.type == MealType.breakfast).isNotEmpty;
    final lunch     = meals.where((m) => m.type == MealType.lunch).isNotEmpty;
    final dinner    = meals.where((m) => m.type == MealType.dinner).isNotEmpty;
    final isToday   = _dk == todayNutritionKey;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: widget.showBackButton
                ? AppBackButton(onPressed: () => context.pop())
                : null,
            automaticallyImplyLeading: widget.showBackButton,
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded,
                    color: AppColors.textSecondary),
                tooltip: 'Статистика',
                onPressed: () =>
                    context.push('/nutrition/child/${widget.childId}/stats'),
              ),
            ],
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
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment:  MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Text('🥗 ', style: TextStyle(fontSize: 22)),
                            const Text('Харчування',
                                style: TextStyle(fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ],
                        ),
                        if (widget.childName != null && widget.childName!.isNotEmpty)
                          Text(widget.childName!,
                              style: const TextStyle(fontSize: 13,
                                  color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Date selector ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded,
                            color: AppColors.textSecondary),
                        onPressed: () => _shiftDate(-1),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedDate = DateTime.now()),
                        child: Text(
                          isToday
                              ? 'Сьогодні'
                              : DateFormat('d MMMM', 'uk').format(_selectedDate),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isToday
                                ? AppColors.orange
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right_rounded,
                            color: isToday
                                ? const Color(0xFF333333)
                                : AppColors.textSecondary),
                        onPressed: isToday ? null : () => _shiftDate(1),
                      ),
                    ],
                  ),
                ),

                // ── Score gauge ────────────────────────────────────────────────
                Center(
                  child: NutritionScoreGauge(
                    score: score,
                    size: 140,
                    strokeWidth: 11,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(score.round().toString(),
                            style: const TextStyle(fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                        const Text('/ 100',
                            style: TextStyle(fontSize: 12,
                                color: AppColors.textSecondary)),
                        Text('Індекс дня',
                            style: TextStyle(fontSize: 10,
                                color: AppColors.orange.withValues(alpha: 0.9))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Quick stats row ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(child: QuickStatChip(emoji: '🌅', label: 'Сніданок', done: breakfast,
                          onTap: () => context.push('/nutrition/child/${widget.childId}/diary',
                              extra: {'date': _dk}))),
                      const SizedBox(width: 8),
                      Expanded(child: QuickStatChip(emoji: '☀️', label: 'Обід', done: lunch,
                          onTap: () => context.push('/nutrition/child/${widget.childId}/diary',
                              extra: {'date': _dk}))),
                      const SizedBox(width: 8),
                      Expanded(child: QuickStatChip(emoji: '🌙', label: 'Вечеря', done: dinner,
                          onTap: () => context.push('/nutrition/child/${widget.childId}/diary',
                              extra: {'date': _dk}))),
                      const SizedBox(width: 8),
                      Expanded(child: QuickStatChip(
                          emoji: '💧',
                          label: waterMl > 0 ? '${(waterMl/1000).toStringAsFixed(1)}л' : 'Вода',
                          done: waterMl >= waterGoal,
                          onTap: () => context.push('/nutrition/child/${widget.childId}/water'))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Water card ─────────────────────────────────────────────────
                NutritionCard(
                  onTap: () => context.push('/nutrition/child/${widget.childId}/water'),
                  child: Row(
                    children: [
                      const Text('💧', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Водний режим',
                                style: TextStyle(fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text(
                              '${(waterMl / 1000).toStringAsFixed(2)} / ${(waterGoal / 1000).toStringAsFixed(1)} л',
                              style: TextStyle(
                                fontSize: 13,
                                color: waterMl >= waterGoal
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(
                                    begin: 0,
                                    end: (waterMl / waterGoal).clamp(0.0, 1.0)),
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.easeOut,
                                builder: (_, v, __) => LinearProgressIndicator(
                                  value: v,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFF2A2A2A),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    v >= 1.0
                                        ? AppColors.success
                                        : const Color(0xFF4FC3F7),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _AddWaterButton(
                          childId: widget.childId, amountMl: 200),
                    ],
                  ),
                ),

                // ── My plate card ──────────────────────────────────────────────
                NutritionCard(
                  onTap: () => context.push('/nutrition/child/${widget.childId}/plate',
                      extra: {'date': _dk}),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Text('🍽', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 8),
                              Text('Моя тарілка',
                                  style: TextStyle(fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                            ],
                          ),
                          Text('${(plate.overall * 100).round()}%',
                              style: const TextStyle(fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.orange)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      PlateElementRow(label: 'Білок',    emoji: '🥩',
                          pct: plate.proteinPct),
                      PlateElementRow(label: 'Овочі',    emoji: '🥦',
                          pct: plate.vegetablesPct),
                      PlateElementRow(label: 'Вуглеводи', emoji: '🌾',
                          pct: plate.carbsPct),
                      PlateElementRow(label: 'Фрукти',   emoji: '🍎',
                          pct: plate.fruitsPct),
                    ],
                  ),
                ),

                // ── Meal diary link ────────────────────────────────────────────
                NutritionCard(
                  onTap: () => context.push('/nutrition/child/${widget.childId}/diary',
                      extra: {'date': _dk}),
                  child: Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color:        AppColors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                            child: Text('📋', style: TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Щоденник харчування',
                                style: TextStyle(fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            Text(
                              meals.isEmpty
                                  ? 'Записів немає'
                                  : '${meals.where((m) => m.status == MealStatus.done).length} з ${meals.length} виконано',
                              style: const TextStyle(fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textSecondary, size: 20),
                    ],
                  ),
                ),

                // ── Tips teaser ────────────────────────────────────────────────
                if (tips.isNotEmpty) ...[
                  NutritionSectionHeader(
                      title: 'Рекомендації',
                      action: 'Всі',
                      onAction: () => context.push('/nutrition/tips')),
                  NutritionCard(
                    onTap: () => context.push('/nutrition/tips'),
                    child: Row(
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tips.first.title,
                                  style: const TextStyle(fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(tips.first.category.label,
                                  style: const TextStyle(fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ],

                // ── Products link ──────────────────────────────────────────────
                NutritionSectionHeader(title: 'Корисні продукти'),
                NutritionCard(
                  onTap: () => context.push('/nutrition/products'),
                  child: Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color:        const Color(0xFF1E2A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                            child: Text('🥗', style: TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('База продуктів',
                                style: TextStyle(fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            Text('Білки, овочі, крупи, фрукти',
                                style: TextStyle(fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textSecondary, size: 20),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
            '/nutrition/child/${widget.childId}/add-meal',
            extra: {'date': _dk}),
        backgroundColor: AppColors.orange,
        icon: const Icon(Icons.add_rounded, color: Colors.black),
        label: const Text('Додати прийом',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black)),
      ),
    );
  }
}

// ── Quick +200ml water button ──────────────────────────────────────────────────

class _AddWaterButton extends ConsumerWidget {
  const _AddWaterButton({required this.childId, required this.amountMl});
  final String childId;
  final int    amountMl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref
          .read(nutritionNotifierProvider.notifier)
          .logWater(childId: childId, amountMl: amountMl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:        const Color(0xFF1A2A34),
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: const Color(0xFF4FC3F7).withValues(alpha: 0.3)),
        ),
        child: const Text('+200 мл',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: Color(0xFF4FC3F7))),
      ),
    );
  }
}

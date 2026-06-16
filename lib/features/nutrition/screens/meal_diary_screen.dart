import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/meal_model.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../providers/nutrition_provider.dart';
import '../widgets/nutrition_widgets.dart';

class MealDiaryScreen extends ConsumerStatefulWidget {
  const MealDiaryScreen({
    super.key,
    required this.childId,
    this.initialDateKey,
  });

  final String  childId;
  final String? initialDateKey;

  @override
  ConsumerState<MealDiaryScreen> createState() => _MealDiaryScreenState();
}

class _MealDiaryScreenState extends ConsumerState<MealDiaryScreen> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    if (widget.initialDateKey != null) {
      try {
        final parts = widget.initialDateKey!.split('-');
        _date = DateTime(int.parse(parts[0]), int.parse(parts[1]),
            int.parse(parts[2]));
      } catch (_) {
        _date = DateTime.now();
      }
    } else {
      _date = DateTime.now();
    }
  }

  String get _dk => nutritionDateKey(_date);
  bool get _isToday => _dk == todayNutritionKey;

  void _shiftDate(int delta) {
    final next = _date.add(Duration(days: delta));
    if (next.isAfter(DateTime.now())) return;
    setState(() => _date = next);
  }

  @override
  Widget build(BuildContext context) {
    final key   = (childId: widget.childId, dateKey: _dk);
    final meals = ref.watch(dayMealsProvider(key));

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
            leading: AppBackButton(onPressed: () => context.pop()),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF181400), AppColors.background],
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
                        Text('📋 Щоденник харчування',
                            style: TextStyle(fontSize: 22,
                                fontWeight: FontWeight.w800, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
              title: const Text('Щоденник',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Date selector ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded,
                            color: AppColors.textSecondary),
                        onPressed: () => _shiftDate(-1),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _date = DateTime.now()),
                        child: Text(
                          _isToday
                              ? 'Сьогодні'
                              : DateFormat('d MMMM', 'uk').format(_date),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _isToday
                                ? AppColors.orange
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right_rounded,
                            color: _isToday
                                ? const Color(0xFF333333)
                                : AppColors.textSecondary),
                        onPressed: _isToday ? null : () => _shiftDate(1),
                      ),
                    ],
                  ),
                ),

                // ── Meals by type ──────────────────────────────────────────────
                if (meals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Text('🍽', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        const Text('Записів немає',
                            style: TextStyle(fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        const Text('Додай перший прийом їжі',
                            style: TextStyle(fontSize: 13,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => context.push(
                              '/nutrition/child/${widget.childId}/add-meal',
                              extra: {'date': _dk}),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Додати прийом'),
                        ),
                      ],
                    ),
                  )
                else
                  ...MealType.values.map((type) {
                    final typeMeals =
                        meals.where((m) => m.type == type).toList();
                    return _MealTypeSection(
                      type:    type,
                      meals:   typeMeals,
                      childId: widget.childId,
                      dateKey: _dk,
                    );
                  }),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(
            '/nutrition/child/${widget.childId}/add-meal',
            extra: {'date': _dk}),
        backgroundColor: AppColors.orange,
        child: const Icon(Icons.add_rounded, color: Colors.black),
      ),
    );
  }
}

class _MealTypeSection extends StatelessWidget {
  const _MealTypeSection({
    required this.type,
    required this.meals,
    required this.childId,
    required this.dateKey,
  });

  final MealType        type;
  final List<MealModel> meals;
  final String          childId;
  final String          dateKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(type.label,
                  style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              GestureDetector(
                onTap: () => context.push(
                    '/nutrition/child/$childId/add-meal',
                    extra: {'date': dateKey, 'type': type.name}),
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: AppColors.orange),
                    Text('Додати',
                        style: TextStyle(fontSize: 12,
                            color: AppColors.orange)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (meals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF222222), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline,
                      color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 10),
                  Text('Не зафіксовано',
                      style: const TextStyle(fontSize: 13,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
          )
        else
          ...meals.map((m) => _MealCard(meal: m, childId: childId)),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal, required this.childId});
  final MealModel meal;
  final String    childId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
          '/nutrition/child/$childId/add-meal',
          extra: {'meal': meal}),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: const Color(0xFF222222)),
        ),
        child: Row(
          children: [
            // Photo
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16)),
              child: SizedBox(
                width: 80, height: 80,
                child: meal.photoUrl != null
                    ? Image.network(meal.photoUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const _PhotoPlaceholder())
                    : const _PhotoPlaceholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meal.mealName.isEmpty ? 'Без назви' : meal.mealName,
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (meal.calories != null) ...[
                          Text('${meal.calories} ккал',
                              style: const TextStyle(fontSize: 11,
                                  color: AppColors.textSecondary)),
                          const SizedBox(width: 8),
                        ],
                        MealStatusBadge(meal.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    PlateDots(meal),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C1C1C),
      child: const Center(
          child: Text('🍽', style: TextStyle(fontSize: 28))),
    );
  }
}

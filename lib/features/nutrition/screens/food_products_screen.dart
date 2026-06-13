import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/food_product_model.dart';
import '../providers/nutrition_provider.dart';

class FoodProductsScreen extends ConsumerStatefulWidget {
  const FoodProductsScreen({super.key});

  @override
  ConsumerState<FoodProductsScreen> createState() => _FoodProductsScreenState();
}

class _FoodProductsScreenState extends ConsumerState<FoodProductsScreen> {
  FoodCategory? _filter;
  String        _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        ref.read(nutritionNotifierProvider.notifier).seedProductsIfEmpty());
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(foodProductsProvider).asData?.value ?? [];
    final filtered = allProducts.where((p) {
      if (_filter != null && p.category != _filter) return false;
      if (_query.isNotEmpty &&
          !p.name.toLowerCase().contains(_query.toLowerCase())) return false;
      return true;
    }).toList();

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
                    colors: [Color(0xFF0A1A0A), AppColors.background],
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
                        Text('🥗 База продуктів',
                            style: TextStyle(fontSize: 22,
                                fontWeight: FontWeight.w800, color: Colors.white)),
                        Text('Корисні продукти для спортсменів',
                            style: TextStyle(fontSize: 13,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
              title: const Text('Продукти',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Search ────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Пошук продукту...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),

                // ── Category filter ───────────────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      _FilterChip(
                          label: 'Всі',
                          selected: _filter == null,
                          onTap: () => setState(() => _filter = null)),
                      ...FoodCategory.values.map((c) => _FilterChip(
                            label: c.label,
                            selected: _filter == c,
                            onTap: () => setState(
                                () => _filter = _filter == c ? null : c),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (filtered.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('Нічого не знайдено',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _ProductCard(product: filtered[i]),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String       label;
  final bool         selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.orange.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected
                ? AppColors.orange
                : const Color(0xFF2C2C2C),
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color:
                  selected ? AppColors.orange : AppColors.textSecondary,
            )),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final FoodProductModel product;

  static const _catEmoji = {
    FoodCategory.protein:    '🥩',
    FoodCategory.vegetables: '🥦',
    FoodCategory.grains:     '🌾',
    FoodCategory.fruits:     '🍎',
    FoodCategory.drinks:     '💧',
  };

  @override
  Widget build(BuildContext context) {
    final emoji = _catEmoji[product.category] ?? '🍽';
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _ProductDetail(product: product),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: const Color(0xFF222222)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color:        const Color(0xFF1C2A1C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(emoji,
                  style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: const TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(product.category.label,
                      style: const TextStyle(fontSize: 11,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${product.calories} ккал',
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange)),
                Text('Б: ${product.protein}г',
                    style: const TextStyle(fontSize: 10,
                        color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductDetail extends StatelessWidget {
  const _ProductDetail({required this.product});
  final FoodProductModel product;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text(product.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(product.category.label,
              style: const TextStyle(fontSize: 13, color: AppColors.orange)),
          const SizedBox(height: 12),
          Text(product.description,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary,
                  height: 1.5)),
          const SizedBox(height: 20),
          const Text('Поживна цінність (100 г)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              _NutrientBadge(label: 'Калорії', value: '${product.calories}',
                  unit: 'ккал', color: AppColors.orange),
              const SizedBox(width: 10),
              _NutrientBadge(label: 'Білки',   value: '${product.protein}',
                  unit: 'г',    color: const Color(0xFF4FC3F7)),
              const SizedBox(width: 10),
              _NutrientBadge(label: 'Жири',    value: '${product.fat}',
                  unit: 'г',    color: AppColors.success),
              const SizedBox(width: 10),
              _NutrientBadge(label: 'Вуглев.', value: '${product.carbs}',
                  unit: 'г',    color: const Color(0xFFFFD060)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutrientBadge extends StatelessWidget {
  const _NutrientBadge({
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: color)),
            Text(unit,
                style: TextStyle(fontSize: 10, color: color)),
            Text(label,
                style: const TextStyle(fontSize: 9,
                    color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

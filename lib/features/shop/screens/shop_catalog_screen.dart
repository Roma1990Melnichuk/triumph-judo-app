import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:judo_app/core/constants/app_colors.dart';
import 'package:judo_app/core/models/cart_model.dart';
import 'package:judo_app/core/models/shop_product_model.dart';
import 'package:judo_app/features/shop/providers/cart_provider.dart';
import 'package:judo_app/features/shop/providers/shop_provider.dart';
import 'package:judo_app/shared/widgets/gradient_button.dart';

enum _SortOrder { popular, priceAsc, priceDesc }

class ShopCatalogScreen extends ConsumerStatefulWidget {
  const ShopCatalogScreen({super.key, this.initialCategory});

  final ShopCategory? initialCategory;

  @override
  ConsumerState<ShopCatalogScreen> createState() => _ShopCatalogScreenState();
}

class _ShopCatalogScreenState extends ConsumerState<ShopCatalogScreen> {
  late ShopCategory? _selectedCategory;
  bool _inStockOnly = false;
  bool _newOnly = false;
  _SortOrder _sortOrder = _SortOrder.popular;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ShopProductFilter get _filter => ShopProductFilter(
        category: _selectedCategory,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        inStockOnly: _inStockOnly,
        newOnly: _newOnly,
      );

  List<ShopProduct> _applySortOrder(List<ShopProduct> products) {
    final sorted = List<ShopProduct>.from(products);
    switch (_sortOrder) {
      case _SortOrder.popular:
        sorted.sort((a, b) {
          if (a.isFeatured && !b.isFeatured) return -1;
          if (!a.isFeatured && b.isFeatured) return 1;
          return 0;
        });
      case _SortOrder.priceAsc:
        sorted.sort((a, b) => a.price.compareTo(b.price));
      case _SortOrder.priceDesc:
        sorted.sort((a, b) => b.price.compareTo(a.price));
    }
    return sorted;
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SortSheet(
        current: _sortOrder,
        onSelected: (order) {
          setState(() => _sortOrder = order);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRaw = ref.watch(shopFilteredProvider(_filter));
    final sorted = _applySortOrder(filteredRaw);
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Каталог товарів',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined,
                    color: AppColors.textPrimary),
                onPressed: () => context.push('/shop/cart'),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: _CartBadge(count: cartCount),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSortSheet,
        backgroundColor: AppColors.surface2,
        foregroundColor: AppColors.accent,
        shape: const CircleBorder(),
        child: const Icon(Icons.sort_rounded),
      ),
      body: Column(
        children: [
          _FilterSection(
            searchController: _searchController,
            selectedCategory: _selectedCategory,
            inStockOnly: _inStockOnly,
            newOnly: _newOnly,
            onCategorySelected: (cat) =>
                setState(() => _selectedCategory = cat),
            onInStockToggle: (v) => setState(() => _inStockOnly = v),
            onNewOnlyToggle: (v) => setState(() => _newOnly = v),
          ),
          Expanded(
            child: sorted.isEmpty
                ? const _EmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.58,
                    ),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) => _ShopProductCard(
                      product: sorted[index],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.searchController,
    required this.selectedCategory,
    required this.inStockOnly,
    required this.newOnly,
    required this.onCategorySelected,
    required this.onInStockToggle,
    required this.onNewOnlyToggle,
  });

  final TextEditingController searchController;
  final ShopCategory? selectedCategory;
  final bool inStockOnly;
  final bool newOnly;
  final ValueChanged<ShopCategory?> onCategorySelected;
  final ValueChanged<bool> onInStockToggle;
  final ValueChanged<bool> onNewOnlyToggle;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: TextField(
              controller: searchController,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'Пошук товарів...',
                hintStyle: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary, size: 20),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: searchController,
                  builder: (_, value, __) => value.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: AppColors.textSecondary, size: 18),
                          onPressed: searchController.clear,
                        )
                      : const SizedBox.shrink(),
                ),
                filled: true,
                fillColor: AppColors.surface2,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(
                  label: 'Усі',
                  selected: selectedCategory == null,
                  onTap: () => onCategorySelected(null),
                ),
                const SizedBox(width: 6),
                ...ShopCategory.values.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _CategoryChip(
                        label: cat.label,
                        selected: selectedCategory == cat,
                        onTap: () => onCategorySelected(
                          selectedCategory == cat ? null : cat,
                        ),
                      ),
                    )),
                _ToggleChip(
                  label: 'В наявності',
                  selected: inStockOnly,
                  onTap: () => onInStockToggle(!inStockOnly),
                ),
                const SizedBox(width: 6),
                _ToggleChip(
                  label: 'Новинки',
                  selected: newOnly,
                  onTap: () => onNewOnlyToggle(!newOnly),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.surface3),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderSoft,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.18) : AppColors.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.borderSoft,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.accent : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current, required this.onSelected});

  final _SortOrder current;
  final ValueChanged<_SortOrder> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surface3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Сортування',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _SortTile(
            label: 'За популярністю',
            icon: Icons.local_fire_department_rounded,
            selected: current == _SortOrder.popular,
            onTap: () => onSelected(_SortOrder.popular),
          ),
          _SortTile(
            label: 'За ціною ↑',
            icon: Icons.arrow_upward_rounded,
            selected: current == _SortOrder.priceAsc,
            onTap: () => onSelected(_SortOrder.priceAsc),
          ),
          _SortTile(
            label: 'За ціною ↓',
            icon: Icons.arrow_downward_rounded,
            selected: current == _SortOrder.priceDesc,
            onTap: () => onSelected(_SortOrder.priceDesc),
          ),
        ],
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  const _SortTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(
        icon,
        color: selected ? AppColors.primary : AppColors.textSecondary,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          fontSize: 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_rounded,
              color: AppColors.primary, size: 18)
          : null,
    );
  }
}

class _ShopProductCard extends ConsumerWidget {
  const _ShopProductCard({required this.product});

  final ShopProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/shop/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSoft, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 55,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(13)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _shopImage(product.imageUrls.isNotEmpty
                        ? product.imageUrls.first
                        : null),
                    if (product.badge != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _BadgeChip(badge: product.badge!),
                      ),
                    if (!product.isInStock)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.55),
                          alignment: Alignment.center,
                          child: const Text(
                            'Немає в\nнаявності',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 45,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${product.price.toInt()} ${product.currency}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 5),
                          Text(
                            '${product.oldPrice!.toInt()}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 34,
                      child: GradientButton(
                        height: 34,
                        onPressed: product.isInStock
                            ? () => _addToCart(ref, context)
                            : null,
                        child: const Text(
                          'В кошик',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(WidgetRef ref, BuildContext context) {
    final firstVariant =
        product.variants.where((v) => v.inStock).firstOrNull;
    final item = CartItem(
      id: '${product.id}_${firstVariant?.id ?? 'default'}_${DateTime.now().millisecondsSinceEpoch}',
      productId: product.id,
      variantId: firstVariant?.id,
      quantity: 1,
      priceSnapshot: product.price,
      title: product.title,
      imageUrl:
          product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
      size: firstVariant?.size,
      color: firstVariant?.color,
    );
    ref.read(cartNotifierProvider.notifier).addItem(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${product.title} додано до кошика',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        ),
        backgroundColor: AppColors.surface2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});

  final ShopBadge badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badge.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        badge.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _CartBadge extends StatelessWidget {
  const _CartBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              size: 56),
          const SizedBox(height: 16),
          const Text(
            'Товарів не знайдено',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Спробуйте змінити фільтри або пошуковий запит',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text3,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _shopImage(String? url) {
  if (url == null) {
    return Container(
      color: AppColors.surface2,
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined,
            color: AppColors.surface3, size: 36),
      ),
    );
  }
  if (url.startsWith('assets/')) {
    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.surface2,
        child: const Center(
          child: Icon(Icons.broken_image_outlined,
              color: AppColors.surface3, size: 36),
        ),
      ),
    );
  }
  return CachedNetworkImage(
    imageUrl: url,
    fit: BoxFit.cover,
    placeholder: (_, __) => Container(color: AppColors.surface2),
    errorWidget: (_, __, ___) => Container(
      color: AppColors.surface2,
      child: const Center(
        child: Icon(Icons.broken_image_outlined,
            color: AppColors.surface3, size: 36),
      ),
    ),
  );
}

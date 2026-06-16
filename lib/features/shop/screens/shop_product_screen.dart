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
import 'package:judo_app/shared/widgets/app_back_button.dart';

class ShopProductScreen extends ConsumerStatefulWidget {
  const ShopProductScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ShopProductScreen> createState() => _ShopProductScreenState();
}

class _ShopProductScreenState extends ConsumerState<ShopProductScreen> {
  String? _selectedSize;
  String? _selectedColor;
  int _quantity = 1;
  int _imagePageIndex = 0;
  bool _descExpanded = false;
  bool _sizeGuideExpanded = false;

  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _buildImageList(ShopProduct product) {
    final urls = List<String>.from(product.imageUrls);
    for (final v in product.variants) {
      if (v.colorImageUrl != null && !urls.contains(v.colorImageUrl)) {
        urls.add(v.colorImageUrl!);
      }
    }
    return urls;
  }

  String? _currentDisplayImage(ShopProduct product) {
    if (_selectedColor != null) {
      final variant = product.variants.firstWhere(
        (v) => v.color == _selectedColor && v.colorImageUrl != null,
        orElse: () => product.variants.firstWhere(
          (v) => v.color == _selectedColor,
          orElse: () => const ShopProductVariant(id: '', productId: ''),
        ),
      );
      if (variant.colorImageUrl != null) return variant.colorImageUrl;
    }
    final images = _buildImageList(product);
    if (images.isEmpty) return null;
    return images[_imagePageIndex.clamp(0, images.length - 1)];
  }

  ShopProductVariant? _findSelectedVariant(ShopProduct product) {
    if (product.variants.isEmpty) return null;
    return product.variants.firstWhere(
      (v) {
        final sizeMatch = _selectedSize == null || v.size == _selectedSize;
        final colorMatch = _selectedColor == null || v.color == _selectedColor;
        return sizeMatch && colorMatch;
      },
      orElse: () => product.variants.first,
    );
  }

  bool _variantInStock(ShopProduct product, String? size, String? color) {
    final matches = product.variants.where((v) {
      final sizeMatch = size == null || v.size == size;
      final colorMatch = color == null || v.color == color;
      return sizeMatch && colorMatch;
    });
    return matches.any((v) => v.inStock);
  }


  Future<void> _addToCart(ShopProduct product) async {
    final hasVariants = product.variants.isNotEmpty;
    final hasSizes = product.availableSizes.isNotEmpty;
    final hasColors = product.availableColors.isNotEmpty;

    if (hasVariants) {
      if (hasSizes && _selectedSize == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Оберіть розмір/колір'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (hasColors && _selectedColor == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Оберіть розмір/колір'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final variant = _findSelectedVariant(product);
    final imageUrl = _currentDisplayImage(product);

    final item = CartItem(
      id: '${product.id}_${variant?.id ?? 'base'}_${DateTime.now().millisecondsSinceEpoch}',
      productId: product.id,
      variantId: variant?.id,
      quantity: _quantity,
      priceSnapshot: product.price + (variant?.priceModifier ?? 0.0),
      title: product.title,
      imageUrl: imageUrl,
      size: _selectedSize,
      color: _selectedColor,
    );

    await ref.read(cartNotifierProvider.notifier).addItem(item);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Додано до кошика'),
        backgroundColor: AppColors.surface2,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Кошик',
          textColor: AppColors.accent,
          onPressed: () => context.push('/shop/cart'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(shopProductProvider(widget.productId));
    final cartCount = ref.watch(cartItemCountProvider);
    final cartState = ref.watch(cartNotifierProvider);

    return productAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background),
        body: Center(
          child: Text('Помилка завантаження', style: TextStyle(color: AppColors.error)),
        ),
      ),
      data: (product) {
        if (product == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(backgroundColor: AppColors.background),
            body: const Center(
              child: Text('Товар не знайдено',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          );
        }

        final images = _buildImageList(product);
        final hasSizes = product.availableSizes.isNotEmpty;
        final hasColors = product.availableColors.isNotEmpty;
        final isKimono = product.category == ShopCategory.kimono;
        final isLoading = cartState.isLoading;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: AppBackButton(onPressed: () => context.pop()),
                actions: [
                  GestureDetector(
                    onTap: () => context.push('/shop/cart'),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface2.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.shopping_cart_outlined,
                              color: AppColors.textPrimary, size: 22),
                          if (cartCount > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  cartCount > 99 ? '99+' : '$cartCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      if (images.isEmpty)
                        Container(
                          color: AppColors.surface,
                          child: const Center(
                            child:
                                Icon(Icons.image_not_supported, color: AppColors.surface3, size: 64),
                          ),
                        )
                      else if (images.length == 1)
                        _ProductImage(imageUrl: images[0])
                      else
                        PageView.builder(
                          controller: _pageController,
                          itemCount: images.length,
                          onPageChanged: (i) => setState(() => _imagePageIndex = i),
                          itemBuilder: (_, i) => _ProductImage(imageUrl: images[i]),
                        ),
                      if (images.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              images.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: _imagePageIndex == i ? 18 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: _imagePageIndex == i
                                      ? AppColors.accent
                                      : AppColors.textSecondary.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.background.withValues(alpha: 0.0),
                              AppColors.background.withValues(alpha: 0.6),
                            ],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.badge != null) ...[
                            _BadgeChip(badge: product.badge!),
                            const SizedBox(height: 10),
                          ],
                          Text(
                            product.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _PriceRow(product: product),
                          const SizedBox(height: 16),
                          _StockChip(inStock: product.isInStock),
                        ],
                      ),
                    ),
                    if (hasSizes || hasColors) ...[
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(color: AppColors.surface3, height: 1),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (hasSizes)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Розмір',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: product.availableSizes.map((size) {
                                final inStock =
                                    _variantInStock(product, size, _selectedColor);
                                final selected = _selectedSize == size;
                                return _SizeChip(
                                  label: size,
                                  selected: selected,
                                  inStock: inStock,
                                  onTap: inStock
                                      ? () => setState(() {
                                            _selectedSize =
                                                _selectedSize == size ? null : size;
                                          })
                                      : null,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    if (hasSizes && hasColors) const SizedBox(height: 16),
                    if (hasColors)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Колір',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: product.availableColors.map((color) {
                                final inStock =
                                    _variantInStock(product, _selectedSize, color);
                                final selected = _selectedColor == color;
                                return _ColorChip(
                                  label: color,
                                  selected: selected,
                                  inStock: inStock,
                                  onTap: inStock
                                      ? () => setState(() {
                                            _selectedColor =
                                                _selectedColor == color ? null : color;
                                          })
                                      : null,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(color: AppColors.surface3, height: 1),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Text(
                            'Кількість',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          _QuantitySelector(
                            value: _quantity,
                            onDecrement: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            onIncrement: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ),
                    if (product.coachNote != null) ...[
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(color: AppColors.surface3, height: 1),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _CoachNoteCard(note: product.coachNote!),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(color: AppColors.surface3, height: 1),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ExpandableDescription(
                        description: product.description,
                        expanded: _descExpanded,
                        onToggle: () =>
                            setState(() => _descExpanded = !_descExpanded),
                      ),
                    ),
                    if (isKimono && product.variants.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(color: AppColors.surface3, height: 1),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _KimonoSizeGuide(
                          variants: product.variants,
                          expanded: _sizeGuideExpanded,
                          onToggle: () =>
                              setState(() => _sizeGuideExpanded = !_sizeGuideExpanded),
                        ),
                      ),
                    ],
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            color: AppColors.background,
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).padding.bottom,
            ),
            child: GradientButton(
              isLoading: isLoading,
              onPressed: isLoading ? null : () => _addToCart(product),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Додати в кошик',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.surface,
          child: const Center(
            child: Icon(Icons.image_not_supported,
                color: AppColors.surface3, size: 48),
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => Container(color: AppColors.surface),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.surface,
        child: const Center(
          child:
              Icon(Icons.image_not_supported, color: AppColors.surface3, size: 48),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badge.color.withValues(alpha: 0.5)),
      ),
      child: Text(
        badge.label,
        style: TextStyle(
          color: badge.color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.product});

  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.hasDiscount;
    final discountPct = hasDiscount
        ? ((product.oldPrice! - product.price) / product.oldPrice! * 100).round()
        : 0;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 4,
      children: [
        Text(
          '${product.price.toStringAsFixed(0)} ${product.currency}',
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (hasDiscount) ...[
          Text(
            '${product.oldPrice!.toStringAsFixed(0)} ${product.currency}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.textSecondary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            child: Text(
              '-$discountPct%',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StockChip extends StatelessWidget {
  const _StockChip({required this.inStock});

  final bool inStock;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: inStock ? AppColors.success : AppColors.error,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          inStock ? 'В наявності' : 'Немає в наявності',
          style: TextStyle(
            color: inStock ? AppColors.success : AppColors.error,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.label,
    required this.selected,
    required this.inStock,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool inStock;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: selected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: AppColors.ctaGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: inStock ? AppColors.surface2 : AppColors.surface,
                border: Border.all(
                  color: inStock
                      ? AppColors.borderSoft
                      : AppColors.surface3,
                ),
              ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : inStock
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.4),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.label,
    required this.selected,
    required this.inStock,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool inStock;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: selected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: AppColors.ctaGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: inStock ? AppColors.surface2 : AppColors.surface,
                border: Border.all(
                  color: selected
                      ? AppColors.borderGold
                      : inStock
                          ? AppColors.borderSoft
                          : AppColors.surface3,
                ),
              ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : inStock
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.4),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QtyButton(
          icon: Icons.remove,
          onTap: onDecrement,
        ),
        const SizedBox(width: 4),
        Container(
          width: 44,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Text(
            '$value',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 4),
        _QtyButton(
          icon: Icons.add,
          onTap: onIncrement,
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? AppColors.surface2 : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? AppColors.borderSoft : AppColors.surface3,
          ),
        ),
        child: Icon(
          icon,
          color: enabled
              ? AppColors.textPrimary
              : AppColors.textSecondary.withValues(alpha: 0.3),
          size: 18,
        ),
      ),
    );
  }
}

class _CoachNoteCard extends StatelessWidget {
  const _CoachNoteCard({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGold),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: const Icon(
              Icons.sports_martial_arts,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Рекомендація тренера',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableDescription extends StatelessWidget {
  const _ExpandableDescription({
    required this.description,
    required this.expanded,
    required this.onToggle,
  });

  final String description;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              const Text(
                'Опис',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _KimonoSizeGuide extends StatelessWidget {
  const _KimonoSizeGuide({
    required this.variants,
    required this.expanded,
    required this.onToggle,
  });

  final List<ShopProductVariant> variants;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final sizedVariants = variants
        .where((v) =>
            v.size != null &&
            (v.heightFrom != null || v.heightTo != null || v.weightFrom != null))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              const Text(
                'Таблиця розмірів кімоно',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: expanded && sizedVariants.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderSoft),
                    ),
                    child: Column(
                      children: [
                        _SizeTableRow(
                          cells: const ['Розмір', 'Ріст (см)', 'Вага (кг)'],
                          isHeader: true,
                        ),
                        ...sizedVariants.asMap().entries.map((entry) {
                          final i = entry.key;
                          final v = entry.value;
                          final heightStr = v.heightFrom != null && v.heightTo != null
                              ? '${v.heightFrom}–${v.heightTo}'
                              : v.heightFrom != null
                                  ? '${v.heightFrom}+'
                                  : '—';
                          final weightStr = v.weightFrom != null && v.weightTo != null
                              ? '${v.weightFrom!.toStringAsFixed(0)}–${v.weightTo!.toStringAsFixed(0)}'
                              : v.weightFrom != null
                                  ? '${v.weightFrom!.toStringAsFixed(0)}+'
                                  : '—';
                          return _SizeTableRow(
                            cells: [v.size ?? '—', heightStr, weightStr],
                            isHeader: false,
                            isLast: i == sizedVariants.length - 1,
                          );
                        }),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SizeTableRow extends StatelessWidget {
  const _SizeTableRow({
    required this.cells,
    required this.isHeader,
    this.isLast = false,
  });

  final List<String> cells;
  final bool isHeader;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.surface3, width: 1),
              ),
        borderRadius: isHeader
            ? const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              )
            : null,
        color: isHeader ? AppColors.surface3 : null,
      ),
      child: Row(
        children: cells.asMap().entries.map((entry) {
          final i = entry.key;
          final cell = entry.value;
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: i < cells.length - 1
                  ? const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: AppColors.surface3, width: 1),
                      ),
                    )
                  : null,
              child: Text(
                cell,
                style: TextStyle(
                  color: isHeader ? AppColors.textSecondary : AppColors.textPrimary,
                  fontSize: isHeader ? 11 : 13,
                  fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: isHeader ? 0.4 : 0,
                ),
                textAlign: i == 0 ? TextAlign.left : TextAlign.center,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:judo_app/core/constants/app_colors.dart';
import 'package:judo_app/core/models/cart_model.dart';
import 'package:judo_app/core/models/shop_product_model.dart';
import 'package:judo_app/features/shop/providers/cart_provider.dart';
import 'package:judo_app/features/shop/providers/shop_provider.dart';
import 'package:judo_app/shared/widgets/gradient_button.dart';
import 'package:judo_app/shared/widgets/app_back_button.dart';

Widget _shopImage(
  String url, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (url.startsWith('assets/')) {
    return Image.asset(
      url,
      width: width,
      height: height,
      fit: fit,
    );
  }
  return CachedNetworkImage(
    imageUrl: url,
    width: width,
    height: height,
    fit: fit,
    placeholder: (_, __) => Container(
      width: width,
      height: height,
      color: AppColors.surface2,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.borderSoft,
          ),
        ),
      ),
    ),
    errorWidget: (_, __, ___) => Container(
      width: width,
      height: height,
      color: AppColors.surface2,
      child: const Icon(Icons.image_not_supported_outlined,
          color: AppColors.textSecondary, size: 28),
    ),
  );
}

class ShopHomeScreen extends ConsumerWidget {
  const ShopHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemCountProvider);
    final featuredProducts = ref.watch(featuredProductsProvider);
    final newProducts = ref.watch(newProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            foregroundColor: AppColors.textPrimary,
            pinned: true,
            leading: AppBackButton(onPressed: () => context.pop()),
            title: Text(
              'Клубний магазин',
              style: GoogleFonts.rubik(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: AppColors.textPrimary, size: 24),
                    onPressed: () => context.push('/shop/cart'),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: IgnorePointer(
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            gradient: AppColors.ctaGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              cartCount > 99 ? '99+' : '$cartCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),
              _HeroBanner(),
              const SizedBox(height: 24),
              _CategoryChipsRow(),
              const SizedBox(height: 28),
              if (featuredProducts.isNotEmpty) ...[
                _SectionHeader(title: 'Хіти клубу'),
                const SizedBox(height: 12),
                _HorizontalProductList(products: featuredProducts),
                const SizedBox(height: 28),
              ],
              if (newProducts.isNotEmpty) ...[
                _SectionHeader(title: 'Новинки'),
                const SizedBox(height: 12),
                _HorizontalProductList(products: newProducts),
                const SizedBox(height: 32),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: AppColors.heroCardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderGold, width: 1),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ТРІУМФ',
                        style: GoogleFonts.russoOne(
                          color: AppColors.textPrimary,
                          fontSize: 40,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'КЛУБНА ЕКІПІРОВКА',
                        style: GoogleFonts.rubik(
                          color: AppColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 200,
                    height: 42,
                    child: GradientButton(
                      onPressed: () => context.push('/shop/catalog'),
                      height: 42,
                      child: Text(
                        'Переглянути каталог',
                        style: GoogleFonts.rubik(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChipsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categories = ShopCategory.values;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () =>
                context.push('/shop/catalog?category=${cat.name}'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.borderSoft, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cat.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat.label,
                    style: GoogleFonts.rubik(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.rubik(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/shop/catalog'),
            child: Text(
              'Всі',
              style: GoogleFonts.rubik(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalProductList extends StatelessWidget {
  final List<ShopProduct> products;

  const _HorizontalProductList({required this.products});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _ShopProductCard(product: products[index]);
        },
      ),
    );
  }
}

class _ShopProductCard extends ConsumerWidget {
  final ShopProduct product;

  const _ShopProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl =
        product.imageUrls.isNotEmpty ? product.imageUrls.first : null;
    final imageHeight = 220 * 0.55;

    return GestureDetector(
      onTap: () => context.push('/shop/product/${product.id}'),
      child: Container(
        width: 160,
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSoft, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: imageUrl != null
                      ? _shopImage(
                          imageUrl,
                          width: 160,
                          height: imageHeight,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 160,
                          height: imageHeight,
                          color: AppColors.surface2,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.textSecondary,
                            size: 32,
                          ),
                        ),
                ),
                if (product.badge != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.badge!.color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.badge!.label,
                        style: GoogleFonts.rubik(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.rubik(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            '${product.price.toStringAsFixed(0)} ${product.currency}',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.rubik(
                              color: AppColors.accent,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${product.oldPrice!.toStringAsFixed(0)}',
                            style: GoogleFonts.rubik(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    GradientButton(
                      height: 30,
                      onPressed: () async {
                        final cartItem = CartItem(
                          id: '${product.id}_${DateTime.now().millisecondsSinceEpoch}',
                          productId: product.id,
                          quantity: 1,
                          priceSnapshot: product.price,
                          title: product.title,
                          imageUrl: product.imageUrls.isNotEmpty
                              ? product.imageUrls.first
                              : null,
                        );
                        await ref
                            .read(cartNotifierProvider.notifier)
                            .addItem(cartItem);
                        context.push('/shop/product/${product.id}');
                      },
                      child: Text(
                        'В кошик',
                        style: GoogleFonts.rubik(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
}

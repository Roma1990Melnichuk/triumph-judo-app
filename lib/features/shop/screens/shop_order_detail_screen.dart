import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:judo_app/core/constants/app_colors.dart';
import 'package:judo_app/core/models/cart_model.dart';
import 'package:judo_app/core/models/shop_order_model.dart';
import 'package:judo_app/features/shop/providers/cart_provider.dart';
import 'package:judo_app/features/shop/providers/order_provider.dart';
import 'package:judo_app/shared/widgets/gradient_button.dart';
import 'package:judo_app/shared/widgets/app_back_button.dart';

class ShopOrderDetailScreen extends ConsumerWidget {
  const ShopOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(shopOrderProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: orderAsync.when(
        loading: () => const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
        error: (e, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(context, null),
          body: const Center(
            child: Text(
              'Помилка завантаження замовлення',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ),
        ),
        data: (order) {
          if (order == null) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: _buildAppBar(context, null),
              body: const Center(
                child: Text(
                  'Замовлення не знайдено',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                ),
              ),
            );
          }
          return _OrderDetailBody(order: order, orderId: orderId);
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String? orderNumber) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: AppBackButton(onPressed: () => context.pop()),
      title: Text(
        orderNumber != null ? 'Замовлення #$orderNumber' : 'Замовлення',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.borderSoft),
      ),
    );
  }
}

class _OrderDetailBody extends ConsumerStatefulWidget {
  const _OrderDetailBody({required this.order, required this.orderId});

  final ShopOrder order;
  final String orderId;

  @override
  ConsumerState<_OrderDetailBody> createState() => _OrderDetailBodyState();
}

class _OrderDetailBodyState extends ConsumerState<_OrderDetailBody> {
  bool _reorderLoading = false;

  Future<void> _repeatOrder() async {
    setState(() => _reorderLoading = true);
    try {
      final cartNotifier = ref.read(cartNotifierProvider.notifier);
      for (final item in widget.order.items) {
        await cartNotifier.addItem(CartItem(
          id: '${item.productId}_${item.variantId ?? 'default'}',
          productId: item.productId,
          variantId: item.variantId,
          quantity: item.quantity,
          priceSnapshot: item.priceSnapshot,
          title: item.productTitle,
          imageUrl: item.imageUrl,
          size: item.size,
          color: item.color,
        ));
      }
      if (mounted) context.push('/shop/cart');
    } finally {
      if (mounted) setState(() => _reorderLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(onPressed: () => context.pop()),
        title: Text(
          'Замовлення #${order.orderNumber}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderSoft),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _StatusSection(order: order),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _ItemsSection(order: order),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _DeliveryPaymentCard(order: order),
            ),
          ),
          if (order.comment.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _CommentCard(comment: order.comment),
              ),
            ),
          if (order.adminComment != null && order.adminComment!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _AdminCommentCard(comment: order.adminComment!),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: GradientButton(
                onPressed: _reorderLoading ? null : _repeatOrder,
                isLoading: _reorderLoading,
                child: const Text(
                  'Повторити замовлення',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.order});

  final ShopOrder order;

  static const _steps = [
    ShopOrderStatus.newOrder,
    ShopOrderStatus.confirmed,
    ShopOrderStatus.preparing,
    ShopOrderStatus.waitingAtClub,
    ShopOrderStatus.delivering,
    ShopOrderStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    if (order.status == ShopOrderStatus.cancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Скасовано',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    final currentIndex = _steps.indexOf(order.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Статус замовлення',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ..._steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isDone = currentIndex > index;
            final isCurrent = currentIndex == index;
            final isLast = index == _steps.length - 1;

            return _StepRow(
              step: step,
              isDone: isDone,
              isCurrent: isCurrent,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  final ShopOrderStatus step;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color dotColor;
    final Widget dotChild;

    if (isDone) {
      dotColor = AppColors.success;
      dotChild = const Icon(Icons.check_rounded, color: Colors.white, size: 12);
    } else if (isCurrent) {
      dotColor = AppColors.primary;
      dotChild = Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      );
    } else {
      dotColor = AppColors.surface3;
      dotChild = const SizedBox.shrink();
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? Colors.transparent
                        : dotColor,
                    shape: BoxShape.circle,
                    gradient: isCurrent ? AppColors.ctaGradient : null,
                    border: (!isDone && !isCurrent)
                        ? Border.all(color: AppColors.surface3, width: 1.5)
                        : null,
                  ),
                  child: Center(child: dotChild),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDone ? AppColors.success.withValues(alpha: 0.5) : AppColors.surface3,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 3),
            child: Text(
              step.label,
              style: TextStyle(
                color: isCurrent
                    ? AppColors.textPrimary
                    : isDone
                        ? AppColors.success
                        : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({required this.order});

  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Text(
                  'Товари',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${order.itemCount} шт.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.borderSoft),
          ...order.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == order.items.length - 1;
            return Column(
              children: [
                _OrderItemRow(item: item),
                if (!isLast) Container(height: 1, color: AppColors.borderSoft),
              ],
            );
          }),
          Container(height: 1, color: AppColors.borderSoft),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                const Text(
                  'Разом',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${order.totalAmount.toStringAsFixed(0)} грн',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final ShopOrderItem item;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl;

    Widget imageWidget;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('assets/')) {
        imageWidget = Image.asset(
          imageUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        );
      } else {
        imageWidget = CachedNetworkImage(
          imageUrl: imageUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: AppColors.surface2,
            child: const Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 24),
          ),
          errorWidget: (_, __, ___) => Container(
            color: AppColors.surface2,
            child: const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary, size: 24),
          ),
        );
      }
    } else {
      imageWidget = Container(
        width: 60,
        height: 60,
        color: AppColors.surface2,
        child: const Icon(Icons.shopping_bag_outlined, color: AppColors.textSecondary, size: 24),
      );
    }

    final variantParts = <String>[];
    if (item.size != null && item.size!.isNotEmpty) variantParts.add(item.size!);
    if (item.color != null && item.color!.isNotEmpty) variantParts.add(item.color!);
    final variantLabel = variantParts.join(' / ');

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageWidget,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                if (variantLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    variantLabel,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '${item.quantity} × ${item.priceSnapshot.toStringAsFixed(0)} грн',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.subtotal.toStringAsFixed(0)} грн',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryPaymentCard extends StatelessWidget {
  const _DeliveryPaymentCard({required this.order});

  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Доставка та оплата',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: _deliveryIcon(order.deliveryMethod),
            label: 'Доставка',
            value: order.deliveryMethod.label,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: _paymentIcon(order.paymentMethod),
            label: 'Оплата',
            value: order.paymentMethod.label,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Отримувач',
            value: order.recipientName,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Телефон',
            value: order.recipientPhone,
          ),
        ],
      ),
    );
  }

  IconData _deliveryIcon(ShopDeliveryMethod method) {
    return switch (method) {
      ShopDeliveryMethod.pickupAtClub => Icons.store_outlined,
      ShopDeliveryMethod.fromCoach => Icons.sports_outlined,
      ShopDeliveryMethod.novaPost => Icons.local_shipping_outlined,
    };
  }

  IconData _paymentIcon(ShopPaymentMethod method) {
    return switch (method) {
      ShopPaymentMethod.online => Icons.credit_card_outlined,
      ShopPaymentMethod.cashAtClub => Icons.payments_outlined,
      ShopPaymentMethod.cardTransfer => Icons.swap_horiz_rounded,
    };
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final String comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textSecondary, size: 16),
              SizedBox(width: 8),
              Text(
                'Коментар',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminCommentCard extends StatelessWidget {
  const _AdminCommentCard({required this.comment});

  final String comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGold, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sports_outlined, color: AppColors.accent, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Повідомлення від тренера',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

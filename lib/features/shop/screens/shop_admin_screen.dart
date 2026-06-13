import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'package:judo_app/core/constants/app_colors.dart';
import 'package:judo_app/core/models/shop_order_model.dart';
import 'package:judo_app/core/models/shop_product_model.dart';
import 'package:judo_app/features/shop/providers/order_provider.dart';
import 'package:judo_app/features/shop/providers/shop_provider.dart';

class ShopAdminScreen extends ConsumerStatefulWidget {
  const ShopAdminScreen({super.key});

  @override
  ConsumerState<ShopAdminScreen> createState() => _ShopAdminScreenState();
}

class _ShopAdminScreenState extends ConsumerState<ShopAdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  ShopOrderStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Адмін-панель магазину',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'Замовлення'),
            Tab(text: 'Товари'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _OrdersTab(filterStatus: _filterStatus, onFilterChanged: (s) {
            setState(() => _filterStatus = s);
          }),
          const _ProductsTab(),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tab,
        builder: (_, __) {
          if (_tab.index != 1) return const SizedBox.shrink();
          return FloatingActionButton(
            backgroundColor: AppColors.fabBg,
            foregroundColor: AppColors.fabIcon,
            onPressed: () => context.push('/shop/admin/add-product'),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab({required this.filterStatus, required this.onFilterChanged});

  final ShopOrderStatus? filterStatus;
  final ValueChanged<ShopOrderStatus?> onFilterChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider);

    return ordersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text('Помилка: $e',
            style: const TextStyle(color: AppColors.textSecondary)),
      ),
      data: (orders) {
        final filtered = filterStatus == null
            ? orders
            : orders.where((o) => o.status == filterStatus).toList();

        return Column(
          children: [
            _OrderFilterChips(
              selected: filterStatus,
              onChanged: onFilterChanged,
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'Замовлень немає',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _OrderCard(order: filtered[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _OrderFilterChips extends StatelessWidget {
  const _OrderFilterChips({required this.selected, required this.onChanged});

  final ShopOrderStatus? selected;
  final ValueChanged<ShopOrderStatus?> onChanged;

  static const _filters = <MapEntry<ShopOrderStatus?, String>>[
    MapEntry(null, 'Всі'),
    MapEntry(ShopOrderStatus.newOrder, 'Нові'),
    MapEntry(ShopOrderStatus.confirmed, 'Підтверджено'),
    MapEntry(ShopOrderStatus.preparing, 'Готується'),
    MapEntry(ShopOrderStatus.completed, 'Завершено'),
    MapEntry(ShopOrderStatus.cancelled, 'Скасовано'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final entry = _filters[i];
          final isSelected = selected == entry.key;
          return GestureDetector(
            onTap: () => onChanged(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.borderSoft,
                ),
              ),
              child: Text(
                entry.value,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});

  final ShopOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd.MM.yyyy HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '№ ${order.orderNumber}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              fmt.format(order.createdAt),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.recipientName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Дзвінок: ${order.recipientPhone}'),
                    backgroundColor: AppColors.surface2,
                  ),
                );
              },
              child: Row(
                children: [
                  const Icon(Icons.phone_outlined,
                      size: 15, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text(
                    order.recipientPhone,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${order.itemCount} поз.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  '${order.totalAmount.toStringAsFixed(0)} ${order.currency}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            if (order.adminComment != null && order.adminComment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.adminComment!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (!order.status.isFinal)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.borderSoft),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () =>
                      _showStatusSheet(context, ref, order),
                  child: const Text(
                    'Змінити статус',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showStatusSheet(BuildContext context, WidgetRef ref, ShopOrder order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _StatusBottomSheet(order: order),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final ShopOrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusBottomSheet extends ConsumerStatefulWidget {
  const _StatusBottomSheet({required this.order});
  final ShopOrder order;

  @override
  ConsumerState<_StatusBottomSheet> createState() => _StatusBottomSheetState();
}

class _StatusBottomSheetState extends ConsumerState<_StatusBottomSheet> {
  late ShopOrderStatus _selected;
  final _commentCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.order.status;
    _commentCtrl.text = widget.order.adminComment ?? '';
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const statuses = ShopOrderStatus.values;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Змінити статус',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...statuses.map((s) {
            final isCurrent = s == widget.order.status;
            final isSelected = s == _selected;
            final isDisabled = s.isFinal && s != widget.order.status;

            return GestureDetector(
              onTap: isDisabled ? null : () => setState(() => _selected = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? s.color.withValues(alpha: 0.15)
                      : AppColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? s.color.withValues(alpha: 0.6)
                        : AppColors.borderSoft,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.label,
                        style: TextStyle(
                          color: isDisabled
                              ? AppColors.textSecondary.withValues(alpha: 0.4)
                              : isSelected
                                  ? s.color
                                  : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface3,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Поточний',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    if (isSelected && !isCurrent)
                      Icon(Icons.check_circle,
                          color: s.color, size: 18),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          TextField(
            controller: _commentCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Коментар адміна (необов\'язково)',
              hintStyle: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
              filled: true,
              fillColor: AppColors.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderSoft),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderSoft),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _saving || _selected == widget.order.status
                  ? null
                  : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Зберегти',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final comment = _commentCtrl.text.trim();
      await ref.read(orderNotifierProvider.notifier).updateStatus(
            widget.order.id,
            _selected,
            adminComment: comment.isEmpty ? null : comment,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ProductsTab extends ConsumerWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(shopProductsProvider);

    return productsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text('Помилка: $e',
            style: const TextStyle(color: AppColors.textSecondary)),
      ),
      data: (products) {
        if (products.isEmpty) {
          return const Center(
            child: Text(
              'Товарів немає',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          itemCount: products.length,
          itemBuilder: (_, i) => _ProductRow(product: products[i]),
        );
      },
    );
  }
}

class _ProductRow extends ConsumerWidget {
  const _ProductRow({required this.product});
  final ShopProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: product.imageUrls.isNotEmpty
                    ? (product.imageUrls.first.startsWith('assets/')
                        ? Image.asset(
                            product.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imageFallback(),
                          )
                        : CachedNetworkImage(
                            imageUrl: product.imageUrls.first,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _imagePlaceholder(),
                            errorWidget: (_, __, ___) => _imageFallback(),
                          ))
                    : _imageFallback(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.price.toStringAsFixed(0)} ${product.currency}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: product.isActive,
              activeThumbColor: AppColors.primary,
              onChanged: (val) {
                ref
                    .read(shopNotifierProvider.notifier)
                    .toggleActive(product.id, val);
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.textSecondary, size: 20),
              onPressed: () =>
                  context.push('/shop/admin/product/${product.id}/edit'),
              tooltip: 'Редагувати',
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() => Container(
        color: AppColors.surface2,
        child: const Icon(Icons.inventory_2_outlined,
            color: AppColors.textSecondary, size: 24),
      );

  Widget _imagePlaceholder() => Container(color: AppColors.surface2);
}

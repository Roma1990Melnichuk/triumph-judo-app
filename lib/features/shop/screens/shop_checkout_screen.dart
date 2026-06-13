import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:judo_app/core/constants/app_colors.dart';
import 'package:judo_app/core/models/cart_model.dart';
import 'package:judo_app/core/models/shop_order_model.dart';
import 'package:judo_app/features/shop/providers/cart_provider.dart';
import 'package:judo_app/features/shop/providers/order_provider.dart';
import 'package:judo_app/shared/widgets/gradient_button.dart';

class ShopCheckoutScreen extends ConsumerStatefulWidget {
  const ShopCheckoutScreen({super.key});

  @override
  ConsumerState<ShopCheckoutScreen> createState() => _ShopCheckoutScreenState();
}

class _ShopCheckoutScreenState extends ConsumerState<ShopCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _novaPostController = TextEditingController(); // Added for Nova Post branch
  final _commentController = TextEditingController();

  ShopDeliveryMethod _delivery = ShopDeliveryMethod.pickupAtClub;
  ShopPaymentMethod _payment = ShopPaymentMethod.cashAtClub;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _novaPostController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit(CartModel cart) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    String fullComment = _commentController.text.trim();
    if (_delivery == ShopDeliveryMethod.novaPost) {
      fullComment = 'НП: ${_novaPostController.text.trim()}\n$fullComment';
    }

    try {
      await ref.read(orderNotifierProvider.notifier).createOrder(
            items: cart.items,
            totalAmount: cart.total,
            delivery: _delivery,
            payment: _payment,
            recipientName: _nameController.text.trim(),
            recipientPhone: _phoneController.text.trim(),
            comment: fullComment,
          );
      await ref.read(cartNotifierProvider.notifier).clear();
      if (mounted) {
        context.pushReplacement('/shop/orders');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Помилка при оформленні: $e',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            backgroundColor: AppColors.surface2,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Оформлення замовлення',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: cartAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Помилка завантаження кошика',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        data: (cart) {
          if (cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      color: AppColors.textSecondary, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Кошик порожній',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text(
                      'Повернутись до магазину',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(label: 'Дані отримувача'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _nameController,
                    label: "Ім'я отримувача",
                    hint: 'Введіть ім\'я',
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Введіть ім'я отримувача";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Телефон',
                    hint: '+380XXXXXXXXX',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Введіть номер телефону';
                      }
                      final cleaned = v.trim().replaceAll(' ', '');
                      final phoneRegex = RegExp(r'^\+380\d{9}$');
                      if (!phoneRegex.hasMatch(cleaned)) {
                        return 'Формат: +380XXXXXXXXX';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _commentController,
                    label: 'Коментар',
                    hint: 'Необов\'язково',
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    validator: null,
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(label: 'Спосіб доставки'),
                  const SizedBox(height: 12),
                  _DeliverySelector(
                    selected: _delivery,
                    onChanged: (v) => setState(() => _delivery = v),
                  ),
                  if (_delivery == ShopDeliveryMethod.novaPost) ...[
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _novaPostController,
                      label: 'Місто та відділення НП',
                      hint: 'Київ, №125 або адреса',
                      validator: (v) {
                        if (_delivery == ShopDeliveryMethod.novaPost &&
                            (v == null || v.trim().isEmpty)) {
                          return 'Вкажіть дані для доставки';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  _SectionLabel(label: 'Спосіб оплати'),
                  const SizedBox(height: 12),
                  _PaymentSelector(
                    selected: _payment,
                    onChanged: (v) => setState(() => _payment = v),
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(label: 'Ваше замовлення'),
                  const SizedBox(height: 12),
                  _OrderSummaryCard(cart: cart),
                  const SizedBox(height: 24),
                  GradientButton(
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : () => _submit(cart),
                    child: const Text(
                      'Підтвердити замовлення',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.text3, fontSize: 14),
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _DeliverySelector extends StatelessWidget {
  const _DeliverySelector({
    required this.selected,
    required this.onChanged,
  });

  final ShopDeliveryMethod selected;
  final ValueChanged<ShopDeliveryMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DeliveryCard(
          method: ShopDeliveryMethod.pickupAtClub,
          icon: Icons.store_outlined,
          label: 'Забрати в клубі',
          description: 'Самовивіз з клубу "Тріумф"',
          selected: selected == ShopDeliveryMethod.pickupAtClub,
          onTap: () => onChanged(ShopDeliveryMethod.pickupAtClub),
        ),
        const SizedBox(height: 10),
        _DeliveryCard(
          method: ShopDeliveryMethod.fromCoach,
          icon: Icons.person_outline,
          label: 'Отримати у тренера',
          description: 'Тренер передасть на тренуванні',
          selected: selected == ShopDeliveryMethod.fromCoach,
          onTap: () => onChanged(ShopDeliveryMethod.fromCoach),
        ),
        const SizedBox(height: 10),
        _DeliveryCard(
          method: ShopDeliveryMethod.novaPost,
          icon: Icons.local_shipping_outlined,
          label: 'Доставка Новою Поштою',
          description: 'На відділення або адресна доставка',
          selected: selected == ShopDeliveryMethod.novaPost,
          onTap: () => onChanged(ShopDeliveryMethod.novaPost),
        ),
      ],
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
    required this.method,
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final ShopDeliveryMethod method;
  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(
                  color: AppColors.borderGold,
                  width: 1.5,
                )
              : Border.all(
                  color: AppColors.borderSoft,
                  width: 1,
                ),
        ),
        child: selected
            ? _gradientBorderWrap(
                child: _cardContent(icon, label, description, selected),
              )
            : _cardContent(icon, label, description, selected),
      ),
    );
  }

  Widget _gradientBorderWrap({required Widget child}) {
    return CustomPaint(
      painter: _GradientBorderPainter(radius: 14),
      child: child,
    );
  }

  Widget _cardContent(
    IconData icon,
    String label,
    String description,
    bool selected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : AppColors.surface3,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: selected ? AppColors.accent : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.textSecondary,
                width: 2,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.ctaGradient,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _PaymentSelector extends StatelessWidget {
  const _PaymentSelector({
    required this.selected,
    required this.onChanged,
  });

  final ShopPaymentMethod selected;
  final ValueChanged<ShopPaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PaymentCard(
          method: ShopPaymentMethod.cashAtClub,
          icon: Icons.payments_outlined,
          label: 'Готівка в клубі',
          description: 'Оплата при отриманні в клубі',
          selected: selected == ShopPaymentMethod.cashAtClub,
          disabled: false,
          onTap: () => onChanged(ShopPaymentMethod.cashAtClub),
        ),
        const SizedBox(height: 10),
        _PaymentCard(
          method: ShopPaymentMethod.cardTransfer,
          icon: Icons.credit_card_outlined,
          label: 'Переказ на картку',
          description: 'Банківський переказ за реквізитами',
          selected: selected == ShopPaymentMethod.cardTransfer,
          disabled: false,
          onTap: () => onChanged(ShopPaymentMethod.cardTransfer),
        ),
        const SizedBox(height: 10),
        _PaymentCard(
          method: ShopPaymentMethod.online,
          icon: Icons.language_outlined,
          label: 'Онлайн',
          description: 'Оплата карткою на сайті',
          selected: selected == ShopPaymentMethod.online,
          disabled: true,
          onTap: null,
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.method,
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final ShopPaymentMethod method;
  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        opacity: disabled ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(14),
            border: selected && !disabled
                ? Border.all(color: AppColors.borderGold, width: 1.5)
                : Border.all(color: AppColors.borderSoft, width: 1),
          ),
          child: selected && !disabled
              ? CustomPaint(
                  painter: _GradientBorderPainter(radius: 14),
                  child: _cardContent(),
                )
              : _cardContent(),
        ),
      ),
    );
  }

  Widget _cardContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected && !disabled
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : AppColors.surface3,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: selected && !disabled
                  ? AppColors.accent
                  : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: disabled
                            ? AppColors.textSecondary
                            : selected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (disabled) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface3,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.borderSoft, width: 1),
                        ),
                        child: const Text(
                          'Незабаром доступно',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (!disabled)
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.ctaGradient,
                        ),
                      ),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  const _GradientBorderPainter({required this.radius});
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    const gradient = AppColors.ctaGradient;
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.cart});
  final CartModel cart;

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
          ...cart.items.map((item) => _OrderItemRow(item: item)),
          if (cart.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                height: 1,
                color: AppColors.surface3,
              ),
            ),
          if (cart.discount > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Знижка',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '−${cart.discount.toStringAsFixed(0)} ₴',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Разом',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${cart.total.toStringAsFixed(0)} ₴',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (item.size != null) item.size!,
      if (item.color != null) item.color!,
    ].join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '×${item.quantity}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              Text(
                '${item.subtotal.toStringAsFixed(0)} ₴',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

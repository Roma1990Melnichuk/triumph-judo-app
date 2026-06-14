import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/membership_provider.dart';
import '../providers/tariff_provider.dart';
import '../utils/subscription_date_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CheckoutScreen
// ─────────────────────────────────────────────────────────────────────────────

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.planName,
    required this.amount,
    required this.childId,
    this.variantMultiplier = 1,
  });

  final String planName;
  final double amount;
  final String childId;
  final int variantMultiplier;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen>
    with SingleTickerProviderStateMixin {
  int _selectedPaymentIdx = 0;
  bool _isProcessing = false;
  final _promoCtrl = TextEditingController();
  int _discountPct = 0;
  String? _promoError;
  bool _promoApplied = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  static const List<_PaymentMethod> _methods = [
    _PaymentMethod(
      icon: Icons.credit_card,
      label: 'Банківська картка',
      subtitle: 'Visa, Mastercard, Apple Pay',
    ),
    _PaymentMethod(
      icon: Icons.apple,
      label: 'Apple Pay',
      subtitle: '',
    ),
    _PaymentMethod(
      icon: Icons.g_mobiledata,
      label: 'Google Pay',
      subtitle: '',
    ),
    _PaymentMethod(
      icon: Icons.account_balance,
      label: 'Готівка в клубі',
      subtitle: 'Оплата на місці',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  double get _finalAmount {
    if (_discountPct <= 0) return widget.amount;
    return (widget.amount * (100 - _discountPct) / 100).roundToDouble();
  }

  void _applyPromo() {
    final codes = ref.read(promoCodesProvider).asData?.value ?? [];
    final notifier = ref.read(tariffNotifierProvider.notifier);
    final found = notifier.validateCode(_promoCtrl.text, codes);
    setState(() {
      if (found != null) {
        _discountPct = found.discountPct;
        _promoApplied = true;
        _promoError = null;
      } else {
        _discountPct = 0;
        _promoApplied = false;
        _promoError = 'Невірний або недійсний промокод';
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _promoCtrl.dispose();
    super.dispose();
  }


  Future<void> _pay() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final now = DateTime.now();
    // FIN-01: if the child already has an active membership, extend from its
    // endDate so existing days are not lost.
    final currentMembership = ref.read(membershipByAthleteProvider(widget.childId)).asData?.value;
    final startDate = resolveSubscriptionStart(
      now: now,
      isCurrentlyActive: currentMembership?.isActive ?? false,
      currentEndDate: currentMembership?.endDate,
    );
    final endDate = computeSubscriptionEndDate(widget.planName, widget.variantMultiplier, startDate);

    try {
      await ref.read(membershipNotifierProvider.notifier).setMembership(
            athleteId: widget.childId,
            planName: widget.planName,
            startDate: startDate,
            endDate: endDate,
            amount: _finalAmount,
          );

      if (mounted) {
        context.go('/payment-success', extra: {
          'planName': widget.planName,
          'amount': _finalAmount,
          'childId': widget.childId,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка оплати: $e'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Оформлення',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Plan summary card ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surface3),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.40)),
                          ),
                          child: const Center(
                            child: Text(
                              '⭐',
                              style: TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.planName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Членство в клубі TRIUMPH',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${widget.amount.toStringAsFixed(0)}₴',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Payment methods ──────────────────────────────────────
                  const Text(
                    'СПОСІБ ОПЛАТИ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surface3),
                    ),
                    child: Column(
                      children: List.generate(
                        _methods.length,
                        (i) => _PaymentTile(
                          method: _methods[i],
                          selected: i == _selectedPaymentIdx,
                          isLast: i == _methods.length - 1,
                          onTap: () =>
                              setState(() => _selectedPaymentIdx = i),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Promo code ───────────────────────────────────────────
                  const Text(
                    'ПРОМОКОД',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoCtrl,
                          enabled: !_promoApplied,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Введіть промокод',
                            errorText: _promoError,
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.surface3),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.surface3),
                            ),
                            suffixIcon: _promoApplied
                                ? GestureDetector(
                                    onTap: () => setState(() {
                                      _promoApplied = false;
                                      _discountPct = 0;
                                      _promoCtrl.clear();
                                      _promoError = null;
                                    }),
                                    child: const Icon(Icons.close,
                                        size: 18, color: AppColors.textSecondary),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _promoApplied ? null : _applyPromo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _promoApplied
                                ? AppColors.success
                                : AppColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            _promoApplied ? 'Застосовано' : 'Застосувати',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_promoApplied) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 16, color: AppColors.success),
                          const SizedBox(width: 8),
                          Text(
                            'Знижка $_discountPct% застосована',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Payment details ──────────────────────────────────────
                  const Text(
                    'ДЕТАЛІ ОПЛАТИ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surface3),
                    ),
                    child: Column(
                      children: [
                        _DetailRow(
                            label: 'Абонемент', value: widget.planName),
                        const SizedBox(height: 10),
                        _DetailRow(
                          label: 'Повна ціна',
                          value: '${widget.amount.toStringAsFixed(0)}₴',
                          valueColor: AppColors.textPrimary,
                        ),
                        if (_promoApplied) ...[
                          const SizedBox(height: 10),
                          _DetailRow(
                            label: 'Знижка $_discountPct%',
                            value: '−${(widget.amount - _finalAmount).toStringAsFixed(0)}₴',
                            valueColor: AppColors.success,
                          ),
                        ],
                        const Divider(
                            height: 20, color: AppColors.surface3),
                        _DetailRow(
                          label: 'До сплати',
                          value: '${_finalAmount.toStringAsFixed(0)}₴',
                          valueColor: AppColors.accent,
                          bold: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Trust badges ─────────────────────────────────────────
                  const _TrustBadgesRow(),
                ],
              ),
            ),
          ),

          // ── Bottom pay button ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                  top: BorderSide(color: AppColors.surface3, width: 1)),
            ),
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Transform.scale(
                scale: _isProcessing ? 1.0 : _pulseAnim.value,
                child: child,
              ),
              child: GestureDetector(
                onTap: _isProcessing ? null : _pay,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: _isProcessing
                        ? const LinearGradient(
                            colors: [AppColors.surface2, AppColors.surface3])
                        : AppColors.ctaGradient,
                    boxShadow: _isProcessing
                        ? []
                        : [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.40),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Center(
                    child: _isProcessing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Оплатити ${_finalAmount.toStringAsFixed(0)}₴',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment method data
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentMethod {
  final IconData icon;
  final String label;
  final String subtitle;

  const _PaymentMethod({
    required this.icon,
    required this.label,
    required this.subtitle,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment tile
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.method,
    required this.selected,
    required this.isLast,
    required this.onTap,
  });

  final _PaymentMethod method;
  final bool selected;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.surface3, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.55)
                      : AppColors.surface3,
                ),
              ),
              child: Icon(
                method.icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: TextStyle(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (method.subtitle.isNotEmpty)
                    Text(
                      method.subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.surface3,
                  width: 2,
                ),
                color: selected ? AppColors.primary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 11)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail row
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: bold ? 16 : 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trust badges row
// ─────────────────────────────────────────────────────────────────────────────

class _TrustBadgesRow extends StatelessWidget {
  const _TrustBadgesRow();

  static const List<(IconData, String)> _badges = [
    (Icons.lock_outline, 'Безпечна оплата'),
    (Icons.bolt_outlined, 'Миттєвий доступ'),
    (Icons.cancel_outlined, 'Скасування будь-який час'),
    (Icons.headset_mic_outlined, 'Підтримка 24/7'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _badges
          .map((b) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surface3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(b.$1, size: 13, color: AppColors.success),
                    const SizedBox(width: 5),
                    Text(
                      b.$2,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

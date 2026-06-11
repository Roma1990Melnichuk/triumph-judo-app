import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/membership_provider.dart';
import '../utils/subscription_date_utils.dart';
import '../../../shared/widgets/triumph_icon.dart';

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

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }


  Future<void> _pay() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final now = DateTime.now();
    // FIN-01: if the child already has an active membership, extend from its
    // endDate so existing days are not lost.
    final currentMembership = ref.read(membershipByAthleteProvider(widget.childId)).value;
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
            amount: widget.amount,
          );

      if (mounted) {
        context.go('/payment-success', extra: {
          'planName': widget.planName,
          'amount': widget.amount,
          'childId': widget.childId,
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Помилка оплати. Спробуйте ще раз.'),
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
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn),
                          child: TriumphIcon(TIcon.back, size: 22),
                        ),
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
                          label: 'Сума',
                          value: '${widget.amount.toStringAsFixed(0)}₴',
                          valueColor: AppColors.textPrimary,
                        ),
                        const Divider(
                            height: 20, color: AppColors.surface3),
                        _DetailRow(
                          label: 'До сплати',
                          value: '${widget.amount.toStringAsFixed(0)}₴',
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
                            'Оплатити ${widget.amount.toStringAsFixed(0)}₴',
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

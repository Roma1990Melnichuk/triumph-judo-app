import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/triumph_icon.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TariffData — simple data class for a membership plan
// ─────────────────────────────────────────────────────────────────────────────

class TariffData {
  final String name;
  final String description;
  final String iconEmoji;
  final String badge;
  final double price;
  final double? oldPrice;

  const TariffData({
    required this.name,
    required this.description,
    required this.iconEmoji,
    required this.badge,
    required this.price,
    this.oldPrice,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// MembershipDetailScreen
// ─────────────────────────────────────────────────────────────────────────────

class MembershipDetailScreen extends StatefulWidget {
  const MembershipDetailScreen({
    super.key,
    required this.tariff,
    required this.childId,
  });

  final TariffData tariff;
  final String childId;

  @override
  State<MembershipDetailScreen> createState() => _MembershipDetailScreenState();
}

class _MembershipDetailScreenState extends State<MembershipDetailScreen> {
  int _selectedVariantIdx = 1; // default to middle variant

  // Build 3 plan variants: single, same, or bundled
  List<_PlanVariant> get _variants {
    final t = widget.tariff;
    final base = t.price;
    return [
      _PlanVariant(
        label: '${t.name} × 1',
        price: base,
        description: t.description,
      ),
      _PlanVariant(
        label: '${t.name} × 2',
        price: base * 2 * 0.95,
        oldPrice: base * 2,
        description: '5% економії при подвійній покупці',
        savingLabel: '-5%',
      ),
      _PlanVariant(
        label: '${t.name} × 3',
        price: base * 3 * 0.90,
        oldPrice: base * 3,
        description: '10% економії при потрійній покупці',
        savingLabel: '-10%',
      ),
    ];
  }

  static const List<String> _features = [
    'Необмежені тренування',
    'Доступ до всіх груп',
    'Участь у турнірах',
    'Відстеження прогресу',
    'Пріоритетний запис на змагання',
    'Спеціальні пропозиції клубу',
  ];

  @override
  Widget build(BuildContext context) {
    final t = widget.tariff;
    final variants = _variants;
    final selected = variants[_selectedVariantIdx];
    final hasDiscount = t.oldPrice != null;
    final discountPct = hasDiscount
        ? (((t.oldPrice! - t.price) / t.oldPrice!) * 100).round()
        : 0;

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
                  Expanded(
                    child: Text(
                      t.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
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
                  // ── Hero card ──────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: AppColors.heroCardGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.iconEmoji,
                              style: const TextStyle(fontSize: 40),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (t.badge.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      margin: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.20),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        t.badge,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    t.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t.description,
                                    style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.75),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${t.price.toStringAsFixed(0)}₴',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (hasDiscount) ...[
                              const SizedBox(width: 10),
                              Text(
                                '${t.oldPrice!.toStringAsFixed(0)}₴',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.50),
                                  fontSize: 16,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.success
                                      .withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.success
                                        .withValues(alpha: 0.55),
                                  ),
                                ),
                                child: Text(
                                  '-$discountPct%',
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Features list ─────────────────────────────────────────
                  const Text(
                    'ЩО ВКЛЮЧЕНО',
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
                      children: _features
                          .map((f) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      f,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Variants swipeable ─────────────────────────────────────
                  const Text(
                    'ВАРІАНТИ ПЛАНУ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 120,
                    child: PageView.builder(
                      controller: PageController(
                        initialPage: _selectedVariantIdx,
                        viewportFraction: 0.82,
                      ),
                      itemCount: variants.length,
                      onPageChanged: (i) =>
                          setState(() => _selectedVariantIdx = i),
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _VariantCard(
                          variant: variants[i],
                          selected: i == _selectedVariantIdx,
                          onTap: () =>
                              setState(() => _selectedVariantIdx = i),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Dots indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      variants.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _selectedVariantIdx ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _selectedVariantIdx
                              ? AppColors.accent
                              : AppColors.surface3,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom CTA ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                  top: BorderSide(
                      color: AppColors.surface3, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'До оплати:',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${selected.price.toStringAsFixed(0)}₴',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _CtaButton(
                  label: 'Продовжити →',
                  onTap: () => context.push(
                    '/checkout',
                    extra: {
                      'planName': widget.tariff.name,
                      'amount': selected.price,
                      'childId': widget.childId,
                      'variantMultiplier': _selectedVariantIdx + 1,
                    },
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

// ─────────────────────────────────────────────────────────────────────────────
// Plan variant data
// ─────────────────────────────────────────────────────────────────────────────

class _PlanVariant {
  final String label;
  final double price;
  final double? oldPrice;
  final String description;
  final String savingLabel;

  const _PlanVariant({
    required this.label,
    required this.price,
    this.oldPrice,
    required this.description,
    this.savingLabel = '',
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Variant card
// ─────────────────────────────────────────────────────────────────────────────

class _VariantCard extends StatelessWidget {
  const _VariantCard({
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  final _PlanVariant variant;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surface3,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    variant.label,
                    style: TextStyle(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (variant.savingLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      variant.savingLabel,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${variant.price.toStringAsFixed(0)}₴',
              style: TextStyle(
                color: selected ? AppColors.accent : AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              variant.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA button
// ─────────────────────────────────────────────────────────────────────────────

class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: AppColors.ctaGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ROUTES TO ADD IN app.dart:
// GoRoute(path: '/abonements', pageBuilder: (_, s) => _fadeSlide(s, MembershipScreen(childId: (s.extra as Map?)?['childId'] ?? '')))
// GoRoute(path: '/abonements/detail', pageBuilder: (_, s) => _fadeSlide(s, MembershipDetailScreen(tariff: (s.extra as Map)['tariff'] as TariffData, childId: (s.extra as Map)['childId'] as String)))
// GoRoute(path: '/checkout', pageBuilder: (_, s) => _fadeSlide(s, CheckoutScreen(planName: (s.extra as Map)['planName'] as String, amount: (s.extra as Map)['amount'] as double, childId: (s.extra as Map)['childId'] as String)))
// GoRoute(path: '/payment-success', pageBuilder: (_, s) => _fadeScale(s, PaymentSuccessScreen(planName: (s.extra as Map)['planName'] as String, amount: (s.extra as Map)['amount'] as double, childId: (s.extra as Map)['childId'] as String)))
// GoRoute(path: '/my-abonements', pageBuilder: (_, s) => _fadeSlide(s, MyMembershipsScreen(childId: (s.extra as Map?)?['childId'] ?? '')))

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/membership_model.dart';
import '../providers/membership_provider.dart';
import '../providers/tariff_provider.dart';
import '../models/tariff_plan.dart';
import '../../../shared/widgets/app_back_button.dart';
import 'membership_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MembershipScreen — Tariff catalog
// ─────────────────────────────────────────────────────────────────────────────

class MembershipScreen extends ConsumerWidget {
  const MembershipScreen({super.key, required this.childId});

  final String childId;

  static TariffData _planToTariffData(TariffPlan p) {
    const icons = ['⭐', '🥋', '🏆', '💎', '🔱', '👑'];
    final idx = TariffPlan.defaults.indexWhere((d) => d.name == p.name);
    return TariffData(
      name: p.name,
      description: _descriptionFor(p),
      iconEmoji: (idx >= 0 && idx < icons.length) ? icons[idx] : '🏅',
      badge: p.badge,
      price: p.price,
      oldPrice: p.oldPrice,
    );
  }

  static String _descriptionFor(TariffPlan p) {
    if (p.days == 1) return 'Одне тренування без зобов\'язань';
    if (p.days <= 7) return 'Необмежені тренування протягом тижня';
    if (p.days <= 30) return 'Повний доступ на місяць';
    if (p.days <= 90) return 'Квартальний абонемент з економією';
    if (p.days <= 180) return 'Півроку без перерв у тренуваннях';
    return 'Річний абонемент — максимальна вигода';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipAsync = ref.watch(membershipByAthleteProvider(childId));
    final plansAsync = ref.watch(tariffPlansProvider);
    final tariffs = (plansAsync.asData?.value ?? TariffPlan.defaults)
        .map(_planToTariffData)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  AppBackButton(onPressed: () => context.pop()),
                  const SizedBox(width: 12),
                  const Text(
                    'Абонементи',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            // ── Top banner ──────────────────────────────────────────────────
            _TopBanner(),

            const SizedBox(height: 16),

            // ── Current membership compact card ─────────────────────────────
            membershipAsync.when(
              loading: () => _skeletonCard(),
              error: (_, __) => const SizedBox.shrink(),
              data: (m) => _CompactMembershipCard(membership: m, childId: childId),
            ),

            const SizedBox(height: 24),

            // ── Available tariffs ──────────────────────────────────────────
            const Text(
              'ДОСТУПНІ АБОНЕМЕНТИ',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),

            const SizedBox(height: 12),

            ...tariffs.map((t) => _TariffTile(
                  tariff: t,
                  onTap: () => context.push(
                    '/abonements/detail',
                    extra: {'tariff': t, 'childId': childId},
                  ),
                )),
          ],
        ),
      ),
      ),
    ],
  ),
  ),
    );
  }

  Widget _skeletonCard() => Container(
        height: 90,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surface3),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Top banner
// ─────────────────────────────────────────────────────────────────────────────

class _TopBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6A00), Color(0xFFFFD21A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Тренуйся більше',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'досягай швидше!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Знижки до 33% на довгострокові плани',
                  style: TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '−33%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact membership status card
// ─────────────────────────────────────────────────────────────────────────────

class _CompactMembershipCard extends StatelessWidget {
  const _CompactMembershipCard({
    required this.membership,
    required this.childId,
  });

  final MembershipModel? membership;
  final String childId;

  @override
  Widget build(BuildContext context) {
    if (membership == null) {
      return _noMembershipTile(context);
    }
    final m = membership!;
    if (m.isExpired) return _expiredTile(context, m);
    if (m.isExpiringSoon) return _expiringTile(context, m);
    return _activeTile(context, m);
  }

  Widget _activeTile(BuildContext context, MembershipModel m) {
    final endDateStr = DateFormat('dd.MM.yyyy', 'uk').format(m.endDate);
    final totalDays = m.endDate.difference(m.startDate).inDays;
    final usedDays = totalDays - m.daysRemaining;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: AppColors.heroCardGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.emoji_events_rounded, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.planName.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'До $endDateStr · ${m.daysRemaining} ${_dayWord(m.daysRemaining)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.55)),
                ),
                child: const Text(
                  'Активний',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: m.progressPercent,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$usedDays / $totalDays дн.',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // CTA buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push(
                    '/abonements/detail',
                    extra: {
                      'tariff': TariffData(
                        name: m.planName,
                        description: 'Продовження поточного абонемента',
                        iconEmoji: '🏆',
                        badge: '',
                        price: m.amount,
                      ),
                      'childId': childId,
                    },
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Продовжити', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push(
                    '/abonements/detail',
                    extra: {
                      'tariff': TariffData(
                        name: m.planName,
                        description: 'Продовження поточного абонемента',
                        iconEmoji: '🏆',
                        badge: '',
                        price: m.amount,
                      ),
                      'childId': childId,
                    },
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Оплатити', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _expiringTile(BuildContext context, MembershipModel m) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surface,
        border: Border.all(
            color: AppColors.orange.withValues(alpha: 0.65), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.orange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.planName.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Залишилось ${m.daysRemaining} ${_dayWord(m.daysRemaining)}',
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'Скоро закінчиться',
            style: TextStyle(
              color: AppColors.orange,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _expiredTile(BuildContext context, MembershipModel m) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surface,
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.cancel_outlined,
              color: AppColors.primary.withValues(alpha: 0.80), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.planName.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Абонемент завершено',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'Прострочений',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noMembershipTile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surface,
        border: Border.all(color: AppColors.surface3),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.emoji_events_outlined, size: 20, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'У вас немає активного абонемента',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tariff tile
// ─────────────────────────────────────────────────────────────────────────────

class _TariffTile extends StatelessWidget {
  const _TariffTile({required this.tariff, required this.onTap});

  final TariffData tariff;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = tariff.oldPrice != null;
    final discountPct = hasDiscount
        ? (((tariff.oldPrice! - tariff.price) / tariff.oldPrice!) * 100)
            .round()
        : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surface3),
        ),
        child: Row(
          children: [
            // Emoji icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surface3),
              ),
              child: Center(
                child: Text(
                  tariff.iconEmoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Name + price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tariff.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (tariff.badge.isNotEmpty) ...[
                        const SizedBox(width: 7),
                        _Badge(label: tariff.badge),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${tariff.price.toStringAsFixed(0)}₴',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${tariff.oldPrice!.toStringAsFixed(0)}₴',
                          style: TextStyle(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.60),
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '-$discountPct%',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge chip
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;

  Color get _color {
    switch (label) {
      case 'Популярний':
        return AppColors.primary;
      case 'Вигідний':
        return AppColors.accent;
      case 'VIP':
        return const Color(0xFF9B59B6);
      case 'Новинка':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.50)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ukrainian day word helper
// ─────────────────────────────────────────────────────────────────────────────

String _dayWord(int days) {
  if (days % 10 == 1 && days % 100 != 11) { return 'день'; }
  if (days % 10 >= 2 &&
      days % 10 <= 4 &&
      (days % 100 < 10 || days % 100 >= 20)) { return 'дні'; }
  return 'днів';
}

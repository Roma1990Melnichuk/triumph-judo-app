import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/membership_model.dart';
import '../providers/membership_provider.dart';
import '../../../shared/widgets/triumph_emblem.dart';
import '../../../shared/widgets/triumph_icon.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Premium Academy Pass hero card — for parent/athlete home screen
// ─────────────────────────────────────────────────────────────────────────────

class AcademyPassCard extends ConsumerStatefulWidget {
  const AcademyPassCard({super.key, required this.childId});

  final String childId;

  @override
  ConsumerState<AcademyPassCard> createState() => _AcademyPassCardState();
}

class _AcademyPassCardState extends ConsumerState<AcademyPassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(membershipByAthleteProvider(widget.childId));
    return async.when(
      loading: () => _skeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (m) {
        if (m == null) return _emptyCard(context);
        if (m.isExpired) return _expiredCard(context, m);
        if (m.isExpiringSoon) return _expiringCard(context, m);
        return _activeCard(context, m);
      },
    );
  }

  Widget _skeleton() => Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surface3),
        ),
      );

  // ── STATE 4: NO MEMBERSHIP ────────────────────────────────────────────────
  Widget _emptyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.surface3,
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surface3),
              ),
              child: const ColorFiltered(
                colorFilter: ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn),
                child: TriumphIcon(TIcon.trophy, size: 22),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'МІЙ АБОНЕМЕНТ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'У вас немає активного абонемента',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _OutlinedBtn(
              label: 'Обрати абонемент',
              onTap: () => context.push('/abonements'),
            ),
          ),
        ],
      ),
    );
  }

  // ── STATE 1: ACTIVE ───────────────────────────────────────────────────────
  Widget _activeCard(BuildContext context, MembershipModel m) {
    final totalDays =
        m.endDate.difference(m.startDate).inDays.clamp(1, 99999);
    final endDateStr = DateFormat('dd.MM.yyyy', 'uk').format(m.endDate);

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Column(
        children: [
          GestureDetector(
            onTap: () => context.push('/membership/${widget.childId}'),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(children: [
                  // Background gradient
                  Container(
                    decoration: const BoxDecoration(
                        gradient: AppColors.heroCardGradient),
                  ),
                  // Shimmer sweep
                  Positioned.fill(
                    child: ShaderMask(
                      shaderCallback: (b) => LinearGradient(
                        begin: Alignment(-1 + _shimmer.value * 3, 0),
                        end: Alignment(0 + _shimmer.value * 3, 0),
                        colors: const [
                          Colors.transparent,
                          Color(0x0DFFFFFF),
                          Colors.transparent,
                        ],
                      ).createShader(b),
                      child: Container(color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: label + status badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'МІЙ АБОНЕМЕНТ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.8,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color:
                                        AppColors.success.withValues(alpha: 0.60),
                                    width: 1),
                              ),
                              child: const Text(
                                'Активний',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Plan name + emblem row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.planName.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Повний доступ до всіх тренувань',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.72),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 2),
                              ),
                              child: const TriumphEmblem(size: 44),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Days remaining label
                        Text(
                          'Залишилось ${m.daysRemaining} ${_dayWord(m.daysRemaining)}',
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 1.0 - (m.daysRemaining / totalDays).clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.20),
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.orange),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Date row
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.70)),
                            const SizedBox(width: 5),
                            Text(
                              'До $endDateStr',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.80),
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => context
                                  .push('/membership/${widget.childId}'),
                              child: const Text(
                                'Деталі →',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Two buttons
                        Row(children: [
                          Expanded(
                            child: _OutlinedBtn(
                              label: 'Продовжити',
                              onTap: () => context.push(
                                  '/membership/${widget.childId}'),
                              small: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _GradientBtn(
                              label: 'Оплатити',
                              onTap: () => context.push(
                                  '/abonements'),
                              small: true,
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Benefit tiles
          _BenefitTilesRow(),
        ],
      ),
    );
  }

  // ── STATE 2: EXPIRING ─────────────────────────────────────────────────────
  Widget _expiringCard(BuildContext context, MembershipModel m) {
    final totalDays =
        m.endDate.difference(m.startDate).inDays.clamp(1, 99999);
    final endDateStr = DateFormat('dd.MM.yyyy', 'uk').format(m.endDate);

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Column(
        children: [
          GestureDetector(
            onTap: () => context.push('/membership/${widget.childId}'),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.70), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orange.withValues(alpha: 0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(children: [
                  Container(
                    decoration: const BoxDecoration(
                        gradient: AppColors.heroCardGradient),
                  ),
                  // Orange tint overlay
                  Container(
                      color: const Color(0xFFFF8A00).withValues(alpha: 0.12)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Warning banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.orange.withValues(alpha: 0.50)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 15, color: AppColors.orange),
                            const SizedBox(width: 7),
                            const Text(
                              'Абонемент скоро закінчиться',
                              style: TextStyle(
                                color: AppColors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ]),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.planName.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Залишилось ${m.daysRemaining} ${_dayWord(m.daysRemaining)}',
                                    style: const TextStyle(
                                      color: AppColors.orange,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.orange.withValues(alpha: 0.40),
                                    width: 2),
                              ),
                              child: const TriumphEmblem(size: 44),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 1.0 -
                                (m.daysRemaining / totalDays).clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.20),
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.orange),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(children: [
                          Icon(Icons.calendar_today,
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.70)),
                          const SizedBox(width: 5),
                          Text(
                            'До $endDateStr',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.80),
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () =>
                                context.push('/membership/${widget.childId}'),
                            child: const Text(
                              'Деталі →',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ]),

                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,
                          child: _OrangeGradientBtn(
                            label: 'Продовжити абонемент',
                            onTap: () => context.push('/abonements'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _BenefitTilesRow(),
        ],
      ),
    );
  }

  // ── STATE 3: EXPIRED ──────────────────────────────────────────────────────
  Widget _expiredCard(BuildContext context, MembershipModel m) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => context.push('/membership/${widget.childId}'),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.55), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A0202), Color(0xFF2A0505)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'МІЙ АБОНЕМЕНТ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.50),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.8,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.55),
                                  width: 1),
                            ),
                            child: const Text(
                              'Прострочений',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.planName.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.60),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Абонемент завершено',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Прострочено ${m.daysExpiredAgo} ${_dayWord(m.daysExpiredAgo)} тому',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.50),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.30),
                                  width: 2),
                            ),
                            child: Opacity(
                              opacity: 0.55,
                              child: const TriumphEmblem(size: 44),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: _RedBtn(
                          label: 'Відновити абонемент',
                          onTap: () => context.push('/abonements'),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _BenefitTilesRow(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Benefit tiles row
// ─────────────────────────────────────────────────────────────────────────────

class _BenefitTilesRow extends StatelessWidget {
  static const _tiles = [
    (tIcon: TIcon.security,      label: 'Доступ до всіх груп'),
    (tIcon: TIcon.statistics,    label: 'Відстеження прогресу'),
    (tIcon: TIcon.tournament,    label: 'Участь у турнірах'),
    (tIcon: TIcon.achievements,  label: 'Рейтинги та досягнення'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _tiles
          .map((t) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surface3),
                  ),
                  child: Column(children: [
                    ColorFiltered(
                      colorFilter: const ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
                      child: TriumphIcon(t.tIcon, size: 18),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      t.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ]),
                ),
              ))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable buttons
// ─────────────────────────────────────────────────────────────────────────────

class _OutlinedBtn extends StatelessWidget {
  const _OutlinedBtn(
      {required this.label, required this.onTap, this.small = false});
  final String label;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: small ? 9 : 12, horizontal: small ? 10 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _GradientBtn extends StatelessWidget {
  const _GradientBtn(
      {required this.label, required this.onTap, this.small = false});
  final String label;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: small ? 9 : 12, horizontal: small ? 10 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: AppColors.ctaGradient,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _OrangeGradientBtn extends StatelessWidget {
  const _OrangeGradientBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6A00), Color(0xFFFFD21A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RedBtn extends StatelessWidget {
  const _RedBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primary.withValues(alpha: 0.18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.60)),
        ),
        child: const Text(
          'Відновити абонемент',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Team Membership Overview card — for coach home screen
// ─────────────────────────────────────────────────────────────────────────────

class TeamMembershipCard extends ConsumerWidget {
  const TeamMembershipCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(membershipSummaryProvider);

    return GestureDetector(
      onTap: () => context.go('/team'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.surface3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const ColorFiltered(
                      colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                      child: TriumphIcon(TIcon.trophy, size: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Абонементи',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ]),
                const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary, size: 18),
              ],
            ),
            const SizedBox(height: 14),
            Row(children: [
              _SummaryTile(
                count: summary.active,
                label: 'Активних',
                color: const Color(0xFF27AE60),
              ),
              const SizedBox(width: 8),
              _SummaryTile(
                count: summary.expiringSoon,
                label: 'Закінч.',
                color: AppColors.orange,
              ),
              const SizedBox(width: 8),
              _SummaryTile(
                count: summary.expired,
                label: 'Прострочених',
                color: AppColors.primary,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ]),
      ),
    );
  }
}

String _dayWord(int days) {
  if (days % 10 == 1 && days % 100 != 11) return 'день';
  if (days % 10 >= 2 &&
      days % 10 <= 4 &&
      (days % 100 < 10 || days % 100 >= 20)) return 'дні';
  return 'днів';
}

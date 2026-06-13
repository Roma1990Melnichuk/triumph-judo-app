import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../team/providers/children_provider.dart';
import '../providers/streak_provider.dart';
import '../../../shared/widgets/triumph_icon.dart';

class JourneyHomeWidget extends ConsumerWidget {
  const JourneyHomeWidget({super.key});

  static const _dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider).asData?.value;
    if (user == null || user.isCoach) return const SizedBox.shrink();

    final streakAsync = ref.watch(streakDataProvider);
    final message = ref.watch(dailyMessageProvider);
    final weekActivity = ref.watch(weekActivityProvider);

    final coachId = _coachIdFrom(ref);
    final isLoading = (coachId != null && coachId.isNotEmpty)
        ? ref.watch(coachSessionsProvider(coachId)).isLoading
        : ref.watch(allChildrenProvider).isLoading;

    return GestureDetector(
      onTap: () => context.push('/journey'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0808), Color(0xFF2A0A0A), Color(0xFF0D0D0D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: isLoading ? _buildSkeleton() : _buildContent(context, ref, streakAsync, message, weekActivity),
      ),
    );
  }

  String? _coachIdFrom(WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider).asData?.value;
    if (user == null || user.isCoach) return null;
    final childId = user.childIds.firstOrNull ?? user.childId;
    if (childId == null) return null;
    final allChildren = ref.watch(allChildrenProvider).asData?.value ?? [];
    return allChildren.where((c) => c.id == childId).firstOrNull?.coachId;
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _shimmerBox(width: 160, height: 32),
            const Spacer(),
            _shimmerBox(width: 80, height: 80),
          ]),
          const SizedBox(height: 12),
          _shimmerBox(width: double.infinity, height: 14),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (_) => _shimmerBox(width: 32, height: 40)),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface3,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    StreakData streak,
    String message,
    List<bool> weekActivity,
  ) {
    final now = DateTime.now();
    final todayIndex = now.weekday - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero section ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Streak counter
                    Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [AppColors.orange, AppColors.orange],
                          ).createShader(b),
                          blendMode: BlendMode.srcATop,
                          child: const TriumphIcon(TIcon.motivation, size: 22),
                        ),
                        const SizedBox(width: 8),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${streak.current} ',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: streak.current >= 7
                                      ? AppColors.accent
                                      : AppColors.orange,
                                  height: 1.0,
                                ),
                              ),
                              const TextSpan(
                                text: 'днів\nпоспіль',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      streak.current > 0 ? 'Твій шлях триває' : 'Почни свій шлях',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Quote
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '"',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 0.9,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Judoka icon with glow
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.orange.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                        radius: 0.8,
                      ),
                    ),
                  ),
                  Builder(builder: (context) {
                    final color = streak.current >= 30
                        ? AppColors.accent
                        : streak.current >= 7
                            ? AppColors.orange
                            : AppColors.textSecondary;
                    return ShaderMask(
                      shaderCallback: (b) =>
                          LinearGradient(colors: [color, color]).createShader(b),
                      blendMode: BlendMode.srcATop,
                      child: const TriumphIcon(TIcon.athlete, size: 72),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Activity stats ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _StatPill(label: 'Серія', value: '${streak.current}'),
              const SizedBox(width: 8),
              _StatPill(label: 'Тренувань', value: '${streak.total}'),
              const SizedBox(width: 8),
              _StatPill(label: 'Найкраща', value: '${streak.best}'),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Week calendar ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final isToday = i == todayIndex;
              final trained = i < weekActivity.length ? weekActivity[i] : false;
              final isFuture = i > todayIndex;
              return _DayCircle(
                label: _dayLabels[i],
                trained: trained,
                isToday: isToday,
                isFuture: isFuture,
              );
            }),
          ),
        ),

        const SizedBox(height: 14),

        // ── CTA button ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            width: double.infinity,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppColors.ctaGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/journey'),
                borderRadius: BorderRadius.circular(12),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Переглянути шлях',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stat pill ─────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surface3),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Day circle ────────────────────────────────────────────────────────────────

class _DayCircle extends StatelessWidget {
  final String label;
  final bool trained;
  final bool isToday;
  final bool isFuture;

  const _DayCircle({
    required this.label,
    required this.trained,
    required this.isToday,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    final double size = isToday ? 34 : 28;

    Color fill;
    Color borderColor;
    Widget? icon;

    if (isFuture) {
      fill = Colors.transparent;
      borderColor = AppColors.surface3;
    } else if (trained) {
      fill = AppColors.accent;
      borderColor = AppColors.accent;
      icon = const Icon(Icons.check_rounded, size: 14, color: AppColors.background);
    } else {
      fill = AppColors.surface2;
      borderColor = AppColors.surface3;
    }

    if (isToday && !isFuture) {
      borderColor = trained ? AppColors.accent : AppColors.orange;
    }

    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(color: borderColor, width: isToday ? 2 : 1),
          ),
          child: icon != null ? Center(child: icon) : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isToday ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

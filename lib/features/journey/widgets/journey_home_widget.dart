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
    final user = ref.watch(currentUserModelProvider).value;
    // Only show for athletes (parents with linked children). Coaches see nothing.
    if (user == null || user.isCoach) return const SizedBox.shrink();

    final streakAsync = ref.watch(streakDataProvider);
    final message = ref.watch(dailyMessageProvider);
    final weekActivity = ref.watch(weekActivityProvider);

    final streak = streakAsync.current;
    final isLoading = ref.watch(coachSessionsProvider(
      // Derive coachId for loading state detection
      _coachIdFrom(ref) ?? '',
    )).isLoading;

    return GestureDetector(
      onTap: () => context.push('/journey'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surface3, width: 1),
        ),
        child: isLoading ? _buildSkeleton() : _buildContent(context, streak, message, weekActivity),
      ),
    );
  }

  String? _coachIdFrom(WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider).value;
    if (user == null || user.isCoach) return null;
    final childId = user.childIds.firstOrNull ?? user.childId;
    if (childId == null) return null;
    final allChildren = ref.watch(allChildrenProvider).value ?? [];
    return allChildren.where((c) => c.id == childId).firstOrNull?.coachId;
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _shimmerBox(width: 160, height: 24),
          const Spacer(),
          _shimmerBox(width: 80, height: 16),
        ]),
        const SizedBox(height: 8),
        _shimmerBox(width: 200, height: 14),
        const SizedBox(height: 10),
        _shimmerBox(width: double.infinity, height: 14),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (_) => _shimmerBox(width: 32, height: 40)),
        ),
      ],
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
    int streak,
    String message,
    List<bool> weekActivity,
  ) {
    final now = DateTime.now();
    // weekday: 1=Mon, 7=Sun → index 0-6
    final todayIndex = now.weekday - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ──────────────────────────────────────────────────────
        Row(
          children: [
            const ColorFiltered(
              colorFilter: ColorFilter.mode(AppColors.orange, BlendMode.srcIn),
              child: TriumphIcon(TIcon.motivation, size: 22),
            ),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$streak ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: streak >= 7
                          ? AppColors.accent
                          : AppColors.orange,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const TextSpan(
                    text: 'днів поспіль',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/journey'),
              child: const Row(
                children: [
                  Text(
                    'Твій шлях',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: AppColors.accent),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // ── Sub-text ─────────────────────────────────────────────────────────
        Text(
          streak > 0 ? 'Твій шлях триває' : 'Почни свій шлях сьогодні',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 10),

        // ── Daily message ────────────────────────────────────────────────────
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
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Week activity circles ────────────────────────────────────────────
        Row(
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
      ],
    );
  }
}

// ── Individual day circle ─────────────────────────────────────────────────────

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
          child: icon != null
              ? Center(child: icon)
              : null,
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

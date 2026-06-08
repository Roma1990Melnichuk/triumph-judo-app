// ROUTES TO ADD IN app.dart:
// GoRoute(path: '/journey', parentNavigatorKey: _rootNavKey, pageBuilder: (_, s) => _fadeSlide(s, const JourneyScreen()))

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/triumph_icon.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/streak_provider.dart';

// ── Stage definitions ─────────────────────────────────────────────────────────

class _Stage {
  final int days;
  final String name;
  final TIcon icon;
  const _Stage(this.days, this.name, this.icon);
}

const _kStages = [
  _Stage(7,   'Перший крок',  TIcon.training),
  _Stage(14,  'Стійкість',    TIcon.motivation),
  _Stage(30,  'Незламність',  TIcon.experience),
  _Stage(60,  'Витримка',     TIcon.statistics),
  _Stage(90,  'Самоконтроль', TIcon.sparring),
  _Stage(180, 'Воїн духу',   TIcon.achievements),
  _Stage(365, 'Шлях дзюдоки',TIcon.trophy),
];

// ── Glow level helper ─────────────────────────────────────────────────────────

_GlowLevel _glowForStreak(int streak) {
  if (streak >= 180) return _GlowLevel.legendary;
  if (streak >= 90)  return _GlowLevel.master;
  if (streak >= 60)  return _GlowLevel.redGold;
  if (streak >= 30)  return _GlowLevel.strongGold;
  if (streak >= 15)  return _GlowLevel.gold;
  if (streak >= 7)   return _GlowLevel.faintGold;
  if (streak >= 1)   return _GlowLevel.orange;
  return _GlowLevel.none;
}

enum _GlowLevel { none, orange, faintGold, gold, strongGold, redGold, master, legendary }

// ── Main screen ───────────────────────────────────────────────────────────────

class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({super.key});

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserModelProvider).value;

    // Coaches have no streak — redirect gracefully
    if (user != null && user.isCoach) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          title: const Text('Твій шлях'),
        ),
        body: const Center(
          child: Text(
            'Ця сторінка доступна лише для спортсменів.',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final streak = ref.watch(streakDataProvider);
    final message = ref.watch(dailyMessageProvider);
    final fourWeeks = ref.watch(fourWeekActivityProvider);
    final weekActivity = ref.watch(weekActivityProvider);

    final currentStreak = streak.current;
    final bestStreak = streak.best;
    final totalTrainings = streak.total;

    // Completion rate from 4-week window (non-future days only)
    final nonFutureDays = fourWeeks.where((d) => !d.future).length;
    final trainedDays = fourWeeks.where((d) => !d.future && d.trained).length;
    final completionRate = nonFutureDays > 0
        ? (trainedDays / nonFutureDays * 100).round()
        : 0;

    // Next stage milestone
    final nextStage = _kStages
        .where((s) => s.days > currentStreak)
        .fold<_Stage?>(null, (prev, s) => prev == null ? s : (s.days < prev.days ? s : prev));
    final daysToNext = nextStage != null ? nextStage.days - currentStreak : 0;

    // Current stage name
    final currentStage = _kStages
        .where((s) => s.days <= currentStreak)
        .fold<_Stage?>(null, (prev, s) => prev == null ? s : (s.days > prev.days ? s : prev));
    final stageName = currentStage?.name ?? 'Початок шляху';

    final glowLevel = _glowForStreak(currentStreak);
    final shouldPulse = currentStreak >= 15;
    final shouldAnimate = currentStreak >= 60;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar ─────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
            title: const Text(
              'Твій шлях',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                // ── 1. HERO SECTION ────────────────────────────────────────────
                _HeroSection(
                  streak: currentStreak,
                  stageName: stageName,
                  glowLevel: glowLevel,
                  shouldPulse: shouldPulse,
                  shouldAnimate: shouldAnimate,
                  pulseAnim: _pulseAnim,
                  shimmerCtrl: _shimmerCtrl,
                ),

                const SizedBox(height: 20),

                // ── 2. DAILY MESSAGE CARD ──────────────────────────────────────
                _DailyMessageCard(message: message),

                const SizedBox(height: 20),

                // ── 3. STAGES PATH ─────────────────────────────────────────────
                _SectionTitle(title: 'Етапи шляху'),
                const SizedBox(height: 12),
                _StagesRow(currentStreak: currentStreak),

                const SizedBox(height: 24),

                // ── 4. ACTIVITY CALENDAR ───────────────────────────────────────
                _SectionTitle(title: 'Календар активності'),
                const SizedBox(height: 12),
                _ActivityCalendar(fourWeeks: fourWeeks),

                const SizedBox(height: 24),

                // ── 5. ACHIEVEMENTS ────────────────────────────────────────────
                _SectionTitle(title: 'Досягнення серії'),
                const SizedBox(height: 12),
                _AchievementsRow(currentStreak: currentStreak),

                const SizedBox(height: 24),

                // ── 6. STATS ───────────────────────────────────────────────────
                _SectionTitle(title: 'Статистика'),
                const SizedBox(height: 12),
                _StatsGrid(
                  currentStreak: currentStreak,
                  bestStreak: bestStreak,
                  totalTrainings: totalTrainings,
                  completionRate: completionRate,
                  daysToNext: daysToNext,
                  weekActivity: weekActivity,
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ── 1. Hero section ──────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final int streak;
  final String stageName;
  final _GlowLevel glowLevel;
  final bool shouldPulse;
  final bool shouldAnimate;
  final Animation<double> pulseAnim;
  final AnimationController shimmerCtrl;

  const _HeroSection({
    required this.streak,
    required this.stageName,
    required this.glowLevel,
    required this.shouldPulse,
    required this.shouldAnimate,
    required this.pulseAnim,
    required this.shimmerCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surface3, width: 1),
      ),
      child: Column(
        children: [
          _JudokaAvatar(
            glowLevel: glowLevel,
            shouldPulse: shouldPulse,
            shouldAnimate: shouldAnimate,
            pulseAnim: pulseAnim,
            shimmerCtrl: shimmerCtrl,
          ),
          const SizedBox(height: 16),
          // Large streak number
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$streak',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: streak >= 7 ? AppColors.accent : AppColors.orange,
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
                const TextSpan(
                  text: '\nДНІВ ПОСПІЛЬ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 2,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Stage name chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: streak >= 7 ? AppColors.ctaGradient : null,
              color: streak < 7 ? AppColors.surface3 : null,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              stageName.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: streak >= 7 ? AppColors.background : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Judoka avatar with glow ───────────────────────────────────────────────────

class _JudokaAvatar extends StatelessWidget {
  final _GlowLevel glowLevel;
  final bool shouldPulse;
  final bool shouldAnimate;
  final Animation<double> pulseAnim;
  final AnimationController shimmerCtrl;

  const _JudokaAvatar({
    required this.glowLevel,
    required this.shouldPulse,
    required this.shouldAnimate,
    required this.pulseAnim,
    required this.shimmerCtrl,
  });

  List<BoxShadow> _shadowsFor(_GlowLevel level, double scale) {
    switch (level) {
      case _GlowLevel.none:
        return [];
      case _GlowLevel.orange:
        return [
          BoxShadow(
            color: AppColors.orange.withOpacity(0.35 * scale),
            blurRadius: 18 * scale,
            spreadRadius: 2 * scale,
          ),
        ];
      case _GlowLevel.faintGold:
        return [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.25 * scale),
            blurRadius: 20 * scale,
            spreadRadius: 3 * scale,
          ),
        ];
      case _GlowLevel.gold:
        return [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.45 * scale),
            blurRadius: 30 * scale,
            spreadRadius: 6 * scale,
          ),
        ];
      case _GlowLevel.strongGold:
        return [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.6 * scale),
            blurRadius: 40 * scale,
            spreadRadius: 10 * scale,
          ),
          BoxShadow(
            color: AppColors.orange.withOpacity(0.3 * scale),
            blurRadius: 20 * scale,
            spreadRadius: 4 * scale,
          ),
        ];
      case _GlowLevel.redGold:
        return [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.5 * scale),
            blurRadius: 50 * scale,
            spreadRadius: 14 * scale,
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4 * scale),
            blurRadius: 30 * scale,
            spreadRadius: 8 * scale,
          ),
        ];
      case _GlowLevel.master:
        return [
          BoxShadow(
            color: const Color(0xFFAA00FF).withOpacity(0.45 * scale),
            blurRadius: 55 * scale,
            spreadRadius: 16 * scale,
          ),
          BoxShadow(
            color: AppColors.accent.withOpacity(0.4 * scale),
            blurRadius: 30 * scale,
            spreadRadius: 8 * scale,
          ),
        ];
      case _GlowLevel.legendary:
        return [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.5 * scale),
            blurRadius: 60 * scale,
            spreadRadius: 20 * scale,
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4 * scale),
            blurRadius: 40 * scale,
            spreadRadius: 12 * scale,
          ),
          BoxShadow(
            color: const Color(0xFFAA00FF).withOpacity(0.3 * scale),
            blurRadius: 25 * scale,
            spreadRadius: 6 * scale,
          ),
        ];
    }
  }

  Color _bgColor(_GlowLevel level) {
    switch (level) {
      case _GlowLevel.none:
        return AppColors.surface3;
      case _GlowLevel.orange:
        return AppColors.orange.withOpacity(0.15);
      case _GlowLevel.faintGold:
      case _GlowLevel.gold:
        return AppColors.accent.withOpacity(0.12);
      case _GlowLevel.strongGold:
      case _GlowLevel.redGold:
        return AppColors.accent.withOpacity(0.18);
      case _GlowLevel.master:
        return const Color(0xFFAA00FF).withOpacity(0.15);
      case _GlowLevel.legendary:
        return AppColors.accent.withOpacity(0.2);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (shouldAnimate) {
      return AnimatedBuilder(
        animation: Listenable.merge([pulseAnim, shimmerCtrl]),
        builder: (_, __) {
          final scale = shouldPulse ? pulseAnim.value : 1.0;
          return _buildCircle(scale);
        },
      );
    }
    if (shouldPulse) {
      return AnimatedBuilder(
        animation: pulseAnim,
        builder: (_, __) => _buildCircle(pulseAnim.value),
      );
    }
    return _buildCircle(1.0);
  }

  Color _iconTint(_GlowLevel level) {
    switch (level) {
      case _GlowLevel.none:
        return AppColors.textSecondary;
      case _GlowLevel.orange:
        return AppColors.orange;
      case _GlowLevel.faintGold:
      case _GlowLevel.gold:
      case _GlowLevel.strongGold:
      case _GlowLevel.redGold:
      case _GlowLevel.legendary:
        return AppColors.accent;
      case _GlowLevel.master:
        return const Color(0xFFCC88FF);
    }
  }

  Widget _buildCircle(double scale) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _bgColor(glowLevel),
        boxShadow: _shadowsFor(glowLevel, scale),
      ),
      child: Center(
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(_iconTint(glowLevel), BlendMode.srcIn),
          child: TriumphIcon(TIcon.athlete, size: 72),
        ),
      ),
    );
  }
}

// ── 2. Daily message card ─────────────────────────────────────────────────────

class _DailyMessageCard extends StatelessWidget {
  final String message;
  const _DailyMessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface3, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left gold border
          Container(
            width: 4,
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: AppColors.ctaGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '"',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 0.8,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Нове послання о 00:00',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
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

// ── 3. Stages row ─────────────────────────────────────────────────────────────

class _StagesRow extends StatelessWidget {
  final int currentStreak;
  const _StagesRow({required this.currentStreak});

  @override
  Widget build(BuildContext context) {
    // Find the current stage (highest completed)
    final currentStageIdx = _kStages.lastIndexWhere((s) => s.days <= currentStreak);

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _kStages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final stage = _kStages[i];
          final completed = currentStreak >= stage.days;
          final isCurrent = i == currentStageIdx + 1; // next to achieve

          return _StageChip(
            stage: stage,
            completed: completed,
            isCurrent: isCurrent,
          );
        },
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  final _Stage stage;
  final bool completed;
  final bool isCurrent;

  const _StageChip({
    required this.stage,
    required this.completed,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color textColor;
    final Color bgColor;

    if (completed) {
      borderColor = AppColors.accent;
      textColor = AppColors.accent;
      bgColor = AppColors.accent.withOpacity(0.1);
    } else if (isCurrent) {
      borderColor = AppColors.orange;
      textColor = AppColors.orange;
      bgColor = AppColors.orange.withOpacity(0.08);
    } else {
      borderColor = AppColors.surface3;
      textColor = AppColors.textSecondary;
      bgColor = AppColors.surface2;
    }

    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
            child: TriumphIcon(stage.icon, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            '${stage.days} д.',
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stage.name,
            style: TextStyle(
              color: textColor,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── 4. Activity calendar ──────────────────────────────────────────────────────

class _ActivityCalendar extends StatelessWidget {
  final List<({DateTime date, bool trained, bool future})> fourWeeks;

  const _ActivityCalendar({required this.fourWeeks});

  static const _dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface3, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _dayLabels
                .map((l) => SizedBox(
                      width: 32,
                      child: Text(
                        l,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // 4 weeks × 7 days
          ...List.generate(4, (week) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (day) {
                  final idx = week * 7 + day;
                  if (idx >= fourWeeks.length) return const SizedBox(width: 32, height: 28);
                  final entry = fourWeeks[idx];
                  return _CalendarCell(
                    date: entry.date,
                    trained: entry.trained,
                    future: entry.future,
                  );
                }),
              ),
            );
          }),
          const SizedBox(height: 8),
          // Legend
          Row(
            children: [
              _LegendDot(color: AppColors.accent),
              const SizedBox(width: 4),
              const Text(
                'Тренування виконано',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.primary.withOpacity(0.5)),
              const SizedBox(width: 4),
              const Text(
                'Пропуск',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  final DateTime date;
  final bool trained;
  final bool future;

  const _CalendarCell({
    required this.date,
    required this.trained,
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    final Color cellColor;
    if (future) {
      cellColor = AppColors.surface2;
    } else if (trained) {
      cellColor = AppColors.accent.withOpacity(0.75);
    } else {
      cellColor = AppColors.primary.withOpacity(0.3);
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(6),
        border: isToday
            ? Border.all(color: AppColors.orange, width: 2)
            : null,
      ),
      child: trained && !future
          ? const Icon(Icons.check_rounded, size: 14, color: AppColors.background)
          : (!future && !trained
              ? const Icon(Icons.close_rounded, size: 12, color: AppColors.textSecondary)
              : null),
    );
  }
}

// ── 5. Achievements row ───────────────────────────────────────────────────────

final _kAchievements = [
  (days: 7,   asset: 'assets/achievements/achievement_streak_7.png'),
  (days: 14,  asset: 'assets/achievements/achievement_streak_14.png'),
  (days: 30,  asset: 'assets/achievements/achievement_streak_30.png'),
  (days: 60,  asset: null as String?),
  (days: 90,  asset: null as String?),
  (days: 180, asset: null as String?),
  (days: 365, asset: null as String?),
];

class _AchievementsRow extends StatelessWidget {
  final int currentStreak;
  const _AchievementsRow({required this.currentStreak});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _kAchievements.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final ach = _kAchievements[i];
          final completed = currentStreak >= ach.days;
          return _AchievementChip(
            days: ach.days,
            asset: ach.asset,
            completed: completed,
          );
        },
      ),
    );
  }
}

class _AchievementChip extends StatelessWidget {
  final int days;
  final String? asset;
  final bool completed;

  const _AchievementChip({
    required this.days,
    required this.asset,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: completed
            ? AppColors.accent.withOpacity(0.12)
            : AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: completed ? AppColors.accent : AppColors.surface3,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!completed)
            const Icon(Icons.lock_outline_rounded,
                size: 22, color: AppColors.textSecondary)
          else if (asset != null)
            Image.asset(asset!, width: 40, height: 40, fit: BoxFit.contain)
          else
            const ColorFiltered(
              colorFilter:
                  ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
              child: TriumphIcon(TIcon.trophy, size: 22),
            ),
          const SizedBox(height: 4),
          Text(
            '$days д.',
            style: TextStyle(
              color: completed ? AppColors.accent : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 6. Stats grid ─────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final int currentStreak;
  final int bestStreak;
  final int totalTrainings;
  final int completionRate;
  final int daysToNext;
  final List<bool> weekActivity;

  const _StatsGrid({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalTrainings,
    required this.completionRate,
    required this.daysToNext,
    required this.weekActivity,
  });

  @override
  Widget build(BuildContext context) {
    final trainedThisWeek = weekActivity.where((b) => b).length;

    final tiles = [
      (label: 'Поточна серія', value: '$currentStreak', unit: 'днів', tIcon: TIcon.motivation),
      (label: 'Найкраща серія', value: '$bestStreak', unit: 'днів', tIcon: TIcon.trophy),
      (label: 'Всього трен.', value: '$totalTrainings', unit: 'занять', tIcon: TIcon.training),
      (label: 'Відвідуваність', value: '$completionRate', unit: '%', tIcon: TIcon.statistics),
      (label: 'До наступного', value: daysToNext > 0 ? '$daysToNext' : '—', unit: daysToNext > 0 ? 'днів' : '', tIcon: TIcon.achievements),
      (label: 'Цього тижня', value: '$trainedThisWeek', unit: 'трен.', tIcon: TIcon.calendar),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, i) {
        final t = tiles[i];
        return _StatTile(
          label: t.label,
          value: t.value,
          unit: t.unit,
          tIcon: t.tIcon,
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final TIcon tIcon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.tIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surface3, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
            child: TriumphIcon(tIcon, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          if (unit.isNotEmpty)
            Text(
              unit,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}


import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/child_model.dart' show ChildModel, displayWeight;
import '../../../shared/widgets/belt_badge.dart';
import '../../../shared/widgets/triumph_icon.dart';
import '../../auth/providers/auth_provider.dart';
import '../../belts/providers/belt_provider.dart';
import '../../schedule/providers/group_provider.dart';
import '../../team/providers/children_provider.dart';
import '../../competitions/providers/competitions_provider.dart';

class MyDataScreen extends ConsumerWidget {
  const MyDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider).value;
    final childId = user?.childIds.firstOrNull;

    if (childId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          title: const Text('Мої дані'),
        ),
        body: const Center(
          child: Text(
            'Не знайдено пов\'язаного спортсмена',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final childAsync = ref.watch(childByIdProvider(childId));

    return childAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Помилка: $e')),
      ),
      data: (child) {
        if (child == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: Text('Спортсмена не знайдено')),
          );
        }
        return _MyDataBody(child: child, childId: childId);
      },
    );
  }
}

class _MyDataBody extends ConsumerWidget {
  const _MyDataBody({required this.child, required this.childId});

  final ChildModel child;
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextBelt = child.currentBelt.next;
    final beltProgressAsync = nextBelt != null
        ? ref.watch(beltProgressProvider((childId: childId, belt: nextBelt)))
        : null;
    final beltReqAsync =
        nextBelt != null ? ref.watch(beltRequirementProvider(nextBelt)) : null;

    final attendanceAsync = ref.watch(childAttendanceStatsProvider(childId));
    final attendanceStats = attendanceAsync.value;

    final resultsAsync = ref.watch(childResultsProvider(childId));
    final results = resultsAsync.value ?? [];

    final passedCount = beltProgressAsync?.value?.passedCount ?? 0;
    final totalExercises = beltReqAsync?.exercises.length ?? 0;
    final techniquePct = totalExercises > 0
        ? (passedCount / totalExercises * 100).round()
        : 0;

    final age = DateTime.now().year - child.birthYear;
    final medalCount = results.where((r) => r.place <= 3).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
            title: const Text(
              'Мої дані',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: const ColorFiltered(
                  colorFilter:
                      ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn),
                  child: TriumphIcon(TIcon.athlete, size: 22),
                ),
                tooltip: 'Повний профіль',
                onPressed: () => context.push('/team/$childId'),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Hero card ─────────────────────────────────────────────────
                _HeroCard(child: child, age: age),

                const SizedBox(height: 16),

                // ── Technique gauge ──────────────────────────────────────────
                _TechniqueGauge(
                  percent: techniquePct,
                  nextBelt: nextBelt,
                ),

                const SizedBox(height: 16),

                // ── Stats row ────────────────────────────────────────────────
                _StatsRow(
                  attendance: attendanceStats?.pct.round() ?? 0,
                  trainings: attendanceStats?.total ?? 0,
                  medals: medalCount,
                  results: results.length,
                ),

                const SizedBox(height: 16),

                // ── Info tiles ───────────────────────────────────────────────
                _InfoGrid(child: child, age: age),

                const SizedBox(height: 16),

                // ── Quick actions ────────────────────────────────────────────
                _QuickActions(childId: childId),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.child, required this.age});

  final ChildModel child;
  final int age;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppColors.heroCardGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Name + belt section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$age років  •  ${child.ageCategory}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                BeltBadge(
                  belt: child.currentBelt,
                  size: BeltBadgeSize.medium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: child.currentBelt == BeltLevel.white
                    ? Colors.white54
                    : child.currentBelt.color,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: child.currentBelt.color.withValues(alpha: 0.4),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: child.photoUrl != null
                ? CircleAvatar(
                    radius: 46,
                    backgroundImage:
                        CachedNetworkImageProvider(child.photoUrl!),
                  )
                : CircleAvatar(
                    radius: 46,
                    backgroundColor: AppColors.avatarColor(child.id),
                    child: Text(
                      '${child.firstName[0]}${child.lastName[0]}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Technique gauge ───────────────────────────────────────────────────────────

class _TechniqueGauge extends StatelessWidget {
  const _TechniqueGauge({required this.percent, required this.nextBelt});

  final int percent;
  final BeltLevel? nextBelt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surface3),
      ),
      child: Row(
        children: [
          // Circular progress gauge
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(100, 100),
                  painter: _ArcPainter(percent: percent),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const Text(
                      'готово',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Info section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Прогрес до поясу',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                if (nextBelt != null) ...[
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: nextBelt!.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          nextBelt!.displayName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      minHeight: 6,
                      backgroundColor: AppColors.surface3,
                      valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Максимальний пояс досягнуто',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.percent});

  final int percent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color = AppColors.surface3
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFD50000), Color(0xFFFFD21A)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;
    final filled = sweepAngle * (percent / 100);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );
    if (percent > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        filled,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.percent != percent;
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.attendance,
    required this.trainings,
    required this.medals,
    required this.results,
  });

  final int attendance;
  final int trainings;
  final int medals;
  final int results;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface3),
      ),
      child: Row(
        children: [
          _StatCell(tIcon: TIcon.statistics, value: '$attendance%', label: 'Відвід.'),
          _Div(),
          _StatCell(tIcon: TIcon.training, value: '$trainings', label: 'Трен.'),
          _Div(),
          _StatCell(tIcon: TIcon.trophy, value: '$medals', label: 'Медалей'),
          _Div(),
          _StatCell(tIcon: TIcon.tournament, value: '$results', label: 'Турнірів'),
        ],
      ),
    );
  }
}

class _Div extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 50,
        color: AppColors.surface3,
      );
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.tIcon,
    required this.value,
    required this.label,
  });

  final TIcon tIcon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            ColorFiltered(
              colorFilter:
                  const ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
              child: TriumphIcon(tIcon, size: 16),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info grid ─────────────────────────────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.child, required this.age});

  final ChildModel child;
  final int age;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoTile(
            tIcon: TIcon.profile,
            label: 'Вік',
            value: '$age р.',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoTile(
            tIcon: TIcon.athlete,
            label: 'Вага',
            value: displayWeight(child.weightCategory),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoTile(
            tIcon: TIcon.belts,
            label: 'Пояс',
            value: child.currentBelt.displayName,
            valueColor: child.currentBelt.color,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.tIcon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final TIcon tIcon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surface3),
      ),
      child: Column(
        children: [
          ColorFiltered(
            colorFilter:
                const ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
            child: TriumphIcon(tIcon, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick actions ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Швидкий доступ',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        _ActionRow(
          tIcon: TIcon.athlete,
          label: 'Повний профіль',
          subtitle: 'Результати, досягнення, відвідуваність',
          onTap: () => context.push('/team/$childId'),
        ),
        const SizedBox(height: 8),
        _ActionRow(
          tIcon: TIcon.calendar,
          label: 'Розклад тренувань',
          subtitle: 'Групові та індивідуальні',
          onTap: () => context.go('/events'),
        ),
        const SizedBox(height: 8),
        _ActionRow(
          tIcon: TIcon.statistics,
          label: 'Прогрес',
          subtitle: 'Серія тренувань та активність',
          onTap: () => context.push('/journey'),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.tIcon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final TIcon tIcon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surface3),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: ColorFiltered(
                  colorFilter:
                      const ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
                  child: TriumphIcon(tIcon, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

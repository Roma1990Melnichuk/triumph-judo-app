import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/child_model.dart';
import '../../../core/models/competition_result_model.dart';
import '../../../core/models/training_schedule_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../competitions/providers/competitions_provider.dart';
import '../../membership/widgets/academy_pass_card.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../team/providers/children_provider.dart';
import '../../journey/widgets/journey_home_widget.dart';
import '../../rating/screens/medal_tracker_screen.dart';
import '../../../shared/animations/app_animations.dart';
import '../../../shared/widgets/belt_badge.dart';
import '../../../shared/widgets/default_avatar.dart';
import '../../../shared/widgets/triumph_icon.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final List<AnimationController> _entryCtrl = [];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 6; i++) {
      final c = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 500));
      _entryCtrl.add(c);
      Future.delayed(Duration(milliseconds: 60 + i * 90), () {
        if (mounted) c.forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _entryCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _enter(int idx, Widget child) {
    if (idx >= _entryCtrl.length) return child;
    final ctrl = _entryCtrl[idx];
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => Opacity(
        opacity: ctrl.value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - ctrl.value)),
          child: child,
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Доброго ранку';
    if (h < 18) return 'Добрий день';
    return 'Доброго вечора';
  }

  @override
  Widget build(BuildContext context) {
    final user        = ref.watch(currentUserModelProvider).value;
    final isCoach     = user?.isCoach ?? false;
    final allAsync    = ref.watch(allChildrenProvider);

    // Auto-seed 1000 demo athletes the first time a coach opens an empty club.
    ref.listen<AsyncValue<List<ChildModel>>>(allChildrenProvider, (prev, next) {
      if ((prev?.hasValue != true) && next.hasValue &&
          isCoach && (next.value?.isEmpty ?? false)) {
        ref.read(childrenNotifierProvider.notifier)
            .seedTestData(user!.uid, user.name);
      }
    });
    final schedAsync  = ref.watch(schedulesProvider);
    final recentAsync = ref.watch(recentResultsProvider);
    final medAsync    = ref.watch(totalResultsCountProvider);

    final children   = allAsync.value ?? [];
    final total      = children.length;
    final beltReady  = children.where((c) => c.beltReady).toList();
    final recent     = recentAsync.value ?? [];
    final medals     = medAsync.value ?? 0;
    final todayWday  = DateTime.now().weekday;
    final todaySched = (schedAsync.value ?? [])
        .where((s) => s.daysOfWeek.contains(todayWday))
        .toList();
    final activePct  =
        total > 0 ? (beltReady.length / total * 100).round() : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        child: Stack(
          children: [
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [

                // ── Greeting ────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: _enter(0, Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_greeting()}, ${user?.name.split(' ').first ?? (isCoach ? 'Тренер' : 'Батьку')}! 🔥',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Готові до нових перемог?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Bell icon with red dot
                        GestureDetector(
                          onTap: () => context.push('/notifications'),
                          child: Stack(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(color: AppColors.surface3),
                                ),
                                child: Center(
                                  child: TriumphIcon(TIcon.notifications, size: 26),
                                ),
                              ),
                              Positioned(
                                right: 9, top: 9,
                                child: Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )),
                  ),
                ),

                // ── Membership card ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _enter(1, Builder(builder: (context) {
                      if (isCoach) return const TeamMembershipCard();
                      final childId = user?.childIds.isNotEmpty == true
                          ? user!.childIds.first
                          : user?.childId;
                      if (childId == null) return const SizedBox.shrink();
                      return AcademyPassCard(childId: childId);
                    })),
                  ),
                ),

                // ── Hero training card ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _enter(2, PulsingGlow(
                      color: AppColors.primary,
                      blurRadius: 20,
                      borderRadius: 20,
                      periodSeconds: 4,
                      minAlpha: 0.15,
                      maxAlpha: 0.35,
                      child: CardBreath(child: _HeroCard(schedules: todaySched)),
                    )),
                  ),
                ),

                // ── Feature icons (parent only) ──────────────────────────────
                if (!isCoach)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _enter(2, const _ParentFeatureIcons()),
                    ),
                  ),

                // ── Journey streak widget (athletes only) ───────────────────
                if (!isCoach)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _enter(6, const JourneyHomeWidget()),
                    ),
                  ),

                // ── Stats ────────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: _enter(3, Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Статистика команди',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500, // Inter Medium 16
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'за цей місяць',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          _StatCard(
                            tIcon: TIcon.team,
                            numValue: total,
                            label: 'Спортсменів',
                            iconColors: const [Color(0xFFD50000), Color(0xFF7A0000)],
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            tIcon: TIcon.statistics,
                            numValue: activePct,
                            numSuffix: '%',
                            label: 'Відвідуваність',
                            iconColors: const [Color(0xFFFFD21A), Color(0xFFFF8A00)],
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            tIcon: TIcon.medal,
                            numValue: medals,
                            label: 'Медалі',
                            iconColors: const [Color(0xFFFF8A00), Color(0xFFD50000)],
                          ),
                        ]),
                      ],
                    )),
                  ),
                ),

                // ── Belt-ready ───────────────────────────────────────────────
                if (beltReady.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: _enter(4, _BeltReadySection(athletes: beltReady)),
                    ),
                  ),

                // ── Medal Tracker dashboard card ─────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: _enter(5, MedalTrackerDashboardCard(
                      onViewDetails: () => context.go('/rating'),
                    )),
                  ),
                ),

                // ── Recent achievements ──────────────────────────────────────
                if (recent.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: _enter(5, _RecentSection(results: recent)),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
// Hero Card — linear-gradient(135deg, #7A0000 0%, #D50000 60%, #FF8A00 100%)
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatefulWidget {
  const _HeroCard({required this.schedules});
  final List<TrainingScheduleModel> schedules;

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.schedules.isEmpty) return _empty();
    return Column(
      children: widget.schedules.map(_card).toList(),
    );
  }

  Widget _empty() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.surface3),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12)),
            child: TriumphIcon(TIcon.calendar, size: 22),
          ),
          const SizedBox(width: 14),
          const Text('Сьогодні тренувань немає',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
        ]),
      );

  Widget _card(TrainingScheduleModel s) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
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
            // Hero gradient: 135deg #7A0000 → #D50000 → #FF8A00
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.heroCardGradient,
              ),
            ),
            // Shimmer sweep
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  begin: Alignment(-1 + _shimmer.value * 3, 0),
                  end: Alignment(0 + _shimmer.value * 3, 0),
                  colors: const [
                    Colors.transparent,
                    Color(0x0AFFFFFF),
                    Colors.transparent,
                  ],
                ).createShader(b),
                child: Container(color: Colors.white),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Наступне тренування',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(children: [
                          ColorFiltered(
                            colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
                            child: TriumphIcon(TIcon.calendar, size: 13),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Сьогодні, ${s.timeStart} – ${s.timeEnd}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 5),
                        Row(children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            s.daysLabel,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Training icon box
                  Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Center(child: TriumphIcon(TIcon.training, size: 34)),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Parent feature icons (4 quick-access icons below membership card)
// ─────────────────────────────────────────────────────────────────────────────

class _ParentFeatureIcons extends StatelessWidget {
  const _ParentFeatureIcons();

  static const _items = [
    (TIcon.profile,     'Мої дані',    '/my-data'),
    (TIcon.training,    'Тренування',  '/events'),
    (TIcon.statistics,  'Прогрес',     '/journey'),
    (TIcon.trophy,      'Досягнення',  '/rating'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _items.map((item) {
        final (icon, label, route) = item;
        return Expanded(
          child: GestureDetector(
            onTap: () => context.push(route),
            child: Column(
              children: [
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surface3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(child: TriumphIcon(icon, size: 28)),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat card
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    this.tIcon,
    required this.numValue,
    required this.label,
    required this.iconColors,
    this.numSuffix = '',
  });

  final TIcon? tIcon;
  final int numValue;
  final String numSuffix;
  final String label;
  final List<Color> iconColors;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surface3),
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: iconColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: tIcon != null
                    ? TriumphIcon(tIcon!, size: 24)
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 8),
            CountUpText(
              numValue,
              suffix: numSuffix,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
              duration: const Duration(milliseconds: 800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
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

// ─────────────────────────────────────────────────────────────────────────────
// Belt-ready section
// ─────────────────────────────────────────────────────────────────────────────

class _BeltReadySection extends StatelessWidget {
  const _BeltReadySection({required this.athletes});
  final List<ChildModel> athletes;

  @override
  Widget build(BuildContext context) {
    final show = athletes.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text(
            'Готові до здачі поясу',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${athletes.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surface3),
          ),
          child: Column(
            children: show.asMap().entries.map((e) {
              final i = e.key;
              final c = e.value;
              final nextBelt = c.currentBelt.next ?? c.currentBelt;
              return Column(children: [
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                  dense: true,
                  onTap: () => context.push('/team/${c.id}'),
                  leading: c.photoUrl != null
                      ? CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(c.photoUrl!))
                      : DefaultAvatarCircle(
                          gender: c.gender, radius: 18, seed: c.id),
                  title: Text(
                    c.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: BeltBadge(
                      belt: nextBelt, size: BeltBadgeSize.small),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color:
                              AppColors.success.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            size: 10, color: AppColors.success),
                        const SizedBox(width: 3),
                        Text(
                          c.gender == Gender.female ? 'Готова' : 'Готовий',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
                if (i < show.length - 1)
                  const Divider(height: 1, indent: 52, endIndent: 12),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent achievements — per и2.png
// ─────────────────────────────────────────────────────────────────────────────

class _RecentSection extends StatelessWidget {
  const _RecentSection({required this.results});
  final List<CompetitionResultModel> results;

  static String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Сьогодні';
    if (diff.inDays == 1) return 'Вчора';
    if (diff.inDays < 7)  return '${diff.inDays} дн тому';
    if (diff.inDays < 30) return '${(diff.inDays / 7).round()} тиж тому';
    return '${(diff.inDays / 30).round()} міс тому';
  }

  static String _medal(int p) =>
      p == 1 ? '🥇' : p == 2 ? '🥈' : p == 3 ? '🥉' : '🏅';

  @override
  Widget build(BuildContext context) {
    final show = results.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Останні досягнення',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              child: const Text(
                'Всі  ›',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surface3),
          ),
          child: Column(
            children: show.asMap().entries.map((e) {
              final i = e.key;
              final r = e.value;
              return Column(children: [
                ListTile(
                  dense: true,
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(_medal(r.place),
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  title: Text(
                    r.childName.isNotEmpty ? r.childName : '—',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    r.competitionName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _timeAgo(r.date),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (i < show.length - 1)
                  const Divider(height: 1, indent: 56, endIndent: 12),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

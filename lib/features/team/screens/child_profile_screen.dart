import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/cloudinary_upload.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/belt_requirement_model.dart';
import '../../../core/models/belt_progress_model.dart';
import '../../../core/models/child_model.dart' show ChildModel, displayWeight, weightCategories;
import '../../../core/models/competition_result_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/belts/providers/belt_provider.dart';
import '../../../features/competitions/providers/competitions_provider.dart';
import '../../../features/schedule/providers/group_provider.dart';
import '../providers/children_provider.dart';
import '../../../core/models/membership_model.dart';
import '../../../features/membership/providers/membership_provider.dart';
import '../../../features/rating/screens/medal_tracker_screen.dart';
import '../../../shared/animations/app_animations.dart';
import '../../../shared/widgets/attendance_calendar.dart';
import '../../../shared/widgets/belt_badge.dart';
import '../../../features/achievements/providers/achievement_provider.dart';
import '../../../features/achievements/providers/achievement_progress_provider.dart';
import '../../../core/constants/achievement_defs.dart';
import '../../../core/models/achievement_model.dart';
import '../../../shared/widgets/achievement_badge.dart';
import '../../../shared/widgets/triumph_icon.dart';
import '../../../features/individual_training/providers/individual_training_provider.dart';
import '../../../features/membership/models/tariff_plan.dart';
import '../../../features/membership/providers/tariff_provider.dart';
import '../../../features/nutrition/providers/nutrition_provider.dart';
import '../../../features/nutrition/widgets/nutrition_widgets.dart';
import '../../../core/models/meal_model.dart' show MealStatus;

class ChildProfileScreen extends ConsumerStatefulWidget {
  const ChildProfileScreen({super.key, required this.childId});

  final String childId;

  @override
  ConsumerState<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends ConsumerState<ChildProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get childId => widget.childId;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final childAsync = ref.watch(childByIdProvider(childId));
    final resultsAsync = ref.watch(childResultsProvider(childId));
    final user = ref.watch(currentUserModelProvider).asData?.value;
    final isCoach = user?.isCoach ?? false;
    final isOwnProfile = !isCoach && (user?.ownsChild(childId) ?? false);
    final allChildrenList = ref.watch(allChildrenProvider).asData?.value ?? const [];

    return childAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Помилка: $e')),
      ),
      data: (child) {
        if (child == null) {
          return const Scaffold(
            body: Center(child: Text('Спортсмена не знайдено')),
          );
        }
        final nextBelt = child.currentBelt.next;
        final beltProgressAsync = nextBelt != null
            ? ref.watch(beltProgressProvider(
                (childId: childId, belt: nextBelt)))
            : null;
        final beltReqAsync = nextBelt != null
            ? ref.watch(beltRequirementProvider(nextBelt))
            : null;

        final membershipAsync = ref.watch(membershipByAthleteProvider(childId));
        final membership = membershipAsync.asData?.value;

        final results = resultsAsync.asData?.value ?? [];
        final passedCount = beltProgressAsync?.asData?.value?.passedCount ?? 0;
        final totalExercises = beltReqAsync?.exercises.length ?? 0;
        final beltPct = totalExercises > 0
            ? (passedCount / totalExercises * 100).round()
            : 0;
        final medalCount = results.where((r) => r.place <= 3).length;

        // Peer ranks among all club athletes
        final _sorted = [...allChildrenList]..sort((a, b) {
          final cmp = b.totalPoints.compareTo(a.totalPoints);
          if (cmp != 0) return cmp;
          return a.lastName.compareTo(b.lastName);
        });
        final _yrCounters = <int, int>{};
        final _yrTotals   = <int, int>{};
        final _wtCounters = <String, int>{};
        final _wtTotals   = <String, int>{};
        final _yrRanks    = <String, int>{};
        final _wtRanks    = <String, int>{};
        for (final c in _sorted) {
          _yrTotals[c.birthYear]  = (_yrTotals[c.birthYear]  ?? 0) + 1;
          _yrCounters[c.birthYear] = (_yrCounters[c.birthYear] ?? 0) + 1;
          _yrRanks[c.id] = _yrCounters[c.birthYear]!;
          final wk = '${c.birthYear}/${c.weightCategory}';
          _wtTotals[wk]   = (_wtTotals[wk]   ?? 0) + 1;
          _wtCounters[wk] = (_wtCounters[wk]  ?? 0) + 1;
          _wtRanks[c.id]  = _wtCounters[wk]!;
        }
        final sameYearRank    = _yrRanks[childId];
        final sameYearTotal   = _yrTotals[child.birthYear];
        final sameWeightRank  = _wtRanks[childId];
        final sameWeightTotal = _wtTotals['${child.birthYear}/${child.weightCategory}'];

        final attendanceStats =
            ref.watch(childAttendanceStatsProvider(childId)).asData?.value;
        final indivCount =
            ref.watch(childConfirmedTrainingCountProvider(childId));
        final coachUser = ref.watch(coachByIdProvider(child.coachId));
        final parents =
            ref.watch(parentsByChildIdProvider(childId)).asData?.value ?? [];

        return Scaffold(
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (ctx, _) => [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    SizedBox(
                      height: 290,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Dark gradient background
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF1A0808),
                                  AppColors.background,
                                ],
                              ),
                            ),
                          ),
                          // Radial red glow around avatar
                          Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 0.55,
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.28),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          // Avatar + name + belt
                          Padding(
                            padding: const EdgeInsets.only(top: 56),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Avatar with belt-colored ring + entry scale
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.85, end: 1.0),
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutBack,
                                  builder: (_, scale, inner) =>
                                      Transform.scale(scale: scale, child: inner),
                                  child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: child.currentBelt.color
                                            .withValues(alpha: 0.5),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                    border: Border.all(
                                      color: child.currentBelt == BeltLevel.white
                                          ? Colors.white54
                                          : child.currentBelt.color,
                                      width: 3,
                                    ),
                                  ),
                                  child: child.photoUrl != null
                                      ? CircleAvatar(
                                          radius: 58,
                                          backgroundImage:
                                              CachedNetworkImageProvider(
                                                  child.photoUrl!),
                                        )
                                      : CircleAvatar(
                                          radius: 58,
                                          backgroundColor:
                                              AppColors.avatarColor(child.id),
                                          child: Text(
                                            '${child.firstName[0]}${child.lastName[0]}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                ),
                                ), // TweenAnimationBuilder
                                const SizedBox(height: 10),
                                Text(
                                  child.fullName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  child.ageCategory,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                PulsingGlow(
                                  color: child.currentBelt.color,
                                  blurRadius: 14,
                                  borderRadius: 20,
                                  periodSeconds: 3,
                                  child: BeltBadge(
                                    belt: child.currentBelt,
                                    size: BeltBadgeSize.medium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Back button + action icons overlay
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.background.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: TriumphIcon(TIcon.back, size: 22, color: AppColors.textPrimary),
                                ),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => context.push(
                                '/fitness/$childId',
                                extra: {'childName': child.fullName},
                              ),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.background.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: TriumphIcon(TIcon.statistics, size: 22, color: AppColors.textPrimary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => context.push(
                                '/my-assignments',
                                extra: {'childId': childId},
                              ),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.background.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: TriumphIcon(TIcon.tasks, size: 22, color: AppColors.textPrimary),
                                ),
                              ),
                            ),
                            if (isOwnProfile) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _showAthleteEditSheet(context, ref, child),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.background.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.edit_outlined, size: 20, color: AppColors.textPrimary),
                                  ),
                                ),
                              ),
                            ],
                            if (isCoach) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => context.push('/team/$childId/edit'),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.background.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.edit_outlined, size: 20, color: AppColors.textPrimary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _confirmDelete(context, ref),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.background.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: TriumphIcon(TIcon.delete, size: 22, color: AppColors.error),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Stats row: belt % / competitions / medals / attendance / indiv
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      _ProfileStat(
                          value: '$beltPct%',
                          label: 'До поясу'),
                      _ProfileStatDivider(),
                      _ProfileStat(
                          value: '${results.length}',
                          label: 'Змагань'),
                      _ProfileStatDivider(),
                      _ProfileStat(
                          value: '$medalCount',
                          label: 'Медалей'),
                      if (sameYearTotal != null && sameYearTotal > 1 && sameYearRank != null) ...[
                        _ProfileStatDivider(),
                        _ProfileStat(
                          value: '#$sameYearRank/$sameYearTotal',
                          label: 'Однолітки',
                        ),
                      ],
                      if (sameWeightTotal != null && sameWeightTotal > 1 &&
                          sameWeightRank != null && child.weightCategory.isNotEmpty) ...[
                        _ProfileStatDivider(),
                        _ProfileStat(
                          value: '#$sameWeightRank/$sameWeightTotal',
                          label: 'У вазі',
                        ),
                      ],
                      if (attendanceStats != null &&
                          attendanceStats.total > 0) ...[
                        _ProfileStatDivider(),
                        _ProfileStat(
                          value:
                              '${attendanceStats.pct.round()}%',
                          label: 'Відвід.',
                        ),
                      ],
                      if (indivCount > 0) ...[
                        _ProfileStatDivider(),
                        _ProfileStat(
                          value: '$indivCount',
                          label: 'Інд. трен.',
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Info chips: birth year / weight / coach ──────────────
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _ProfileInfoChip(
                        icon: Icons.cake_outlined,
                        label: '${child.birthYear} р.н.',
                      ),
                      _ProfileInfoChip(
                        icon: Icons.scale_outlined,
                        label: displayWeight(child.weightCategory),
                        onTap: isCoach
                            ? () => _editWeight(context, ref, child)
                            : null,
                      ),
                      _ProfileInfoChip(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Вага/Ріст',
                        onTap: () => context.push('/team/$childId/measurements'),
                      ),
                      _ProfileInfoChip(
                        tIcon: TIcon.coach,
                        label: 'Тренер: ${child.coachName.isNotEmpty ? child.coachName : '—'}',
                        onTap: isCoach
                            ? () => _changeCoach(context, ref, child)
                            : null,
                      ),
                      if (coachUser?.phone != null &&
                          coachUser!.phone!.isNotEmpty)
                        _ProfileInfoChip(
                          icon: Icons.phone_outlined,
                          label: 'Тел. тренера: ${coachUser.phone!}',
                          trailingIcon: Icons.copy_outlined,
                          onTap: () =>
                              _copyToClipboard(context, coachUser.phone!),
                        ),
                      if (child.phone != null && child.phone!.isNotEmpty)
                        _ProfileInfoChip(
                          icon: Icons.phone_outlined,
                          label: 'Тел. спортсмена: ${child.phone!}',
                          trailingIcon: Icons.copy_outlined,
                          onTap: () =>
                              _copyToClipboard(context, child.phone!),
                        ),
                      ...parents
                          .where((p) =>
                              p.phone != null && p.phone!.isNotEmpty)
                          .map(
                            (p) => _ProfileInfoChip(
                              icon: Icons.phone_outlined,
                              label: 'Тел. батьків: ${p.phone!}',
                              trailingIcon: Icons.copy_outlined,
                              onTap: () =>
                                  _copyToClipboard(context, p.phone!),
                            ),
                          ),
                    ],
                  ),
                ),
              ),

              // ── Membership section ───────────────────────────────────────
              SliverToBoxAdapter(
                child: _MembershipSection(
                  membership: membership,
                  childId: childId,
                  isCoach: isCoach,
                ),
              ),

              // Sticky TabBar
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBar(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.accent,
                    indicatorWeight: 2,
                    labelColor: AppColors.accent,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'Прогрес до поясу'),
                      Tab(text: 'Досягнення'),
                      Tab(text: 'Відвідування'),
                      Tab(text: 'Нагороди клубу'),
                      Tab(text: 'Харчування'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                // ── Tab 0: Прогрес до поясу (belt progress) ──────────────
                _ResultatyTab(
                  childId: childId,
                  child: child,
                  nextBelt: nextBelt,
                  beltReqAsync: beltReqAsync,
                  beltProgressAsync: beltProgressAsync,
                  isCoach: isCoach,
                ),
                // ── Tab 1: Досягнення (competition results) ───────────────
                _DosyagnennyaTab(
                  childId: childId,
                  results: results,
                  isCoach: isCoach,
                  onDelete: (r) => _deleteResult(context, ref, r),
                ),
                // ── Tab 2: Відзнаки (info + attendance) ─────────────────
                _VidznakiTab(
                  child: child,
                  childId: childId,
                  isCoach: isCoach,
                ),
                // ── Tab 3: Нагороди клубу ────────────────────────────────
                _NagorodyKlubuTab(childId: childId),
                // ── Tab 4: Харчування ─────────────────────────────────────
                _NutritionTab(childId: childId),
              ],
            ),
          ),
        );
      },
    );
  }


  void _editWeight(BuildContext context, WidgetRef ref, ChildModel child) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Вагова категорія',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: weightCategories.map((w) {
                  final selected = child.weightCategory == w;
                  return ListTile(
                    title: Text(displayWeight(w)),
                    trailing: selected
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    selected: selected,
                    selectedColor: AppColors.primary,
                    onTap: () async {
                      Navigator.pop(context);
                      await ref
                          .read(childrenNotifierProvider.notifier)
                          .updateChild(child.copyWith(weightCategory: w));
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _changeCoach(BuildContext context, WidgetRef ref, ChildModel child) {
    final coaches = ref.read(allCoachesProvider).asData?.value ?? [];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Тренер',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...coaches.map((c) => ListTile(
                title: Text(c.name),
                trailing: child.coachId == c.uid
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                selected: child.coachId == c.uid,
                selectedColor: AppColors.primary,
                onTap: () async {
                  Navigator.pop(context);
                  await ref
                      .read(childrenNotifierProvider.notifier)
                      .updateChild(child.copyWith(
                        coachId: c.uid,
                        coachName: c.name,
                      ));
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Номер скопійовано'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Видалити спортсмена?'),
        content: const Text(
            'Буде видалено всі результати та прогрес пояса. Цю дію не можна скасувати.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(childrenNotifierProvider.notifier)
                  .deleteChild(childId);
              if (context.mounted) context.go('/team');
            },
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
  }

  void _showAthleteEditSheet(BuildContext context, WidgetRef ref, ChildModel child) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AthleteEditSheet(child: child),
    );
  }

  void _deleteResult(
      BuildContext context, WidgetRef ref, CompetitionResultModel result) {
    ref.read(competitionsNotifierProvider.notifier).deleteResult(result);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Результат видалено'),
          action: SnackBarAction(
            label: 'Скасувати',
            onPressed: () =>
                ref.read(competitionsNotifierProvider.notifier).addResult(result),
          ),
        ),
      );
  }
}

// ── Athlete self-edit sheet ───────────────────────────────────────────────────

class _AthleteEditSheet extends ConsumerStatefulWidget {
  const _AthleteEditSheet({required this.child});
  final ChildModel child;

  @override
  ConsumerState<_AthleteEditSheet> createState() => _AthleteEditSheetState();
}

class _AthleteEditSheetState extends ConsumerState<_AthleteEditSheet> {
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _phoneCtrl;
  File? _photoFile;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _firstCtrl = TextEditingController(text: widget.child.firstName);
    _lastCtrl  = TextEditingController(text: widget.child.lastName);
    _phoneCtrl = TextEditingController(text: widget.child.phone ?? '');
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.surface3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Зняти фото'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Обрати з галереї'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 800);
    if (file != null) setState(() => _photoFile = File(file.path));
  }

  Future<void> _save() async {
    final firstName = _firstCtrl.text.trim();
    final lastName  = _lastCtrl.text.trim();
    if (firstName.isEmpty || lastName.isEmpty) return;
    setState(() => _loading = true);
    try {
      String? photoUrl = widget.child.photoUrl;
      if (_photoFile != null) {
        final bytes = await _photoFile!.readAsBytes();
        photoUrl = await uploadImageToCloudinary(
          bytes,
          'children_${widget.child.id}',
        );
      }
      final updated = widget.child.copyWith(
        firstName: firstName,
        lastName: lastName,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        photoUrl: photoUrl,
      );
      await this.ref.read(childrenNotifierProvider.notifier).updateChild(updated);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surface3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Редагувати профіль',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Photo picker
              GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundImage: _photoFile != null
                          ? FileImage(_photoFile!) as ImageProvider
                          : (widget.child.photoUrl != null
                              ? CachedNetworkImageProvider(widget.child.photoUrl!)
                              : null),
                      backgroundColor: AppColors.avatarColor(widget.child.id),
                      child: _photoFile == null && widget.child.photoUrl == null
                          ? Text(
                              '${widget.child.firstName[0]}${widget.child.lastName[0]}',
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _firstCtrl,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: "Ім'я"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _lastCtrl,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Прізвище'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  hintText: '+380...',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Зберегти'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _BeltProgressCard extends ConsumerStatefulWidget {
  const _BeltProgressCard({
    required this.childId,
    required this.beltReq,
    required this.beltProgress,
    required this.isCoach,
  });

  final String childId;
  final dynamic beltReq;
  final dynamic beltProgress;
  final bool isCoach;

  @override
  ConsumerState<_BeltProgressCard> createState() => _BeltProgressCardState();
}

class _BeltProgressCardState extends ConsumerState<_BeltProgressCard> {
  bool _markingAll = false;

  @override
  void initState() {
    super.initState();
    _syncBeltReady();
  }

  @override
  void didUpdateWidget(_BeltProgressCard old) {
    super.didUpdateWidget(old);
    if (old.beltProgress != widget.beltProgress) _syncBeltReady();
  }

  void _syncBeltReady() {
    final exercises = (widget.beltReq?.exercises as List?) ?? [];
    if (exercises.isEmpty) return;
    final belt = widget.beltReq?.belt;
    if (belt == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(beltNotifierProvider.notifier)
          .syncBeltReady(widget.childId, belt);
    });
  }

  Future<void> _markAll() async {
    final exercises = (widget.beltReq?.exercises as List?) ?? [];
    if (exercises.isEmpty) return;
    setState(() => _markingAll = true);
    await ref.read(beltNotifierProvider.notifier).markAllPassed(
      childId: widget.childId,
      belt: widget.beltReq!.belt,
      exerciseIds: exercises.map<String>((e) => e.id as String).toList(),
    );
    if (mounted) {
      setState(() => _markingAll = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const TriumphIcon(TIcon.success, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Всі вимоги підтверджено'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.beltReq == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Вимоги ще не заповнені тренером'),
        ),
      );
    }
    final exercises = widget.beltReq.exercises as List;
    if (exercises.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Немає вимог для цього поясу'),
        ),
      );
    }

    final passed =
        (widget.beltProgress?.passed as Map<String, bool>?) ?? <String, bool>{};
    final passedCount = passed.values.where((v) => v).length;
    final allDone = passedCount == exercises.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$passedCount / ${exercises.length} виконано',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: allDone ? AppColors.success : AppColors.primary,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 80,
                  child: LinearProgressIndicator(
                    value: passedCount / exercises.length,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                        allDone ? AppColors.success : AppColors.primary),
                  ),
                ),
                if (widget.isCoach && !allDone) ...[
                  const SizedBox(width: 8),
                  _markingAll
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton.icon(
                          onPressed: _markAll,
                          icon: const Icon(Icons.done_all, size: 16),
                          label: const Text('Всі ✓'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          ),
                        ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            ...exercises.map((ex) {
              final isPassed = passed[ex.id] ?? false;
              if (widget.isCoach) {
                return CheckboxListTile(
                  value: isPassed,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.success,
                  title: Text(
                    ex.name,
                    style: TextStyle(
                      decoration:
                          isPassed ? TextDecoration.lineThrough : null,
                      color: isPassed
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: ex.description.isNotEmpty
                      ? Text(
                          ex.description,
                          style: const TextStyle(fontSize: 12),
                        )
                      : null,
                  onChanged: (val) async {
                    await ref
                        .read(beltNotifierProvider.notifier)
                        .toggleExercise(
                          childId: widget.childId,
                          belt: widget.beltReq.belt,
                          exerciseId: ex.id,
                          passed: val ?? false,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Збережено'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                );
              } else {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isPassed
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isPassed
                        ? AppColors.success
                        : Colors.grey.shade400,
                    size: 22,
                  ),
                  title: Text(
                    ex.name,
                    style: TextStyle(
                      decoration:
                          isPassed ? TextDecoration.lineThrough : null,
                      color: isPassed
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: ex.description.isNotEmpty
                      ? Text(
                          ex.description,
                          style: const TextStyle(fontSize: 12),
                        )
                      : null,
                );
              }
            }),
          ],
        ),
      ),
    );
  }
}

// ── Attendance section ────────────────────────────────────────────────────────

class _AttendanceSectionWrapper extends ConsumerWidget {
  const _AttendanceSectionWrapper({required this.childId});

  final String childId;

  static int _currentSeasonYear() {
    final now = DateTime.now();
    return now.month >= 9 ? now.year : now.year - 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(childGroupsProvider(childId));
    final seasonYear = _currentSeasonYear();

    // Compute all training dates across all groups
    final allTrainingDates = <DateTime>{};
    for (final g in groups) {
      allTrainingDates.addAll(g.trainingDates(seasonYear));
    }
    final sortedDates = allTrainingDates.toList()..sort();

    final groupIds = groups.map((g) => g.id).toList();

    final title =
        'Відвідуваність $seasonYear/${(seasonYear + 1) % 100}';

    if (groups.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Тренер ще не додав вас до жодної групи',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }

    final attendanceAsync = ref.watch(childAttendanceMapProvider((
      childId: childId,
      groupIds: groupIds,
      seasonYear: seasonYear,
    )));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title),
        attendanceAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
          error: (_, __) => const SizedBox(),
          data: (absenceMap) => AttendanceCalendar(
            trainingDates: sortedDates,
            absenceMap: absenceMap,
            seasonYear: seasonYear,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Membership section card
// ─────────────────────────────────────────────────────────────────────────────

class _MembershipSection extends ConsumerWidget {
  const _MembershipSection({
    required this.membership,
    required this.childId,
    required this.isCoach,
  });

  final MembershipModel? membership;
  final String childId;
  final bool isCoach;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (membership == null && !isCoach) return const SizedBox.shrink();

    final Color statusColor;
    final String statusLabel;
    final String detail;

    if (membership == null) {
      statusColor = AppColors.textSecondary;
      statusLabel = 'Не активовано';
      detail = 'Абонемент не встановлено';
    } else {
      final m = membership!;
      statusColor = m.statusColor;
      statusLabel = m.statusLabel;
      detail = m.isExpired
          ? 'Прострочений ${m.daysExpiredAgo} дн тому'
          : '${m.daysRemaining} дн залишається';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: GestureDetector(
        onTap: isCoach
            ? () => _showCoachSetMembership(context, ref)
            : () => context.push('/membership/$childId'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surface3),
          ),
          child: Row(children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Абонемент',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    if (membership != null &&
                        membership!.planName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          membership!.planName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
            Text(
              detail,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isCoach ? Icons.edit_outlined : Icons.chevron_right,
              size: 16,
              color: isCoach ? AppColors.accent : AppColors.textSecondary,
            ),
          ]),
        ),
      ),
    );
  }

  void _showCoachSetMembership(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CoachSetMembershipSheet(
        childId: childId,
        existing: membership,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coach direct set-membership bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CoachSetMembershipSheet extends ConsumerStatefulWidget {
  const _CoachSetMembershipSheet({required this.childId, this.existing});
  final String childId;
  final MembershipModel? existing;

  @override
  ConsumerState<_CoachSetMembershipSheet> createState() =>
      _CoachSetMembershipSheetState();
}

class _CoachSetMembershipSheetState
    extends ConsumerState<_CoachSetMembershipSheet> {
  int _planIdx = 2;
  bool _saving = false;

  DateTime get _start => DateTime.now();

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(tariffPlansProvider).asData?.value ?? TariffPlan.defaults;
    final planIdx = _planIdx.clamp(0, plans.length - 1);
    final plan = plans[planIdx];
    final endDate = _start.add(Duration(days: plan.days));
    final fmt = DateFormat('dd.MM.yyyy');

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text(
              'Встановити абонемент',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
          const SizedBox(height: 12),

          // Plan selector
          const Text('Тариф',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: List.generate(plans.length, (i) {
              final selected = i == planIdx;
              return GestureDetector(
                onTap: () => setState(() => _planIdx = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.ctaGradient : null,
                    color: selected ? null : AppColors.surface2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : AppColors.surface3,
                    ),
                  ),
                  child: Text(
                    plans[i].name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          // Date summary
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surface3),
            ),
            child: Row(children: [
              const TriumphIcon(TIcon.calendar, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${fmt.format(_start)} — ${fmt.format(endDate)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        )),
                    Text(
                      '${plan.days} днів · ${plan.price.toStringAsFixed(0)} грн',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Підтвердити',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final plans = ref.read(tariffPlansProvider).asData?.value ?? TariffPlan.defaults;
      final planIdx = _planIdx.clamp(0, plans.length - 1);
      final plan = plans[planIdx];
      final endDate = _start.add(Duration(days: plan.days));
      await ref.read(membershipNotifierProvider.notifier).setMembership(
            athleteId: widget.childId,
            planName: plan.name,
            startDate: _start,
            endDate: endDate,
            amount: plan.price,
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Помилка збереження. Перевірте підключення.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile stat widget
// ─────────────────────────────────────────────────────────────────────────────
// Achievements section (shown in Досягнення tab)
// ─────────────────────────────────────────────────────────────────────────────

class _AchievementsSection extends ConsumerWidget {
  const _AchievementsSection({required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earned = ref.watch(childAchievementsProvider(childId)).asData?.value ?? [];
    final progressMap =
        ref.watch(achievementProgressProvider(childId));

    final earnedIds = earned.map((a) => a.achievementId).toSet();
    final earnedDefs =
        kAchievements.where((d) => earnedIds.contains(d.id)).toList();

    // In-progress: auto achievements not yet earned with progress > 0,
    // hidden ones excluded (user shouldn't know about them).
    final inProgress = progressMap.entries
        .where((e) =>
            !earnedIds.contains(e.key) &&
            !(achievementById(e.key)?.isHidden ?? true))
        .toList()
      ..sort((a, b) => b.value.current
          .compareTo(a.value.current)); // most-progressed first

    final showAny = earnedDefs.isNotEmpty || inProgress.isNotEmpty;
    if (!showAny) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Досягнення',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            Text(
              '${earnedDefs.length} / ${kAchievements.length}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),

        // Earned badges
        if (earnedDefs.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: earnedDefs
                .map((d) => AchievementBadge(
                      def: d,
                      small: true,
                      earnedAt: earned
                          .firstWhere((a) => a.achievementId == d.id)
                          .earnedAt,
                    ))
                .toList(),
          ),
        ],

        // In-progress locked badges
        if (inProgress.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            'На підході',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: inProgress.map((e) {
              final def = achievementById(e.key);
              if (def == null) return const SizedBox.shrink();
              final pct =
                  (e.value.current / e.value.target).clamp(0.0, 1.0);
              return AchievementBadge(
                def: def,
                small: true,
                locked: true,
                progress: pct,
                progressHint: '${e.value.current} / ${e.value.target}',
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info chip (birth year / weight / coach)
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileInfoChip extends StatelessWidget {
  const _ProfileInfoChip({
    this.icon,
    this.tIcon,
    required this.label,
    this.onTap,
    this.trailingIcon,
  }) : assert(icon != null || tIcon != null);

  final IconData? icon;
  final TIcon? tIcon;
  final String label;
  final VoidCallback? onTap;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surface3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tIcon != null)
              TriumphIcon(tIcon!, size: 13, color: AppColors.textSecondary)
            else
              Icon(icon, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(trailingIcon ?? Icons.edit_outlined,
                  size: 11, color: AppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      );
}

class _ProfileStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1, height: 32,
        color: AppColors.surface3,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky TabBar delegate
// ─────────────────────────────────────────────────────────────────────────────

class _StickyTabBar extends SliverPersistentHeaderDelegate {
  const _StickyTabBar(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          tabBar,
          const Divider(height: 1),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyTabBar old) => old.tabBar != tabBar;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0: Досягнення (competition results)
// ─────────────────────────────────────────────────────────────────────────────

class _DosyagnennyaTab extends StatelessWidget {
  const _DosyagnennyaTab({
    required this.childId,
    required this.results,
    required this.isCoach,
    required this.onDelete,
  });

  final String childId;
  final List<CompetitionResultModel> results;
  final bool isCoach;
  final void Function(CompetitionResultModel) onDelete;

  static Widget _medal(int p) {
    final color = p == 1
        ? AppColors.goldMedal
        : p == 2
            ? AppColors.silverMedal
            : p == 3
                ? AppColors.bronzeMedal
                : AppColors.textSecondary;
    return TriumphIcon(p <= 3 ? TIcon.medal3d : TIcon.medal, size: 26, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AchievementsSection(childId: childId),
        const SizedBox(height: 16),
        AthleteMedalBlock(childId: childId),
        if (results.isNotEmpty) const SizedBox(height: 16),
        if (results.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Результатів ще немає',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          ...results.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: _medal(r.place)),
                  ),
                  title: Text(r.competitionName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                    '${r.level.displayName} • ${DateFormat('dd.MM.yyyy').format(r.date)}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('+${r.points} б',
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          Text('${r.place} місце',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                        ],
                      ),
                      if (isCoach) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
                          onPressed: () => onDelete(r),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ],
                  ),
                ),
              )),
        const SizedBox(height: 16),
        if (isCoach)
          ElevatedButton.icon(
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: const Text('Додати результат'),
            onPressed: () => context.push('/team/$childId/add-result'),
          ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Результати (belt progress)
// ─────────────────────────────────────────────────────────────────────────────

class _ResultatyTab extends ConsumerWidget {
  const _ResultatyTab({
    required this.childId,
    required this.child,
    required this.nextBelt,
    required this.beltReqAsync,
    required this.beltProgressAsync,
    required this.isCoach,
  });

  final String childId;
  final ChildModel child;
  final BeltLevel? nextBelt;
  final BeltRequirementModel? beltReqAsync;
  final AsyncValue<BeltProgressModel?>? beltProgressAsync;
  final bool isCoach;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (nextBelt == null) {
      return const Center(
        child: Text('Максимальний пояс досягнуто',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(
          title: 'До поясу: ${nextBelt!.displayName}',
          action: isCoach
              ? TextButton(
                  onPressed: () => context.push('/belts/edit'),
                  child: const Text('Редагувати'),
                )
              : null,
        ),
        const SizedBox(height: 8),
        _BeltProgressCard(
          childId: childId,
          beltReq: beltReqAsync,
          beltProgress: beltProgressAsync?.asData?.value,
          isCoach: isCoach,
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Відзнаки (info + belt card + attendance)
// ─────────────────────────────────────────────────────────────────────────────

class _VidznakiTab extends StatelessWidget {
  const _VidznakiTab({
    required this.child,
    required this.childId,
    required this.isCoach,
  });

  final ChildModel child;
  final String childId;
  final bool isCoach;

  @override
  Widget build(BuildContext ctx) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Belt + coach card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Поточний пояс',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      PulsingGlow(
                        color: child.currentBelt.color,
                        blurRadius: 16,
                        borderRadius: 24,
                        periodSeconds: 3,
                        child: BeltBadge(belt: child.currentBelt, size: BeltBadgeSize.large),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Тренер',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(child.coachName,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Attendance
        _AttendanceSectionWrapper(childId: childId),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3: Нагороди клубу
// ─────────────────────────────────────────────────────────────────────────────

class _NagorodyKlubuTab extends ConsumerWidget {
  const _NagorodyKlubuTab({required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(childAchievementsProvider(childId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Помилка: $e', style: const TextStyle(color: AppColors.textSecondary))),
      data: (earned) {
        if (earned.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_outlined, size: 56, color: AppColors.textSecondary),
                SizedBox(height: 12),
                Text('Ще немає нагород',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 15)),
                SizedBox(height: 4),
                Text(
                  'Нагороди з\'являться після перших досягнень',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          );
        }

        final earnedMap = {for (final a in earned) a.achievementId: a};
        final grouped = allAchievementsByCategory;

        final items = <Widget>[];
        for (final entry in grouped.entries) {
          final defs = entry.value
              .where((d) => earnedMap.containsKey(d.id))
              .toList();
          if (defs.isEmpty) continue;
          items.add(Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
            child: Text(
              entry.key.displayName.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
          ));
          for (final def in defs) {
            items.add(_AwardCard(def: def, achievement: earnedMap[def.id]!));
          }
        }
        items.add(const SizedBox(height: 40));

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: items,
        );
      },
    );
  }
}

class _AwardCard extends StatelessWidget {
  const _AwardCard({required this.def, required this.achievement});

  final AchievementDef def;
  final AchievementModel achievement;

  Color get _borderColor {
    switch (def.rarity) {
      case AchievementRarity.common:    return Colors.grey.shade600;
      case AchievementRarity.rare:      return Colors.green.shade600;
      case AchievementRarity.epic:      return Colors.blue.shade600;
      case AchievementRarity.legendary: return Colors.purple.shade600;
      case AchievementRarity.mythic:    return AppColors.accent;
    }
  }

  Color get _bgColor {
    switch (def.rarity) {
      case AchievementRarity.common:    return Colors.grey.shade900;
      case AchievementRarity.rare:      return Colors.green.shade900;
      case AchievementRarity.epic:      return Colors.blue.shade900;
      case AchievementRarity.legendary: return Colors.purple.shade900;
      case AchievementRarity.mythic:    return const Color(0xFF2A1A00);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _borderColor.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          AchievementIcon(def: def, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  def.description,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _borderColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    def.rarity.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _borderColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('dd.MM\nyyyy').format(achievement.earnedAt),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4: Харчування
// ─────────────────────────────────────────────────────────────────────────────

class _NutritionTab extends ConsumerWidget {
  const _NutritionTab({required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dk    = todayNutritionKey;
    final nKey  = (childId: childId, dateKey: dk);
    final score = ref.watch(nutritionScoreProvider(nKey));
    final meals = ref.watch(dayMealsProvider(nKey));
    final waterMl   = ref.watch(dayWaterMlProvider(nKey));
    final waterGoal = ref.watch(waterGoalMlProvider);
    final doneMeals = meals.where((m) => m.status == MealStatus.done).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // ── Score gauge row ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF222222)),
          ),
          child: Row(
            children: [
              NutritionScoreGauge(
                score: score,
                size: 88,
                strokeWidth: 8,
                child: Text(
                  score.round().toString(),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Харчування сьогодні',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      _scoreLabel(score),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _scoreColor(score),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${score.round()} / 100 балів',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Quick stats ─────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _QuickStat(
                icon: Icons.restaurant_rounded,
                color: AppColors.orange,
                label: 'Прийомів',
                value: '$doneMeals',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickStat(
                icon: Icons.water_drop_rounded,
                color: const Color(0xFF4FC3F7),
                label: 'Вода',
                value: '${(waterMl / 1000).toStringAsFixed(1)} л',
                subValue: '/ ${(waterGoal / 1000).toStringAsFixed(1)} л',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Open full dashboard ──────────────────────────────────────────────
        GestureDetector(
          onTap: () => context.push('/nutrition/child/$childId'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.orange.withValues(alpha: 0.15),
                  AppColors.orange.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.restaurant_menu_rounded,
                    color: AppColors.orange, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Відкрити щоденник харчування',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      Text('Страви, вода, поради, статистика',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.orange),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _scoreLabel(double s) {
    if (s >= 80) return 'Відмінно';
    if (s >= 60) return 'Добре';
    if (s >= 40) return 'Задовільно';
    return 'Треба краще';
  }

  Color _scoreColor(double s) {
    if (s >= 80) return AppColors.success;
    if (s >= 60) return AppColors.orange;
    if (s >= 40) return const Color(0xFFFFCC00);
    return AppColors.error;
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.subValue,
  });

  final IconData icon;
  final Color    color;
  final String   label;
  final String   value;
  final String?  subValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: color)),
                  if (subValue != null) ...[
                    const SizedBox(width: 3),
                    Text(subValue!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

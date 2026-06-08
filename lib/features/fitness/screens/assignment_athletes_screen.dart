import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/child_model.dart';

import '../../../shared/widgets/default_avatar.dart';
import '../../team/providers/children_provider.dart';
import '../providers/fitness_assignment_provider.dart';

enum _SortMode { progress, name, lastResult }

class AssignmentAthletesScreen extends ConsumerStatefulWidget {
  const AssignmentAthletesScreen({super.key, required this.assignmentId});
  final String assignmentId;

  @override
  ConsumerState<AssignmentAthletesScreen> createState() =>
      _AssignmentAthletesScreenState();
}

class _AssignmentAthletesScreenState
    extends ConsumerState<AssignmentAthletesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  _SortMode _sort = _SortMode.progress;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assignment = ref.watch(assignmentByIdProvider(widget.assignmentId));
    final logsAsync = ref.watch(assignmentLogsProvider(widget.assignmentId));
    final childrenAsync = ref.watch(allChildrenProvider);

    if (assignment == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Спортсмени')),
        body: const Center(
          child: Text('Завдання не знайдено',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final logs = logsAsync.value ?? [];
    final children = childrenAsync.value ?? [];
    final assignedChildren = children
        .where((c) => assignment.assignedChildIds.contains(c.id))
        .toList();

    final Map<String, double> athleteProgress = {};
    final Map<String, DateTime?> lastResultDate = {};
    for (final c in assignedChildren) {
      final childLogs = logs.where((l) => l.childId == c.id).toList();
      athleteProgress[c.id] = childLogs.fold(0.0, (acc, l) => acc + l.value);
      lastResultDate[c.id] =
          childLogs.isNotEmpty ? childLogs.map((l) => l.date).reduce((a, b) => a.isAfter(b) ? a : b) : null;
    }

    final target = assignment.targetValue;

    // Filter
    List<ChildModel> filtered = assignedChildren.where((c) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return c.firstName.toLowerCase().contains(q) ||
          c.lastName.toLowerCase().contains(q);
    }).toList();

    // Tab 0 = All, Tab 1 = Lagging
    if (_tab.index == 1) {
      filtered = filtered.where((c) {
        final pct =
            target > 0 ? (athleteProgress[c.id] ?? 0) / target : 0.0;
        return pct < 0.5;
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      switch (_sort) {
        case _SortMode.progress:
          return (athleteProgress[b.id] ?? 0)
              .compareTo(athleteProgress[a.id] ?? 0);
        case _SortMode.name:
          return '${a.firstName} ${a.lastName}'
              .compareTo('${b.firstName} ${b.lastName}');
        case _SortMode.lastResult:
          final da = lastResultDate[a.id];
          final db = lastResultDate[b.id];
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Спортсмени'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Усі'),
            Tab(text: 'Відстають'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Пошук...',
                      prefixIcon: Icon(Icons.search,
                          color: AppColors.textSecondary, size: 18),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    onChanged: (q) => setState(() => _search = q),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<_SortMode>(
                  icon: const Icon(Icons.sort,
                      color: AppColors.textSecondary),
                  color: AppColors.surface,
                  onSelected: (m) => setState(() => _sort = m),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: _SortMode.progress,
                        child: Text('За прогресом')),
                    PopupMenuItem(
                        value: _SortMode.name,
                        child: Text('За іменем')),
                    PopupMenuItem(
                        value: _SortMode.lastResult,
                        child: Text('За останнім результатом')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Немає спортсменів',
                        style:
                            TextStyle(color: AppColors.textSecondary)))
                : ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final child = filtered[i];
                      final progress =
                          athleteProgress[child.id] ?? 0.0;
                      final pct = target > 0
                          ? (progress / target).clamp(0.0, 1.0)
                          : 0.0;
                      final lastDate = lastResultDate[child.id];
                      final daysSince = lastDate != null
                          ? DateTime.now()
                              .difference(lastDate)
                              .inDays
                          : null;

                      return _AthleteCard(
                        child: child,
                        progress: progress,
                        pct: pct,
                        unit: assignment.exerciseUnit,
                        daysSinceActivity: daysSince,
                        target: target,
                        onTap: () => context.push(
                          '/assignments/${widget.assignmentId}/athlete/${child.id}',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Athlete card ──────────────────────────────────────────────────────────────

class _AthleteCard extends StatelessWidget {
  const _AthleteCard({
    required this.child,
    required this.progress,
    required this.pct,
    required this.unit,
    required this.daysSinceActivity,
    required this.target,
    required this.onTap,
  });

  final ChildModel child;
  final double progress;
  final double pct;
  final String unit;
  final int? daysSinceActivity;
  final double target;
  final VoidCallback onTap;

  _AthleteStatus get _status {
    if (pct >= 0.8) return _AthleteStatus.onTrack;
    if (pct >= 0.5) return _AthleteStatus.onWay;
    if (pct > 0) return _AthleteStatus.lagging;
    return _AthleteStatus.notStarted;
  }

  @override
  Widget build(BuildContext context) {
    final pctInt = (pct * 100).round();
    final fmtVal = (double v) => v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(1);

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
            DefaultAvatar(
              gender: child.gender,
              size: 44,
              seed: child.id,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${child.firstName} ${child.lastName}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _status.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _status.label,
                          style: TextStyle(
                              color: _status.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    child.currentBelt.displayName,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${fmtVal(progress)} / ${fmtVal(target)} $unit',
                        style: TextStyle(
                          color: _status.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$pctInt%',
                        style: TextStyle(
                            color: _status.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 4,
                      backgroundColor: AppColors.surface3,
                      valueColor: AlwaysStoppedAnimation(_status.color),
                    ),
                  ),
                  if (daysSinceActivity != null &&
                      daysSinceActivity! > 3) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 11,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          'Немає активності $daysSinceActivity дн.',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Status enum (reused from group progress screen) ───────────────────────────

enum _AthleteStatus { onTrack, onWay, lagging, notStarted }

extension _AthleteStatusX on _AthleteStatus {
  String get label {
    switch (this) {
      case _AthleteStatus.onTrack:
        return 'Виконує';
      case _AthleteStatus.onWay:
        return 'На шляху';
      case _AthleteStatus.lagging:
        return 'Відстає';
      case _AthleteStatus.notStarted:
        return 'Не почав';
    }
  }

  Color get color {
    switch (this) {
      case _AthleteStatus.onTrack:
        return AppColors.success;
      case _AthleteStatus.onWay:
        return AppColors.accent;
      case _AthleteStatus.lagging:
        return AppColors.warning;
      case _AthleteStatus.notStarted:
        return AppColors.textSecondary;
    }
  }
}

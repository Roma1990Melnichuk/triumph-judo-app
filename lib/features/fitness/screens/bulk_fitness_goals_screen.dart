import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/child_model.dart';
import '../../../core/models/fitness_assignment_model.dart';
import '../../../core/models/fitness_exercise_model.dart';
import '../../../core/models/group_model.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/triumph_icon.dart';
import '../../auth/providers/auth_provider.dart';
import '../../team/providers/children_provider.dart';
import '../../schedule/providers/group_provider.dart';
import '../providers/fitness_provider.dart';
import '../providers/fitness_assignment_provider.dart';

class BulkFitnessGoalsScreen extends ConsumerStatefulWidget {
  const BulkFitnessGoalsScreen({super.key});

  @override
  ConsumerState<BulkFitnessGoalsScreen> createState() =>
      _BulkFitnessGoalsScreenState();
}

class _BulkFitnessGoalsScreenState
    extends ConsumerState<BulkFitnessGoalsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

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
                  const Expanded(
                    child: Text(
                      'Масові фітнес-завдання',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tab,
              tabs: const [
                Tab(text: 'Цілі'),
                Tab(text: 'Завдання'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _GoalsTab(),
                  _AssignmentsTab(),
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
// Tab 1: Bulk Goals (individual FitnessGoal per athlete)
// ─────────────────────────────────────────────────────────────────────────────

class _GoalsTab extends ConsumerStatefulWidget {
  const _GoalsTab();

  @override
  ConsumerState<_GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends ConsumerState<_GoalsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final Set<String> _selectedGroupIds = {};
  final Set<int> _selectedYears = {};
  final Set<BeltLevel> _selectedBelts = {};

  String? _exerciseId;
  String _exerciseName = '';
  String _exerciseUnit = 'рази';
  final _valueCtrl = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  List<ChildModel> _matched(List<ChildModel> all, List<GroupModel> groups) {
    return all.where((c) {
      if (_selectedGroupIds.isNotEmpty) {
        final inGroup = groups
            .where((g) => _selectedGroupIds.contains(g.id))
            .any((g) => g.childIds.contains(c.id));
        if (!inGroup) return false;
      }
      if (_selectedYears.isNotEmpty && !_selectedYears.contains(c.birthYear)) {
        return false;
      }
      if (_selectedBelts.isNotEmpty &&
          !_selectedBelts.contains(c.currentBelt)) {
        return false;
      }
      return true;
    }).toList();
  }

  bool get _canApply {
    if (_saving || _exerciseId == null) return false;
    final v = double.tryParse(_valueCtrl.text.trim().replaceAll(',', '.'));
    return v != null && v > 0;
  }

  Future<void> _apply(List<ChildModel> matched) async {
    final v = double.tryParse(_valueCtrl.text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0 || _exerciseId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Підтвердити цілі?'),
        content: Text(
          'Встановити ціль "$_exerciseName" — '
          '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)} $_exerciseUnit '
          'до ${_fmt(_deadline)} для ${matched.length} спортсменів?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Скасувати')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Підтвердити')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    try {
      final notifier = ref.read(fitnessNotifierProvider.notifier);
      for (final child in matched) {
        await notifier.setGoal(
          childId: child.id,
          exerciseId: _exerciseId!,
          exerciseName: _exerciseName,
          exerciseUnit: _exerciseUnit,
          targetValue: v,
          deadline: _deadline,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const ColorFiltered(
                colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                child: TriumphIcon(TIcon.success, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('Цілі встановлено для ${matched.length} спортсменів')),
            ],
          ),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Помилка: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final children = ref.watch(allChildrenProvider).value ?? [];
    final groups = ref.watch(groupsProvider).value ?? [];
    final exercises = ref.watch(fitnessExercisesProvider).value ?? [];
    final birthYears = children.map((c) => c.birthYear).toSet().toList()..sort();
    final matched = _matched(children, groups);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _FilterCard(
          groups: groups,
          birthYears: birthYears,
          selectedGroupIds: _selectedGroupIds,
          selectedYears: _selectedYears,
          selectedBelts: _selectedBelts,
          matchCount: matched.length,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 16),
        _GoalFormCard(
          exercises: exercises,
          exerciseId: _exerciseId,
          exerciseUnit: _exerciseUnit,
          valueCtrl: _valueCtrl,
          deadline: _deadline,
          onExerciseChanged: (id, name, unit) => setState(() {
            _exerciseId = id;
            _exerciseName = name;
            _exerciseUnit = unit;
          }),
          onDeadlineChanged: (d) => setState(() => _deadline = d),
          onValueChanged: () => setState(() {}),
        ),
        const SizedBox(height: 24),
        GradientButton(
          onPressed: (_canApply && matched.isNotEmpty) ? () => _apply(matched) : null,
          isLoading: _saving,
          child: Text(
            matched.isEmpty
                ? 'Оберіть спортсменів і вправу'
                : 'Застосувати до ${matched.length} спортсменів',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Group Assignments
// ─────────────────────────────────────────────────────────────────────────────

class _AssignmentsTab extends ConsumerStatefulWidget {
  const _AssignmentsTab();

  @override
  ConsumerState<_AssignmentsTab> createState() => _AssignmentsTabState();
}

class _AssignmentsTabState extends ConsumerState<_AssignmentsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final Set<String> _selectedGroupIds = {};
  final Set<int> _selectedYears = {};
  final Set<BeltLevel> _selectedBelts = {};

  String? _exerciseId;
  String _exerciseName = '';
  String _exerciseUnit = 'рази';
  final _titleCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  List<ChildModel> _matched(List<ChildModel> all, List<GroupModel> groups) {
    return all.where((c) {
      if (_selectedGroupIds.isNotEmpty) {
        final inGroup = groups
            .where((g) => _selectedGroupIds.contains(g.id))
            .any((g) => g.childIds.contains(c.id));
        if (!inGroup) return false;
      }
      if (_selectedYears.isNotEmpty && !_selectedYears.contains(c.birthYear)) {
        return false;
      }
      if (_selectedBelts.isNotEmpty &&
          !_selectedBelts.contains(c.currentBelt)) {
        return false;
      }
      return true;
    }).toList();
  }

  bool get _canCreate {
    if (_saving || _exerciseId == null) return false;
    if (_titleCtrl.text.trim().isEmpty) return false;
    final v = double.tryParse(_valueCtrl.text.trim().replaceAll(',', '.'));
    return v != null && v > 0;
  }

  Future<void> _create(List<ChildModel> matched) async {
    final v = double.tryParse(_valueCtrl.text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0 || _exerciseId == null) return;
    final title = _titleCtrl.text.trim();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Створити завдання?'),
        content: Text(
          '"$title"\n\n'
          'Вправа: $_exerciseName\n'
          'Ціль: ${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)} $_exerciseUnit накопичено\n'
          'Дедлайн: ${_fmt(_deadline)}\n'
          'Спортсменів: ${matched.length}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Скасувати')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Створити')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _saving = true);
    try {
      final coachId =
          ref.read(currentUserModelProvider).value?.uid ?? '';
      await ref.read(assignmentNotifierProvider.notifier).createAssignment(
            coachId: coachId,
            title: title,
            exerciseId: _exerciseId!,
            exerciseName: _exerciseName,
            exerciseUnit: _exerciseUnit,
            targetValue: v,
            startDate: DateTime.now(),
            deadline: _deadline,
            assignedChildIds: matched.map((c) => c.id).toList(),
          );
      if (mounted) {
        _titleCtrl.clear();
        _valueCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const ColorFiltered(
                colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                child: TriumphIcon(TIcon.success, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('Завдання створено для ${matched.length} спортсменів')),
            ],
          ),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Помилка: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Видалити завдання?'),
        content: const Text('Завдання буде видалено для всіх спортсменів.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Скасувати')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(assignmentNotifierProvider.notifier).deleteAssignment(id);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final children = ref.watch(allChildrenProvider).value ?? [];
    final groups = ref.watch(groupsProvider).value ?? [];
    final exercises = ref.watch(fitnessExercisesProvider).value ?? [];
    final assignmentsAsync = ref.watch(allAssignmentsProvider);
    final assignments = assignmentsAsync.value ?? [];
    final birthYears = children.map((c) => c.birthYear).toSet().toList()..sort();
    final matched = _matched(children, groups);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Description ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Спортсмени накопичують результати зі своїх тренувань. '
                  'Завдання виконано, коли сума записів досягла цілі до дедлайну.',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Filter ────────────────────────────────────────────────────────
        _FilterCard(
          groups: groups,
          birthYears: birthYears,
          selectedGroupIds: _selectedGroupIds,
          selectedYears: _selectedYears,
          selectedBelts: _selectedBelts,
          matchCount: matched.length,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 16),

        // ── Assignment form ───────────────────────────────────────────────
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Нове завдання',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 16),

              // Title
              TextField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Назва завдання',
                  hintText: 'напр. 100 відтискань за тиждень',
                  prefixIcon: Icon(Icons.edit_outlined,
                      color: AppColors.textSecondary),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              _GoalFormCard(
                exercises: exercises,
                exerciseId: _exerciseId,
                exerciseUnit: _exerciseUnit,
                valueCtrl: _valueCtrl,
                deadline: _deadline,
                onExerciseChanged: (id, name, unit) => setState(() {
                  _exerciseId = id;
                  _exerciseName = name;
                  _exerciseUnit = unit;
                }),
                onDeadlineChanged: (d) => setState(() => _deadline = d),
                onValueChanged: () => setState(() {}),
                embedded: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        GradientButton(
          onPressed: (_canCreate && matched.isNotEmpty) ? () => _create(matched) : null,
          isLoading: _saving,
          child: Text(
            matched.isEmpty
                ? 'Оберіть спортсменів і заповніть форму'
                : 'Створити для ${matched.length} спортсменів',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        const SizedBox(height: 24),

        // ── Existing assignments ──────────────────────────────────────────
        if (assignments.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Усі завдання',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textSecondary),
            ),
          ),
          ...assignments.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AssignmentListTile(
                  assignment: a,
                  onDelete: () => _delete(a.id),
                ),
              )),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Assignment list tile
// ─────────────────────────────────────────────────────────────────────────────

class _AssignmentListTile extends StatelessWidget {
  const _AssignmentListTile({
    required this.assignment,
    required this.onDelete,
  });

  final FitnessAssignment assignment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final active = assignment.isActive;
    final statusColor = active ? AppColors.success : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.surface3,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.assignment_outlined, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  '${assignment.exerciseName} · '
                  '${_fmtVal(assignment.targetValue)} ${assignment.exerciseUnit}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                Text(
                  '${assignment.assignedChildIds.length} спортсменів · '
                  'до ${_fmt(assignment.deadline)}',
                  style: TextStyle(
                    color: active ? AppColors.success : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
            onPressed: onDelete,
            tooltip: 'Видалити',
          ),
        ],
      ),
    );
  }

  static String _fmtVal(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: filter card
// ─────────────────────────────────────────────────────────────────────────────

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.groups,
    required this.birthYears,
    required this.selectedGroupIds,
    required this.selectedYears,
    required this.selectedBelts,
    required this.matchCount,
    required this.onChanged,
  });

  final List<GroupModel> groups;
  final List<int> birthYears;
  final Set<String> selectedGroupIds;
  final Set<int> selectedYears;
  final Set<BeltLevel> selectedBelts;
  final int matchCount;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Фільтр спортсменів',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          const Text(
            'Умови поєднуються як "І". Порожня категорія не обмежує вибірку.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),

          if (groups.isNotEmpty) ...[
            _FilterHeader(
              label: 'Групи',
              count: selectedGroupIds.length,
              onClear: selectedGroupIds.isEmpty
                  ? null
                  : () { selectedGroupIds.clear(); onChanged(); },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: groups
                  .map((g) => _Chip(
                        label: g.name,
                        selected: selectedGroupIds.contains(g.id),
                        onTap: () {
                          selectedGroupIds.contains(g.id)
                              ? selectedGroupIds.remove(g.id)
                              : selectedGroupIds.add(g.id);
                          onChanged();
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          _FilterHeader(
            label: 'Рік народження',
            count: selectedYears.length,
            onClear: selectedYears.isEmpty
                ? null
                : () { selectedYears.clear(); onChanged(); },
          ),
          const SizedBox(height: 8),
          birthYears.isEmpty
              ? const Text('Немає даних',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
              : Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: birthYears
                      .map((y) => _Chip(
                            label: '$y',
                            selected: selectedYears.contains(y),
                            onTap: () {
                              selectedYears.contains(y)
                                  ? selectedYears.remove(y)
                                  : selectedYears.add(y);
                              onChanged();
                            },
                          ))
                      .toList(),
                ),
          const SizedBox(height: 16),

          _FilterHeader(
            label: 'Пояс',
            count: selectedBelts.length,
            onClear: selectedBelts.isEmpty
                ? null
                : () { selectedBelts.clear(); onChanged(); },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: BeltLevel.values
                .where((b) => b != BeltLevel.white)
                .map((b) => _Chip(
                      label: b.displayName,
                      selected: selectedBelts.contains(b),
                      onTap: () {
                        selectedBelts.contains(b)
                            ? selectedBelts.remove(b)
                            : selectedBelts.add(b);
                        onChanged();
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: matchCount == 0
                      ? AppColors.surface3
                      : AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: matchCount == 0
                        ? AppColors.surface3
                        : AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  matchCount == 0
                      ? 'Спортсменів не знайдено'
                      : 'Знайдено: $matchCount спортсменів',
                  style: TextStyle(
                    color: matchCount == 0
                        ? AppColors.textSecondary
                        : AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: goal / assignment form fields (exercise + value + deadline)
// ─────────────────────────────────────────────────────────────────────────────

class _GoalFormCard extends StatelessWidget {
  const _GoalFormCard({
    required this.exercises,
    required this.exerciseId,
    required this.exerciseUnit,
    required this.valueCtrl,
    required this.deadline,
    required this.onExerciseChanged,
    required this.onDeadlineChanged,
    required this.onValueChanged,
    this.embedded = false,
  });

  final List<FitnessExercise> exercises;
  final String? exerciseId;
  final String exerciseUnit;
  final TextEditingController valueCtrl;
  final DateTime deadline;
  final void Function(String id, String name, String unit) onExerciseChanged;
  final void Function(DateTime) onDeadlineChanged;
  final VoidCallback onValueChanged;
  final bool embedded;

  Future<void> _pickDeadline(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('uk'),
      initialDate: deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) onDeadlineChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!embedded) ...[
          const Text('Ціль',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
        ],

        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Вправа',
            prefixIcon: Icon(Icons.fitness_center, color: AppColors.textSecondary),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          child: DropdownButton<String>(
            value: exerciseId,
            isExpanded: true,
            isDense: true,
            underline: const SizedBox.shrink(),
            hint: Text(
              exercises.isEmpty ? 'Завантаження...' : 'Оберіть вправу',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            items: exercises
                .map((e) => DropdownMenuItem<String>(
                      value: e.id,
                      child: Text(e.name),
                    ))
                .toList(),
            onChanged: (id) {
              if (id == null) return;
              final ex = exercises.firstWhere((e) => e.id == id);
              onExerciseChanged(ex.id, ex.name, ex.unit);
            },
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: valueCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Ціль (накопичено)',
            hintText: 'напр. 100',
            prefixIcon: const Icon(Icons.track_changes,
                color: AppColors.textSecondary),
            suffixText: exerciseUnit,
            isDense: true,
          ),
          onChanged: (_) => onValueChanged(),
        ),
        const SizedBox(height: 16),

        InkWell(
          onTap: () => _pickDeadline(context),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Дедлайн',
              prefixIcon: Icon(Icons.calendar_today,
                  color: AppColors.textSecondary),
              isDense: true,
              suffixIcon:
                  Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
            ),
            child: Text(_fmt(deadline),
                style: const TextStyle(fontSize: 14)),
          ),
        ),
      ],
    );

    return embedded ? content : _SurfaceCard(child: content);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surface3),
        ),
        child: child,
      );
}

class _FilterHeader extends StatelessWidget {
  const _FilterHeader(
      {required this.label, required this.count, this.onClear});
  final String label;
  final int count;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textSecondary)),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10)),
              child: Text('$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ],
          const Spacer(),
          if (onClear != null)
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Очистити',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ),
        ],
      );
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface3,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.surface3.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

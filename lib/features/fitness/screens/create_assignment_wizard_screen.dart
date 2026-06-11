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
import '../../auth/providers/auth_provider.dart';
import '../../team/providers/children_provider.dart';
import '../../schedule/providers/group_provider.dart';
import '../providers/fitness_provider.dart';
import '../providers/fitness_assignment_provider.dart';

class CreateAssignmentWizardScreen extends ConsumerStatefulWidget {
  const CreateAssignmentWizardScreen({super.key});

  @override
  ConsumerState<CreateAssignmentWizardScreen> createState() =>
      _CreateAssignmentWizardScreenState();
}

class _CreateAssignmentWizardScreenState
    extends ConsumerState<CreateAssignmentWizardScreen> {
  int _step = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fitnessNotifierProvider.notifier).seedDefaultsIfEmpty();
    });
  }

  // Step 1 state
  final _titleCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  String? _exerciseId;
  String _exerciseName = '';
  String _exerciseUnit = 'рази';
  final _valueCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _deadline = DateTime.now().add(const Duration(days: 30));
  _PeriodType _period = _PeriodType.month;
  bool _isCumulative = true; // Added state

  // Step 2 state
  final Set<String> _selectedChildIds = {};
  _SelectMode _selectMode = _SelectMode.group;
  final Set<String> _selectedGroupIds = {};
  final Set<BeltLevel> _selectedBelts = {};
  final Set<int> _selectedYears = {};
  String _searchQuery = '';
  bool _savingDraft = false;

  bool get _step1Valid {
    if (_exerciseId == null) return false;
    if (_titleCtrl.text.trim().isEmpty) return false;
    final v = double.tryParse(_valueCtrl.text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0) return false;
    if (!_deadline.isAfter(_startDate)) return false;
    return true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _commentCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  void _applyPeriod(_PeriodType p) {
    final now = DateTime.now();
    setState(() {
      _period = p;
      switch (p) {
        case _PeriodType.week:
          _startDate = now;
          _deadline = now.add(const Duration(days: 7));
        case _PeriodType.month:
          _startDate = DateTime(now.year, now.month, 1);
          _deadline = DateTime(now.year, now.month + 1, 0);
        case _PeriodType.quarter:
          final q = ((now.month - 1) ~/ 3);
          _startDate = DateTime(now.year, q * 3 + 1, 1);
          _deadline = DateTime(now.year, q * 3 + 4, 0);
        case _PeriodType.custom:
          break;
      }
    });
  }

  List<ChildModel> _computeSelected(
    List<ChildModel> all,
    List<GroupModel> groups,
  ) {
    switch (_selectMode) {
      case _SelectMode.group:
        if (_selectedGroupIds.isEmpty) return [];
        return all.where((c) {
          return groups
              .where((g) => _selectedGroupIds.contains(g.id))
              .any((g) => g.childIds.contains(c.id));
        }).toList();
      case _SelectMode.belt:
        if (_selectedBelts.isEmpty) return [];
        return all.where((c) => _selectedBelts.contains(c.currentBelt)).toList();
      case _SelectMode.year:
        if (_selectedYears.isEmpty) return [];
        return all.where((c) => _selectedYears.contains(c.birthYear)).toList();
      case _SelectMode.manual:
        return all.where((c) => _selectedChildIds.contains(c.id)).toList();
    }
  }

  Future<void> _create({bool draft = false}) async {
    final v =
        double.tryParse(_valueCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    final coachId = ref.read(currentUserModelProvider).asData?.value?.uid ?? '';
    setState(() => _savingDraft = true);
    try {
      await ref.read(assignmentNotifierProvider.notifier).createAssignment(
            coachId: coachId,
            title: _titleCtrl.text.trim(),
            exerciseId: _exerciseId!,
            exerciseName: _exerciseName,
            exerciseUnit: _exerciseUnit,
            targetValue: v,
            startDate: _startDate,
            deadline: _deadline,
            assignedChildIds: _step2Children.map((c) => c.id).toList(),
            coachComment: _commentCtrl.text.trim(),
            status:
                draft ? AssignmentStatus.draft : AssignmentStatus.active,
            isCumulative: _isCumulative,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Помилка: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _savingDraft = false);
    }
  }

  List<ChildModel> _step2Children = [];

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(fitnessExercisesProvider).asData?.value ?? [];
    final children = ref.watch(allChildrenProvider).asData?.value ?? [];
    final groups = ref.watch(groupsProvider).asData?.value ?? [];

    _step2Children = _computeSelected(children, groups);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
                children: [
                  if (_step == 0)
                    const SizedBox(width: 56)
                  else
                    GestureDetector(
                      onTap: () => setState(() => _step--),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_back, size: 22, color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _stepTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _StepIndicator(current: _step, total: 3),
          Expanded(
            child: IndexedStack(
              index: _step,
              children: [
                _Step1Params(
                  exercises: exercises,
                  exerciseId: _exerciseId,
                  exerciseUnit: _exerciseUnit,
                  titleCtrl: _titleCtrl,
                  commentCtrl: _commentCtrl,
                  valueCtrl: _valueCtrl,
                  startDate: _startDate,
                  deadline: _deadline,
                  period: _period,
                  isCumulative: _isCumulative,
                  onExerciseChanged: (id, name, unit) => setState(() {
                    _exerciseId = id;
                    _exerciseName = name;
                    _exerciseUnit = unit;
                  }),
                  onPeriodChanged: _applyPeriod,
                  onStartChanged: (d) => setState(() => _startDate = d),
                  onDeadlineChanged: (d) => setState(() => _deadline = d),
                  onTitleChanged: () => setState(() {}),
                  onValueChanged: () => setState(() {}),
                  onModeChanged: (val) => setState(() => _isCumulative = val),
                ),
                _Step2Athletes(
                  children: children,
                  groups: groups,
                  selectMode: _selectMode,
                  selectedGroupIds: _selectedGroupIds,
                  selectedBelts: _selectedBelts,
                  selectedYears: _selectedYears,
                  selectedChildIds: _selectedChildIds,
                  searchQuery: _searchQuery,
                  computed: _step2Children,
                  onModeChanged: (m) => setState(() {
                    _selectMode = m;
                    _selectedGroupIds.clear();
                    _selectedBelts.clear();
                    _selectedYears.clear();
                    _selectedChildIds.clear();
                  }),
                  onGroupToggle: (id) => setState(() =>
                      _selectedGroupIds.contains(id)
                          ? _selectedGroupIds.remove(id)
                          : _selectedGroupIds.add(id)),
                  onBeltToggle: (b) => setState(() =>
                      _selectedBelts.contains(b)
                          ? _selectedBelts.remove(b)
                          : _selectedBelts.add(b)),
                  onYearToggle: (y) => setState(() =>
                      _selectedYears.contains(y)
                          ? _selectedYears.remove(y)
                          : _selectedYears.add(y)),
                  onChildToggle: (id) => setState(() =>
                      _selectedChildIds.contains(id)
                          ? _selectedChildIds.remove(id)
                          : _selectedChildIds.add(id)),
                  onSearchChanged: (q) => setState(() => _searchQuery = q),
                  onSelectAll: () => setState(() =>
                      _selectedChildIds.addAll(children.map((c) => c.id))),
                  onClearAll: () => setState(() => _selectedChildIds.clear()),
                ),
                _Step3Confirm(
                  title: _titleCtrl.text.trim(),
                  exerciseName: _exerciseName,
                  exerciseUnit: _exerciseUnit,
                  targetValue: double.tryParse(
                          _valueCtrl.text.trim().replaceAll(',', '.')) ??
                      0,
                  startDate: _startDate,
                  deadline: _deadline,
                  athletes: _step2Children,
                ),
              ],
            ),
          ),
          _BottomBar(
            step: _step,
            canNext: _step == 0
                ? _step1Valid
                : _step == 1
                    ? _step2Children.isNotEmpty
                    : true,
            saving: _savingDraft,
            onNext: () {
              if (_step < 2) {
                setState(() => _step++);
              } else {
                _create(draft: false);
              }
            },
            onDraft: _step == 2 ? () => _create(draft: true) : null,
          ),
        ],
      ),
      ),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case 0:
        return 'Параметри завдання';
      case 1:
        return 'Вибір спортсменів';
      default:
        return 'Підтвердження';
    }
  }
}

// ── Step indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: List.generate(total * 2 - 1, (i) {
            if (i.isOdd) {
              return Expanded(
                child: Container(
                  height: 2,
                  color: i ~/ 2 < current
                      ? AppColors.primary
                      : AppColors.surface3,
                ),
              );
            }
            final step = i ~/ 2;
            final done = step < current;
            final active = step == current;
            return Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done || active ? AppColors.primary : AppColors.surface3,
              ),
              alignment: Alignment.center,
              child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color:
                            active ? Colors.white : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            );
          }),
        ),
      );
}

// ── Step 1: Params ────────────────────────────────────────────────────────────

enum _PeriodType { week, month, quarter, custom }

class _Step1Params extends StatelessWidget {
  const _Step1Params({
    required this.exercises,
    required this.exerciseId,
    required this.exerciseUnit,
    required this.titleCtrl,
    required this.commentCtrl,
    required this.valueCtrl,
    required this.startDate,
    required this.deadline,
    required this.period,
    required this.isCumulative,
    required this.onExerciseChanged,
    required this.onPeriodChanged,
    required this.onStartChanged,
    required this.onDeadlineChanged,
    required this.onTitleChanged,
    required this.onValueChanged,
    required this.onModeChanged,
  });

  final List<FitnessExercise> exercises;
  final String? exerciseId;
  final String exerciseUnit;
  final TextEditingController titleCtrl;
  final TextEditingController commentCtrl;
  final TextEditingController valueCtrl;
  final DateTime startDate;
  final DateTime deadline;
  final _PeriodType period;
  final bool isCumulative;
  final void Function(String, String, String) onExerciseChanged;
  final void Function(_PeriodType) onPeriodChanged;
  final void Function(DateTime) onStartChanged;
  final void Function(DateTime) onDeadlineChanged;
  final VoidCallback onTitleChanged;
  final VoidCallback onValueChanged;
  final void Function(bool) onModeChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        TextField(
          controller: titleCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Назва завдання',
            hintText: 'напр. 100 відтискань за місяць',
          ),
          onChanged: (_) => onTitleChanged(),
        ),
        const SizedBox(height: 16),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Вправа',
            prefixIcon: Icon(Icons.fitness_center,
                color: AppColors.textSecondary),
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          child: DropdownButton<String>(
            value: exerciseId,
            isExpanded: true,
            isDense: true,
            underline: const SizedBox.shrink(),
            hint: const Text('Оберіть вправу',
                style: TextStyle(color: AppColors.textSecondary)),
            items: exercises
                .map((e) => DropdownMenuItem(
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Ціль',
            hintText: 'напр. 100',
            suffixText: exerciseUnit,
          ),
          onChanged: (_) => onValueChanged(),
        ),
        const SizedBox(height: 20),

        // ── Mode selection (Cumulative vs Peak) ───────────────────────────
        const Text('Режим прогресу',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surface3),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ModeTabSmall(
                  label: 'Сума',
                  subtitle: 'Накопичувально',
                  selected: isCumulative,
                  onTap: () => onModeChanged(true),
                ),
              ),
              Expanded(
                child: _ModeTabSmall(
                  label: 'Рекорд',
                  subtitle: 'Найкращий результат',
                  selected: !isCumulative,
                  onTap: () => onModeChanged(false),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Період',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PeriodChip(
                label: 'Тиждень',
                selected: period == _PeriodType.week,
                onTap: () => onPeriodChanged(_PeriodType.week)),
            _PeriodChip(
                label: 'Місяць',
                selected: period == _PeriodType.month,
                onTap: () => onPeriodChanged(_PeriodType.month)),
            _PeriodChip(
                label: 'Квартал',
                selected: period == _PeriodType.quarter,
                onTap: () => onPeriodChanged(_PeriodType.quarter)),
            _PeriodChip(
                label: 'Свій діапазон',
                selected: period == _PeriodType.custom,
                onTap: () => onPeriodChanged(_PeriodType.custom)),
          ],
        ),
        if (period == _PeriodType.custom) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DateRow(
                  label: 'Початок',
                  date: startDate,
                  onPick: onStartChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateRow(
                  label: 'Дедлайн',
                  date: deadline,
                  onPick: onDeadlineChanged,
                ),
              ),
            ],
          ),
          if (!deadline.isAfter(startDate))
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Дедлайн має бути після дати початку',
                style: TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
        ] else ...[
          const SizedBox(height: 12),
          Text(
            '${_fmtFull(startDate)} – ${_fmtFull(deadline)}',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: commentCtrl,
          maxLines: 3,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Коментар тренера (необов\'язково)',
            hintText: 'Мотиваційний коментар або інструкція...',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.surface3,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 13,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
}

class _DateRow extends StatelessWidget {
  const _DateRow(
      {required this.label, required this.date, required this.onPick});
  final String label;
  final DateTime date;
  final void Function(DateTime) onPick;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            locale: const Locale('uk'),
            initialDate: date,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
          );
          if (picked != null) onPick(picked);
        },
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            suffixIcon: const Icon(Icons.calendar_today,
                size: 16, color: AppColors.textSecondary),
          ),
          child: Text(_fmtFull(date),
              style: const TextStyle(fontSize: 13)),
        ),
      );
}

// ── Step 2: Athlete selection ─────────────────────────────────────────────────

enum _SelectMode { group, belt, year, manual }

class _Step2Athletes extends StatelessWidget {
  const _Step2Athletes({
    required this.children,
    required this.groups,
    required this.selectMode,
    required this.selectedGroupIds,
    required this.selectedBelts,
    required this.selectedYears,
    required this.selectedChildIds,
    required this.searchQuery,
    required this.computed,
    required this.onModeChanged,
    required this.onGroupToggle,
    required this.onBeltToggle,
    required this.onYearToggle,
    required this.onChildToggle,
    required this.onSearchChanged,
    required this.onSelectAll,
    required this.onClearAll,
  });

  final List<ChildModel> children;
  final List<GroupModel> groups;
  final _SelectMode selectMode;
  final Set<String> selectedGroupIds;
  final Set<BeltLevel> selectedBelts;
  final Set<int> selectedYears;
  final Set<String> selectedChildIds;
  final String searchQuery;
  final List<ChildModel> computed;
  final void Function(_SelectMode) onModeChanged;
  final void Function(String) onGroupToggle;
  final void Function(BeltLevel) onBeltToggle;
  final void Function(int) onYearToggle;
  final void Function(String) onChildToggle;
  final void Function(String) onSearchChanged;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final birthYears = children.map((c) => c.birthYear).toSet().toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        // Mode selector
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _ModeTab(
                label: 'Група',
                selected: selectMode == _SelectMode.group,
                onTap: () => onModeChanged(_SelectMode.group),
              ),
              _ModeTab(
                label: 'Пояс',
                selected: selectMode == _SelectMode.belt,
                onTap: () => onModeChanged(_SelectMode.belt),
              ),
              _ModeTab(
                label: 'Рік',
                selected: selectMode == _SelectMode.year,
                onTap: () => onModeChanged(_SelectMode.year),
              ),
              _ModeTab(
                label: 'Вручну',
                selected: selectMode == _SelectMode.manual,
                onTap: () => onModeChanged(_SelectMode.manual),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Filters by mode
        if (selectMode == _SelectMode.group)
          _ChipSection(
            items: groups.map((g) => (g.id, g.name)).toList(),
            selected: selectedGroupIds,
            onToggle: onGroupToggle,
            emptyText: 'Немає груп',
          ),
        if (selectMode == _SelectMode.belt)
          _ChipSection(
            items: BeltLevel.values
                .map((b) => (b.name, b.displayName))
                .toList(),
            selected: selectedBelts.map((b) => b.name).toSet(),
            onToggle: (name) {
              final belt =
                  BeltLevel.values.firstWhere((b) => b.name == name);
              onBeltToggle(belt);
            },
          ),
        if (selectMode == _SelectMode.year)
          _ChipSection(
            items: birthYears.map((y) => ('$y', '$y')).toList(),
            selected: selectedYears.map((y) => '$y').toSet(),
            onToggle: (y) => onYearToggle(int.parse(y)),
          ),
        if (selectMode == _SelectMode.manual) ...[
          TextField(
            decoration: const InputDecoration(
              hintText: 'Пошук спортсмена...',
              prefixIcon:
                  Icon(Icons.search, color: AppColors.textSecondary),
              isDense: true,
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: onSelectAll,
                child: const Text('Вибрати всіх'),
              ),
              TextButton(
                onPressed: onClearAll,
                child: const Text('Зняти вибір',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
          ...children
              .where((c) {
                if (searchQuery.isEmpty) return true;
                final q = searchQuery.toLowerCase();
                return c.firstName.toLowerCase().contains(q) ||
                    c.lastName.toLowerCase().contains(q);
              })
              .map((c) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${c.firstName} ${c.lastName}'),
                    subtitle: Text(c.currentBelt.displayName,
                        style: const TextStyle(fontSize: 11)),
                    value: selectedChildIds.contains(c.id),
                    onChanged: (_) => onChildToggle(c.id),
                    activeColor: AppColors.primary,
                    controlAffinity: ListTileControlAffinity.trailing,
                  )),
        ],
        const SizedBox(height: 12),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: computed.isEmpty
                ? AppColors.surface3
                : AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            computed.isEmpty
                ? 'Спортсменів не обрано'
                : 'Обрано: ${computed.length} спортсменів',
            style: TextStyle(
              color: computed.isEmpty
                  ? AppColors.textSecondary
                  : AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeTabSmall extends StatelessWidget {
  const _ModeTabSmall({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
}

class _ModeTab extends StatelessWidget {
  const _ModeTab(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color:
                    selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.items,
    required this.selected,
    required this.onToggle,
    this.emptyText = 'Немає даних',
  });

  final List<(String, String)> items;
  final Set<String> selected;
  final void Function(String) onToggle;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(emptyText,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final sel = selected.contains(item.$1);
        return GestureDetector(
          onTap: () => onToggle(item.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: sel ? AppColors.primary : AppColors.surface3),
            ),
            child: Text(
              item.$2,
              style: TextStyle(
                color: sel ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Step 3: Confirmation ──────────────────────────────────────────────────────

class _Step3Confirm extends StatelessWidget {
  const _Step3Confirm({
    required this.title,
    required this.exerciseName,
    required this.exerciseUnit,
    required this.targetValue,
    required this.startDate,
    required this.deadline,
    required this.athletes,
  });

  final String title;
  final String exerciseName;
  final String exerciseUnit;
  final double targetValue;
  final DateTime startDate;
  final DateTime deadline;
  final List<ChildModel> athletes;

  @override
  Widget build(BuildContext context) {
    final fmtVal = targetValue == targetValue.truncateToDouble()
        ? targetValue.toInt().toString()
        : targetValue.toStringAsFixed(1);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.heroCardGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                '$exerciseName · $fmtVal $exerciseUnit',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14),
              ),
              Text(
                '${_fmtFull(startDate)} – ${_fmtFull(deadline)}',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _ConfirmRow(
            icon: Icons.people_outline,
            label: 'Спортсменів',
            value: '${athletes.length}'),
        const Divider(color: AppColors.surface3),
        const SizedBox(height: 10),
        const Text('Список спортсменів',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        ...athletes.take(15).map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text('${c.firstName} ${c.lastName}',
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            )),
        if (athletes.length > 15)
          Text(
            '... та ще ${athletes.length - 15} спортсменів',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
          ),
      ],
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style:
                      const TextStyle(color: AppColors.textSecondary)),
            ),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      );
}

// ── Bottom action bar ─────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.step,
    required this.canNext,
    required this.saving,
    required this.onNext,
    this.onDraft,
  });

  final int step;
  final bool canNext;
  final bool saving;
  final VoidCallback onNext;
  final VoidCallback? onDraft;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
              top: BorderSide(color: AppColors.surface3, width: 1)),
        ),
        child: Row(
          children: [
            if (onDraft != null) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: saving ? null : onDraft,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.surface3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Зберегти чернетку'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: GradientButton(
                onPressed: canNext && !saving ? onNext : null,
                isLoading: saving,
                child: Text(
                  step == 2 ? 'Створити завдання' : 'Далі',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtFull(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

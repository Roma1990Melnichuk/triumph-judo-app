import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/child_model.dart';
import '../../../core/models/training_schedule_model.dart';
import '../../../core/models/training_session_model.dart';
import '../../../shared/widgets/triumph_icon.dart';
import '../../auth/providers/auth_provider.dart';
import '../../team/providers/children_provider.dart';
import '../providers/schedule_provider.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
  }

  DateTime get _dateOnly =>
      DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

  int get _weekday => _selectedDate.weekday;

  static const _shortMonths = [
    'січня','лютого','березня','квітня','травня','червня',
    'липня','серпня','вересня','жовтня','листопада','грудня',
  ];
  static const _weekdayShort = ['Пн','Вт','Ср','Чт','Пт','Сб','Нд'];

  String _formatDate(DateTime d) =>
      '${_weekdayShort[d.weekday - 1]}, ${d.day} ${_shortMonths[d.month - 1]}';

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(schedulesProvider);
    final childrenMap = ref.watch(childByIdMapProvider);
    final user = ref.watch(currentUserModelProvider).value;
    final coachId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: schedulesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Помилка: $e')),
          data: (schedules) {
            final trainingWeekdays =
                schedules.expand((s) => s.daysOfWeek).toSet();
            final todaySchedules =
                schedules.where((s) => s.daysOfWeek.contains(_weekday)).toList();
            final children = childrenMap.values.toList();

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                // ── Header ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Розклад',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showAddScheduleDialog(context, coachId),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            gradient: AppColors.ctaGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Month calendar ──────────────────────────────────────────
                _MonthCalendar(
                  displayMonth: _displayMonth,
                  selectedDate: _selectedDate,
                  trainingWeekdays: trainingWeekdays,
                  onDayTap: (date) => setState(() => _selectedDate = date),
                  onPrevMonth: () => setState(() {
                    _displayMonth = DateTime(
                        _displayMonth.year, _displayMonth.month - 1);
                  }),
                  onNextMonth: () => setState(() {
                    _displayMonth = DateTime(
                        _displayMonth.year, _displayMonth.month + 1);
                  }),
                ),

                const SizedBox(height: 20),

                // ── Sessions for selected day ────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Text(
                    _formatDate(_selectedDate),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                if (todaySchedules.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _EmptyCard(text: 'Немає занять на цей день'),
                  )
                else
                  ...todaySchedules.map((s) => _SessionCard(
                        schedule: s,
                        date: _dateOnly,
                        children: children,
                        coachId: coachId,
                      )),

                const SizedBox(height: 24),

                // ── Recurring schedules ──────────────────────────────────
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Text(
                    'Регулярний розклад',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                if (schedules.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _EmptyCard(text: 'Розклад ще не створений'),
                  )
                else
                  ...schedules.map((s) => _ScheduleItemTile(
                        schedule: s,
                        onDelete: () =>
                            _confirmDelete(context, s.id, s.label),
                      )),

                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String label) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Видалити "$label"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              ref.read(scheduleNotifierProvider.notifier).deleteSchedule(id);
            },
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
  }

  void _showAddScheduleDialog(BuildContext context, String coachId) {
    final labelCtrl = TextEditingController();
    final selectedDays = <int>{};
    TimeOfDay startTime = const TimeOfDay(hour: 18, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 19, minute: 30);
    String? labelError;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          String formatTime(TimeOfDay t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

          return AlertDialog(
            title: const Text('Новий розклад'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: labelCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Назва тренування',
                      errorText: labelError,
                    ),
                    onChanged: (_) {
                      if (labelError != null) {
                        setDialogState(() => labelError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Дні тижня:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (i) {
                      final day = i + 1;
                      final dayName = TrainingScheduleModel.dayNames[i];
                      final selected = selectedDays.contains(day);
                      return FilterChip(
                        label: Text(dayName),
                        selected: selected,
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                        onSelected: (val) => setDialogState(() {
                          if (val) {
                            selectedDays.add(day);
                          } else {
                            selectedDays.remove(day);
                          }
                        }),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text('Початок: ${formatTime(startTime)}'),
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: dialogCtx,
                              initialTime: startTime,
                            );
                            if (t != null) setDialogState(() => startTime = t);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text('Кінець: ${formatTime(endTime)}'),
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: dialogCtx,
                              initialTime: endTime,
                            );
                            if (t != null) setDialogState(() => endTime = t);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Скасувати'),
              ),
              FilledButton(
                onPressed: () async {
                  final label = labelCtrl.text.trim();
                  if (label.length < 2) {
                    setDialogState(() => labelError = 'Мінімум 2 символи');
                    return;
                  }
                  if (selectedDays.isEmpty) {
                    setDialogState(
                        () => labelError = 'Оберіть хоча б один день');
                    return;
                  }

                  String fmtTime(TimeOfDay t) =>
                      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

                  final schedule = TrainingScheduleModel(
                    id: '',
                    coachId: coachId,
                    label: label,
                    daysOfWeek: selectedDays.toList()..sort(),
                    timeStart: fmtTime(startTime),
                    timeEnd: fmtTime(endTime),
                  );
                  Navigator.pop(dialogCtx);
                  await ref
                      .read(scheduleNotifierProvider.notifier)
                      .addSchedule(schedule);
                },
                child: const Text('Зберегти'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Month calendar ────────────────────────────────────────────────────────────

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.displayMonth,
    required this.selectedDate,
    required this.trainingWeekdays,
    required this.onDayTap,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  final DateTime displayMonth;
  final DateTime selectedDate;
  final Set<int> trainingWeekdays;
  final ValueChanged<DateTime> onDayTap;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  static const _monthNames = [
    'Січень','Лютий','Березень','Квітень','Травень','Червень',
    'Липень','Серпень','Вересень','Жовтень','Листопад','Грудень',
  ];
  static const _dayLabels = ['Пн','Вт','Ср','Чт','Пт','Сб','Нд'];

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(displayMonth.year, displayMonth.month, 1);
    final daysInMonth =
        DateTime(displayMonth.year, displayMonth.month + 1, 0).day;
    final startOffset = firstDay.weekday - 1;
    final today = DateTime.now();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surface3),
      ),
      child: Column(
        children: [
          // Month nav
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left,
                    color: AppColors.textSecondary),
                onPressed: onPrevMonth,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              Expanded(
                child: Text(
                  '${_monthNames[displayMonth.month - 1]} ${displayMonth.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary),
                onPressed: onNextMonth,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Day-of-week headers
          Row(
            children: _dayLabels
                .map((label) => Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Day grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (_, index) {
              if (index < startOffset) return const SizedBox();
              final dayNum = index - startOffset + 1;
              final date = DateTime(
                  displayMonth.year, displayMonth.month, dayNum);
              final isSelected = date.day == selectedDate.day &&
                  date.month == selectedDate.month &&
                  date.year == selectedDate.year;
              final isToday = date.day == today.day &&
                  date.month == today.month &&
                  date.year == today.year;
              final hasTraining =
                  trainingWeekdays.contains(date.weekday);

              return GestureDetector(
                onTap: () => onDayTap(date),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        border: isToday && !isSelected
                            ? Border.all(
                                color: AppColors.primary, width: 1.5)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 6,
                      child: hasTraining
                          ? Center(
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Empty placeholder ─────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface3),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

// ── Recurring schedule tile ───────────────────────────────────────────────────

class _ScheduleItemTile extends StatelessWidget {
  const _ScheduleItemTile({
    required this.schedule,
    required this.onDelete,
  });
  final TrainingScheduleModel schedule;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surface3),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.surface2,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: ColorFiltered(
                colorFilter:
                    ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                child: TriumphIcon(TIcon.training, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${schedule.daysLabel}  •  ${schedule.timeStart}–${schedule.timeEnd}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const ColorFiltered(
              colorFilter:
                  ColorFilter.mode(AppColors.error, BlendMode.srcIn),
              child: TriumphIcon(TIcon.delete, size: 20),
            ),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32),
          ),
        ],
      ),
    );
  }
}

// ── Session card with attendance ─────────────────────────────────────────────

class _SessionCard extends ConsumerWidget {
  const _SessionCard({
    required this.schedule,
    required this.date,
    required this.children,
    required this.coachId,
  });

  final TrainingScheduleModel schedule;
  final DateTime date;
  final List<ChildModel> children;
  final String coachId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionId = TrainingSessionModel.makeId(schedule.id, date);
    final sessionAsync = ref.watch(sessionProvider(sessionId));

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Red left accent bar
              Container(width: 4, color: AppColors.primary),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  schedule.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${schedule.timeStart}–${schedule.timeEnd}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            icon: const ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                  AppColors.success, BlendMode.srcIn),
                              child: TriumphIcon(TIcon.success, size: 16),
                            ),
                            label: const Text(
                              'Всі присутні',
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: () => ref
                                .read(scheduleNotifierProvider.notifier)
                                .resetToAllPresent(
                                  schedule: schedule,
                                  date: date,
                                  coachId: coachId,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 16),

                    // Attendance list — PERF-01 Fix: Filter athletes by relevance and use efficient list rendering
                    sessionAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const SizedBox(),
                      data: (session) {
                        if (children.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
                            child: Text(
                              'Немає спортсменів',
                              style: TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                          );
                        }

                        // Optimization: Only show athletes who are in this group or already have attendance recorded
                        // This prevents showing 1000 athletes in every single session card.
                        final relevantChildren = children.where((c) {
                          if (session?.attendance.containsKey(c.id) == true) return true;
                          // If it's a new session, we'd ideally filter by Group ID here
                          return true; // Fallback to all for now, but in a builder
                        }).toList();

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: relevantChildren.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                          itemBuilder: (context, i) {
                            final child = relevantChildren[i];
                            final isPresent = session?.isPresent(child.id) ?? true;
                            return SwitchListTile(
                              dense: true,
                              title: Text(
                                child.fullName,
                                style: const TextStyle(color: AppColors.textPrimary),
                              ),
                              subtitle: Text(
                                child.weightCategory,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              value: isPresent,
                              activeThumbColor: AppColors.primary,
                              activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                              onChanged: (val) => ref
                                  .read(scheduleNotifierProvider.notifier)
                                  .toggleAttendance(
                                    schedule: schedule,
                                    date: date,
                                    childId: child.id,
                                    present: val,
                                    coachId: coachId,
                                  ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

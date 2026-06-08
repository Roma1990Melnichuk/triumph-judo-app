import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
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

  DateTime get _dateOnly =>
      DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

  /// ISO weekday: 1=Mon … 7=Sun
  int get _weekday => _selectedDate.weekday;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('uk'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'січня','лютого','березня','квітня','травня','червня',
      'липня','серпня','вересня','жовтня','листопада','грудня',
    ];
    const weekdays = ['Пн','Вт','Ср','Чт','Пт','Сб','Нд'];
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(schedulesProvider);
    final childrenAsync = ref.watch(allChildrenProvider);
    final user = ref.watch(currentUserModelProvider).value;
    final coachId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Розклад тренувань'),
      ),
      body: schedulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Помилка: $e')),
        data: (schedules) {
          final todaySchedules = schedules
              .where((s) => s.daysOfWeek.contains(_weekday))
              .toList();
          final children = childrenAsync.value ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Date picker row ──────────────────────────────────────────
              Card(
                child: ListTile(
                  leading: const ColorFiltered(
                    colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                    child: TriumphIcon(TIcon.calendar, size: 22),
                  ),
                  title: Text(
                    _formatDate(_selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const ColorFiltered(
                    colorFilter: ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn),
                    child: TriumphIcon(TIcon.calendar, size: 20),
                  ),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(height: 16),

              // ── Today's sessions ─────────────────────────────────────────
              const Text(
                'Заняття на обрану дату',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              if (todaySchedules.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Немає занять на цей день',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                )
              else
                ...todaySchedules.map((schedule) => _SessionCard(
                      schedule: schedule,
                      date: _dateOnly,
                      children: children,
                      coachId: coachId,
                    )),

              const SizedBox(height: 24),

              // ── Recurring schedules ──────────────────────────────────────
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Регулярний розклад',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primary),
                    onPressed: () => _showAddScheduleDialog(context, coachId),
                    tooltip: 'Додати розклад',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (schedules.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          ColorFiltered(
                            colorFilter: const ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn),
                            child: TriumphIcon(TIcon.calendar, size: 40),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Розклад ще не створений',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Card(
                  child: Column(
                    children: schedules.asMap().entries.map((entry) {
                      final i = entry.key;
                      final s = entry.value;
                      return Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              radius: 18,
                              child: const ColorFiltered(
                                colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                child: TriumphIcon(TIcon.training, size: 18),
                              ),
                            ),
                            title: Text(
                              s.label,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${s.daysLabel}  •  ${s.timeStart}–${s.timeEnd}',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            trailing: IconButton(
                              icon: const ColorFiltered(colorFilter: ColorFilter.mode(AppColors.error, BlendMode.srcIn), child: TriumphIcon(TIcon.delete, size: 22)),
                              onPressed: () =>
                                  _confirmDelete(context, s.id, s.label),
                            ),
                          ),
                          if (i < schedules.length - 1)
                            const Divider(height: 1),
                        ],
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          );
        },
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
                    setDialogState(() => labelError = 'Оберіть хоча б один день');
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

// ── Session card with attendance toggles ────────────────────────────────────

class _SessionCard extends ConsumerWidget {
  const _SessionCard({
    required this.schedule,
    required this.date,
    required this.children,
    required this.coachId,
  });

  final TrainingScheduleModel schedule;
  final DateTime date;
  final List<dynamic> children;
  final String coachId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionId = TrainingSessionModel.makeId(schedule.id, date);
    final sessionAsync = ref.watch(sessionProvider(sessionId));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
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
                        ),
                      ),
                      Text(
                        '${schedule.timeStart}–${schedule.timeEnd}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  icon: const ColorFiltered(colorFilter: ColorFilter.mode(AppColors.success, BlendMode.srcIn), child: TriumphIcon(TIcon.success, size: 18)),
                  label: const Text('Всі присутні'),
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

          // Children attendance list
          sessionAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox(),
            data: (session) {
              if (children.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    'Немає спортсменів',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return Column(
                children: children.asMap().entries.map((entry) {
                  final i = entry.key;
                  final child = entry.value;
                  final isPresent = session?.isPresent(child.id) ?? true;
                  return Column(
                    children: [
                      SwitchListTile(
                        dense: true,
                        title: Text(child.fullName),
                        subtitle: Text(
                          child.weightCategory,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                        value: isPresent,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => ref
                            .read(scheduleNotifierProvider.notifier)
                            .toggleAttendance(
                              schedule: schedule,
                              date: date,
                              childId: child.id,
                              present: val,
                              coachId: coachId,
                            ),
                      ),
                      if (i < children.length - 1)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

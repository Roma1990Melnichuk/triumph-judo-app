import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/models/group_model.dart';
import '../../../core/models/child_model.dart';
import '../../../shared/widgets/triumph_icon.dart';
import '../../auth/providers/auth_provider.dart';
import '../../team/providers/children_provider.dart';
import '../providers/group_provider.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  DateTime _selectedDate = _todayDateOnly();
  final _searchCtrl = TextEditingController();

  static DateTime _todayDateOnly() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);
    final user = ref.watch(currentUserModelProvider).value;
    final coachId = user?.uid ?? '';

    return groupsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Помилка: $e')),
      ),
      data: (groups) {
        final group = groups.cast<GroupModel?>().firstWhere(
              (g) => g?.id == widget.groupId,
              orElse: () => null,
            );

        if (group == null) {
          return const Scaffold(
            body: Center(child: Text('Групу не знайдено')),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(group.name),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Header card ─────────────────────────────────────────────
              _GroupHeaderCard(
                group: group,
                coachId: coachId,
                onGroupUpdated: (updated) {
                  ref
                      .read(groupNotifierProvider.notifier)
                      .updateGroup(updated);
                },
              ),
              const SizedBox(height: 16),

              // ── Athletes section ────────────────────────────────────────
              _AthletesSection(
                group: group,
                coachId: coachId,
              ),
              const SizedBox(height: 16),

              // ── Attendance section ──────────────────────────────────────
              _AttendanceSection(
                group: group,
                coachId: coachId,
                selectedDate: _selectedDate,
                onDateChanged: (d) => setState(() => _selectedDate = d),
              ),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

// ── Header card ────────────────────────────────────────────────────────────────

class _GroupHeaderCard extends StatelessWidget {
  const _GroupHeaderCard({
    required this.group,
    required this.coachId,
    required this.onGroupUpdated,
  });

  final GroupModel group;
  final String coachId;
  final void Function(GroupModel) onGroupUpdated;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    group.daysLabel,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    '${group.timeStart}–${group.timeEnd}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () =>
                  _showEditDialog(context, group, coachId, onGroupUpdated),
            ),
          ],
        ),
      ),
    );
  }

  static void _showEditDialog(
    BuildContext context,
    GroupModel group,
    String coachId,
    void Function(GroupModel) onSave,
  ) {
    final nameCtrl = TextEditingController(text: group.name);
    final selectedDays = <int>{...group.daysOfWeek};

    TimeOfDay parseTime(String s) {
      final parts = s.split(':');
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 18,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      );
    }

    TimeOfDay startTime = parseTime(group.timeStart);
    TimeOfDay endTime = parseTime(group.timeEnd);
    String? nameError;
    String? daysError;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          String formatTime(TimeOfDay t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

          return AlertDialog(
            title: const Text('Редагувати групу'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Назва групи',
                      errorText: nameError,
                    ),
                    onChanged: (_) {
                      if (nameError != null) {
                        setDialogState(() => nameError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Дні тренувань:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  if (daysError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        daysError!,
                        style: TextStyle(
                            color: Theme.of(dialogCtx).colorScheme.error,
                            fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: List.generate(7, (i) {
                      final day = i + 1;
                      final dayName = GroupModel.dayNames[i];
                      final selected = selectedDays.contains(day);
                      return FilterChip(
                        label: Text(dayName),
                        selected: selected,
                        selectedColor:
                            AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                        onSelected: (val) => setDialogState(() {
                          if (val) {
                            selectedDays.add(day);
                          } else {
                            selectedDays.remove(day);
                          }
                          daysError = null;
                        }),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text('Початок: ${formatTime(startTime)}'),
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: dialogCtx,
                              initialTime: startTime,
                            );
                            if (t != null) {
                              setDialogState(() => startTime = t);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text('Кінець: ${formatTime(endTime)}'),
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: dialogCtx,
                              initialTime: endTime,
                            );
                            if (t != null) {
                              setDialogState(() => endTime = t);
                            }
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
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  bool valid = true;
                  if (name.isEmpty) {
                    setDialogState(() => nameError = 'Вкажіть назву');
                    valid = false;
                  }
                  if (selectedDays.isEmpty) {
                    setDialogState(
                        () => daysError = 'Оберіть хоча б один день');
                    valid = false;
                  }
                  if (!valid) return;

                  String fmt(TimeOfDay t) =>
                      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

                  final updated = group.copyWith(
                    name: name,
                    daysOfWeek: selectedDays.toList()..sort(),
                    timeStart: fmt(startTime),
                    timeEnd: fmt(endTime),
                  );
                  Navigator.pop(dialogCtx);
                  onSave(updated);
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

// ── Athletes section ───────────────────────────────────────────────────────────

class _AthletesSection extends ConsumerStatefulWidget {
  const _AthletesSection({
    required this.group,
    required this.coachId,
  });

  final GroupModel group;
  final String coachId;

  @override
  ConsumerState<_AthletesSection> createState() => _AthletesSectionState();
}

class _AthletesSectionState extends ConsumerState<_AthletesSection> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allChildrenAsync = ref.watch(allChildrenProvider);
    final allChildren = allChildrenAsync.value ?? [];
    final groupChildren = allChildren
        .where((c) => widget.group.childIds.contains(c.id))
        .toList();

    final searchResults = _query.length >= 2
        ? allChildren
            .where((c) =>
                !widget.group.childIds.contains(c.id) &&
                (c.lastName
                        .toLowerCase()
                        .contains(_query.toLowerCase()) ||
                    c.firstName
                        .toLowerCase()
                        .contains(_query.toLowerCase())))
            .take(10)
            .toList()
        : <ChildModel>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Спортсмени',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '${groupChildren.length}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Current members
        if (groupChildren.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Групу ще порожня',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          Card(
            child: Column(
              children: groupChildren.asMap().entries.map((entry) {
                final i = entry.key;
                final child = entry.value;
                return Column(
                  children: [
                    ListTile(
                      dense: true,
                      title: Text(child.fullName),
                      subtitle: Text(
                        '${child.birthYear} р.н.',
                        style:
                            const TextStyle(color: AppColors.textSecondary),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_remove_outlined,
                            size: 20, color: AppColors.error),
                        onPressed: () => ref
                            .read(groupNotifierProvider.notifier)
                            .removeChildFromGroup(
                                widget.group.id, child.id),
                      ),
                    ),
                    if (i < groupChildren.length - 1)
                      const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 12),

        // Search field to add athletes
        TextField(
          controller: _searchCtrl,
          decoration: const InputDecoration(
            hintText: 'Пошук спортсмена для додавання...',
            prefixIcon: Icon(Icons.search),
            isDense: true,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),

        if (searchResults.isNotEmpty) ...[
          const SizedBox(height: 4),
          Card(
            child: Column(
              children: searchResults.asMap().entries.map((entry) {
                final i = entry.key;
                final child = entry.value;
                return Column(
                  children: [
                    ListTile(
                      dense: true,
                      title: Text(child.fullName),
                      subtitle: Text(
                        '${child.birthYear} р.н.',
                        style:
                            const TextStyle(color: AppColors.textSecondary),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_add_outlined,
                            size: 20, color: AppColors.primary),
                        onPressed: () async {
                          await ref
                              .read(groupNotifierProvider.notifier)
                              .addChildToGroup(widget.group.id, child.id);
                          setState(() {
                            _query = '';
                            _searchCtrl.clear();
                          });
                        },
                      ),
                    ),
                    if (i < searchResults.length - 1)
                      const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Attendance section ─────────────────────────────────────────────────────────

class _AttendanceSection extends ConsumerWidget {
  const _AttendanceSection({
    required this.group,
    required this.coachId,
    required this.selectedDate,
    required this.onDateChanged,
  });

  final GroupModel group;
  final String coachId;
  final DateTime selectedDate;
  final void Function(DateTime) onDateChanged;

  List<DateTime> get _trainingDates {
    // Use current season or next season depending on month
    final now = DateTime.now();
    final seasonYear = now.month >= 9 ? now.year : now.year - 1;
    return group.trainingDates(seasonYear);
  }

  DateTime _prevTrainingDate() {
    final dates = _trainingDates;
    final idx =
        dates.indexWhere((d) => !d.isAfter(selectedDate)) - 1;
    if (idx < 0) return dates.first;
    // Find the last training date before selectedDate
    for (var i = dates.length - 1; i >= 0; i--) {
      if (dates[i].isBefore(selectedDate)) return dates[i];
    }
    return dates.first;
  }

  DateTime _nextTrainingDate() {
    final dates = _trainingDates;
    for (final d in dates) {
      if (d.isAfter(selectedDate)) return d;
    }
    return dates.last;
  }

  String _formatDate(DateTime d) {
    const months = [
      'січня', 'лютого', 'березня', 'квітня', 'травня', 'червня',
      'липня', 'серпня', 'вересня', 'жовтня', 'листопада', 'грудня',
    ];
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allChildrenAsync = ref.watch(allChildrenProvider);
    final allChildren = allChildrenAsync.value ?? [];
    final groupChildren = allChildren
        .where((c) => group.childIds.contains(c.id))
        .toList();

    final isTrainingDay =
        group.daysOfWeek.contains(selectedDate.weekday);

    final docId = AttendanceModel.makeId(group.id, selectedDate);
    final attendanceAsync = ref.watch(attendanceDocProvider(docId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Відмітити відсутніх',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Date navigator
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _trainingDates.isEmpty
                      ? null
                      : () => onDateChanged(_prevTrainingDate()),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      locale: const Locale('uk'),
                    );
                    if (picked != null) {
                      onDateChanged(DateTime(
                          picked.year, picked.month, picked.day));
                    }
                  },
                  child: Text(
                    _formatDate(selectedDate),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _trainingDates.isEmpty
                      ? null
                      : () => onDateChanged(_nextTrainingDate()),
                ),
              ],
            ),
          ),
        ),

        if (!isTrainingDay)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Цей день не є тренувальним для групи',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else ...[
          const SizedBox(height: 8),
          if (groupChildren.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Немає спортсменів у групі',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            attendanceAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
              data: (attendance) {
                return Card(
                  child: Column(
                    children: [
                      // "Всі присутні" button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const ColorFiltered(colorFilter: ColorFilter.mode(AppColors.success, BlendMode.srcIn), child: TriumphIcon(TIcon.success, size: 18)),
                              label: const Text('Всі присутні'),
                              onPressed: () => ref
                                  .read(groupNotifierProvider.notifier)
                                  .setAbsences(
                                    groupId: group.id,
                                    coachId: coachId,
                                    date: selectedDate,
                                    absentChildIds: [],
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 8),
                      ...groupChildren.asMap().entries.map((entry) {
                        final i = entry.key;
                        final child = entry.value;
                        final isPresent =
                            attendance?.isPresent(child.id) ?? true;
                        return Column(
                          children: [
                            SwitchListTile(
                              dense: true,
                              title: Text(child.fullName),
                              subtitle: Text(
                                isPresent ? 'Присутній' : 'Відсутній',
                                style: TextStyle(
                                  color: isPresent
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontSize: 12,
                                ),
                              ),
                              value: isPresent,
                              activeThumbColor: AppColors.success,
                              inactiveThumbColor: AppColors.error,
                              onChanged: (val) => ref
                                  .read(groupNotifierProvider.notifier)
                                  .toggleAbsence(
                                    groupId: group.id,
                                    coachId: coachId,
                                    date: selectedDate,
                                    childId: child.id,
                                    absent: !val,
                                  ),
                            ),
                            if (i < groupChildren.length - 1)
                              const Divider(height: 1, indent: 16),
                          ],
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
        ],
      ],
    );
  }
}

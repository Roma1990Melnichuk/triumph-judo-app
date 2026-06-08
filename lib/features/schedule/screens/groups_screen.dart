import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/group_model.dart';
import '../../../shared/widgets/triumph_icon.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/group_provider.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);
    final user = ref.watch(currentUserModelProvider).value;
    final coachId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Групи тренувань'),
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Помилка: $e')),
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ColorFiltered(
                    colorFilter: const ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn),
                    child: TriumphIcon(TIcon.team, size: 64),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Груп ще немає',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Натисніть + щоб створити першу групу',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: groups.length,
            itemBuilder: (context, i) {
              final group = groups[i];
              return Card(
                child: ListTile(
                  title: Text(
                    group.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${group.daysLabel}  •  ${group.timeStart}–${group.timeEnd}\n'
                    '${group.childIds.length} спортсменів',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const ColorFiltered(colorFilter: ColorFilter.mode(AppColors.error, BlendMode.srcIn), child: TriumphIcon(TIcon.delete, size: 22)),
                    onPressed: () => _confirmDelete(context, group),
                  ),
                  onTap: () => context.push('/group/${group.id}'),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGroupDialog(context, coachId),
        child: const ColorFiltered(colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn), child: TriumphIcon(TIcon.add, size: 24)),
      ),
    );
  }

  void _confirmDelete(BuildContext context, GroupModel group) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Видалити групу "${group.name}"?'),
        content: const Text(
            'Групу буде видалено. Записи про відвідуваність збережуться.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(groupNotifierProvider.notifier)
                  .deleteGroup(group.id);
            },
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, String coachId) {
    final nameCtrl = TextEditingController();
    final selectedDays = <int>{};
    TimeOfDay startTime = const TimeOfDay(hour: 18, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 19, minute: 30);
    String? nameError;
    String? daysError;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          String formatTime(TimeOfDay t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

          return AlertDialog(
            title: const Text('Нова група'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.sentences,
                    autofocus: true,
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
                  const Text(
                    'Дні тренувань:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (daysError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        daysError!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
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
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  bool valid = true;
                  if (name.isEmpty) {
                    setDialogState(() => nameError = 'Вкажіть назву групи');
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

                  final group = GroupModel(
                    id: '',
                    coachId: coachId,
                    name: name,
                    childIds: const [],
                    daysOfWeek: selectedDays.toList()..sort(),
                    timeStart: fmt(startTime),
                    timeEnd: fmt(endTime),
                  );
                  Navigator.pop(dialogCtx);
                  await ref
                      .read(groupNotifierProvider.notifier)
                      .createGroup(group);
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

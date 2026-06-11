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
    final user = ref.watch(currentUserModelProvider).asData?.value;
    final coachId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Text(
                'Групи',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            Expanded(
              child: groupsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Помилка: $e')),
                data: (groups) {
                  if (groups.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const ColorFiltered(
                            colorFilter: ColorFilter.mode(
                                AppColors.textSecondary, BlendMode.srcIn),
                            child: TriumphIcon(TIcon.team, size: 64),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Груп ще немає',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Натисніть + щоб створити першу групу',
                            style:
                                TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: groups.length,
                    itemBuilder: (context, i) {
                      final group = groups[i];
                      return _GroupCard(
                        group: group,
                        onTap: () => context.push('/group/${group.id}'),
                        onDelete: () =>
                            _confirmDelete(context, group),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: () => _showCreateGroupDialog(context, coachId),
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            gradient: AppColors.ctaGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x55D50000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
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
              ref.read(groupNotifierProvider.notifier).deleteGroup(group.id);
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
                    setDialogState(
                        () => nameError = 'Вкажіть назву групи');
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

// ── Group card ────────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.onTap,
    required this.onDelete,
  });

  final GroupModel group;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String get _initial =>
      group.name.isNotEmpty ? group.name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showOptions(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surface3),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                gradient: AppColors.ctaGradient,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${group.daysLabel}  •  ${group.timeStart}–${group.timeEnd}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${group.childIds.length} спортсменів',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surface3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const ColorFiltered(
                colorFilter:
                    ColorFilter.mode(AppColors.error, BlendMode.srcIn),
                child: TriumphIcon(TIcon.delete, size: 22),
              ),
              title: const Text(
                'Видалити групу',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:file_picker/file_picker.dart';
import '../../../core/utils/cloudinary_upload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/belt_requirement_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/belt_provider.dart';
import '../../../shared/widgets/belt_badge.dart';
import '../../../shared/widgets/triumph_icon.dart';
import '../../../shared/widgets/video_player_dialog.dart';

class BeltRequirementsScreen extends ConsumerStatefulWidget {
  const BeltRequirementsScreen({super.key});

  @override
  ConsumerState<BeltRequirementsScreen> createState() =>
      _BeltRequirementsScreenState();
}

class _BeltRequirementsScreenState
    extends ConsumerState<BeltRequirementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: BeltLevel.values.length - 1, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserModelProvider).value;
      if (user?.isCoach == true) {
        ref.read(beltNotifierProvider.notifier).seedDefaultsIfEmpty(user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserModelProvider).value;
    final isCoach = user?.isCoach ?? false;
    final allReqs = ref.watch(beltRequirementsProvider);

    // Belts that have requirements (skip black — it's the last)
    final belts = BeltLevel.values.where((b) => !b.isLast).toList();

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
                      'Вимоги до поясів',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (isCoach)
                    GestureDetector(
                      onTap: () => context.push('/bulk-belt'),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.groups, color: AppColors.textPrimary, size: 22),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.accent,
              unselectedLabelColor: Colors.white70,
              indicatorColor: AppColors.accent,
              tabs: belts.map((b) {
                final next = b.next!;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: next.color,
                          shape: BoxShape.circle,
                          border: next == BeltLevel.white
                              ? Border.all(color: Colors.white38)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(next.displayName, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
              onTap: (_) {},
            ),
            Expanded(
              child: allReqs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Помилка: $e')),
        data: (reqs) {
          return TabBarView(
            controller: _tabController,
            children: belts.map((fromBelt) {
              final targetBelt = fromBelt.next!;
              final req = reqs[targetBelt];
              final exercises = req?.exercises ?? [];

              return _BeltTab(
                fromBelt: fromBelt,
                targetBelt: targetBelt,
                exercises: exercises,
                isCoach: isCoach,
                coachId: user?.uid ?? '',
              );
            }).toList(),
          );
        },
      ),
      ),
    ],
  ),
  ),
    );
  }
}

class _BeltTab extends ConsumerStatefulWidget {
  const _BeltTab({
    required this.fromBelt,
    required this.targetBelt,
    required this.exercises,
    required this.isCoach,
    required this.coachId,
  });

  final BeltLevel fromBelt;
  final BeltLevel targetBelt;
  final List<Exercise> exercises;
  final bool isCoach;
  final String coachId;

  @override
  ConsumerState<_BeltTab> createState() => _BeltTabState();
}

class _BeltTabState extends ConsumerState<_BeltTab> {
  late List<Exercise> _exercises;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _exercises = List.from(widget.exercises);
  }

  @override
  void didUpdateWidget(_BeltTab old) {
    super.didUpdateWidget(old);
    if (!_editing) _exercises = List.from(widget.exercises);
  }

  Future<void> _addExercise() async {
    final result = await showDialog<Exercise>(
      context: context,
      builder: (_) => const _ExerciseDialog(),
    );
    if (result != null) {
      setState(() {
        _exercises.add(result);
        _editing = true;
      });
    }
  }

  Future<void> _editExercise(int index) async {
    final result = await showDialog<Exercise>(
      context: context,
      builder: (_) => _ExerciseDialog(initial: _exercises[index]),
    );
    if (result != null) {
      setState(() => _exercises[index] = result);
    }
  }

  Future<void> _save() async {
    await ref.read(beltNotifierProvider.notifier).updateRequirements(
          widget.targetBelt,
          _exercises,
          widget.coachId,
        );
    setState(() => _editing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вимоги збережено')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header — belt progression + exercise count + edit button
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Belt progression row
              Row(
                children: [
                  BeltBadge(belt: widget.fromBelt, size: BeltBadgeSize.medium),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.arrow_forward,
                        size: 20, color: AppColors.textSecondary),
                  ),
                  BeltBadge(belt: widget.targetBelt, size: BeltBadgeSize.medium),
                ],
              ),
              const SizedBox(height: 8),
              // Count + edit button row
              Row(
                children: [
                  Text(
                    '${_exercises.length} вправ',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                  if (widget.isCoach) ...[
                    const Spacer(),
                    if (_editing)
                      TextButton(
                        onPressed: _save,
                        child: const Text('Зберегти'),
                      )
                    else
                      TextButton(
                        onPressed: () => setState(() => _editing = true),
                        child: const Text('Редагувати'),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: _exercises.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.list_alt,
                          size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 8),
                      const Text(
                        'Вимоги ще не додані',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      if (widget.isCoach) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _editing = true);
                            _addExercise();
                          },
                          icon: const Icon(Icons.add, color: Colors.white, size: 18),
                          label: const Text('Додати вправу'),
                        ),
                      ],
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  onReorder: _editing
                      ? (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = _exercises.removeAt(oldIndex);
                            _exercises.insert(newIndex, item);
                          });
                        }
                      : (_, __) {},
                  itemCount: _exercises.length,
                  itemBuilder: (context, i) {
                    final ex = _exercises[i];
                    final hasVideo = ex.videoUrl.isNotEmpty;
                    final trailingItems = <Widget>[
                      if (hasVideo)
                        IconButton(
                          icon: const ColorFiltered(
                            colorFilter: ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
                            child: TriumphIcon(TIcon.video, size: 22),
                          ),
                          tooltip: 'Переглянути відео',
                          onPressed: () => VideoPlayerDialog.show(
                              context, ex.videoUrl, title: ex.name),
                        ),
                      if (_editing) ...[
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editExercise(i),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error),
                          onPressed: () =>
                              setState(() => _exercises.removeAt(i)),
                        ),
                      ],
                    ];
                    return ListTile(
                      key: Key(ex.id),
                      leading: CircleAvatar(
                        backgroundColor: widget.targetBelt.color,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(color: widget.targetBelt.textColor),
                        ),
                      ),
                      title: Text(ex.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: ex.description.isNotEmpty
                          ? Text(ex.description)
                          : null,
                      trailing: trailingItems.isEmpty
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: trailingItems,
                            ),
                    );
                  },
                ),
        ),

        if (widget.isCoach && _editing)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: const Text('Додати вправу'),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exercise add/edit dialog with video support
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseDialog extends StatefulWidget {
  const _ExerciseDialog({this.initial});
  final Exercise? initial;

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _urlCtrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    _descCtrl = TextEditingController(text: widget.initial?.description ?? '');
    _urlCtrl = TextEditingController(text: widget.initial?.videoUrl ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _uploadVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.path == null) return;
    setState(() => _uploading = true);
    try {
      final videoId = const Uuid().v4();
      final url = await uploadVideoToCloudinary(picked.path!, 'exercise_$videoId');
      if (mounted) setState(() => _urlCtrl.text = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Помилка завантаження: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(
      context,
      Exercise(
        id: widget.initial?.id ?? const Uuid().v4(),
        name: name,
        description: _descCtrl.text.trim(),
        category: widget.initial?.category ?? ExerciseCategory.technique,
        videoUrl: _urlCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initial == null;
    return AlertDialog(
      title: Text(isNew ? 'Нова вправа' : 'Редагувати вправу'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                autofocus: isNew,
                decoration:
                    const InputDecoration(labelText: 'Назва вправи'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Опис (необов\'язково)'),
              ),
              const SizedBox(height: 16),
              const Text('Відео (необов\'язково)',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _urlCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Посилання YouTube',
                  hintText: 'https://youtu.be/...',
                  isDense: true,
                  prefixIcon: Icon(Icons.link, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              const Row(children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('або',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
                ),
                Expanded(child: Divider()),
              ]),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _uploading ? null : _uploadVideo,
                  icon: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const ColorFiltered(
                          colorFilter: ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
                          child: TriumphIcon(TIcon.video, size: 18),
                        ),
                  label: Text(_uploading
                      ? 'Завантаження...'
                      : 'Завантажити відео з пристрою'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _uploading ? null : () => Navigator.pop(context),
          child: const Text('Скасувати'),
        ),
        TextButton(
          onPressed: _uploading ? null : _submit,
          child: const Text(
            'Зберегти',
            style: TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

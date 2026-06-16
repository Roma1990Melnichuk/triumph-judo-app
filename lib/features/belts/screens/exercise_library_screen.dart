import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/belt_exercise_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/exercise_library_provider.dart';
import '../../../shared/widgets/app_back_button.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState
    extends ConsumerState<ExerciseLibraryScreen> {
  final _searchCtrl = TextEditingController();
  String         _query   = '';
  BeltLevel?     _belt;
  ExerciseCategory? _cat;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(beltExercisesProvider);
    final isCoach = ref.watch(currentUserModelProvider).asData?.value?.isCoach ?? false;
    final allExercises   = exercisesAsync.asData?.value ?? [];

    // Apply name filter + optional belt + category filters
    var filtered = allExercises;
    if (_belt != null) {
      filtered = filtered.where((e) => e.forBelts.contains(_belt)).toList();
    }
    if (_cat != null) {
      filtered = filtered.where((e) => e.category == _cat).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      filtered = filtered.where((e) => e.name.toLowerCase().contains(q)).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: AppBackButton(onPressed: () => context.pop()),
            title: const Text('Бібліотека вправ',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            actions: isCoach
                ? [
                    IconButton(
                      icon: const Icon(Icons.add_rounded,
                          color: AppColors.orange),
                      onPressed: () =>
                          _showAddExerciseDialog(context, ref),
                    ),
                  ]
                : null,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Назва вправи...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textSecondary),
                    suffixIcon: _query.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                            child: const Icon(Icons.close_rounded,
                                color: AppColors.textSecondary),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ),

          // ── Category filter ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Всі',
                    active: _cat == null,
                    onTap: () => setState(() => _cat = null),
                  ),
                  ...ExerciseCategory.values.map((c) => _FilterChip(
                    label: '${c.emoji} ${c.label}',
                    active: _cat == c,
                    onTap: () =>
                        setState(() => _cat = _cat == c ? null : c),
                  )),
                ],
              ),
            ),
          ),

          // ── Belt filter ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Будь-який пояс',
                    active: _belt == null,
                    onTap: () => setState(() => _belt = null),
                  ),
                  ...BeltLevel.values
                      .where((b) => b != BeltLevel.white)
                      .map((b) => _FilterChip(
                            label: b.name,
                            active: _belt == b,
                            onTap: () => setState(
                                () => _belt = _belt == b ? null : b),
                          )),
                ],
              ),
            ),
          ),

          // ── Results ────────────────────────────────────────────────────────
          exercisesAsync.when(
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Помилка: $e'))),
            data: (_) {
              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🥋', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text('Вправ не знайдено',
                            style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ExerciseCard(
                        ex: filtered[i], isCoach: isCoach, ref: ref),
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    var cat     = ExerciseCategory.throws;
    var belts   = <BeltLevel>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                          color: const Color(0xFF3A3A3A),
                          borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                const Text('Нова вправа',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Назва *'),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Опис'),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                const Text('Категорія',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ExerciseCategory.values.map((c) {
                      final active = cat == c;
                      return GestureDetector(
                        onTap: () => setModal(() => cat = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.orange.withValues(alpha: 0.18)
                                : const Color(0xFF1C1C1C),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active
                                  ? AppColors.orange
                                  : const Color(0xFF2C2C2C),
                            ),
                          ),
                          child: Text('${c.emoji} ${c.label}',
                              style: TextStyle(
                                fontSize: 11,
                                color: active
                                    ? AppColors.orange
                                    : AppColors.textSecondary,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Пояси (для яких підходить)',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: BeltLevel.values.map((b) {
                    final selected = belts.contains(b);
                    return GestureDetector(
                      onTap: () => setModal(() {
                        if (selected) {
                          belts = belts.where((x) => x != b).toList();
                        } else {
                          belts = [...belts, b];
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected
                              ? (b.color).withValues(alpha: 0.18)
                              : const Color(0xFF1C1C1C),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? b.color : const Color(0xFF2C2C2C),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: b.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(b.displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: selected ? b.color : AppColors.textSecondary,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                                )),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    await ref
                        .read(exerciseLibraryNotifierProvider.notifier)
                        .addExercise(
                          name:        name,
                          description: descCtrl.text.trim(),
                          category:    cat,
                          forBelts:    belts,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.black),
                  child: const Text('Зберегти'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Exercise card ─────────────────────────────────────────────────────────────

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({
    required this.ex,
    required this.isCoach,
    required this.ref,
  });

  final BeltExerciseModel ex;
  final bool              isCoach;
  final WidgetRef         ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(ex.category.emoji,
                  style: const TextStyle(fontSize: 20)),
            ),
          ),
          title: Text(ex.name,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          subtitle: Text(ex.category.label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ex.description.isNotEmpty) ...[
                    Text(ex.description,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.5)),
                    const SizedBox(height: 10),
                  ],
                  if (ex.forBelts.isNotEmpty) ...[
                    const Text('Пояси',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ex.forBelts.map((b) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(b.name,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.orange,
                                  fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                    ),
                  ],
                  if (isCoach && !ex.isDefault) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _confirmDelete(context, ref),
                      child: const Text('Видалити вправу',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.error)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Видалити вправу?'),
        content: Text(ex.name),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Скасувати')),
          TextButton(
            onPressed: () {
              ref.read(exerciseLibraryNotifierProvider.notifier)
                  .deleteExercise(ex.id);
              Navigator.pop(context);
            },
            child: const Text('Видалити',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String       label;
  final bool         active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.orange.withValues(alpha: 0.18)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? AppColors.orange : const Color(0xFF2C2C2C)),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? AppColors.orange : AppColors.textSecondary,
            )),
      ),
    );
  }
}

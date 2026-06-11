import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/child_model.dart';
import '../../../shared/widgets/belt_badge.dart';
import '../../../shared/widgets/default_avatar.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../team/providers/children_provider.dart';
import '../../../shared/widgets/triumph_icon.dart';


class BulkBeltScreen extends ConsumerStatefulWidget {
  const BulkBeltScreen({super.key});

  @override
  ConsumerState<BulkBeltScreen> createState() => _BulkBeltScreenState();
}

class _BulkBeltScreenState extends ConsumerState<BulkBeltScreen> {
  BeltLevel? _targetBelt;
  final Set<String> _selected = {};
  DateTime _date = DateTime.now();
  final _commentCtrl = TextEditingController();
  bool _saving = false;

  static final _targetBelts =
      BeltLevel.values.where((b) => b != BeltLevel.white).toList();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  List<ChildModel> _eligible(List<ChildModel> all) {
    if (_targetBelt == null) return all;
    return all
        .where((c) => c.currentBelt.next == _targetBelt)
        .toList()
      ..sort((a, b) => a.lastName.compareTo(b.lastName));
  }

  Future<void> _confirm(List<ChildModel> eligible) async {
    final belt = _targetBelt!;
    final selectedChildren =
        eligible.where((c) => _selected.contains(c.id)).toList();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Підтвердити пояс?'),
        content: Text(
          'Підвищити пояс до "${belt.displayName}" '
          'для ${selectedChildren.length} спортсменів?\n'
          '${_commentCtrl.text.isNotEmpty ? '\nКоментар: ${_commentCtrl.text}' : ''}',
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
      final notifier = ref.read(childrenNotifierProvider.notifier);
      for (final child in selectedChildren) {
        await notifier.advanceBelts(
          childIds: [child.id],
          newBelt: belt,
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
              Expanded(
                child: Text('Пояс "${belt.displayName}" підтверджено для ${selectedChildren.length} спортсменів'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
        ));
        setState(() {
          _selected.clear();
          _saving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Помилка: $e'),
          backgroundColor: AppColors.error,
        ));
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('uk'),
    );
    if (d != null) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(allChildrenProvider);
    final all = childrenAsync.asData?.value ?? [];
    final eligible = _eligible(all);

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
                  const Text(
                    'Масова підтвердження поясів',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [

          // ── Athlete selector ───────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Оберіть спортсменів',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              if (_selected.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Вибрано: ${_selected.length}',
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (childrenAsync.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (eligible.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surface3),
              ),
              child: const Text(
                'Немає спортсменів для обраного поясу',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            )
          else
            // Horizontal avatar grid
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: eligible.length,
                itemBuilder: (_, i) {
                  final child = eligible[i];
                  final isSelected = _selected.contains(child.id);
                  final isReady = child.beltReady;
                  return GestureDetector(
                    onTap: isReady
                        ? () => setState(() {
                              if (isSelected) {
                                _selected.remove(child.id);
                              } else {
                                _selected.add(child.id);
                              }
                            })
                        : null,
                    child: Opacity(
                      opacity: isReady ? 1.0 : 0.45,
                      child: Container(
                        width: 72,
                        margin: const EdgeInsets.only(right: 10),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.accent
                                          : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: child.photoUrl != null
                                      ? CircleAvatar(
                                          radius: 26,
                                          backgroundImage:
                                              NetworkImage(child.photoUrl!),
                                        )
                                      : DefaultAvatarCircle(
                                          gender: child.gender,
                                          radius: 26,
                                          seed: child.id,
                                        ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        color: AppColors.accent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check,
                                          size: 12, color: Colors.black),
                                    ),
                                  )
                                else if (!isReady)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface3,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppColors.background,
                                            width: 1.5),
                                      ),
                                      child: const Icon(Icons.lock_outline,
                                          size: 10,
                                          color: AppColors.textSecondary),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              child.firstName,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),

          // ── Belt target selector ───────────────────────────────────────
          const Text(
            'Новий пояс',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _targetBelts.length,
              itemBuilder: (_, i) {
                final b = _targetBelts[i];
                final active = b == _targetBelt;
                return GestureDetector(
                  onTap: () => setState(() {
                    _targetBelt = b;
                    _selected.clear();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: active
                          ? b.color.withValues(alpha: 0.2)
                          : AppColors.surface2,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? b.color : AppColors.surface3,
                        width: active ? 2.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: b.color,
                          shape: BoxShape.circle,
                          border: b == BeltLevel.white
                              ? Border.all(color: Colors.white38)
                              : null,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_targetBelt != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  BeltBadge(belt: _targetBelt!, size: BeltBadgeSize.small),
                  const SizedBox(width: 8),
                  Text(
                    '${eligible.where((c) => c.beltReady).length} / ${eligible.length} готові до здачі',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // ── Date picker ────────────────────────────────────────────────
          const Text(
            'Дата підтвердження',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surface3),
              ),
              child: Row(
                children: [
                  const ColorFiltered(
                    colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                    child: TriumphIcon(TIcon.calendar, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('dd MMMM yyyy', 'uk').format(_date),
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  const Spacer(),
                  const ColorFiltered(
                    colorFilter: ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn),
                    child: TriumphIcon(TIcon.calendar, size: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Comment ────────────────────────────────────────────────────
          const Text(
            'Коментар (необов\'язково)',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _commentCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Додайте коментар...',
            ),
          ),
          const SizedBox(height: 24),

          // ── Confirm button ─────────────────────────────────────────────
          GradientButton(
            onPressed: _saving || _selected.isEmpty || _targetBelt == null
                ? null
                : () => _confirm(eligible),
            isLoading: _saving,
            child: Text(
              _selected.isEmpty
                  ? 'Оберіть спортсменів'
                  : 'Підтвердити пояс для ${_selected.length} спортсменів',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
      ),
    ],
  ),
  ),
    );
  }
}

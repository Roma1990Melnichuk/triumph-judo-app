import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

import '../../../shared/widgets/gradient_button.dart';
import '../providers/fitness_provider.dart';
import '../providers/fitness_assignment_provider.dart';

class AddAssignmentResultScreen extends ConsumerStatefulWidget {
  const AddAssignmentResultScreen({
    super.key,
    required this.assignmentId,
    required this.childId,
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseUnit,
  });

  final String assignmentId;
  final String childId;
  final String exerciseId;
  final String exerciseName;
  final String exerciseUnit;

  @override
  ConsumerState<AddAssignmentResultScreen> createState() =>
      _AddAssignmentResultScreenState();
}

class _AddAssignmentResultScreenState
    extends ConsumerState<AddAssignmentResultScreen> {
  DateTime _date = DateTime.now();
  final _valueCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  int _difficulty = 1; // 1=easy, 2=medium, 3=hard
  bool _saving = false;

  @override
  void dispose() {
    _valueCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  bool get _canSave {
    final v = double.tryParse(_valueCtrl.text.trim().replaceAll(',', '.'));
    return v != null && v > 0 && !_saving;
  }

  Future<void> _save() async {
    final v =
        double.tryParse(_valueCtrl.text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0) return;
    setState(() => _saving = true);
    try {
      await ref.read(fitnessNotifierProvider.notifier).addLog(
            childId: widget.childId,
            exerciseId: widget.exerciseId,
            exerciseName: widget.exerciseName,
            exerciseUnit: widget.exerciseUnit,
            date: _date,
            value: v,
            difficulty: _difficulty,
            comment: _commentCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Результат збережено ✅'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Помилка: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignment = ref.watch(assignmentByIdProvider(widget.assignmentId));
    final logsAsync = ref.watch(childFitnessLogsProvider(widget.childId));
    final logs = logsAsync.value ?? [];

    final currentProgress = assignment != null
        ? logs
            .where((l) =>
                l.exerciseId == widget.exerciseId &&
                !l.date.isBefore(assignment.startDate) &&
                !l.date.isAfter(assignment.deadline))
            .fold<double>(0.0, (acc, l) => acc + l.value)
        : 0.0;

    final target = assignment?.targetValue ?? 0.0;
    final pct = target > 0
        ? (currentProgress / target).clamp(0.0, 1.0)
        : 0.0;

    final fmtVal = (double v) => v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Додати результат'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          // ── Assignment mini-card ────────────────────────────────────────
          if (assignment != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: AppColors.heroCardGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assignment.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_fmtDate(assignment.startDate)} – ${_fmtDate(assignment.deadline)}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(pct * 100).round()}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${fmtVal(currentProgress)} / ${fmtVal(target)} ${widget.exerciseUnit}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // ── Date ───────────────────────────────────────────────────────
          const Text(
            'Дата',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: assignment?.startDate ??
                    DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _date = picked);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surface3),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text(
                    _fmtDate(_date),
                    style: const TextStyle(fontSize: 15),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Дата не може бути у майбутньому',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 20),

          // ── Result ─────────────────────────────────────────────────────
          const Text(
            'Результат',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _valueCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            autofocus: false,
            decoration: InputDecoration(
              hintText: '0',
              suffixText: widget.exerciseUnit,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.surface3),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.surface3),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          Text(
            'Додане значення буде додано до вашого поточного прогресу',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 20),

          // ── Difficulty ─────────────────────────────────────────────────
          const Text(
            'Складність',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DifficultyBtn(
                  label: 'Легко',
                  icon: Icons.sentiment_satisfied_outlined,
                  color: AppColors.success,
                  selected: _difficulty == 1,
                  onTap: () => setState(() => _difficulty = 1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DifficultyBtn(
                  label: 'Середньо',
                  icon: Icons.sentiment_neutral_outlined,
                  color: AppColors.accent,
                  selected: _difficulty == 2,
                  onTap: () => setState(() => _difficulty = 2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DifficultyBtn(
                  label: 'Важко',
                  icon: Icons.sentiment_dissatisfied_outlined,
                  color: AppColors.primary,
                  selected: _difficulty == 3,
                  onTap: () => setState(() => _difficulty = 3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Comment ────────────────────────────────────────────────────
          TextField(
            controller: _commentCtrl,
            maxLines: 4,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Як пройшло тренування?',
              labelText: 'Коментар (необов\'язково)',
              alignLabelWithHint: true,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.surface3),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.surface3),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: GradientButton(
            onPressed: _canSave ? _save : null,
            isLoading: _saving,
            child: const Text(
              'Зберегти результат',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Difficulty button ─────────────────────────────────────────────────────────

class _DifficultyBtn extends StatelessWidget {
  const _DifficultyBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : AppColors.surface3,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? color : AppColors.textSecondary,
                  size: 26),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

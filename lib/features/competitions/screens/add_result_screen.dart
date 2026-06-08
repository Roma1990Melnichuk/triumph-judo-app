import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/models/competition_result_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/team/providers/children_provider.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/triumph_icon.dart';
import '../providers/competitions_provider.dart';

class AddResultScreen extends ConsumerStatefulWidget {
  const AddResultScreen({super.key, required this.childId});

  final String childId;

  @override
  ConsumerState<AddResultScreen> createState() => _AddResultScreenState();
}

class _AddResultScreenState extends ConsumerState<AddResultScreen> {
  final _formKey = GlobalKey<FormState>();
  final _competitionNameCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController();
  final _placeCtrl = TextEditingController(text: '1');
  CompetitionLevel _level = CompetitionLevel.local;
  int _place = 1;
  DateTime _date = DateTime.now();
  String? _selectedType;
  bool _loading = false;

  @override
  void dispose() {
    _competitionNameCtrl.dispose();
    _pointsCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  // Medal/place button
  Widget _medalButton(int p) {
    final selected = _place == p;
    final emoji = p == 1 ? '🥇' : p == 2 ? '🥈' : '🥉';
    final medalColor = p == 1
        ? AppColors.goldMedal
        : p == 2
            ? AppColors.silverMedal
            : AppColors.bronzeMedal;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: p < 3 ? 8.0 : 0),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _place = p;
              _placeCtrl.text = '$p';
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? medalColor.withValues(alpha: 0.18)
                  : AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? medalColor.withValues(alpha: 0.8)
                    : AppColors.surface3,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  '$p місце',
                  style: TextStyle(
                    color: selected ? medalColor : AppColors.textSecondary,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Level chip
  Widget _levelChip(CompetitionLevel l) {
    final selected = _level == l;
    return GestureDetector(
      onTap: () => setState(() => _level = l),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.redGoldGradient : null,
          color: selected ? null : AppColors.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.surface3,
          ),
        ),
        child: Text(
          l.displayName,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final user = ref.read(currentUserModelProvider).value;
    final child = ref.read(childByIdProvider(widget.childId)).value;

    final result = CompetitionResultModel(
      id: '',
      childId: widget.childId,
      childName: child?.fullName ?? '',
      competitionName: _competitionNameCtrl.text.trim(),
      competitionType: _selectedType ?? '',
      level: _level,
      place: int.tryParse(_placeCtrl.text) ?? _place,
      points: int.tryParse(_pointsCtrl.text) ?? 0,
      date: _date,
      seasonYear: _date.year,
      addedByCoachId: user?.uid ?? '',
    );

    await ref.read(competitionsNotifierProvider.notifier).addResult(result);
    setState(() => _loading = false);

    final error = ref.read(competitionsNotifierProvider).error;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Помилка: $error'),
            backgroundColor: AppColors.error),
      );
    } else if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(competitionTypesProvider);
    final types = typesAsync.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Додати результат')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Competition name ─────────────────────────────────────────
              TextFormField(
                controller: _competitionNameCtrl,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                enableSuggestions: true,
                decoration: const InputDecoration(
                  labelText: 'Назва змагань',
                  prefixIcon: ColorFiltered(
                    colorFilter: ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn),
                    child: TriumphIcon(TIcon.trophy, size: 22),
                  ),
                ),
                validator: FormValidators.competitionName,
              ),
              const SizedBox(height: 16),

              // ── Competition type ─────────────────────────────────────────
              if (types.isNotEmpty) ...[
                _sectionLabel('Тип змагань'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  dropdownColor: AppColors.surface2,
                  decoration: const InputDecoration(
                    prefixIcon: ColorFiltered(
                      colorFilter: ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn),
                      child: TriumphIcon(TIcon.category, size: 22),
                    ),
                    hintText: 'Оберіть тип',
                  ),
                  items: types
                      .map((t) => DropdownMenuItem(
                            value: t.name,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedType = v),
                ),
                const SizedBox(height: 16),
              ],

              // ── Level ────────────────────────────────────────────────────
              _sectionLabel('Рівень змагань'),
              const SizedBox(height: 10),
              Wrap(
                children: CompetitionLevel.values
                    .map(_levelChip)
                    .toList(),
              ),
              const SizedBox(height: 16),

              // ── Place: medal buttons ─────────────────────────────────────
              _sectionLabel('Місце'),
              const SizedBox(height: 10),
              Row(
                children: [1, 2, 3].map(_medalButton).toList(),
              ),
              const SizedBox(height: 10),

              // Manual place override
              TextFormField(
                controller: _placeCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Або введіть будь-яке місце',
                  prefixIcon: const Icon(Icons.format_list_numbered),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          final v = int.tryParse(_placeCtrl.text) ?? 1;
                          if (v > 1) {
                            setState(() {
                              _place = v - 1;
                              _placeCtrl.text = '$_place';
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          final v = int.tryParse(_placeCtrl.text) ?? 1;
                          setState(() {
                            _place = v + 1;
                            _placeCtrl.text = '$_place';
                          });
                        },
                      ),
                    ],
                  ),
                ),
                onChanged: (v) {
                  final parsed = int.tryParse(v);
                  if (parsed != null && parsed > 0) {
                    setState(() => _place = parsed);
                  }
                },
                validator: FormValidators.place,
              ),
              const SizedBox(height: 16),

              // ── Points ───────────────────────────────────────────────────
              TextFormField(
                controller: _pointsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Кількість балів',
                  prefixIcon: const ColorFiltered(
                    colorFilter: ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn),
                    child: TriumphIcon(TIcon.trophy, size: 22),
                  ),
                ),
                validator: FormValidators.points,
              ),
              const SizedBox(height: 16),

              // ── Date ─────────────────────────────────────────────────────
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surface3),
                  ),
                  child: Row(
                    children: [
                      const ColorFiltered(
                        colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                        child: TriumphIcon(TIcon.calendar, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Дата змагань',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              DateFormat('dd MMMM yyyy', 'uk').format(_date),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const ColorFiltered(
                        colorFilter: ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn),
                        child: TriumphIcon(TIcon.calendar, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Save button ──────────────────────────────────────────────
              GradientButton(
                onPressed: _loading ? null : _submit,
                isLoading: _loading,
                child: const Text(
                  'Зберегти результат',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/meal_model.dart';
import '../../../core/utils/cloudinary_upload.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/nutrition_provider.dart';

class AddMealScreen extends ConsumerStatefulWidget {
  const AddMealScreen({
    super.key,
    required this.childId,
    this.dateKey,
    this.meal,
  });

  final String     childId;
  final String?    dateKey;
  final MealModel? meal; // non-null = edit mode

  @override
  ConsumerState<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends ConsumerState<AddMealScreen> {
  final _nameCtrl    = TextEditingController();
  final _calCtrl     = TextEditingController();
  final _commentCtrl = TextEditingController();

  late MealType   _type;
  bool _hasProtein    = false;
  bool _hasVegetables = false;
  bool _hasCarbs      = false;
  bool _hasFruits     = false;
  bool _hadWater      = false;
  String? _photoUrl;
  bool _uploading = false;
  bool _saving    = false;

  bool get _isEdit => widget.meal != null;

  @override
  void initState() {
    super.initState();
    final m = widget.meal;
    if (m != null) {
      _type          = m.type;
      _nameCtrl.text = m.mealName;
      _calCtrl.text  = m.calories?.toString() ?? '';
      _commentCtrl.text = m.comment;
      _hasProtein    = m.hasProtein;
      _hasVegetables = m.hasVegetables;
      _hasCarbs      = m.hasCarbs;
      _hasFruits     = m.hasFruits;
      _hadWater      = m.hadWater;
      _photoUrl      = m.photoUrl;
    } else {
      _type = MealType.breakfast;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  DateTime get _date {
    if (widget.dateKey == null) return DateTime.now();
    try {
      final parts = widget.dateKey!.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (_) {
      return DateTime.now();
    }
  }

  Future<void> _pickPhoto() async {
    final img = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 75);
    if (img == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await File(img.path).readAsBytes();
      final url = await uploadImageToCloudinary(
          bytes, 'meals/${DateTime.now().millisecondsSinceEpoch}');
      setState(() => _photoUrl = url);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введи назву страви')));
      return;
    }
    setState(() => _saving = true);
    try {
      final notifier = ref.read(nutritionNotifierProvider.notifier);
      final cal = int.tryParse(_calCtrl.text.trim());
      if (_isEdit) {
        await notifier.updateMeal(widget.meal!.copyWith(
          type:          _type,
          mealName:      name,
          hasProtein:    _hasProtein,
          hasVegetables: _hasVegetables,
          hasCarbs:      _hasCarbs,
          hasFruits:     _hasFruits,
          hadWater:      _hadWater,
          calories:      cal,
          comment:       _commentCtrl.text.trim(),
          photoUrl:      _photoUrl,
          status:        MealStatus.done,
        ));
      } else {
        await notifier.addMeal(
          childId:       widget.childId,
          type:          _type,
          date:          _date,
          mealName:      name,
          hasProtein:    _hasProtein,
          hasVegetables: _hasVegetables,
          hasCarbs:      _hasCarbs,
          hasFruits:     _hasFruits,
          hadWater:      _hadWater,
          calories:      cal,
          comment:       _commentCtrl.text.trim(),
          photoUrl:      _photoUrl,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Помилка: $e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(_isEdit ? 'Редагувати прийом' : 'Додати прийом',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Видалити прийом?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false),
                          child: const Text('Скасувати')),
                      TextButton(onPressed: () => Navigator.pop(context, true),
                          child: const Text('Видалити',
                              style: TextStyle(color: AppColors.error))),
                    ],
                  ),
                );
                if (ok == true && mounted) {
                  await ref.read(nutritionNotifierProvider.notifier)
                      .deleteMeal(widget.meal!.id);
                  if (mounted) context.pop();
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // ── Photo ──────────────────────────────────────────────────────────
          GestureDetector(
            onTap: _uploading ? null : _pickPhoto,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color:        AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border:       Border.all(color: const Color(0xFF2A2A2A)),
                image: _photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_photoUrl!),
                        fit:   BoxFit.cover)
                    : null,
              ),
              child: _photoUrl == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_uploading)
                          const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(AppColors.orange))
                        else ...[
                          const Icon(Icons.add_photo_alternate_outlined,
                              color: AppColors.textSecondary, size: 36),
                          const SizedBox(height: 8),
                          const Text('Додати фото страви',
                              style: TextStyle(fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ],
                      ],
                    )
                  : _uploading
                      ? const Center(
                          child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation(AppColors.orange)))
                      : null,
            ),
          ),
          const SizedBox(height: 16),

          // ── Meal type ──────────────────────────────────────────────────────
          const Text('Тип прийому',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _MealTypeSelector(
              selected: _type,
              onChanged: (t) => setState(() => _type = t)),
          const SizedBox(height: 16),

          // ── Name ───────────────────────────────────────────────────────────
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
                labelText: 'Назва страви',
                prefixIcon: Icon(Icons.restaurant_outlined)),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),

          // ── Calories ───────────────────────────────────────────────────────
          TextField(
            controller: _calCtrl,
            decoration: const InputDecoration(
                labelText: 'Калорії (необов\'язково)',
                prefixIcon: Icon(Icons.local_fire_department_outlined),
                suffixText: 'ккал'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),

          // ── Plate checklist ────────────────────────────────────────────────
          const Text('Склад тарілки',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Відзнач елементи, які є у цьому прийомі',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          _PlateCheck(
              emoji: '🥩',
              label: 'Є білок',
              subtitle: 'М\'ясо, риба, яйця, бобові',
              value: _hasProtein,
              onChanged: (v) => setState(() => _hasProtein = v)),
          _PlateCheck(
              emoji: '🥦',
              label: 'Є овочі',
              subtitle: 'Свіжі або варені',
              value: _hasVegetables,
              onChanged: (v) => setState(() => _hasVegetables = v)),
          _PlateCheck(
              emoji: '🌾',
              label: 'Є складні вуглеводи',
              subtitle: 'Гречка, рис, вівсянка, макарони',
              value: _hasCarbs,
              onChanged: (v) => setState(() => _hasCarbs = v)),
          _PlateCheck(
              emoji: '🍎',
              label: 'Є фрукти',
              subtitle: 'Свіжі або сухофрукти',
              value: _hasFruits,
              onChanged: (v) => setState(() => _hasFruits = v)),
          _PlateCheck(
              emoji: '💧',
              label: 'Випив воду',
              subtitle: 'Стакан води до або під час їжі',
              value: _hadWater,
              onChanged: (v) => setState(() => _hadWater = v)),
          const SizedBox(height: 16),

          // ── Comment ────────────────────────────────────────────────────────
          TextField(
            controller: _commentCtrl,
            decoration: const InputDecoration(
                labelText: 'Коментар (необов\'язково)',
                prefixIcon: Icon(Icons.chat_bubble_outline)),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),

          GradientButton(
            onPressed: _saving ? null : _save,
            gradient: const LinearGradient(
                colors: [Color(0xFFFF8C00), Color(0xFFFFB800)]),
            child: _saving
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black))
                : Text(_isEdit ? 'Зберегти зміни' : 'Зберегти прийом',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

// ── Meal type selector ────────────────────────────────────────────────────────

class _MealTypeSelector extends StatelessWidget {
  const _MealTypeSelector({required this.selected, required this.onChanged});
  final MealType                   selected;
  final ValueChanged<MealType>     onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: MealType.values.map((t) {
          final isActive = t == selected;
          return GestureDetector(
            onTap: () => onChanged(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.orange.withValues(alpha: 0.2)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: isActive
                      ? AppColors.orange
                      : const Color(0xFF2C2C2C),
                ),
              ),
              child: Text(t.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive ? AppColors.orange : AppColors.textSecondary,
                  )),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Plate check row ───────────────────────────────────────────────────────────

class _PlateCheck extends StatelessWidget {
  const _PlateCheck({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String              emoji;
  final String              label;
  final String              subtitle;
  final bool                value;
  final ValueChanged<bool>  onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value
              ? AppColors.orange.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value
                ? AppColors.orange.withValues(alpha: 0.4)
                : const Color(0xFF2A2A2A),
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: value
                              ? AppColors.textPrimary
                              : AppColors.textSecondary)),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value
                    ? AppColors.orange
                    : Colors.transparent,
                border: Border.all(
                  color: value
                      ? AppColors.orange
                      : const Color(0xFF3A3A3A),
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.black)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/cloudinary_upload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/child_model.dart' show ChildModel, Gender, displayWeight, weightCategories;
import '../../../core/models/user_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/schedule/providers/group_provider.dart';
import '../providers/children_provider.dart';
import '../../../shared/widgets/belt_badge.dart';
import '../../../shared/widgets/triumph_icon.dart';

class AddEditChildScreen extends ConsumerStatefulWidget {
  const AddEditChildScreen({super.key, this.childId});

  final String? childId;

  @override
  ConsumerState<AddEditChildScreen> createState() =>
      _AddEditChildScreenState();
}

class _AddEditChildScreenState extends ConsumerState<AddEditChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  int _birthYear = DateTime.now().year - 10;
  String _weightCategory = '-30 кг';
  BeltLevel _belt = BeltLevel.white;
  Gender? _gender;
  File? _photoFile;
  String? _existingPhotoUrl;
  int _existingTotalPoints = 0;
  DateTime? _existingCreatedAt;
  String? _selectedCoachId;
  String? _selectedCoachName;
  String? _existingCoachId; // track original coach to detect changes
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _initFromChild(ChildModel child) {
    if (_initialized) return;
    _initialized = true;
    _firstNameCtrl.text = child.firstName;
    _lastNameCtrl.text = child.lastName;
    _phoneCtrl.text = child.phone ?? '';
    _birthYear = child.birthYear;
    _weightCategory = child.weightCategory;
    _belt = child.currentBelt;
    _gender = child.gender;
    _existingPhotoUrl = child.photoUrl;
    _existingTotalPoints = child.totalPoints;
    _existingCreatedAt = child.createdAt;
    _existingCoachId = child.coachId;
    _selectedCoachId = child.coachId;
    _selectedCoachName = child.coachName;
  }

  void _pickCoach(BuildContext context, List<UserModel> coaches) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Оберіть тренера',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ...coaches.map((c) => ListTile(
                  leading: const Icon(Icons.person_outlined),
                  title: Text(c.name),
                  subtitle: Text(c.email,
                      style: const TextStyle(fontSize: 12)),
                  trailing: _selectedCoachId == c.uid
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedCoachId = c.uid;
                      _selectedCoachName = c.name;
                    });
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.surface3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Зняти фото'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Обрати з галереї'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: source, imageQuality: 80, maxWidth: 800);
    if (file != null) setState(() => _photoFile = File(file.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final user = ref.read(currentUserModelProvider).asData?.value;
    if (user == null) { setState(() => _loading = false); return; }

    // Generate ID up front so we can use it for photo upload path
    final childId = widget.childId ?? const Uuid().v4();

    // Upload photo independently — failure is non-fatal
    String? photoUrl = _existingPhotoUrl;
    if (_photoFile != null) {
      try {
        final bytes = await _photoFile!.readAsBytes();
        photoUrl = await uploadImageToCloudinary(bytes, 'children_$childId');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Фото не вдалося зберегти — дані збережено без фото'),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        // Continue saving without photo
      }
    }

    final phoneText = _phoneCtrl.text.trim();
    final child = ChildModel(
      id: childId,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      birthYear: _birthYear,
      weightCategory: _weightCategory,
      currentBelt: _belt,
      gender: _gender,
      photoUrl: photoUrl,
      coachId: _selectedCoachId ?? user.uid,
      coachName: _selectedCoachName ?? user.name,
      totalPoints: _existingTotalPoints,
      createdAt: _existingCreatedAt ?? DateTime.now(),
      phone: phoneText.isNotEmpty ? phoneText : null,
    );

    final notifier = ref.read(childrenNotifierProvider.notifier);
    if (widget.childId == null) {
      await notifier.addChild(child);
    } else {
      await notifier.updateChild(child);
      // If coach changed, remove child from old coach's groups
      final newCoachId = _selectedCoachId ?? user.uid;
      if (_existingCoachId != null && _existingCoachId != newCoachId) {
        try {
          await ref.read(groupNotifierProvider.notifier).removeChildFromCoachGroups(
                childId: childId,
                oldCoachId: _existingCoachId!,
              );
        } catch (_) {}
      }
    }

    setState(() => _loading = false);
    final error = ref.read(childrenNotifierProvider).error;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка збереження: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.childId != null;
    final childAsync = isEdit
        ? ref.watch(childByIdProvider(widget.childId!))
        : null;

    if (isEdit && childAsync?.asData?.value != null) {
      _initFromChild(childAsync!.asData!.value!);
    }

    final user = ref.watch(currentUserModelProvider).asData?.value;
    final coachesAsync = ref.watch(allCoachesProvider);
    final coaches = coachesAsync.asData?.value ?? [];

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
                  Expanded(
                    child: Text(
                      isEdit ? 'Редагувати' : 'Новий спортсмен',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isEdit && childAsync?.isLoading == true
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo
                    Center(
                      child: GestureDetector(
                        onTap: _loading ? null : _pickPhoto,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 56,
                              backgroundColor:
                                  AppColors.surface2,
                              backgroundImage: _photoFile != null
                                  ? FileImage(_photoFile!) as ImageProvider
                                  : (_existingPhotoUrl != null
                                      ? CachedNetworkImageProvider(
                                          _existingPhotoUrl!) as ImageProvider
                                      : null),
                              child: _photoFile == null &&
                                      _existingPhotoUrl == null
                                  ? const Icon(Icons.person,
                                      size: 52,
                                      color: AppColors.textSecondary)
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.background, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_photoFile != null) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => setState(() => _photoFile = null),
                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
                          label: const Text('Видалити фото',
                              style: TextStyle(
                                  color: AppColors.error, fontSize: 13)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _lastNameCtrl,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                          labelText: 'Прізвище',
                          prefixIcon: Icon(Icons.badge_outlined)),
                      validator: FormValidators.lastName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _firstNameCtrl,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                          labelText: "Ім'я",
                          prefixIcon: Icon(Icons.person_outlined)),
                      validator: FormValidators.firstName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Номер телефону (необов\'язково)',
                        hintText: '+380XXXXXXXXX',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final clean = v.trim().replaceAll(RegExp(r'[\s\-()]'), '');
                        if (!RegExp(r'^\+380\d{9}$').hasMatch(clean)) {
                          return 'Формат: +380XXXXXXXXX';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Birth year
                    const Text(
                      'Рік народження',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppColors.primary,
                          onPressed: () =>
                              setState(() => _birthYear--),
                        ),
                        Expanded(
                          child: Text(
                            '$_birthYear',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: AppColors.primary,
                          onPressed: () =>
                              setState(() => _birthYear++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Weight category
                    DropdownButtonFormField<String>(
                      initialValue: _weightCategory,
                      decoration: const InputDecoration(
                        labelText: 'Вагова категорія',
                        prefixIcon: Icon(Icons.scale),
                      ),
                      items: weightCategories
                          .map((w) => DropdownMenuItem(
                              value: w, child: Text(displayWeight(w))))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _weightCategory = v!),
                    ),
                    const SizedBox(height: 16),

                    // Gender
                    const Text(
                      'Стать',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: Gender.values.map((g) {
                        final selected = _gender == g;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: g == Gender.male ? 8 : 0),
                            child: GestureDetector(
                              onTap: () => setState(() =>
                                  _gender = selected ? null : g),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primary
                                        : Colors.grey.shade300,
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(g.icon,
                                        style:
                                            const TextStyle(fontSize: 22)),
                                    Text(
                                      g.displayName,
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Belt
                    const Text(
                      'Поточний пояс',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: BeltLevel.values.map((b) {
                        final selected = _belt == b;
                        return GestureDetector(
                          onTap: () => setState(() => _belt = b),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected ? b.color : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? b.color
                                    : Colors.grey.shade300,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              b.displayName,
                              style: TextStyle(
                                color: selected
                                    ? b.textColor
                                    : AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    BeltBadge(belt: _belt, size: BeltBadgeSize.large),

                    // Coach picker (only when multiple coaches exist)
                    if (coaches.length > 1) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Тренер',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _pickCoach(context, coaches),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outlined,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedCoachName ??
                                      user?.name ??
                                      '',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down,
                                  color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            ),
            // Sticky save button — always visible, no scroll needed
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isEdit ? 'Зберегти зміни' : 'Додати спортсмена'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/club_honor_board_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/honor_board_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HonorBoardScreen
// ─────────────────────────────────────────────────────────────────────────────

class HonorBoardScreen extends ConsumerWidget {
  const HonorBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCoach =
        ref.watch(currentUserModelProvider).asData?.value?.isCoach ?? false;
    final selectedFilter = ref.watch(honorBoardFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          '🏆 Дошка пошани',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (isCoach)
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.textPrimary),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => const _AddHonorItemSheet(),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter chips ─────────────────────────────────────────────────
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: HonorBoardFilter.values.map((filter) {
                final selected = filter == selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => ref
                        .read(honorBoardFilterProvider.notifier)
                        .state = filter,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.borderSoft,
                        ),
                      ),
                      child: Text(
                        filter.label,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Items list ───────────────────────────────────────────────────
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final rawAsync = ref.watch(honorBoardProvider);
                final items = ref.watch(filteredHonorBoardProvider);

                return rawAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                  error: (_, __) => const Center(
                    child: Text(
                      'Помилка завантаження',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  data: (_) {
                    if (items.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '👑',
                              style: TextStyle(fontSize: 48),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Дошки пошани ще немає',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Separate pinned featured item from the rest
                    final pinnedIndex =
                        items.indexWhere((i) => i.isPinned);
                    final hasFeatured = pinnedIndex != -1;
                    final featured =
                        hasFeatured ? items[pinnedIndex] : null;
                    final rest = hasFeatured
                        ? [
                            ...items.sublist(0, pinnedIndex),
                            ...items.sublist(pinnedIndex + 1),
                          ]
                        : items;

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount:
                          (hasFeatured ? 1 : 0) + rest.length,
                      itemBuilder: (context, index) {
                        if (hasFeatured && index == 0) {
                          return _FeaturedHonorCard(item: featured!);
                        }
                        final item =
                            rest[hasFeatured ? index - 1 : index];
                        return _HonorCard(
                          item: item,
                          isCoach: isCoach,
                          onDelete: () =>
                              _confirmDelete(context, ref, item.id),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: const Text(
          'Видалити запис?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Цю дію неможливо скасувати.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Скасувати',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Видалити',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(honorBoardNotifierProvider.notifier)
          .deleteItem(id);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FeaturedHonorCard
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedHonorCard extends StatelessWidget {
  const _FeaturedHonorCard({required this.item});

  final ClubHonorBoardItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.6, 1.0],
          colors: [
            Color(0xFF7A0000),
            AppColors.primary,
            Color(0xFFFF8A00),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image with gradient overlay
          if (item.imageUrl != null)
            CachedNetworkImage(
              imageUrl: item.imageUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          if (item.imageUrl != null)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xCC000000),
                  ],
                ),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type label row + medal emoji
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.type.label,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.medalType?.emoji ?? item.type.emoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ],
                ),

                const Spacer(),

                // Athlete name
                Text(
                  item.athleteName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black54,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Title row
                Row(
                  children: [
                    const Text('🏅 ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HonorCard
// ─────────────────────────────────────────────────────────────────────────────

class _HonorCard extends StatelessWidget {
  const _HonorCard({
    required this.item,
    required this.isCoach,
    required this.onDelete,
  });

  final ClubHonorBoardItem item;
  final bool isCoach;
  final VoidCallback onDelete;

  Color get _borderColor {
    if (item.medalType != null) return item.medalType!.color;
    if (item.type.isBelt) return AppColors.accent;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd.MM.yy').format(item.publishedAt);

    return GestureDetector(
      onLongPress: isCoach ? onDelete : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _borderColor, width: 2),
              ),
              child: ClipOval(
                child: item.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            _InitialsAvatar(name: item.athleteName),
                      )
                    : _InitialsAvatar(name: item.athleteName),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.athleteName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.competitionName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.competitionName!,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Emoji + date
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.type.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name});

  final String name;

  String _initials() {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.avatarColor(name),
      alignment: Alignment.center,
      child: Text(
        _initials(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AddHonorItemSheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddHonorItemSheet extends ConsumerStatefulWidget {
  const _AddHonorItemSheet();

  @override
  ConsumerState<_AddHonorItemSheet> createState() =>
      _AddHonorItemSheetState();
}

class _AddHonorItemSheetState extends ConsumerState<_AddHonorItemSheet> {
  final _formKey = GlobalKey<FormState>();

  final _athleteNameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _competitionCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  HonorBoardType _type = HonorBoardType.firstPlace;
  MedalType? _medalType;

  bool _loading = false;

  @override
  void dispose() {
    _athleteNameCtrl.dispose();
    _titleCtrl.dispose();
    _competitionCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final now = DateTime.now();
    final item = ClubHonorBoardItem(
      id: '',
      athleteId: '',
      athleteName: _athleteNameCtrl.text.trim(),
      type: _type,
      title: _titleCtrl.text.trim(),
      competitionName: _competitionCtrl.text.trim().isEmpty
          ? null
          : _competitionCtrl.text.trim(),
      medalType: _medalType,
      coachComment: _commentCtrl.text.trim().isEmpty
          ? null
          : _commentCtrl.text.trim(),
      publishedAt: now,
      createdAt: now,
    );

    await ref.read(honorBoardNotifierProvider.notifier).addItem(item);

    setState(() => _loading = false);
    if (mounted) Navigator.pop(context);
  }

  InputDecoration _inputDecoration(String label, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: AppColors.surface2,
      );

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSoft,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Додати до дошки пошани',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Athlete name
              TextFormField(
                controller: _athleteNameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Ім\'я спортсмена'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Обов\'язкове поле' : null,
              ),
              const SizedBox(height: 14),

              // Type dropdown
              DropdownButtonFormField<HonorBoardType>(
                initialValue: _type,
                dropdownColor: AppColors.surface2,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Тип досягнення'),
                items: HonorBoardType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          '${t.emoji}  ${t.label}',
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 14),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: 14),

              // Title
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Заголовок'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Обов\'язкове поле' : null,
              ),
              const SizedBox(height: 14),

              // Competition name (optional)
              TextFormField(
                controller: _competitionCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Змагання',
                    hint: 'Необов\'язково'),
              ),
              const SizedBox(height: 14),

              // Medal type (nullable)
              DropdownButtonFormField<MedalType?>(
                initialValue: _medalType,
                dropdownColor: AppColors.surface2,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Медаль'),
                items: [
                  const DropdownMenuItem<MedalType?>(
                    value: null,
                    child: Text(
                      'Без медалі',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ),
                  ...MedalType.values.map(
                    (m) => DropdownMenuItem<MedalType?>(
                      value: m,
                      child: Text(
                        '${m.emoji}  ${m.label}',
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14),
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _medalType = v),
              ),
              const SizedBox(height: 14),

              // Coach comment (optional, multiline)
              TextFormField(
                controller: _commentCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration:
                    _inputDecoration('Коментар тренера', hint: 'Необов\'язково'),
                maxLines: 3,
                minLines: 1,
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Додати',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/achievement_defs.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/user_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/notifications/providers/notification_provider.dart';
import '../../../features/competitions/providers/competitions_provider.dart';
import '../../../features/team/providers/children_provider.dart';
import '../../../features/team/services/csv_import_service.dart';
import '../../../services/export_service.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/triumph_icon.dart';
import '../../membership/models/tariff_plan.dart';
import '../../membership/providers/tariff_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider).value;
    final isCoach = user?.isCoach ?? false;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Налаштування',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [

          // ── Profile card ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surface3),
            ),
            child: Row(
              children: [
                _ProfileAvatar(name: user?.name ?? ''),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Користувач',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          isCoach ? 'Тренер' : 'Батьки / Опікун',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Menu items ────────────────────────────────────────────────────
          _MenuSection(
            items: [
              _MenuItem(
                icon: Icons.person_outline,
                color: AppColors.primary,
                label: 'Редагувати профіль',
                onTap: () => _showEditProfile(context, ref, user!),
              ),
              if (isCoach) ...[
                _MenuItem(
                  tIcon: TIcon.memberCard3d,
                  label: 'Абонементи спортсменів',
                  onTap: () => context.push('/membership-management'),
                ),
                _MenuItem(
                  icon: Icons.price_change_outlined,
                  color: const Color(0xFF34C759),
                  label: 'Тарифи абонементів',
                  onTap: () => _showTariffEditor(context, ref),
                ),
                _MenuItem(
                  icon: Icons.group_outlined,
                  color: const Color(0xFF34C759),
                  label: 'Імпорт спортсменів',
                  onTap: () => _showCsvImport(context, ref, user!),
                ),
                _MenuItem(
                  tIcon: TIcon.training3d,
                  label: 'Індивідуальні тренування',
                  onTap: () => context.push('/individual-training'),
                ),
                _MenuItem(
                  tIcon: TIcon.motivation3d,
                  label: 'Завдання спортсменам',
                  onTap: () => context.push('/assignments'),
                ),
                _MenuItem(
                  tIcon: TIcon.calendar3d,
                  label: 'Розклад тренувань',
                  onTap: () => context.push('/schedule'),
                ),
                _MenuItem(
                  tIcon: TIcon.trophy3d,
                  label: 'Типи змагань',
                  onTap: () => _showCompetitionTypes(context, ref, user!),
                ),
                _MenuItem(
                  tIcon: TIcon.coach,
                  label: 'Управління тренерами',
                  onTap: () => _showCoachManagement(context, ref, user!),
                ),
                _MenuItem(
                  tIcon: TIcon.medal3d,
                  label: 'Видача досягнень',
                  onTap: () => context.push('/achievements'),
                ),
                _MenuItem(
                  icon: Icons.style,
                  color: const Color(0xFFFF9500),
                  label: 'Масова здача поясів',
                  onTap: () => context.push('/bulk-belt'),
                ),
                _MenuItem(
                  tIcon: TIcon.training3d,
                  label: 'Каталог вправ',
                  onTap: () => context.push(
                    '/fitness/${user!.uid}',
                    extra: {'childName': ''},
                  ),
                ),
                _MenuItem(
                  icon: Icons.bar_chart,
                  color: const Color(0xFF30D158),
                  label: 'Масові фітнес-цілі',
                  onTap: () => context.push('/bulk-fitness-goals'),
                ),
                _MenuItem(
                  icon: Icons.history,
                  color: const Color(0xFF5AC8FA),
                  label: 'Експорт даних',
                  onTap: () => _showExportMenu(context, ref),
                ),
                _MenuItem(
                  icon: Icons.restart_alt,
                  label: 'Скидання результатів сезону',
                  onTap: () => _showResetDialog(context, ref),
                  color: AppColors.error,
                ),
              ],
              if (!isCoach) ...[
                _MenuItem(
                  tIcon: TIcon.training3d,
                  label: 'Індивідуальні тренування',
                  onTap: () => context.push('/individual-training'),
                ),
                _MenuItem(
                  icon: Icons.child_care,
                  color: AppColors.primary,
                  label: 'Моя дитина',
                  onTap: () => _showLinkChild(context, ref, user!),
                ),
              ],
              _MenuItem(
                icon: Icons.notifications_outlined,
                color: const Color(0xFFFF3B30),
                label: 'Сповіщення',
                badge: unreadCount > 0 ? unreadCount : null,
                onTap: () => context.push('/notifications'),
              ),
              _MenuItem(
                icon: Icons.info_outline,
                color: AppColors.textSecondary,
                label: 'Про додаток',
                onTap: () => _showAbout(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (isCoach) ...[
            const _DevSection(),
            const SizedBox(height: 20),
          ],

          // ── Sign out ───────────────────────────────────────────────────────
          GradientButton(
            onPressed: () => _confirmSignOut(context, ref),
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.error],
            ),
            child: const Text(
              'Вийти з акаунту',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialogs / Sheets ───────────────────────────────────────────────────────

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Вийти з акаунту?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Скасувати')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Вийти'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) context.go('/auth/login');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showExportMenu(BuildContext context, WidgetRef ref) {
    final allChildren = ref.read(allChildrenProvider).value ?? [];
    final allResults = ref.read(allResultsProvider).value ?? [];

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
              child: Text('Експорт даних',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.group_outlined, color: AppColors.info, size: 24),
              title: const Text('Команда (список спортсменів)'),
              subtitle: Text('${allChildren.length} спортсменів'),
              onTap: () {
                Navigator.pop(context);
                ExportService.exportAthletes(context, allChildren);
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events_outlined, color: AppColors.accent, size: 24),
              title: const Text('Результати змагань'),
              subtitle: Text('${allResults.length} результатів'),
              onTap: () {
                Navigator.pop(context);
                ExportService.exportResults(context, allResults);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ТРІУМФ'),
        content: const Text(
          'Додаток для управління спортивним клубом\n\nВерсія 1.0.0',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK')),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    int? selectedYear = DateTime.now().year;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Скинути результати сезону'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Видалить усі результати змагань за обраний рік.'),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedYear,
                decoration: const InputDecoration(labelText: 'Рік'),
                items: List.generate(5, (i) {
                  final y = DateTime.now().year - i;
                  return DropdownMenuItem(value: y, child: Text('$y'));
                }),
                onChanged: (v) => setState(() => selectedYear = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Скасувати')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () async {
                Navigator.pop(ctx);
                if (selectedYear != null) {
                  await ref
                      .read(competitionsNotifierProvider.notifier)
                      .resetSeason(selectedYear!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Результати скинуто'),
                    ));
                  }
                }
              },
              child: const Text('Скинути'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCsvImport(BuildContext context, WidgetRef ref, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CsvImportSheet(user: user),
    );
  }

  void _showCompetitionTypes(BuildContext context, WidgetRef ref, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CompetitionTypesSheet(user: user),
    );
  }

  void _showCoachManagement(BuildContext context, WidgetRef ref, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CoachManagementSheet(user: user),
    );
  }

  void _showEditProfile(BuildContext context, WidgetRef ref, UserModel user) {
    showDialog<void>(
      context: context,
      builder: (_) => _EditProfileDialog(user: user),
    );
  }

  void _showLinkChild(BuildContext context, WidgetRef ref, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LinkChildSheet(user: user),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu section + item
// ─────────────────────────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface3),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Column(
            children: [
              item,
              if (i < items.length - 1)
                const Divider(height: 1, indent: 56, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    this.icon,
    this.tIcon,
    required this.label,
    required this.onTap,
    this.color,
    this.badge,
  }) : assert(icon != null || tIcon != null);

  final IconData? icon;
  final TIcon? tIcon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final int? badge;

  static bool _is3dIcon(TIcon icon) =>
      icon.name.endsWith('3d') || icon == TIcon.coach;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    final Widget leading;
    if (tIcon != null && _is3dIcon(tIcon!)) {
      // 3D photorealistic icon — clip to rounded square, fill space
      leading = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40, height: 40,
          child: TriumphIcon(tIcon!, size: 40),
        ),
      );
    } else {
      // Simple monochrome or Material icon — tinted inside a subtle container
      final Widget iconWidget = tIcon != null
          ? TriumphIcon(tIcon!, size: 22, color: c)
          : Icon(icon!, color: c, size: 20);
      leading = Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: iconWidget,
      );
    }
    return ListTile(
      leading: leading,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color ?? AppColors.textPrimary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null && badge! > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: c.withValues(alpha: 0.5), size: 18),
        ],
      ),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CSV Import Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CsvImportSheet extends ConsumerStatefulWidget {
  const _CsvImportSheet({required this.user});
  final UserModel user;

  @override
  ConsumerState<_CsvImportSheet> createState() => _CsvImportSheetState();
}

class _CsvImportSheetState extends ConsumerState<_CsvImportSheet> {
  bool _loading = false;
  String? _result;

  Future<void> _pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.single.path == null) return;
    setState(() { _loading = true; _result = null; });
    try {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final parsed = CsvImportService.parse(content);
      if (parsed.valid.isEmpty) {
        setState(() { _result = 'Помилка: ${parsed.errors.join(', ')}'; });
        return;
      }
      final count = await ref
          .read(childrenNotifierProvider.notifier)
          .importFromCsv(parsed.valid, widget.user.uid, widget.user.name);
      setState(() { _result = 'Імпортовано $count спортсменів ✅'; });
    } catch (e) {
      setState(() { _result = 'Помилка: $e'; });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Імпорт спортсменів',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Файл має містити колонки: Прізвище, Ім\'я, Рік (обов\'язкові), Вага, Пояс (необов\'язкові). Кодування: UTF-8.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (_result != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_result!,
                  style: TextStyle(
                      color: _result!.contains('✅')
                          ? AppColors.success
                          : AppColors.error)),
            ),
          GradientButton(
            onPressed: _loading ? null : _pickAndImport,
            isLoading: _loading,
            height: 48,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Обрати CSV файл',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Competition types sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CompetitionTypesSheet extends ConsumerStatefulWidget {
  const _CompetitionTypesSheet({required this.user});
  final UserModel user;

  @override
  ConsumerState<_CompetitionTypesSheet> createState() =>
      _CompetitionTypesSheetState();
}

class _CompetitionTypesSheetState
    extends ConsumerState<_CompetitionTypesSheet> {

  // Input field is intentionally in an AlertDialog, not here.
  // BottomSheet on Android does not establish a correct IME connection
  // for non-Latin input — CyrillicBottomSheet→TextField combos result
  // in a keyboard that appears but ignores Cyrillic keypresses on many OEMs.
  // AlertDialog uses a different focus/route mechanism and works correctly.

  void _openAddDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddCompetitionTypeDialog(
        onAdd: (name) => ref
            .read(competitionsNotifierProvider.notifier)
            .addCompetitionType(name, widget.user.uid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(competitionTypesProvider);
    final types = typesAsync.value ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Типи змагань',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => _openAddDialog(context),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text('Додати'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (types.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Немає типів. Натисніть "Додати".',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: types
                      .map((t) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(t.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
                              onPressed: () => ref
                                  .read(competitionsNotifierProvider.notifier)
                                  .deleteCompetitionType(t.id),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add competition type — AlertDialog (not BottomSheet) for proper IME on Android
// ─────────────────────────────────────────────────────────────────────────────

// ── Profile avatar: photo from Firebase Auth or initials fallback ─────────────

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.name});
  final String name;

  String _initials() {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: photoUrl != null ? null : AppColors.ctaGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: photoUrl != null && photoUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                photoUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _InitialsCircle(text: _initials()),
              ),
            )
          : _InitialsCircle(text: _initials()),
    );
  }
}

class _InitialsCircle extends StatelessWidget {
  const _InitialsCircle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      );
}

class _AddCompetitionTypeDialog extends StatefulWidget {
  const _AddCompetitionTypeDialog({required this.onAdd});
  final void Function(String name) onAdd;

  @override
  State<_AddCompetitionTypeDialog> createState() =>
      _AddCompetitionTypeDialogState();
}

class _AddCompetitionTypeDialogState
    extends State<_AddCompetitionTypeDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    widget.onAdd(name);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новий тип змагань'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          hintText: 'Наприклад: Кубок міста',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Скасувати'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text(
            'Додати',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coach management sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CoachManagementSheet extends ConsumerStatefulWidget {
  const _CoachManagementSheet({required this.user});
  final UserModel user;

  @override
  ConsumerState<_CoachManagementSheet> createState() =>
      _CoachManagementSheetState();
}

class _CoachManagementSheetState
    extends ConsumerState<_CoachManagementSheet> {
  final _emailCtrl = TextEditingController();
  bool _searching = false;
  String? _searchError;
  UserModel? _foundUser;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _search() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() { _searching = true; _searchError = null; _foundUser = null; });
    try {
      final snap = await ref
          .read(firestoreProvider)
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        setState(() { _searchError = 'Користувача не знайдено'; });
      } else {
        setState(() { _foundUser = UserModel.fromFirestore(snap.docs.first); });
      }
    } catch (e) {
      setState(() { _searchError = 'Помилка: $e'; });
    } finally {
      setState(() => _searching = false);
    }
  }

  Future<void> _grantCoach(String uid) async {
    await ref.read(firestoreProvider)
        .collection('users')
        .doc(uid)
        .update({'role': 'coach'});
    setState(() { _foundUser = null; _emailCtrl.clear(); });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text('Права тренера надано'),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Управління тренерами',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Надати права тренера:',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email користувача',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              GradientButton(
                onPressed: _searching ? null : _search,
                isLoading: _searching,
                height: 48,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Знайти',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          if (_searchError != null) ...[
            const SizedBox(height: 8),
            Text(_searchError!,
                style: const TextStyle(color: AppColors.error)),
          ],
          if (_foundUser != null) ...[
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_foundUser!.name),
              subtitle: Text(_foundUser!.email),
              trailing: ElevatedButton(
                onPressed: () => _grantCoach(_foundUser!.uid),
                child: const Text('Надати права'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Link child sheet (parent view)
// ─────────────────────────────────────────────────────────────────────────────

class _LinkChildSheet extends ConsumerStatefulWidget {
  const _LinkChildSheet({required this.user});
  final UserModel user;

  @override
  ConsumerState<_LinkChildSheet> createState() => _LinkChildSheetState();
}

class _LinkChildSheetState extends ConsumerState<_LinkChildSheet> {
  @override
  Widget build(BuildContext context) {
    final children = ref.watch(allChildrenProvider).value ?? [];
    final myChild = children
        .where((c) => widget.user.ownsChild(c.id))
        .firstOrNull;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Моя дитина',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (myChild != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.person, color: Colors.white, size: 22),
              ),
              title: Text(myChild.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${myChild.birthYear} р.н.'),
            )
          else
            const Text(
              'Дитину не пов\'язано. Зверніться до тренера.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit profile dialog (AlertDialog — avoids IME issues with BottomSheet)
// ─────────────────────────────────────────────────────────────────────────────

class _EditProfileDialog extends ConsumerStatefulWidget {
  const _EditProfileDialog({required this.user});
  final UserModel user;

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).updateProfile(
            name: name,
            phone: _phoneCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редагувати профіль'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: "Ім'я та прізвище",
              prefixIcon: Icon(Icons.person_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Номер телефону',
              hintText: '+380XXXXXXXXX',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Скасувати'),
        ),
        TextButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'Зберегти',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dev tools / seed section (coach only)
// ─────────────────────────────────────────────────────────────────────────────

class _DevSection extends ConsumerStatefulWidget {
  const _DevSection();

  @override
  ConsumerState<_DevSection> createState() => _DevSectionState();
}

class _DevSectionState extends ConsumerState<_DevSection> {
  bool _seeding = false;
  String? _result;

  Future<void> _run(Future<String> Function() fn) async {
    setState(() { _seeding = true; _result = null; });
    try {
      final msg = await fn();
      setState(() => _result = msg);
    } catch (e) {
      setState(() => _result = 'Помилка: $e');
    } finally {
      setState(() => _seeding = false);
    }
  }

  // ── 1. Seed 1000 athletes ─────────────────────────────────────────────────
  Future<void> _seedAthletes() => _run(() async {
    final user = ref.read(currentUserModelProvider).value;
    if (user == null) return 'Не авторизовано';
    await ref.read(childrenNotifierProvider.notifier)
        .seedTestData(user.uid, user.name);
    return 'Засіяно 1000 спортсменів ✓';
  });

  // ── 2. Seed memberships ───────────────────────────────────────────────────
  Future<void> _seedMemberships() => _run(() async {
    final children = ref.read(allChildrenProvider).value ?? [];
    if (children.isEmpty) return 'Спортсменів не знайдено';

    final db = ref.read(firestoreProvider);
    final now = DateTime.now();
    final plans = [
      'Безлімітний', '3 рази на тиждень', '2 рази на тиждень',
      'Разові відвідування',
    ];
    // Session-based plan: 12 sessions total
    const sessionPlan = 'Разові відвідування';
    var batch = db.batch();
    var count = 0;
    var seeded = 0;

    for (int i = 0; i < children.length; i++) {
      final c = children[i];
      final segment = i % 5;
      if (segment == 4) continue; // 20% without membership

      final DateTime startDate;
      final DateTime endDate;
      switch (segment) {
        case 0: // active, ends in 40+ days
          startDate = now.subtract(const Duration(days: 15));
          endDate = now.add(Duration(days: 40 + (i % 20) * 3));
        case 1: // active, ends in 15+ days
          startDate = now.subtract(const Duration(days: 20));
          endDate = now.add(Duration(days: 15 + (i % 10)));
        case 2: // expiring soon (≤7 days)
          startDate = now.subtract(const Duration(days: 25));
          endDate = now.add(Duration(days: 1 + i % 6));
        default: // expired
          startDate = now.subtract(Duration(days: 40 + i % 30));
          endDate = now.subtract(Duration(days: 3 + i % 25));
      }

      final isSession = plans[i % plans.length] == sessionPlan;
      final Map<String, dynamic> data = {
        'athleteId': c.id,
        'planName': plans[i % plans.length],
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'amount': (800 + (i % 5) * 200).toDouble(),
        'currency': 'UAH',
      };
      if (isSession) {
        data['totalSessions'] = 12;
        data['sessionsUsed'] = 3 + i % 10;
      }

      batch.set(db.collection('memberships').doc(c.id), data);
      count++;
      seeded++;

      if (count == 400) {
        await batch.commit();
        batch = db.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
    return 'Засіяно $seeded абонементів ✓';
  });

  // ── 3. Seed achievements ──────────────────────────────────────────────────
  Future<void> _seedAchievements() => _run(() async {
    final children = ref.read(allChildrenProvider).value ?? [];
    if (children.isEmpty) return 'Спортсменів не знайдено';

    const beltAchIds = [
      'belt_white', 'belt_whiteYellow', 'belt_yellow', 'belt_yellowOrange',
      'belt_orange', 'belt_orangeGreen', 'belt_green', 'belt_greenBlue',
      'belt_blue', 'belt_blueBrown', 'belt_brown', 'belt_black',
    ];

    final db = ref.read(firestoreProvider);
    final coachId = ref.read(currentUserModelProvider).value?.uid ?? '';
    final now = DateTime.now();
    var batch = db.batch();
    var count = 0;
    var seeded = 0;

    for (int idx = 0; idx < children.length; idx++) {
      final child = children[idx];
      final beltIdx = BeltLevel.values.indexOf(child.currentBelt);
      final pts = child.totalPoints;
      final achieved = <String>{};

      // Belt achievements: every belt earned up to current
      for (int b = 0; b <= beltIdx; b++) {
        achieved.add(beltAchIds[b]);
      }

      // Tournament achievements (based on total points tier)
      if (pts > 0)   achieved.add('first_tournament');
      if (pts > 0  && idx % 4 < 3) { achieved.add('first_medal'); achieved.add('bronze_medalist'); }
      if (pts > 20 && idx % 4 < 2) achieved.add('silver_medalist');
      if (pts > 30)  achieved.add('champion');
      if (pts > 50)  achieved.add('tournament_3_streak');
      if (pts > 100) achieved.add('medals_10');
      if (pts > 200) achieved.add('medals_20');
      if (pts > 150 && idx % 3 == 0) achieved.add('podium_5_streak');

      // Training achievements (based on belt seniority)
      achieved.add('first_training');
      achieved.add('trainings_10');
      if (beltIdx >= 3) achieved.add('trainings_50');
      if (beltIdx >= 5) achieved.add('trainings_100');
      if (beltIdx >= 8) achieved.add('trainings_250');
      if (beltIdx >= 10) achieved.add('trainings_500');

      // Discipline (attendance streaks — spread deterministically)
      if (idx % 2 == 0) achieved.add('streak_7');
      if (idx % 4 == 0) achieved.add('streak_14');
      if (idx % 7 == 0) achieved.add('streak_30');
      if (idx % 13 == 0) achieved.add('streak_100');
      if (idx % 34 == 0) achieved.add('year_no_miss');
      if (idx % 21 == 0) achieved.add('attendance_100_year');
      // Seasonal samurais (~5% each, non-overlapping)
      if (idx % 17 == 1)  achieved.add('autumn_discipline');
      if (idx % 17 == 5)  achieved.add('winter_discipline');
      if (idx % 17 == 9)  achieved.add('spring_discipline');
      if (idx % 17 == 13) achieved.add('summer_discipline');

      // Behavior / technique (manual, sparse)
      if (idx % 3 == 0) achieved.add('fair_play');
      if (idx % 5 == 0) achieved.add('friend_of_team');
      if (idx % 7 == 1) achieved.add('respect');
      if (idx % 9 == 2) achieved.add('team_support');
      if (idx % 15 == 3) achieved.add('team_leader');
      if (idx % 4 == 1) achieved.add('throw_master');
      if (beltIdx >= 6 && idx % 5 == 2) achieved.add('hold_master');
      if (beltIdx >= 7 && idx % 7 == 3) achieved.add('pain_master');
      if (beltIdx >= 9 && idx % 9 == 4) achieved.add('counter_master');

      // Validate: keep only IDs that exist in kAchievements
      final validIds = kAchievements.map((a) => a.id).toSet();
      achieved.retainAll(validIds);

      final earnedAt = now.subtract(Duration(days: idx % 600 + 10));

      for (final achId in achieved) {
        batch.set(
          db.collection('achievements').doc('${child.id}_$achId'),
          {
            'childId': child.id,
            'achievementId': achId,
            'earnedAt': Timestamp.fromDate(earnedAt),
            if (coachId.isNotEmpty) 'grantedByCoachId': coachId,
          },
        );
        count++;
        seeded++;
        if (count == 400) {
          await batch.commit();
          batch = db.batch();
          count = 0;
        }
      }
    }
    if (count > 0) await batch.commit();
    return 'Засіяно $seeded ачивок ✓';
  });

  // ── 4. Seed competition results ───────────────────────────────────────────
  Future<void> _seedCompetitionResults() => _run(() async {
    final children = ref.read(allChildrenProvider).value ?? [];
    if (children.isEmpty) return 'Спортсменів не знайдено';

    // Points awarded per place index [0=1st, 1=2nd, 2=3rd, 3=4–6th]
    const levelPts = {
      'club':          [5, 3, 2, 1],
      'local':         [8, 5, 3, 1],
      'district':      [12, 8, 5, 2],
      'regional':      [20, 13, 8, 3],
      'national':      [40, 25, 15, 5],
      'international': [60, 40, 25, 8],
      'european':      [80, 50, 30, 10],
      'world':         [120, 80, 50, 15],
    };
    const compNames = [
      'Кубок міста', 'Міська першість', 'Відкрита першість',
      'Першість клубу', 'Регіональний чемпіонат', 'Всеукраїнська першість',
      'Кубок України', 'Чемпіонат України', 'Міжнародний турнір',
      'Меморіал Сагайдачного', 'Кубок Гетьмана', 'Призи весни',
      'Осінній турнір', 'Різдвяний кубок', 'Турнір дружби',
      'Відкритий чемпіонат', 'Першість федерації', 'Кубок регіону',
    ];

    List<String> levelsFor(int pts) {
      if (pts < 20)  return ['club'];
      if (pts < 60)  return ['club', 'local'];
      if (pts < 150) return ['club', 'local', 'district'];
      if (pts < 300) return ['local', 'district', 'regional'];
      return ['regional', 'national', 'international'];
    }

    int resultCount(int pts) {
      if (pts == 0) return 0;
      if (pts < 15)  return 1;
      if (pts < 40)  return 2 + pts ~/ 15;
      if (pts < 100) return 4 + pts ~/ 20;
      if (pts < 250) return 7 + pts ~/ 30;
      return (12 + pts ~/ 50).clamp(0, 20);
    }

    final db = ref.read(firestoreProvider);
    final coachId = ref.read(currentUserModelProvider).value?.uid ?? '';
    final now = DateTime.now();
    var batch = db.batch();
    var count = 0;
    var seeded = 0;

    for (int idx = 0; idx < children.length; idx++) {
      final child = children[idx];
      final pts = child.totalPoints;
      final n = resultCount(pts);
      final levels = levelsFor(pts);

      for (int j = 0; j < n; j++) {
        final levelName = levels[(idx + j) % levels.length];
        final ptsTable = levelPts[levelName]!;

        // Place distribution: better athletes place higher
        final roll = (idx * 7 + j * 13) % 10;
        final int place;
        if (pts > 300) {
          place = [1, 1, 2, 1, 2, 3, 1, 2, 3, 1][roll];
        } else if (pts > 100) {
          place = [1, 2, 3, 3, 4, 2, 3, 1, 5, 4][roll];
        } else if (pts > 30) {
          place = [3, 4, 5, 4, 3, 5, 6, 4, 3, 6][roll];
        } else {
          place = [4, 5, 6, 5, 4, 6, 5, 6, 4, 5][roll];
        }

        final resultPts = place <= 3 ? ptsTable[place - 1] : ptsTable[3];
        final daysAgo = 20 + j * 45 + (idx % 30);
        final date = now.subtract(Duration(days: daysAgo));
        final seasonYear = date.month >= 9 ? date.year : date.year - 1;

        batch.set(
          db.collection('competition_results').doc(),
          {
            'childId': child.id,
            'childName': child.fullName,
            'competitionName': compNames[(idx + j * 3) % compNames.length],
            'competitionType': '',
            'level': levelName,
            'place': place,
            'points': resultPts,
            'date': Timestamp.fromDate(date),
            'seasonYear': seasonYear,
            'addedByCoachId': coachId,
          },
        );
        count++;
        seeded++;
        if (count == 400) {
          await batch.commit();
          batch = db.batch();
          count = 0;
        }
      }
    }
    if (count > 0) await batch.commit();
    return 'Засіяно $seeded турнірних результатів ✓';
  });

  // ── UI ────────────────────────────────────────────────────────────────────
  Widget _btn({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) =>
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: _seeding
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, size: 16),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
            side: const BorderSide(color: Colors.orange),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onPressed: _seeding ? null : onPressed,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bug_report_outlined, color: Colors.orange, size: 16),
              SizedBox(width: 6),
              Text(
                'Тестові дані',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _btn(
            icon: Icons.people_outline,
            label: 'Засіяти 1000 спортсменів',
            onPressed: _seedAthletes,
          ),
          const SizedBox(height: 8),
          _btn(
            icon: Icons.credit_card,
            label: 'Засіяти абонементи',
            onPressed: _seedMemberships,
          ),
          const SizedBox(height: 8),
          _btn(
            icon: Icons.emoji_events_outlined,
            label: 'Засіяти турнірні результати',
            onPressed: _seedCompetitionResults,
          ),
          const SizedBox(height: 8),
          _btn(
            icon: Icons.military_tech_outlined,
            label: 'Засіяти ачивки',
            onPressed: _seedAchievements,
          ),
          if (_result != null) ...[
            const SizedBox(height: 10),
            Text(
              _result!,
              style: TextStyle(
                fontSize: 12,
                color: _result!.startsWith('Помилка')
                    ? AppColors.error
                    : AppColors.success,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

void _showTariffEditor(BuildContext context, WidgetRef ref) {
  final plans = ref.read(tariffPlansProvider).value ?? TariffPlan.defaults;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _TariffEditorSheet(
      initialPlans: List<TariffPlan>.from(plans),
    ),
  );
}

class _TariffEditorSheet extends StatefulWidget {
  const _TariffEditorSheet({required this.initialPlans});
  final List<TariffPlan> initialPlans;

  @override
  State<_TariffEditorSheet> createState() => _TariffEditorSheetState();
}

class _TariffEditorSheetState extends State<_TariffEditorSheet> {
  late final List<TextEditingController> _priceCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _priceCtrl = widget.initialPlans
        .map((p) => TextEditingController(text: p.price.toStringAsFixed(0)))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _priceCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text(
                  'Тарифи абонементів',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
              const SizedBox(height: 4),
              const Text(
                'Вкажіть вартість кожного тарифного плану',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ...List.generate(widget.initialPlans.length, (i) {
                final plan = widget.initialPlans[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: _priceCtrl[i],
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: false),
                          decoration: const InputDecoration(
                            suffixText: 'грн',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        try {
                          final updated = List.generate(
                            widget.initialPlans.length,
                            (i) {
                              final price = double.tryParse(
                                    _priceCtrl[i]
                                        .text
                                        .trim()
                                        .replaceAll(',', '.'),
                                  ) ??
                                  widget.initialPlans[i].price;
                              return TariffPlan(
                                name: widget.initialPlans[i].name,
                                days: widget.initialPlans[i].days,
                                price: price,
                              );
                            },
                          );
                          await ref
                              .read(tariffNotifierProvider.notifier)
                              .savePlans(updated);
                          if (context.mounted) Navigator.pop(context);
                        } catch (_) {
                          setState(() => _saving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Помилка збереження'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Зберегти',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

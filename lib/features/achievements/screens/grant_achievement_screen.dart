import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/achievement_defs.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/achievement_model.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/child_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/team/providers/children_provider.dart';
import '../providers/achievement_provider.dart';
import '../../../shared/widgets/achievement_badge.dart';
import '../../../shared/widgets/default_avatar.dart';
import '../../../shared/widgets/triumph_icon.dart';

class GrantAchievementScreen extends ConsumerStatefulWidget {
  const GrantAchievementScreen({super.key});

  @override
  ConsumerState<GrantAchievementScreen> createState() =>
      _GrantAchievementScreenState();
}

class _GrantAchievementScreenState
    extends ConsumerState<GrantAchievementScreen> {
  ChildModel? _selected;

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(allChildrenProvider).value ?? [];

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
                      'Видача досягнень',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/achievement-stats'),
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
                          child: TriumphIcon(TIcon.statistics, size: 22),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => context.push('/bulk-achievements'),
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
                          child: TriumphIcon(TIcon.team, size: 22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _selected == null
                  ? _athleteList(children)
                  : _achievementList(_selected!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _athleteList(List<ChildModel> children) {
    if (children.isEmpty) {
      return const Center(
        child: Text('Список спортсменів порожній',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showCatalog(context),
          child: Container(
            width: double.infinity,
            height: 70,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.surface2],
              ),
            ),
            alignment: Alignment.center,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grid_view, color: Colors.white70, size: 14),
                SizedBox(width: 6),
                Text('Переглянути каталог значків',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: children.length,
      itemBuilder: (_, i) {
        final c = children[i];
        return Card(
          child: ListTile(
            leading: c.photoUrl != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(c.photoUrl!), radius: 20)
                : DefaultAvatarCircle(
                    gender: c.gender, radius: 20, seed: c.id),
            title: Text(c.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(c.currentBelt.displayName,
                style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 18),
            onTap: () => setState(() => _selected = c),
          ),
        );
      },
        ),
      ),
      ],
    );
  }

  Widget _achievementList(ChildModel athlete) {
    final earnedAsync =
        ref.watch(childAchievementsProvider(athlete.id));
    final earned = earnedAsync.value ?? [];
    final earnedIds = earned.map((a) => a.achievementId).toSet();
    final user = ref.watch(currentUserModelProvider).value;

    final grouped = allAchievementsByCategory;

    return Column(
      children: [
        // Achievement catalog image
        GestureDetector(
          onTap: () => _showCatalog(context),
          child: Container(
            width: double.infinity,
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.surface2],
              ),
            ),
            alignment: Alignment.center,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grid_view, color: Colors.white70, size: 16),
                SizedBox(width: 6),
                Text('Переглянути всі значки',
                    style: TextStyle(color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        // Header
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              athlete.photoUrl != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(athlete.photoUrl!),
                      radius: 22)
                  : DefaultAvatarCircle(
                      gender: athlete.gender, radius: 22, seed: athlete.id),
              const SizedBox(width: 12),
              Expanded(
                child: Text(athlete.fullName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => setState(() => _selected = null),
                child: const Text('Змінити'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final entry in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                  child: Text(
                    entry.key.displayName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ...entry.value.map((def) {
                  final isEarned = earnedIds.contains(def.id);
                  return _AchievementTile(
                    def: def,
                    isEarned: isEarned,
                    onTap: () => _handleTap(
                        athlete, def, isEarned, user?.uid ?? '', earned),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _handleTap(ChildModel athlete, AchievementDef def, bool isEarned,
      String coachId, List<AchievementModel> earned) {
    if (isEarned) {
      _confirmRevoke(athlete, def);
    } else {
      _showGrantDialog(athlete, def, coachId);
    }
  }

  void _showCatalog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Каталог досягнень',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                itemCount: kAchievements.length,
                itemBuilder: (_, i) {
                  final def = kAchievements[i];
                  return Column(
                    children: [
                      Expanded(
                        child: Image.asset(
                          'assets/achievements/achievement_${def.id}.webp',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        def.name,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 7,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGrantDialog(ChildModel athlete, AchievementDef def, String coachId) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${def.emoji} ${def.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(def.description,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Нотатка (необов\'язково)',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Скасувати')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(achievementNotifierProvider.notifier)
                  .grant(athlete.id, def.id, coachId,
                      note: noteCtrl.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${def.emoji} ${def.name} видано!'),
                  backgroundColor: AppColors.success,
                ));
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Видати'),
          ),
        ],
      ),
    );
  }

  void _confirmRevoke(ChildModel athlete, AchievementDef def) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Відкликати досягнення?'),
        content: Text('${def.emoji} ${def.name} буде видалено.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Скасувати')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(achievementNotifierProvider.notifier)
                  .revoke(athlete.id, def.id);
            },
            child: const Text('Відкликати'),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.def,
    required this.isEarned,
    required this.onTap,
  });

  final AchievementDef def;
  final bool isEarned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: AchievementIcon(def: def, size: 36),
      title: Row(
        children: [
          Expanded(
            child: Text(
              def.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isEarned ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          if (def.isAuto && !def.isManual)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surface3,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('авто',
                  style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
            ),
        ],
      ),
      subtitle: Text(
        def.description,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isEarned
          ? const Icon(Icons.check_circle, color: AppColors.success, size: 22)
          : const Icon(Icons.add_circle_outline,
              color: AppColors.textSecondary, size: 20),
    );
  }
}

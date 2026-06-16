import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/nutrition_tip_model.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/nutrition_provider.dart';

class NutritionTipsScreen extends ConsumerStatefulWidget {
  const NutritionTipsScreen({super.key, this.childId});
  final String? childId;

  @override
  ConsumerState<NutritionTipsScreen> createState() =>
      _NutritionTipsScreenState();
}

class _NutritionTipsScreenState extends ConsumerState<NutritionTipsScreen> {
  TipCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final user    = ref.watch(currentUserModelProvider).asData?.value;
    final tips    = ref.watch(nutritionTipsProvider).asData?.value ?? [];
    final isCoach = user?.isCoach ?? false;
    final childId = widget.childId ?? user?.childId ??
        (user?.childIds.isNotEmpty == true ? user!.childIds.first : '');

    final filtered = _filter == null
        ? tips
        : tips.where((t) => t.category == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: AppBackButton(onPressed: () => context.pop()),
            actions: isCoach
                ? [
                    IconButton(
                      icon: const Icon(Icons.add_rounded,
                          color: AppColors.orange),
                      tooltip: 'Додати пораду',
                      onPressed: () =>
                          _showAddTipDialog(context, ref),
                    )
                  ]
                : null,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1200), AppColors.background],
                    begin: Alignment.topCenter,
                    end:   Alignment.bottomCenter,
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment:  MainAxisAlignment.end,
                      children: [
                        Text('💡 Рекомендації',
                            style: TextStyle(fontSize: 22,
                                fontWeight: FontWeight.w800, color: Colors.white)),
                        Text('Поради щодо харчування',
                            style: TextStyle(fontSize: 13,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
              title: const Text('Рекомендації',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
          ),

          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  _TipChip(
                      label: 'Всі',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null)),
                  ...TipCategory.values.map((c) => _TipChip(
                        label: c.label,
                        selected: _filter == c,
                        onTap: () =>
                            setState(() => _filter = _filter == c ? null : c),
                      )),
                ],
              ),
            ),
          ),

          if (filtered.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('💡', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text('Рекомендацій немає',
                        style: TextStyle(fontSize: 16,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _TipCard(
                    tip:     filtered[i],
                    childId: childId,
                    isCoach: isCoach,
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddTipDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl   = TextEditingController();
    final bodyCtrl    = TextEditingController();
    var   category    = TipCategory.general;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20,
              MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              const Text('Нова порада',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Заголовок')),
              const SizedBox(height: 12),
              TextField(
                  controller: bodyCtrl,
                  decoration: const InputDecoration(labelText: 'Текст'),
                  maxLines: 4),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: TipCategory.values.map((c) => GestureDetector(
                    onTap: () => setState(() => category = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: category == c
                            ? AppColors.orange.withValues(alpha: 0.2)
                            : const Color(0xFF1C1C1C),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: category == c
                              ? AppColors.orange
                              : const Color(0xFF2C2C2C),
                        ),
                      ),
                      child: Text(c.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: category == c
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: category == c
                                ? AppColors.orange
                                : AppColors.textSecondary,
                          )),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final t = titleCtrl.text.trim();
                  final b = bodyCtrl.text.trim();
                  if (t.isEmpty || b.isEmpty) return;
                  await ref.read(nutritionNotifierProvider.notifier)
                      .addTip(title: t, body: b, category: category);
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
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String       label;
  final bool         selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.orange.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
              color: selected ? AppColors.orange : const Color(0xFF2C2C2C)),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? AppColors.orange : AppColors.textSecondary,
            )),
      ),
    );
  }
}

class _TipCard extends ConsumerWidget {
  const _TipCard({
    required this.tip,
    required this.childId,
    required this.isCoach,
  });

  final NutritionTipModel tip;
  final String            childId;
  final bool              isCoach;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRead = tip.isReadBy(childId);

    return GestureDetector(
      onTap: () {
        if (!isCoach && !isRead && childId.isNotEmpty) {
          ref.read(nutritionNotifierProvider.notifier)
              .markTipRead(tipId: tip.id, childId: childId);
        }
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => _TipDetail(tip: tip),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? AppColors.orange.withValues(alpha: 0.25)
                : const Color(0xFF222222),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(_categoryEmoji(tip.category),
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(tip.title,
                            style: const TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (isRead)
                        const Icon(Icons.check_circle_rounded,
                            size: 16, color: AppColors.orange),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(tip.category.label,
                      style: const TextStyle(fontSize: 11,
                          color: AppColors.orange)),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMM yyyy', 'uk').format(tip.publishedAt),
                    style: const TextStyle(fontSize: 10,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryEmoji(TipCategory c) => switch (c) {
    TipCategory.general   => '💡',
    TipCategory.preTrain  => '⚡',
    TipCategory.postTrain => '💪',
    TipCategory.hydration => '💧',
    TipCategory.recovery  => '🌿',
  };
}

class _TipDetail extends StatelessWidget {
  const _TipDetail({required this.tip});
  final NutritionTipModel tip;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color:        AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(tip.category.label,
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w600, color: AppColors.orange)),
          ),
          const SizedBox(height: 10),
          Text(tip.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Text(tip.body,
              style: const TextStyle(fontSize: 14,
                  color: AppColors.textPrimary, height: 1.6)),
          const SizedBox(height: 16),
          Text(
            DateFormat('d MMMM yyyy', 'uk').format(tip.publishedAt),
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

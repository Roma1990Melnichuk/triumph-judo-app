import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/triumph_icon.dart';
import '../../../core/models/child_model.dart';
import '../../../core/models/membership_model.dart';
import '../providers/membership_provider.dart';
import '../../team/providers/children_provider.dart';

class CoachMembershipsScreen extends ConsumerWidget {
  const CoachMembershipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(allChildrenProvider);
    final membershipsAsync = ref.watch(allMembershipsProvider);

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
                    'Абонементи',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Expanded(
              child: childrenAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const Center(
          child: Text('Помилка завантаження',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        data: (children) {
          final membershipMap = <String, MembershipModel>{
            for (final m in membershipsAsync.value ?? []) m.athleteId: m,
          };

          final summary = (
            active: membershipMap.values
                .where((m) => m.status == MembershipStatus.active)
                .length,
            expiringSoon:
                membershipMap.values.where((m) => m.isExpiringSoon).length,
            expired:
                membershipMap.values.where((m) => m.isExpired).length,
            none: children
                .where((c) => !membershipMap.containsKey(c.id))
                .length,
          );

          // Sort: expired → expiring soon → no membership → active
          int priority(MembershipModel? m) {
            if (m == null) return 2;
            if (m.isExpired) return 0;
            if (m.isExpiringSoon) return 1;
            return 3;
          }

          final sorted = [...children]
            ..sort((a, b) =>
                priority(membershipMap[a.id])
                    .compareTo(priority(membershipMap[b.id])));

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: _SummaryHeader(summary: summary),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final child = sorted[i];
                      final m = membershipMap[child.id];
                      return _AthleteRow(
                        child: child,
                        membership: m,
                        onTap: () => _showSetSheet(ctx, child.id, m),
                      );
                    },
                    childCount: sorted.length,
                  ),
                ),
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

  void _showSetSheet(
      BuildContext context, String childId, MembershipModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _CoachSetMembershipSheet(childId: childId, existing: existing),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary header
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.summary});

  final ({int active, int expiringSoon, int expired, int none}) summary;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _Chip(count: summary.expired, label: 'Прострочених', color: AppColors.primary),
      const SizedBox(width: 8),
      _Chip(count: summary.expiringSoon, label: 'Закінчується', color: AppColors.orange),
      const SizedBox(width: 8),
      _Chip(count: summary.none, label: 'Без абонементу', color: AppColors.textSecondary),
      const SizedBox(width: 8),
      _Chip(count: summary.active, label: 'Активних', color: AppColors.success),
    ]);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.count, required this.label, required this.color});

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Athlete row
// ─────────────────────────────────────────────────────────────────────────────

class _AthleteRow extends StatelessWidget {
  const _AthleteRow({
    required this.child,
    required this.membership,
    required this.onTap,
  });

  final ChildModel child;
  final MembershipModel? membership;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusLabel;
    final String detail;

    if (membership == null) {
      statusColor = AppColors.textSecondary;
      statusLabel = 'Не активовано';
      detail = '';
    } else {
      final m = membership!;
      statusColor = m.statusColor;
      statusLabel = m.planName.isNotEmpty ? m.planName : m.statusLabel;
      detail = m.isExpired
          ? 'Прострочений ${m.daysExpiredAgo} дн тому'
          : '${m.daysRemaining} ${_dayWord(m.daysRemaining)} залишається';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surface3),
        ),
        child: Row(children: [
          // Avatar circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              shape: BoxShape.circle,
              border: Border.all(
                color: statusColor.withValues(alpha: 0.55),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '${child.firstName[0]}${child.lastName[0]}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${child.firstName} ${child.lastName}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ],
            ),
          ),

          // Days detail + edit icon
          if (detail.isNotEmpty)
            Text(
              detail,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          const SizedBox(width: 6),
          const Icon(
            Icons.edit_outlined,
            size: 16,
            color: AppColors.accent,
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coach set-membership bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CoachSetMembershipSheet extends ConsumerStatefulWidget {
  const _CoachSetMembershipSheet({required this.childId, this.existing});

  final String childId;
  final MembershipModel? existing;

  @override
  ConsumerState<_CoachSetMembershipSheet> createState() =>
      _CoachSetMembershipSheetState();
}

class _CoachSetMembershipSheetState
    extends ConsumerState<_CoachSetMembershipSheet> {
  static const _plans = [
    ('Разове тренування', 1, 150.0),
    ('1 тиждень', 7, 550.0),
    ('1 місяць', 30, 1450.0),
    ('3 місяці', 90, 3600.0),
    ('6 місяців', 180, 6000.0),
    ('12 місяців', 365, 9600.0),
  ];

  int _planIdx = 2;
  bool _saving = false;

  DateTime get _start => DateTime.now();
  DateTime get _end => _start.add(Duration(days: _plans[_planIdx].$2));

  @override
  Widget build(BuildContext context) {
    final plan = _plans[_planIdx];
    final fmt = DateFormat('dd.MM.yyyy');

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
              'Встановити абонемент',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ]),

          const SizedBox(height: 12),

          const Text('Тариф',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: List.generate(_plans.length, (i) {
              final selected = i == _planIdx;
              return GestureDetector(
                onTap: () => setState(() => _planIdx = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.ctaGradient : null,
                    color: selected ? null : AppColors.surface2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? Colors.transparent : AppColors.surface3,
                    ),
                  ),
                  child: Text(
                    _plans[i].$1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surface3),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${fmt.format(_start)} — ${fmt.format(_end)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${plan.$2} днів · ${plan.$3.toStringAsFixed(0)} грн',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _saving ? null : _save,
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
                : const Text('Підтвердити',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final plan = _plans[_planIdx];
      await ref.read(membershipNotifierProvider.notifier).setMembership(
            athleteId: widget.childId,
            planName: plan.$1,
            startDate: _start,
            endDate: _end,
            amount: plan.$3,
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Помилка збереження. Перевірте підключення.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }
}

String _dayWord(int days) {
  if (days % 10 == 1 && days % 100 != 11) { return 'день'; }
  if (days % 10 >= 2 &&
      days % 10 <= 4 &&
      (days % 100 < 10 || days % 100 >= 20)) { return 'дні'; }
  return 'днів';
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import 'package:flutter/services.dart';
import '../../../core/models/child_model.dart';
import '../models/promo_code.dart';
import '../../../core/models/membership_model.dart';
import '../providers/membership_provider.dart';
import '../models/tariff_plan.dart';
import '../providers/tariff_provider.dart';
import '../../team/providers/children_provider.dart';

class CoachMembershipsScreen extends ConsumerWidget {
  const CoachMembershipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(allChildrenProvider);
    final membershipsAsync = ref.watch(allMembershipsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.settings_outlined, size: 20),
        label: const Text('Тарифи', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) => const _TariffManagementSheet(),
        ),
      ),
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
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20, color: AppColors.textPrimary),
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
            for (final m in membershipsAsync.asData?.value ?? []) m.athleteId: m,
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
  int _planIdx = 2;
  bool _saving = false;

  DateTime get _start => DateTime.now();

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(tariffPlansProvider).asData?.value ?? TariffPlan.defaults;
    final planIdx = _planIdx.clamp(0, plans.length - 1);
    final plan = plans[planIdx];
    final endDate = _start.add(Duration(days: plan.days));
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
            children: List.generate(plans.length, (i) {
              final selected = i == planIdx;
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
                    plans[i].name,
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
                      '${fmt.format(_start)} — ${fmt.format(endDate)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${plan.days} днів · ${plan.price.toStringAsFixed(0)} грн',
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
      final plans = ref.read(tariffPlansProvider).asData?.value ?? TariffPlan.defaults;
      final planIdx = _planIdx.clamp(0, plans.length - 1);
      final plan = plans[planIdx];
      final endDate = _start.add(Duration(days: plan.days));
      await ref.read(membershipNotifierProvider.notifier).setMembership(
            athleteId: widget.childId,
            planName: plan.name,
            startDate: _start,
            endDate: endDate,
            amount: plan.price,
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

// ─────────────────────────────────────────────────────────────────────────────
// Tariff & promo management sheet (coach only)
// ─────────────────────────────────────────────────────────────────────────────

class _TariffManagementSheet extends ConsumerStatefulWidget {
  const _TariffManagementSheet();

  @override
  ConsumerState<_TariffManagementSheet> createState() =>
      _TariffManagementSheetState();
}

class _TariffManagementSheetState
    extends ConsumerState<_TariffManagementSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late List<TariffPlan> _plans;
  late List<PromoCode> _promos;
  bool _plansInitialized = false;
  bool _promosInitialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _plans = List.from(TariffPlan.defaults);
    _promos = [];
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(tariffPlansProvider);
    final promosAsync = ref.watch(promoCodesProvider);

    if (!_plansInitialized && plansAsync.asData != null) {
      _plans = List.from(plansAsync.asData!.value);
      _plansInitialized = true;
    }
    if (!_promosInitialized && promosAsync.asData != null) {
      _promos = List.from(promosAsync.asData!.value);
      _promosInitialized = true;
    }

    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
            child: Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.surface3,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Тарифи та промокоди',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Tabs
          TabBar(
            controller: _tab,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.accent,
            tabs: const [
              Tab(text: 'Тарифи'),
              Tab(text: 'Промокоди'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                // ── Tariffs tab ──────────────────────────────────────────
                ListView(
                  controller: scrollCtrl,
                  padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 80),
                  children: [
                    ..._plans.asMap().entries.map((entry) {
                      final i = entry.key;
                      final plan = entry.value;
                      return _TariffEditRow(
                        plan: plan,
                        onChanged: (updated) => setState(() => _plans[i] = updated),
                      );
                    }),
                  ],
                ),
                // ── Promo codes tab ──────────────────────────────────────
                ListView(
                  controller: scrollCtrl,
                  padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 80),
                  children: [
                    ..._promos.asMap().entries.map((entry) {
                      final i = entry.key;
                      final promo = entry.value;
                      return _PromoRow(
                        promo: promo,
                        onToggle: (val) => setState(() {
                          _promos[i] = PromoCode(
                            code: promo.code,
                            discountPct: promo.discountPct,
                            validUntil: promo.validUntil,
                            isActive: val,
                          );
                        }),
                        onDelete: () => setState(() => _promos.removeAt(i)),
                      );
                    }),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _addPromo,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Додати промокод'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.accent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Save button
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 16),
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Зберегти',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  void _addPromo() async {
    final result = await showDialog<PromoCode>(
      context: context,
      builder: (_) => const _AddPromoDialog(),
    );
    if (result != null) setState(() => _promos.add(result));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final notifier = ref.read(tariffNotifierProvider.notifier);
      await notifier.savePlans(_plans);
      await notifier.savePromoCodes(_promos);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Помилка: $e'),
          backgroundColor: AppColors.primary,
        ));
      }
    }
  }
}

// ── Tariff edit row ───────────────────────────────────────────────────────────

class _TariffEditRow extends StatefulWidget {
  const _TariffEditRow({required this.plan, required this.onChanged});
  final TariffPlan plan;
  final ValueChanged<TariffPlan> onChanged;

  @override
  State<_TariffEditRow> createState() => _TariffEditRowState();
}

class _TariffEditRowState extends State<_TariffEditRow> {
  late final TextEditingController _priceCtrl;
  late final TextEditingController _oldPriceCtrl;
  late final TextEditingController _badgeCtrl;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(
        text: widget.plan.price.toStringAsFixed(0));
    _oldPriceCtrl = TextEditingController(
        text: widget.plan.oldPrice?.toStringAsFixed(0) ?? '');
    _badgeCtrl = TextEditingController(text: widget.plan.badge);
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _oldPriceCtrl.dispose();
    _badgeCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    final price = double.tryParse(_priceCtrl.text.trim()) ?? widget.plan.price;
    final oldPrice = _oldPriceCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_oldPriceCtrl.text.trim());
    widget.onChanged(TariffPlan(
      name: widget.plan.name,
      days: widget.plan.days,
      price: price,
      oldPrice: oldPrice,
      badge: _badgeCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surface3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.plan.name} · ${widget.plan.days} дн.',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Field(
                  controller: _priceCtrl,
                  label: 'Ціна (грн)',
                  isNumeric: true,
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Field(
                  controller: _oldPriceCtrl,
                  label: 'Стара ціна (грн)',
                  hint: 'необов\'язково',
                  isNumeric: true,
                  onChanged: (_) => _emit(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Field(
            controller: _badgeCtrl,
            label: 'Бейдж (напр. Популярний)',
            hint: 'необов\'язково',
            onChanged: (_) => _emit(),
          ),
        ],
      ),
    );
  }
}

// ── Promo row ─────────────────────────────────────────────────────────────────

class _PromoRow extends StatelessWidget {
  const _PromoRow({
    required this.promo,
    required this.onToggle,
    required this.onDelete,
  });
  final PromoCode promo;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: promo.isValid ? AppColors.success.withValues(alpha: 0.4) : AppColors.surface3,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      promo.code,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 1),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '−${promo.discountPct}%',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
                if (promo.validUntil != null)
                  Text(
                    'До ${DateFormat('dd.MM.yyyy').format(promo.validUntil!)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          Switch(
            value: promo.isActive,
            onChanged: onToggle,
            activeColor: AppColors.success,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: AppColors.primary),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ── Add promo dialog ──────────────────────────────────────────────────────────

class _AddPromoDialog extends StatefulWidget {
  const _AddPromoDialog();

  @override
  State<_AddPromoDialog> createState() => _AddPromoDialogState();
}

class _AddPromoDialogState extends State<_AddPromoDialog> {
  final _codeCtrl = TextEditingController();
  final _pctCtrl = TextEditingController();
  DateTime? _validUntil;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _pctCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Новий промокод',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _Field(
              controller: _codeCtrl,
              label: 'Код (напр. TRIUMPH20)',
              onChanged: (_) => setState(() {
                _codeCtrl.value = _codeCtrl.value.copyWith(
                  text: _codeCtrl.text.toUpperCase(),
                  selection: TextSelection.collapsed(
                      offset: _codeCtrl.text.length),
                );
              }),
            ),
            const SizedBox(height: 10),
            _Field(
              controller: _pctCtrl,
              label: 'Знижка (%)',
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) setState(() => _validUntil = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.surface3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      _validUntil != null
                          ? 'Дійсний до: ${DateFormat('dd.MM.yyyy').format(_validUntil!)}'
                          : 'Термін дії (необов\'язково)',
                      style: TextStyle(
                        fontSize: 13,
                        color: _validUntil != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Скасувати'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final code = _codeCtrl.text.trim().toUpperCase();
                    final pct = int.tryParse(_pctCtrl.text.trim()) ?? 0;
                    if (code.isEmpty || pct <= 0 || pct >= 100) return;
                    Navigator.pop(context, PromoCode(
                      code: code,
                      discountPct: pct,
                      validUntil: _validUntil,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  child: const Text('Додати',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Shared input field ────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.onChanged,
    this.inputFormatters,
    this.isNumeric = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final bool isNumeric;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      inputFormatters: inputFormatters ??
          (isNumeric ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : null),
      keyboardType: isNumeric ? TextInputType.number : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.surface3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.surface3),
        ),
      ),
    );
  }
}

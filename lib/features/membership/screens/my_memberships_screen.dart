import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/membership_model.dart';
import '../../../shared/widgets/triumph_icon.dart';
import '../providers/membership_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MyMembershipsScreen
// ─────────────────────────────────────────────────────────────────────────────

class MyMembershipsScreen extends ConsumerStatefulWidget {
  const MyMembershipsScreen({super.key, required this.childId});

  final String childId;

  @override
  ConsumerState<MyMembershipsScreen> createState() =>
      _MyMembershipsScreenState();
}

class _MyMembershipsScreenState extends ConsumerState<MyMembershipsScreen> {
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo() {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Промокод застосовано'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
    _promoController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final membershipAsync =
        ref.watch(membershipByAthleteProvider(widget.childId));

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
                        child: TriumphIcon(TIcon.back, size: 22, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Мої абонементи',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
                child: membershipAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (m) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Current membership compact card ─────────────────────────
              _CurrentMembershipCard(membership: m),

              const SizedBox(height: 28),

              // ── History section ─────────────────────────────────────────
              const Text(
                'ІСТОРІЯ АБОНЕМЕНТІВ',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              _buildHistoryList(m),

              const SizedBox(height: 28),

              // ── Promo code banner ───────────────────────────────────────
              _PromoCodeCard(
                controller: _promoController,
                onApply: _applyPromo,
              ),
            ],
          ),
        ),
      ),
      ),
    ],
  ),
  ),
    );
  }

  Widget _buildHistoryList(MembershipModel? current) {
    // Build static fake history based on current membership
    final now = DateTime.now();
    final items = <_HistoryItem>[
      if (current != null)
        _HistoryItem(
          planName: current.planName,
          startDate: current.startDate,
          endDate: current.endDate,
          amount: current.amount,
          status: current.isExpired ? 'Завершено' : 'Активний',
          statusColor: current.isExpired ? AppColors.primary : AppColors.success,
        ),
      _HistoryItem(
        planName: '1 місяць',
        startDate: DateTime(now.year, now.month - 2, 1),
        endDate: DateTime(now.year, now.month - 1, 1),
        amount: 1450,
        status: 'Завершено',
        statusColor: AppColors.textSecondary,
      ),
      _HistoryItem(
        planName: '3 місяці',
        startDate: DateTime(now.year - 1, 10, 1),
        endDate: DateTime(now.year, 1, 1),
        amount: 3600,
        status: 'Завершено',
        statusColor: AppColors.textSecondary,
      ),
      _HistoryItem(
        planName: '1 місяць',
        startDate: DateTime(now.year - 1, 9, 1),
        endDate: DateTime(now.year - 1, 10, 1),
        amount: 1450,
        status: 'Завершено',
        statusColor: AppColors.textSecondary,
      ),
    ];

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surface3),
        ),
        child: const Center(
          child: Text(
            'Немає записів про абонементи',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface3),
      ),
      child: Column(
        children: List.generate(
          items.length,
          (i) => _PaymentHistoryItem(
            item: items[i],
            isLast: i == items.length - 1,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Current membership compact card
// ─────────────────────────────────────────────────────────────────────────────

class _CurrentMembershipCard extends StatelessWidget {
  const _CurrentMembershipCard({required this.membership});

  final MembershipModel? membership;

  @override
  Widget build(BuildContext context) {
    if (membership == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surface3),
        ),
        child: const Row(
          children: [
            TriumphIcon(TIcon.trophy, size: 24, color: AppColors.textSecondary),
            SizedBox(width: 12),
            Text(
              'Немає активного абонемента',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final m = membership!;
    final endDateStr = DateFormat('dd.MM.yyyy', 'uk').format(m.endDate);
    final totalDays = m.endDate.difference(m.startDate).inDays.clamp(1, 99999);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: m.isExpired
            ? const LinearGradient(
                colors: [Color(0xFF1A0202), Color(0xFF2A0505)],
              )
            : AppColors.heroCardGradient,
        border: m.isExpired
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.50), width: 1.5)
            : null,
        boxShadow: m.isExpired
            ? []
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'МІЙ АБОНЕМЕНТ',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.60),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: m.statusColor.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: m.statusColor.withValues(alpha: 0.55)),
                ),
                child: Text(
                  m.statusLabel,
                  style: TextStyle(
                    color: m.statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            m.planName.toUpperCase(),
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 12, color: Colors.white.withValues(alpha: 0.65)),
              const SizedBox(width: 5),
              Text(
                'До $endDateStr',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (!m.isExpired)
                Text(
                  'Залишилось ${m.daysRemaining} ${_dayWord(m.daysRemaining)}',
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (!m.isExpired) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 1.0 -
                    (m.daysRemaining / totalDays).clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.20),
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.orange),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History item data
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryItem {
  final String planName;
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final String status;
  final Color statusColor;

  const _HistoryItem({
    required this.planName,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.status,
    required this.statusColor,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment history item widget
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentHistoryItem extends StatelessWidget {
  const _PaymentHistoryItem({required this.item, required this.isLast});

  final _HistoryItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final startStr = DateFormat('dd.MM.yyyy', 'uk').format(item.startDate);
    final endStr = DateFormat('dd.MM.yyyy', 'uk').format(item.endDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.surface3, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surface3),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: AppColors.textSecondary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.planName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$startStr — $endStr',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.amount.toStringAsFixed(0)}₴',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.status,
                style: TextStyle(
                  color: item.statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Promo code card
// ─────────────────────────────────────────────────────────────────────────────

class _PromoCodeCard extends StatelessWidget {
  const _PromoCodeCard({
    required this.controller,
    required this.onApply,
  });

  final TextEditingController controller;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A00), Color(0xFF2A1200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
            color: AppColors.orange.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_offer_outlined,
                    color: AppColors.orange, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Є промокод?',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Введіть промокод, щоб отримати знижку на абонемент',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                  decoration: InputDecoration(
                    hintText: 'TRIUMPH2024',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.50),
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.surface3),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.surface3),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppColors.orange.withValues(alpha: 0.60),
                          width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onApply,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6A00), Color(0xFFFFD21A)],
                    ),
                  ),
                  child: const Text(
                    'Застосувати',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────────────────────────

String _dayWord(int days) {
  if (days % 10 == 1 && days % 100 != 11) { return 'день'; }
  if (days % 10 >= 2 &&
      days % 10 <= 4 &&
      (days % 100 < 10 || days % 100 >= 20)) { return 'дні'; }
  return 'днів';
}

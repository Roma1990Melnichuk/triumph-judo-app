import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/payment_card_model.dart';
import '../../../core/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/coach_settings_provider.dart';

/// Відкриває sheet фінансових налаштувань тренера.
void showCoachFinancialSettings(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _CoachFinancialSettingsSheet(),
  );
}

class _CoachFinancialSettingsSheet extends ConsumerStatefulWidget {
  const _CoachFinancialSettingsSheet();

  @override
  ConsumerState<_CoachFinancialSettingsSheet> createState() =>
      _CoachFinancialSettingsSheetState();
}

class _CoachFinancialSettingsSheetState
    extends ConsumerState<_CoachFinancialSettingsSheet> {
  final _priceCtrl = TextEditingController();
  bool _priceDirty = false;

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  UserModel? get _user =>
      ref.read(currentUserModelProvider).asData?.value;

  void _initPrice(double price) {
    if (!_priceDirty) {
      _priceCtrl.text = price > 0 ? price.toStringAsFixed(0) : '';
    }
  }

  Future<void> _savePrice() async {
    final raw = double.tryParse(_priceCtrl.text.trim());
    if (raw == null) return;
    try {
      await ref
          .read(coachSettingsNotifierProvider.notifier)
          .updateIndividualPrice(raw);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ціну збережено'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Помилка: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
    setState(() => _priceDirty = false);
  }

  Future<void> _removeCard(String cardId) async {
    try {
      await ref
          .read(coachSettingsNotifierProvider.notifier)
          .removeCard(cardId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Помилка: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _reorder(List<PaymentCard> cards, int oldIdx, int newIdx) async {
    if (newIdx > oldIdx) newIdx--;
    final updated = [...cards];
    final item = updated.removeAt(oldIdx);
    updated.insert(newIdx, item);
    try {
      await ref
          .read(coachSettingsNotifierProvider.notifier)
          .reorderCards(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Помилка: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  void _showAddCardDialog(BuildContext ctx) {
    final labelCtrl  = TextEditingController();
    final numberCtrl = TextEditingController();
    final holderCtrl = TextEditingController();
    final formKey    = GlobalKey<FormState>();

    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: const Text('Додати картку'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(
                ctrl: labelCtrl,
                label: 'Назва (напр. Monobank)',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Обов\'язкове поле' : null,
              ),
              const SizedBox(height: 10),
              _DialogField(
                ctrl: numberCtrl,
                label: 'Номер картки або IBAN',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Обов\'язкове поле' : null,
              ),
              const SizedBox(height: 10),
              _DialogField(
                ctrl: holderCtrl,
                label: 'Ім\'я власника',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Обов\'язкове поле' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dCtx);
              final card = PaymentCard.create(
                label: labelCtrl.text.trim(),
                number: numberCtrl.text.trim(),
                holder: holderCtrl.text.trim(),
              );
              try {
                await ref
                    .read(coachSettingsNotifierProvider.notifier)
                    .addCard(card);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Помилка: $e'),
                    backgroundColor: AppColors.error,
                  ));
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Додати'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserModelProvider).asData?.value;
    if (user != null) _initPrice(user.individualPrice);

    final cards = user?.paymentCards ?? [];
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ──────────────────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surface3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const Text(
            'Фінансові налаштування',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),

          // ── Individual training price ────────────────────────────────────
          const Text(
            'Ціна індивідуального заняття',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() => _priceDirty = true),
                  decoration: InputDecoration(
                    hintText: '0',
                    suffixText: '₴',
                    filled: true,
                    fillColor: AppColors.surface2,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.surface3),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.surface3),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _priceDirty ? _savePrice : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.surface3,
                  minimumSize: const Size(80, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Зберегти'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Payment cards ────────────────────────────────────────────────
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Картки для оплати',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Перша в списку — дефолтна для клієнта',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddCardDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Додати'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (cards.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Картки не додано.\nКлієнт не побачить реквізити на екрані оплати.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            )
          else
            // Обмеження висоти, щоб sheet не виходив за екран
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: cards.length,
                onReorder: (o, n) => _reorder(cards, o, n),
                itemBuilder: (_, i) {
                  final card = cards[i];
                  return _CardTile(
                    key: ValueKey(card.id),
                    card: card,
                    isDefault: i == 0,
                    onDelete: () => _removeCard(card.id),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Допоміжні віджети ─────────────────────────────────────────────────────────

class _CardTile extends StatelessWidget {
  const _CardTile({
    super.key,
    required this.card,
    required this.isDefault,
    required this.onDelete,
  });

  final PaymentCard card;
  final bool isDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDefault ? AppColors.primary.withValues(alpha: 0.5) : AppColors.surface3,
          width: isDefault ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // drag handle
          const Icon(Icons.drag_handle, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Icon(Icons.credit_card_outlined,
              color: isDefault ? AppColors.primary : AppColors.textSecondary,
              size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      card.label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'дефолт',
                          style: TextStyle(
                              fontSize: 9,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  card.number,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                if (card.holder.isNotEmpty)
                  Text(
                    card.holder,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.error, size: 20),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.ctrl,
    required this.label,
    this.validator,
  });

  final TextEditingController ctrl;
  final String label;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface3,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

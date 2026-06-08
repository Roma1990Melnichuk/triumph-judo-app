import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/individual_slot_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/team/providers/children_provider.dart';
import '../../../services/export_service.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/triumph_icon.dart';
import '../providers/individual_training_provider.dart';

class IndividualTrainingScreen extends ConsumerStatefulWidget {
  const IndividualTrainingScreen({super.key});

  @override
  ConsumerState<IndividualTrainingScreen> createState() =>
      _IndividualTrainingScreenState();
}

class _IndividualTrainingScreenState
    extends ConsumerState<IndividualTrainingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserModelProvider).value;
    final isCoach = user?.isCoach ?? false;

    if (isCoach) {
      return _CoachView(userId: user!.uid, coachName: user.name);
    } else {
      // Parent/athlete view: available slots + their bookings
      return _ParentView(user: user);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coach view: manage slots, see requests
// ─────────────────────────────────────────────────────────────────────────────

class _CoachView extends ConsumerWidget {
  const _CoachView({required this.userId, required this.coachName});
  final String userId;
  final String coachName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(coachSlotsProvider(userId));
    final slots = slotsAsync.value ?? [];

    final pending = slots.where((s) => s.status == SlotStatus.requested).toList();
    final upcoming = slots
        .where((s) =>
            s.status == SlotStatus.available ||
            s.status == SlotStatus.confirmed)
        .where((s) => !s.date.isBefore(
            DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)))
        .toList();
    final past = slots
        .where((s) => s.date.isBefore(
            DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Індивідуальні тренування'),
        actions: [
          if (slots.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Експорт',
              onPressed: () => ExportService.exportIndividualTrainings(
                  context, slots),
            ),
        ],
      ),
      body: Column(
        children: [
          // Pending requests banner
          if (pending.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                const ColorFiltered(
                  colorFilter: ColorFilter.mode(AppColors.warning, BlendMode.srcIn),
                  child: TriumphIcon(TIcon.notifications, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${pending.length} ${_requestWord(pending.length)} очікують підтвердження',
                    style: const TextStyle(
                        color: AppColors.warning, fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),

          Expanded(
            child: slotsAsync.isLoading
                ? const Center(child: CircularProgressIndicator())
                : slots.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ColorFiltered(
                            colorFilter: ColorFilter.mode(AppColors.textSecondary.withValues(alpha: 0.4), BlendMode.srcIn),
                            child: const TriumphIcon(TIcon.calendar, size: 56),
                          ),
                            const SizedBox(height: 12),
                            const Text('Немає слотів',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            const Text(
                              'Натисніть + щоб додати часові слоти',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding:
                            const EdgeInsets.only(top: 4, bottom: 90),
                        children: [
                          if (pending.isNotEmpty) ...[
                            _SectionHeader(
                                'Запити (${pending.length})'),
                            ...pending.map((s) => _SlotTile(
                                  slot: s,
                                  isCoach: true,
                                  onConfirm: () => ref
                                      .read(
                                          individualTrainingNotifierProvider
                                              .notifier)
                                      .confirmSlot(s.id),
                                  onCancel: () => ref
                                      .read(
                                          individualTrainingNotifierProvider
                                              .notifier)
                                      .cancelSlot(s.id),
                                )),
                          ],
                          if (upcoming.isNotEmpty) ...[
                            _SectionHeader('Найближчі'),
                            ...upcoming.map((s) => _SlotTile(
                                  slot: s,
                                  isCoach: true,
                                  onDelete: s.status ==
                                          SlotStatus.available
                                      ? () => ref
                                          .read(
                                              individualTrainingNotifierProvider
                                                  .notifier)
                                          .deleteSlot(s.id)
                                      : null,
                                  onMarkPaid:
                                      s.status == SlotStatus.confirmed &&
                                              !s.isPaid
                                          ? () => ref
                                              .read(
                                                  individualTrainingNotifierProvider
                                                      .notifier)
                                              .markPaid(s.id)
                                          : null,
                                )),
                          ],
                          if (past.isNotEmpty) ...[
                            _SectionHeader('Минулі'),
                            ...past.map((s) =>
                                _SlotTile(slot: s, isCoach: true)),
                          ],
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSlotDialog(context, ref, userId, coachName),
        tooltip: 'Додати слот',
        child: const ColorFiltered(colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn), child: TriumphIcon(TIcon.add, size: 24)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Parent/athlete view: browse available slots + own bookings
// ─────────────────────────────────────────────────────────────────────────────

class _ParentView extends ConsumerWidget {
  const _ParentView({this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableAsync = ref.watch(availableSlotsProvider);
    final available = availableAsync.value ?? [];

    // Parent's linked child
    final childId = user?.childIds.firstOrNull;
    final myBookingsAsync =
        childId != null ? ref.watch(childSlotsProvider(childId)) : null;
    final myBookings = myBookingsAsync?.value ?? [];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Індивідуальні тренування'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Доступні'),
              Tab(text: 'Мої записи'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Available slots
            availableAsync.isLoading
                ? const Center(child: CircularProgressIndicator())
                : available.isEmpty
                    ? const Center(
                        child: Text('Немає доступних слотів',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        itemCount: available.length,
                        itemBuilder: (_, i) => _SlotTile(
                          slot: available[i],
                          isCoach: false,
                          onBook: childId != null
                              ? () => _confirmBook(
                                  context, ref, available[i], childId)
                              : null,
                        ),
                      ),

            // My bookings
            myBookings.isEmpty
                ? const Center(
                    child: Text('Немає записів',
                        style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: myBookings.length,
                    itemBuilder: (_, i) => _SlotTile(
                      slot: myBookings[i],
                      isCoach: false,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _confirmBook(BuildContext context, WidgetRef ref,
      IndividualSlotModel slot, String childId) {
    final allChildren = ref.read(allChildrenProvider).value ?? [];
    final child = allChildren.firstWhere((c) => c.id == childId,
        orElse: () => allChildren.first);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Записатись на тренування?'),
        content: Text(
          '${DateFormat('dd MMM yyyy', 'uk').format(slot.date)}\n'
          '${slot.timeStart} – ${slot.timeEnd}\n'
          'Тренер: ${slot.coachName}'
          '${slot.price != null ? '\nВартість: ${slot.price} ${slot.currency}' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(individualTrainingNotifierProvider.notifier)
                  .requestSlot(
                    slotId: slot.id,
                    childId: childId,
                    childName: child.fullName,
                    userId: user?.uid ?? '',
                  );
            },
            child: const Text('Записатись'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared slot tile
// ─────────────────────────────────────────────────────────────────────────────

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.isCoach,
    this.onConfirm,
    this.onCancel,
    this.onDelete,
    this.onBook,
    this.onMarkPaid,
  });

  final IndividualSlotModel slot;
  final bool isCoach;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;
  final VoidCallback? onBook;
  final VoidCallback? onMarkPaid;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(slot.status);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date/time column
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  DateFormat('dd').format(slot.date),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  DateFormat('MMM', 'uk').format(slot.date),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Main info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${slot.timeStart} – ${slot.timeEnd}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (!isCoach)
                    Text('Тренер: ${slot.coachName}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  if (slot.childName != null)
                    Text(slot.childName!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        slot.status.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (slot.price != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${slot.price} ${slot.currency}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.accent),
                      ),
                    ],
                    if (slot.isPaid) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.check_circle,
                          size: 13, color: AppColors.success),
                      const Text(' Оплачено',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.success)),
                    ],
                  ]),
                ],
              ),
            ),

            // Action buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onConfirm != null)
                  _ActionBtn(
                    tIcon: TIcon.success,
                    color: AppColors.success,
                    tooltip: 'Підтвердити',
                    onTap: onConfirm!,
                  ),
                if (onCancel != null) ...[
                  const SizedBox(height: 4),
                  _ActionBtn(
                    icon: Icons.close,
                    color: AppColors.error,
                    tooltip: 'Відхилити',
                    onTap: onCancel!,
                  ),
                ],
                if (onDelete != null) ...[
                  const SizedBox(height: 4),
                  _ActionBtn(
                    tIcon: TIcon.delete,
                    color: AppColors.textSecondary,
                    tooltip: 'Видалити',
                    onTap: onDelete!,
                  ),
                ],
                if (onBook != null)
                  _ActionBtn(
                    tIcon: TIcon.add,
                    color: AppColors.primary,
                    tooltip: 'Записатись',
                    onTap: onBook!,
                  ),
                if (onMarkPaid != null) ...[
                  const SizedBox(height: 4),
                  _ActionBtn(
                    icon: Icons.payment,
                    color: AppColors.accent,
                    tooltip: 'Оплачено',
                    onTap: onMarkPaid!,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    this.icon,
    this.tIcon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  }) : assert(icon != null || tIcon != null);
  final IconData? icon;
  final TIcon? tIcon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: tIcon != null
                ? ColorFiltered(
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                    child: TriumphIcon(tIcon!, size: 16),
                  )
                : Icon(icon, size: 16, color: color),
          ),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Add slot dialog
// ─────────────────────────────────────────────────────────────────────────────

void _showAddSlotDialog(
    BuildContext context, WidgetRef ref, String coachId, String coachName) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AddSlotSheet(coachId: coachId, coachName: coachName),
  );
}

class _AddSlotSheet extends ConsumerStatefulWidget {
  const _AddSlotSheet({required this.coachId, required this.coachName});
  final String coachId;
  final String coachName;

  @override
  ConsumerState<_AddSlotSheet> createState() => _AddSlotSheetState();
}

class _AddSlotSheetState extends ConsumerState<_AddSlotSheet> {
  DateTime _date = DateTime.now();
  final List<({String start, String end})> _slots = [];
  final _startCtrl = TextEditingController(text: '14:00');
  final _endCtrl = TextEditingController(text: '14:45');
  final _priceCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('uk'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _addSlot() {
    final s = _startCtrl.text.trim();
    final e = _endCtrl.text.trim();
    if (s.isEmpty || e.isEmpty) return;
    setState(() => _slots.add((start: s, end: e)));
    // Advance time by slot duration
    final parts = e.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]) ?? 14;
      final m = int.tryParse(parts[1]) ?? 0;
      final next = TimeOfDay(hour: h, minute: m + 30 > 59 ? m : m + 30);
      final nextEnd = TimeOfDay(
          hour: next.minute >= 30 ? h + 1 : h,
          minute: next.minute >= 30 ? next.minute - 30 : next.minute + 15);
      _startCtrl.text = '${next.hour.toString().padLeft(2, '0')}:${next.minute.toString().padLeft(2, '0')}';
      _endCtrl.text =
          '${nextEnd.hour.toString().padLeft(2, '0')}:${nextEnd.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (_slots.isEmpty) return;
    setState(() => _saving = true);
    final price = double.tryParse(_priceCtrl.text.trim());
    for (final slot in _slots) {
      await ref.read(individualTrainingNotifierProvider.notifier).createSlot(
            IndividualSlotModel(
              id: '',
              coachId: widget.coachId,
              coachName: widget.coachName,
              date: _date,
              timeStart: slot.start,
              timeEnd: slot.end,
              price: price,
              currency: 'UAH',
              status: SlotStatus.available,
            ),
          );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text('Додати слоти',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),

          // Date
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surface3),
              ),
              child: Row(children: [
                const ColorFiltered(
                  colorFilter: ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn),
                  child: TriumphIcon(TIcon.calendar, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMMM yyyy', 'uk').format(_date),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Time range row
          Row(children: [
            Expanded(
              child: TextField(
                controller: _startCtrl,
                decoration: const InputDecoration(
                  labelText: 'Початок',
                  hintText: '14:00',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _endCtrl,
                decoration: const InputDecoration(
                  labelText: 'Кінець',
                  hintText: '14:45',
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _addSlot,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const ColorFiltered(colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn), child: TriumphIcon(TIcon.add, size: 18)),
            ),
          ]),
          const SizedBox(height: 8),

          // Added slots
          if (_slots.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _slots
                  .map((s) => Chip(
                        label: Text(
                          '${s.start}–${s.end}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onDeleted: () =>
                            setState(() => _slots.remove(s)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],

          // Price
          TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Вартість (UAH, необов\'язково)',
              prefixIcon: Icon(Icons.attach_money_outlined),
            ),
          ),
          const SizedBox(height: 16),

          GradientButton(
            onPressed: (_saving || _slots.isEmpty) ? null : _save,
            child: Text(
              _saving
                  ? 'Збереження...'
                  : 'Зберегти (${_slots.length} слот${_slotSuffix(_slots.length)})',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

Color _statusColor(SlotStatus s) {
  switch (s) {
    case SlotStatus.available:  return AppColors.success;
    case SlotStatus.requested:  return AppColors.warning;
    case SlotStatus.confirmed:  return AppColors.info;
    case SlotStatus.cancelled:  return AppColors.textSecondary;
  }
}

String _requestWord(int n) {
  if (n == 1) return 'запит';
  if (n < 5) return 'запити';
  return 'запитів';
}

String _slotSuffix(int n) {
  if (n == 1) return '';
  if (n < 5) return 'и';
  return 'ів';
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/event_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/triumph_icon.dart';
import '../providers/events_provider.dart';

class AddEditEventScreen extends ConsumerStatefulWidget {
  const AddEditEventScreen({super.key, this.eventId});
  final String? eventId;

  @override
  ConsumerState<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends ConsumerState<AddEditEventScreen> {
  final _form = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  EventType _type = EventType.competition;
  DateTime _date = DateTime.now();
  final Set<BeltLevel> _selectedBelts = {};
  bool _loading = false;
  EventModel? _original;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEvent());
  }

  void _loadEvent() {
    if (widget.eventId == null) return;
    final event = ref
        .read(allEventsProvider)
        .value
        ?.where((e) => e.id == widget.eventId)
        .firstOrNull;
    if (event == null) return;
    _original = event;
    _titleCtrl.text = event.title;
    _locationCtrl.text = event.location;
    _descCtrl.text = event.description ?? '';
    _type = event.type;
    _date = event.date;
    for (final name in event.beltLevels) {
      final b = BeltLevel.values.firstWhere(
        (b) => b.name == name,
        orElse: () => BeltLevel.white,
      );
      _selectedBelts.add(b);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('uk'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);

    final user = ref.read(currentUserModelProvider).asData?.value;
    final notifier = ref.read(eventsNotifierProvider.notifier);

    if (_original != null) {
      await notifier.updateEvent(_original!.copyWith(
        title: _titleCtrl.text.trim(),
        type: _type,
        date: _date,
        location: _locationCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        beltLevels: _selectedBelts.map((b) => b.name).toList(),
      ));
    } else {
      await notifier.addEvent(EventModel(
        id: '',
        title: _titleCtrl.text.trim(),
        type: _type,
        date: _date,
        location: _locationCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        coachId: user?.uid ?? '',
        beltLevels: _selectedBelts.map((b) => b.name).toList(),
        participantIds: [],
        year: _date.year,
      ));
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _original != null;
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
                  Text(
                    isEdit ? 'Редагувати подію' : 'Нова подія',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Назва події',
                hintText: 'Наприклад: Чемпіонат міста',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Введіть назву' : null,
            ),
            const SizedBox(height: 16),

            // Type picker
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surface3),
              ),
              child: Row(
                children: [
                  const Text('Тип:',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      children: EventType.values.map((t) {
                        final sel = _type == t;
                        return GestureDetector(
                          onTap: () => setState(() => _type = t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: sel ? AppColors.ctaGradient : null,
                              color: sel ? null : AppColors.surface3,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_typeIcon(t)} ${t.displayName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: sel
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: sel
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Date
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surface3),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('dd MMM yyyy', 'uk').format(_date),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Місце проведення',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Belt levels
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surface3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Пояси (для кого)',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: BeltLevel.values.map((b) {
                      final sel = _selectedBelts.contains(b);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (sel) {
                            _selectedBelts.remove(b);
                          } else {
                            _selectedBelts.add(b);
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: sel
                                ? b.color.withValues(alpha: 0.2)
                                : AppColors.surface3,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel
                                  ? b.color.withValues(alpha: 0.5)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: b.color,
                                shape: BoxShape.circle,
                                border: b == BeltLevel.white
                                    ? Border.all(
                                        color: Colors.grey.shade400, width: 0.5)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              b.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: sel
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            if (sel) ...[
                              const SizedBox(width: 3),
                              const Icon(Icons.check,
                                  size: 11, color: AppColors.success),
                            ],
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Опис (необов\'язково)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),

            GradientButton(
              onPressed: _loading ? null : _save,
              child: Text(
                _loading ? 'Збереження...' : (isEdit ? 'Зберегти' : 'Додати подію'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      ),
    ],
  ),
  ),
    );
  }
}

String _typeIcon(EventType t) {
  switch (t) {
    case EventType.competition: return '🥇';
    case EventType.tournament:  return '🏆';
    case EventType.camp:        return '🏕️';
    case EventType.other:       return '📅';
  }
}

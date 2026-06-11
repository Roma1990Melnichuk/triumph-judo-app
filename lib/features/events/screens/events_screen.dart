import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/child_model.dart';
import '../../../core/models/event_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/team/providers/children_provider.dart';
import '../../../shared/widgets/triumph_icon.dart';
import '../providers/events_provider.dart';

// ── Locale constants ──────────────────────────────────────────────────────────
const _kMonthsNom = [
  'Січень','Лютий','Березень','Квітень','Травень','Червень',
  'Липень','Серпень','Вересень','Жовтень','Листопад','Грудень',
];
const _kMonthsGen = [
  'Січня','Лютого','Березня','Квітня','Травня','Червня',
  'Липня','Серпня','Вересня','Жовтня','Листопада','Грудня',
];
const _kWeekdaysFull = [
  'Понеділок','Вівторок','Середа','Четвер','П\'ятниця','Субота','Неділя',
];
const _kWeekdaysShort = ['Пн','Вт','Ср','Чт','Пт','Сб','Нд'];

// ─────────────────────────────────────────────────────────────────────────────
// Events Screen — Google Calendar style
// ─────────────────────────────────────────────────────────────────────────────

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _prevMonth() => setState(() {
        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      });

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month);
      _selectedDay = DateTime(now.year, now.month, now.day);
    });
  }

  void _selectDay(DateTime day) => setState(() {
        _selectedDay = day;
        if (day.year != _focusedMonth.year || day.month != _focusedMonth.month) {
          _focusedMonth = DateTime(day.year, day.month);
        }
      });

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserModelProvider).value;
    final isCoach = user?.isCoach ?? false;
    final filter = ref.watch(eventsFilterProvider);
    final allFiltered = ref.watch(filteredEventsProvider);
    final years = ref.watch(eventYearsProvider);
    final loading = ref.watch(allEventsProvider).isLoading;

    // Group events by calendar date key
    final eventsByDay = <DateTime, List<EventModel>>{};
    for (final e in allFiltered) {
      final key = DateTime(e.date.year, e.date.month, e.date.day);
      (eventsByDay[key] ??= []).add(e);
    }
    final selectedEvents = eventsByDay[_selectedDay] ?? const [];

    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Графік подій',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const ColorFiltered(
                      colorFilter: ColorFilter.mode(
                          AppColors.textSecondary, BlendMode.srcIn),
                      child: TriumphIcon(TIcon.calendar, size: 22),
                    ),
                    tooltip: 'Сьогодні',
                    onPressed: _jumpToToday,
                  ),
                  if (isCoach)
                    GestureDetector(
                      onTap: () => context.push('/events/add'),
                      child: Container(
                        width: 34,
                        height: 34,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: const BoxDecoration(
                          gradient: AppColors.ctaGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Filters (always visible) ─────────────────────────────
            _buildFilters(context, filter, years),

            // ── Calendar ─────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surface3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMonthHeader(),
                  _buildWeekdayHeader(),
                  _buildMonthGrid(eventsByDay, todayKey),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Agenda day header ─────────────────────────────────────
            _buildAgendaHeader(_selectedDay, selectedEvents.length, todayKey),

            // ── Events list for selected day ──────────────────────────
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : selectedEvents.isEmpty
                      ? _buildEmptyDay(isCoach, context)
                      : ListView.builder(
                          padding:
                              const EdgeInsets.only(top: 4, bottom: 80),
                          itemCount: selectedEvents.length,
                          itemBuilder: (_, i) => _EventCard(
                            event: selectedEvents[i],
                            isCoach: isCoach,
                            currentUserId: user?.uid ?? '',
                            currentChildId: user?.childIds.firstOrNull,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Calendar sub-widgets ──────────────────────────────────────────────────

  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            splashRadius: 20,
            color: AppColors.textSecondary,
            onPressed: _prevMonth,
          ),
          Expanded(
            child: GestureDetector(
              onTap: _jumpToToday,
              child: Text(
                '${_kMonthsNom[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            splashRadius: 20,
            color: AppColors.textSecondary,
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Row(
        children: _kWeekdaysShort.map((d) {
          final isSunday = d == 'Нд';
          return Expanded(
            child: Center(
              child: Text(
                d,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSunday
                      ? AppColors.primary.withValues(alpha: 0.7)
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthGrid(
      Map<DateTime, List<EventModel>> eventsByDay, DateTime todayKey) {
    final firstDay =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startOffset = firstDay.weekday - 1; // 0 = Mon
    final totalCells =
        ((startOffset + daysInMonth) / 7).ceil() * 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 0.82,
        ),
        itemCount: totalCells,
        itemBuilder: (_, index) {
          final dayOffset = index - startOffset;
          final date = firstDay.add(Duration(days: dayOffset));
          final dateKey =
              DateTime(date.year, date.month, date.day);

          return _DayCell(
            date: date,
            isCurrentMonth:
                date.month == _focusedMonth.month,
            isSelected: dateKey == _selectedDay,
            isToday: dateKey == todayKey,
            events: eventsByDay[dateKey] ?? const [],
            onTap: () => _selectDay(dateKey),
          );
        },
      ),
    );
  }

  Widget _buildAgendaHeader(
      DateTime day, int count, DateTime todayKey) {
    final isToday = day == todayKey;
    final label = isToday
        ? 'Сьогодні, ${day.day} ${_kMonthsGen[day.month - 1]}'
        : '${_kWeekdaysFull[day.weekday - 1]}, ${day.day} ${_kMonthsGen[day.month - 1]}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      color: AppColors.surface,
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isToday ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyDay(bool isCoach, BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              AppColors.textSecondary.withValues(alpha: 0.3),
              BlendMode.srcIn,
            ),
            child: TriumphIcon(TIcon.calendar, size: 48),
          ),
          const SizedBox(height: 10),
          const Text('Немає подій цього дня',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          if (isCoach) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => context.push('/events/add'),
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: const Text('Додати подію'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilters(
      BuildContext context, EventsFilter filter, List<int> years) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
              children: [
                _FilterChip(
                  label: filter.year?.toString() ?? 'Рік',
                  selected: filter.year != null,
                  onTap: () =>
                      _showYearPicker(context, filter, years),
                  onClear: filter.year != null
                      ? () => ref
                          .read(eventsFilterProvider.notifier)
                          .update((s) => s.copyWith(clearYear: true))
                      : null,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: filter.type?.displayName ?? 'Тип',
                  selected: filter.type != null,
                  onTap: () => _showTypePicker(context, filter),
                  onClear: filter.type != null
                      ? () => ref
                          .read(eventsFilterProvider.notifier)
                          .update((s) => s.copyWith(clearType: true))
                      : null,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: filter.belt?.displayName ?? 'Пояс',
                  selected: filter.belt != null,
                  onTap: () => _showBeltPicker(context, filter),
                  onClear: filter.belt != null
                      ? () => ref
                          .read(eventsFilterProvider.notifier)
                          .update((s) => s.copyWith(clearBelt: true))
                      : null,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Топ 20',
                  selected: filter.top20Only,
                  onTap: () => ref
                      .read(eventsFilterProvider.notifier)
                      .update((s) =>
                          s.copyWith(top20Only: !s.top20Only)),
                  onClear: filter.top20Only
                      ? () => ref
                          .read(eventsFilterProvider.notifier)
                          .update(
                              (s) => s.copyWith(top20Only: false))
                      : null,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Крім топ 20',
                  selected: filter.exceptTop20,
                  onTap: () => ref
                      .read(eventsFilterProvider.notifier)
                      .update((s) =>
                          s.copyWith(exceptTop20: !s.exceptTop20)),
                  onClear: filter.exceptTop20
                      ? () => ref
                          .read(eventsFilterProvider.notifier)
                          .update(
                              (s) => s.copyWith(exceptTop20: false))
                      : null,
                ),
              ],
            ),
          );
  }

  // ── Pickers ───────────────────────────────────────────────────────────────

  void _showYearPicker(
      BuildContext context, EventsFilter filter, List<int> years) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Оберіть рік',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...years.map((y) => ListTile(
                  title: Text(y.toString()),
                  selected: filter.year == y,
                  selectedColor: AppColors.primary,
                  onTap: () {
                    ref.read(eventsFilterProvider.notifier).update(
                          (s) => s.copyWith(year: y),
                        );
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showTypePicker(BuildContext context, EventsFilter filter) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Тип події',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...EventType.values.map((t) => ListTile(
                  leading: Text(_typeIcon(t),
                      style: const TextStyle(fontSize: 22)),
                  title: Text(t.displayName),
                  selected: filter.type == t,
                  selectedColor: AppColors.primary,
                  onTap: () {
                    ref.read(eventsFilterProvider.notifier).update(
                          (s) => s.copyWith(type: t),
                        );
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showBeltPicker(BuildContext context, EventsFilter filter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Пояс',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: BeltLevel.values
                      .map((b) => ListTile(
                            leading: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: b.color,
                                shape: BoxShape.circle,
                                border: b == BeltLevel.white
                                    ? Border.all(
                                        color: Colors.grey.shade400)
                                    : null,
                              ),
                            ),
                            title: Text(b.displayName),
                            selected: filter.belt == b,
                            selectedColor: AppColors.primary,
                            onTap: () {
                              ref
                                  .read(eventsFilterProvider.notifier)
                                  .update((s) => s.copyWith(belt: b));
                              Navigator.pop(context);
                            },
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Day cell ──────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isToday,
    required this.events,
    required this.onTap,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isToday;
  final List<EventModel> events;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSunday = date.weekday == 7;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  width: 1)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Day number with today circle
            Container(
              width: 28,
              height: 28,
              decoration: isToday
                  ? BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    )
                  : null,
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isToday || isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isToday
                        ? Colors.white
                        : !isCurrentMonth
                            ? AppColors.textSecondary
                                .withValues(alpha: 0.3)
                            : isSunday
                                ? AppColors.primary
                                    .withValues(alpha: 0.7)
                                : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            // Event dots
            if (events.isNotEmpty) ...[
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: events.take(3).map((e) {
                  return Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: _eventDotColor(e.type)
                          .withValues(alpha: isCurrentMonth ? 1.0 : 0.4),
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _eventDotColor(EventType type) {
    switch (type) {
      case EventType.competition: return AppColors.accent;
      case EventType.tournament:  return AppColors.primary;
      case EventType.camp:        return AppColors.success;
      case EventType.other:       return AppColors.info;
    }
  }
}

// ── Event detail bottom sheet ─────────────────────────────────────────────────

void _showEventDetail(
    BuildContext context, EventModel event, List<ChildModel> allChildren) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: ListView(
          controller: ctrl,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              '${_typeIcon(event.type)} ${event.title}',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const ColorFiltered(
                colorFilter: ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn),
                child: TriumphIcon(TIcon.calendar, size: 14),
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('dd MMMM yyyy', 'uk').format(event.date),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ]),
            if (event.location.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(event.location,
                    style: const TextStyle(
                        color: AppColors.textSecondary)),
              ]),
            ],
            if (event.description != null &&
                event.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(event.description!,
                  style: const TextStyle(fontSize: 14)),
            ],
            if (event.participantIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Учасники (${event.participantIds.length}):',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: event.participantIds.map((id) {
                  final name = allChildren
                          .where((c) => c.id == id)
                          .firstOrNull
                          ?.fullName ??
                      id;
                  return Chip(
                    label: Text(name,
                        style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

// ── Event card ────────────────────────────────────────────────────────────────

class _EventCard extends ConsumerWidget {
  const _EventCard({
    required this.event,
    required this.isCoach,
    required this.currentUserId,
    this.currentChildId,
  });

  final EventModel event;
  final bool isCoach;
  final String currentUserId;
  final String? currentChildId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allChildren = ref.watch(allChildrenProvider).value ?? [];
    final isGoing = currentChildId != null &&
        event.participantIds.contains(currentChildId);
    final participantCount = event.participantIds.length;

    final participantNames = event.participantIds
        .take(3)
        .map((id) =>
            allChildren.where((c) => c.id == id).firstOrNull?.firstName ??
            '?')
        .toList();

    return GestureDetector(
      onTap: () => _showEventDetail(context, event, allChildren),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surface3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: _typeColor(event.type)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type icon box
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _typeColor(event.type)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _typeColor(event.type)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(_typeIcon(event.type),
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 12,
                              color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yyyy', 'uk')
                                .format(event.date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (event.location.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.location_on_outlined,
                                size: 12,
                                color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                event.location,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),
                  if (!isCoach)
                    _GoingButton(
                      event: event,
                      childId: currentChildId,
                      isGoing: isGoing,
                    )
                  else
                    _CoachActions(event: event),
                ],
              ),

              const SizedBox(height: 10),

              // Belt chips
              if (event.beltLevels.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: event.beltLevels.map((bName) {
                    final b = BeltLevel.values.firstWhere(
                      (b) => b.name == bName,
                      orElse: () => BeltLevel.white,
                    );
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: b.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: b.color.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        b.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          color: b == BeltLevel.white
                              ? Colors.white
                              : b.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              if (participantCount > 0) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const ColorFiltered(
                    colorFilter: ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn),
                    child: TriumphIcon(TIcon.team, size: 13),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$participantCount учасн.',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary),
                  ),
                  if (participantNames.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      participantNames.join(', ') +
                          (participantCount > 3 ? '...' : ''),
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ]),
              ],
            ],
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── "Я іду" button ────────────────────────────────────────────────────────────

class _GoingButton extends ConsumerWidget {
  const _GoingButton({
    required this.event,
    required this.childId,
    required this.isGoing,
  });

  final EventModel event;
  final String? childId;
  final bool isGoing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (childId == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () {
        ref
            .read(eventsNotifierProvider.notifier)
            .toggleParticipant(event.id, childId!);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: isGoing ? AppColors.ctaGradient : null,
          color: isGoing ? null : AppColors.surface3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isGoing ? Colors.transparent : AppColors.surface3,
          ),
        ),
        child: Text(
          isGoing ? 'Іду ✓' : 'Іду',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color:
                isGoing ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Coach quick actions ───────────────────────────────────────────────────────

class _CoachActions extends ConsumerWidget {
  const _CoachActions({required this.event});
  final EventModel event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert,
          size: 18, color: AppColors.textSecondary),
      color: AppColors.surface2,
      itemBuilder: (_) => [
        const PopupMenuItem(
            value: 'edit', child: Text('Редагувати')),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Видалити',
              style: TextStyle(color: AppColors.error)),
        ),
      ],
      onSelected: (v) {
        if (v == 'edit') context.push('/events/${event.id}/edit');
        if (v == 'delete') _confirmDelete(context, ref);
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Видалити подію?'),
        content: Text('«${event.title}» буде видалено.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(eventsNotifierProvider.notifier)
                  .deleteEvent(event.id);
            },
            child: const Text('Видалити',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Filter chip widget ────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? null : AppColors.surface2,
          gradient: selected ? AppColors.redGoldGradient : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.surface3,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
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
            if (selected && onClear != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close,
                    size: 13, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _typeIcon(EventType t) {
  switch (t) {
    case EventType.competition: return '🥇';
    case EventType.tournament:  return '🏆';
    case EventType.camp:        return '🏕️';
    case EventType.other:       return '📅';
  }
}

Color _typeColor(EventType t) {
  switch (t) {
    case EventType.competition: return AppColors.accent;
    case EventType.tournament:  return AppColors.primary;
    case EventType.camp:        return AppColors.success;
    case EventType.other:       return AppColors.info;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/event_model.dart';
import 'package:judo_app/features/events/providers/events_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

EventModel makeEvent({
  String id = 'e1',
  EventType type = EventType.tournament,
  int year = 2026,
  List<String> beltLevels = const [],
  List<String> participantIds = const [],
}) =>
    EventModel(
      id: id,
      title: 'Подія',
      type: type,
      date: DateTime(year, 5, 1),
      location: 'Місто',
      coachId: 'coach1',
      beltLevels: beltLevels,
      participantIds: participantIds,
      year: year,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── EventsFilter initial state ────────────────────────────────────────────

  group('EventsFilter — початковий стан', () {
    test('всі фільтри вимкнені за замовчуванням', () {
      const f = EventsFilter();
      expect(f.year, isNull);
      expect(f.type, isNull);
      expect(f.belt, isNull);
      expect(f.top20Only, isFalse);
    });
  });

  // ── EventsFilter.copyWith ─────────────────────────────────────────────────

  group('EventsFilter.copyWith — встановлення фільтрів', () {
    test('встановлює year', () {
      const f = EventsFilter();
      final updated = f.copyWith(year: 2025);
      expect(updated.year, 2025);
      expect(updated.type, isNull);
      expect(updated.belt, isNull);
    });

    test('встановлює type', () {
      const f = EventsFilter();
      final updated = f.copyWith(type: EventType.competition);
      expect(updated.type, EventType.competition);
      expect(updated.year, isNull);
    });

    test('встановлює belt', () {
      const f = EventsFilter();
      final updated = f.copyWith(belt: BeltLevel.green);
      expect(updated.belt, BeltLevel.green);
    });

    test('включає top20Only', () {
      const f = EventsFilter();
      final updated = f.copyWith(top20Only: true);
      expect(updated.top20Only, isTrue);
    });

    test('не змінює незадані поля', () {
      const f = EventsFilter(year: 2026, type: EventType.camp, top20Only: true);
      final updated = f.copyWith(belt: BeltLevel.blue);
      expect(updated.year, 2026);
      expect(updated.type, EventType.camp);
      expect(updated.top20Only, isTrue);
      expect(updated.belt, BeltLevel.blue);
    });
  });

  group('EventsFilter.copyWith — очищення фільтрів', () {
    test('clearYear обнуляє рік', () {
      const f = EventsFilter(year: 2026);
      final cleared = f.copyWith(clearYear: true);
      expect(cleared.year, isNull);
    });

    test('clearType обнуляє тип', () {
      const f = EventsFilter(type: EventType.competition);
      final cleared = f.copyWith(clearType: true);
      expect(cleared.type, isNull);
    });

    test('clearBelt обнуляє пояс', () {
      const f = EventsFilter(belt: BeltLevel.yellow);
      final cleared = f.copyWith(clearBelt: true);
      expect(cleared.belt, isNull);
    });

    test('clearYear має пріоритет над переданим year', () {
      const f = EventsFilter(year: 2026);
      final cleared = f.copyWith(year: 2025, clearYear: true);
      expect(cleared.year, isNull);
    });

    test('clearType не зачіпає інші поля', () {
      const f = EventsFilter(year: 2024, type: EventType.tournament, belt: BeltLevel.green);
      final cleared = f.copyWith(clearType: true);
      expect(cleared.type, isNull);
      expect(cleared.year, 2024);
      expect(cleared.belt, BeltLevel.green);
    });

    test('очищення невстановленого фільтра не призводить до помилки', () {
      const f = EventsFilter();
      final cleared = f.copyWith(clearYear: true, clearType: true, clearBelt: true);
      expect(cleared.year, isNull);
      expect(cleared.type, isNull);
      expect(cleared.belt, isNull);
    });
  });

  // ── Filtering logic (pure, without providers) ─────────────────────────────

  group('EventsFilter — логіка фільтрації (чиста)', () {
    final events = [
      makeEvent(id: 'a', year: 2025, type: EventType.competition, beltLevels: ['yellow']),
      makeEvent(id: 'b', year: 2026, type: EventType.tournament, beltLevels: ['green', 'blue']),
      makeEvent(id: 'c', year: 2026, type: EventType.camp, beltLevels: []),
      makeEvent(id: 'd', year: 2026, type: EventType.competition, beltLevels: ['green']),
    ];

    List<EventModel> applyFilter(EventsFilter f, {Set<String> top20Ids = const {}}) {
      return events.where((e) {
        if (f.year != null && e.year != f.year) return false;
        if (f.type != null && e.type != f.type) return false;
        if (f.belt != null && e.beltLevels.isNotEmpty) {
          if (!e.beltLevels.contains(f.belt!.name)) return false;
        }
        if (f.top20Only) {
          if (!e.participantIds.any((id) => top20Ids.contains(id))) return false;
        }
        return true;
      }).toList();
    }

    test('без фільтрів — всі події', () {
      expect(applyFilter(const EventsFilter()).length, 4);
    });

    test('фільтр по року 2026 — виключає 2025', () {
      final result = applyFilter(const EventsFilter(year: 2026));
      expect(result.map((e) => e.id), containsAll(['b', 'c', 'd']));
      expect(result.map((e) => e.id), isNot(contains('a')));
    });

    test('фільтр по року 2025 — тільки одна подія', () {
      final result = applyFilter(const EventsFilter(year: 2025));
      expect(result.length, 1);
      expect(result.first.id, 'a');
    });

    test('фільтр по типу competition', () {
      final result = applyFilter(const EventsFilter(type: EventType.competition));
      expect(result.map((e) => e.id).toList(), containsAll(['a', 'd']));
      expect(result.length, 2);
    });

    test('фільтр по типу camp — тільки одна подія', () {
      final result = applyFilter(const EventsFilter(type: EventType.camp));
      expect(result.length, 1);
      expect(result.first.id, 'c');
    });

    test('фільтр по поясу green — залишає події з green або без поясів', () {
      final result = applyFilter(const EventsFilter(belt: BeltLevel.green));
      // Event 'c' has empty beltLevels — passes through (no restriction)
      // Event 'b' has 'green' → passes
      // Event 'd' has 'green' → passes
      // Event 'a' has 'yellow' only → excluded
      final ids = result.map((e) => e.id).toList();
      expect(ids, contains('b'));
      expect(ids, contains('c'));
      expect(ids, contains('d'));
      expect(ids, isNot(contains('a')));
    });

    test('фільтр по поясу yellow — лише event з yellow', () {
      final result = applyFilter(const EventsFilter(belt: BeltLevel.yellow));
      expect(result.length, greaterThanOrEqualTo(1));
      expect(result.where((e) => e.id == 'a').length, 1);
    });

    test('поєднання year + type', () {
      final result = applyFilter(const EventsFilter(year: 2026, type: EventType.competition));
      expect(result.length, 1);
      expect(result.first.id, 'd');
    });

    test('top20Only виключає події без учасників з top-20', () {
      final eventsWithParticipants = [
        makeEvent(id: 'x', participantIds: ['top1', 'top2']),
        makeEvent(id: 'y', participantIds: ['other']),
        makeEvent(id: 'z', participantIds: []),
      ];

      final top20 = {'top1', 'top2'};
      final filtered = eventsWithParticipants.where((e) {
        if (!e.participantIds.any((id) => top20.contains(id))) return false;
        return true;
      }).toList();

      expect(filtered.length, 1);
      expect(filtered.first.id, 'x');
    });
  });
}

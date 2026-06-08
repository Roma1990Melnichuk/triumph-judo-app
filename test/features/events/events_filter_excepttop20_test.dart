import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/event_model.dart';
import 'package:judo_app/features/events/providers/events_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

EventModel makeEvent({
  String id = 'e1',
  List<String> participantIds = const [],
  int year = 2026,
  EventType type = EventType.tournament,
}) =>
    EventModel(
      id: id,
      title: 'Подія',
      type: type,
      date: DateTime(year, 5, 1),
      location: 'Місто',
      coachId: 'coach1',
      beltLevels: const [],
      participantIds: participantIds,
      year: year,
    );

/// Pure application of EventsFilter to a list — mirrors filteredEventsProvider logic.
List<EventModel> applyFilter(
  EventsFilter f,
  List<EventModel> events, {
  Set<String> top20Ids = const {},
}) {
  return events.where((e) {
    if (f.year != null && e.year != f.year) return false;
    if (f.type != null && e.type != f.type) return false;
    if (f.belt != null && e.beltLevels.isNotEmpty) {
      if (!e.beltLevels.contains(f.belt!.name)) return false;
    }
    if (f.top20Only) {
      if (!e.participantIds.any((id) => top20Ids.contains(id))) return false;
    }
    if (f.exceptTop20) {
      if (e.participantIds.any((id) => top20Ids.contains(id))) return false;
    }
    return true;
  }).toList();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── початковий стан ───────────────────────────────────────────────────────

  group('EventsFilter — exceptTop20 початковий стан', () {
    test('exceptTop20 = false за замовчуванням', () {
      expect(const EventsFilter().exceptTop20, isFalse);
    });

    test('top20Only і exceptTop20 обидва false за замовчуванням', () {
      const f = EventsFilter();
      expect(f.top20Only, isFalse);
      expect(f.exceptTop20, isFalse);
    });
  });

  // ── взаємне виключення в copyWith ─────────────────────────────────────────

  group('EventsFilter.copyWith — взаємне виключення top20Only/exceptTop20', () {
    test('встановлення exceptTop20=true скидає top20Only в false', () {
      const f = EventsFilter(top20Only: true);
      final updated = f.copyWith(exceptTop20: true);
      expect(updated.exceptTop20, isTrue);
      expect(updated.top20Only, isFalse);
    });

    test('встановлення top20Only=true скидає exceptTop20 в false', () {
      const f = EventsFilter(exceptTop20: true);
      final updated = f.copyWith(top20Only: true);
      expect(updated.top20Only, isTrue);
      expect(updated.exceptTop20, isFalse);
    });

    test('exceptTop20=false не скидає top20Only', () {
      const f = EventsFilter(top20Only: true);
      final updated = f.copyWith(exceptTop20: false);
      expect(updated.top20Only, isTrue);
      expect(updated.exceptTop20, isFalse);
    });

    test('незмінений exceptTop20 зберігається через copyWith', () {
      const f = EventsFilter(exceptTop20: true);
      final updated = f.copyWith(year: 2026);
      expect(updated.exceptTop20, isTrue);
      expect(updated.year, 2026);
    });
  });

  // ── логіка фільтрації exceptTop20 ────────────────────────────────────────

  group('EventsFilter — логіка фільтрації exceptTop20', () {
    final events = [
      makeEvent(id: 'a', participantIds: ['top1', 'top2']),  // є топ-20
      makeEvent(id: 'b', participantIds: ['top1', 'other']), // є топ-20
      makeEvent(id: 'c', participantIds: ['other1', 'other2']), // немає топ-20
      makeEvent(id: 'd', participantIds: []),                 // порожній список
    ];
    const top20 = {'top1', 'top2'};

    test('exceptTop20 виключає події з топ-20 учасниками', () {
      const f = EventsFilter(exceptTop20: true);
      final result = applyFilter(f, events, top20Ids: top20);
      final ids = result.map((e) => e.id).toList();
      expect(ids, isNot(contains('a')));
      expect(ids, isNot(contains('b')));
    });

    test('exceptTop20 включає події без топ-20 учасників', () {
      const f = EventsFilter(exceptTop20: true);
      final result = applyFilter(f, events, top20Ids: top20);
      final ids = result.map((e) => e.id).toList();
      expect(ids, contains('c'));
      expect(ids, contains('d'));
    });

    test('exceptTop20 з порожнім top20Ids не фільтрує нічого', () {
      const f = EventsFilter(exceptTop20: true);
      final result = applyFilter(f, events, top20Ids: {});
      expect(result.length, events.length);
    });

    test('top20Only і exceptTop20 дають взаємно доповнювальні множини', () {
      final onlyTop = applyFilter(
        const EventsFilter(top20Only: true), events, top20Ids: top20,
      );
      final exceptTop = applyFilter(
        const EventsFilter(exceptTop20: true), events, top20Ids: top20,
      );
      final allIds = {...onlyTop.map((e) => e.id), ...exceptTop.map((e) => e.id)};
      expect(allIds, containsAll(events.map((e) => e.id)));
      expect(
        onlyTop.map((e) => e.id).toSet().intersection(exceptTop.map((e) => e.id).toSet()),
        isEmpty,
      );
    });

    test('без фільтра всі події проходять', () {
      const f = EventsFilter();
      expect(applyFilter(f, events, top20Ids: top20).length, events.length);
    });
  });
}

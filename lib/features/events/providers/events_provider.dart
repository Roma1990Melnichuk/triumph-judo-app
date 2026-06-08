import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/event_model.dart';
import '../../../core/constants/belt_levels.dart';
import '../../auth/providers/auth_provider.dart';
import '../../team/providers/children_provider.dart';

// ── All events ────────────────────────────────────────────────────────────────
final allEventsProvider = StreamProvider<List<EventModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('events')
      .orderBy('date', descending: false)
      .snapshots()
      .map((s) => s.docs.map(EventModel.fromFirestore).toList())
      .handleError((_) {});
});

// ── Filter state ─────────────────────────────────────────────────────────────
class EventsFilter {
  final int? year;
  final EventType? type;
  final BeltLevel? belt;
  final bool top20Only;
  final bool exceptTop20;

  const EventsFilter({
    this.year,
    this.type,
    this.belt,
    this.top20Only = false,
    this.exceptTop20 = false,
  });

  EventsFilter copyWith({
    int? year,
    EventType? type,
    BeltLevel? belt,
    bool? top20Only,
    bool? exceptTop20,
    bool clearYear = false,
    bool clearType = false,
    bool clearBelt = false,
  }) {
    final newTop20 = exceptTop20 == true ? false : (top20Only ?? this.top20Only);
    final newExcept = top20Only == true ? false : (exceptTop20 ?? this.exceptTop20);
    return EventsFilter(
      year: clearYear ? null : (year ?? this.year),
      type: clearType ? null : (type ?? this.type),
      belt: clearBelt ? null : (belt ?? this.belt),
      top20Only: newTop20,
      exceptTop20: newExcept,
    );
  }
}

final eventsFilterProvider =
    StateProvider<EventsFilter>((ref) => const EventsFilter());

// ── Filtered events (applies year / type / belt / top-20) ────────────────────
final filteredEventsProvider = Provider<List<EventModel>>((ref) {
  final events = ref.watch(allEventsProvider).value ?? [];
  final filter = ref.watch(eventsFilterProvider);

  // Top-20 child IDs by points (needed for both top20Only and exceptTop20)
  Set<String> top20Ids = {};
  if (filter.top20Only || filter.exceptTop20) {
    final all = ref.watch(allChildrenProvider).value ?? [];
    final sorted = [...all]..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    top20Ids = sorted.take(20).map((c) => c.id).toSet();
  }

  return events.where((e) {
    if (filter.year != null && e.year != filter.year) return false;
    if (filter.type != null && e.type != filter.type) return false;
    if (filter.belt != null && e.beltLevels.isNotEmpty) {
      if (!e.beltLevels.contains(filter.belt!.name)) return false;
    }
    if (filter.top20Only) {
      if (!e.participantIds.any((id) => top20Ids.contains(id))) return false;
    }
    if (filter.exceptTop20) {
      // Exclude events where any top-20 athlete is listed as participant
      if (e.participantIds.any((id) => top20Ids.contains(id))) return false;
    }
    return true;
  }).toList();
});

// ── Available years ───────────────────────────────────────────────────────────
final eventYearsProvider = Provider<List<int>>((ref) {
  final events = ref.watch(allEventsProvider).value ?? [];
  final years = events.map((e) => e.year).toSet().toList()..sort((a, b) => b.compareTo(a));
  if (years.isEmpty) {
    final now = DateTime.now().year;
    return [now, now - 1, now + 1];
  }
  return years;
});

// ── CRUD notifier ─────────────────────────────────────────────────────────────
class EventsNotifier extends StateNotifier<AsyncValue<void>> {
  EventsNotifier(this._db) : super(const AsyncValue.data(null));

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  Future<void> addEvent(EventModel event) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final id = _uuid.v4();
      await _db.collection('events').doc(id).set(
            EventModel(
              id: id,
              title: event.title,
              type: event.type,
              date: event.date,
              location: event.location,
              description: event.description,
              coachId: event.coachId,
              beltLevels: event.beltLevels,
              participantIds: event.participantIds,
              year: event.date.year,
            ).toFirestore(),
          );
    });
  }

  Future<void> updateEvent(EventModel event) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db.collection('events').doc(event.id).update(event.toFirestore());
    });
  }

  Future<void> deleteEvent(String eventId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db.collection('events').doc(eventId).delete();
    });
  }

  // Toggle participation for a child
  Future<void> toggleParticipant(String eventId, String childId) async {
    state = await AsyncValue.guard(() async {
      final doc = await _db.collection('events').doc(eventId).get();
      final event = EventModel.fromFirestore(doc);
      final updated = event.participantIds.contains(childId)
          ? event.participantIds.where((id) => id != childId).toList()
          : [...event.participantIds, childId];
      await _db.collection('events').doc(eventId).update({
        'participantIds': updated,
      });
    });
  }
}

final eventsNotifierProvider =
    StateNotifierProvider<EventsNotifier, AsyncValue<void>>((ref) {
  return EventsNotifier(ref.watch(firestoreProvider));
});

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/event_model.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

EventModel makeEvent({
  String id = 'ev1',
  String title = 'Київський турнір',
  EventType type = EventType.tournament,
  DateTime? date,
  String location = 'Київ',
  String? description,
  String coachId = 'coach1',
  List<String> beltLevels = const ['yellow', 'orange'],
  List<String> participantIds = const ['c1', 'c2'],
  int year = 2026,
}) =>
    EventModel(
      id: id,
      title: title,
      type: type,
      date: date ?? DateTime(2026, 3, 15),
      location: location,
      description: description,
      coachId: coachId,
      beltLevels: beltLevels,
      participantIds: participantIds,
      year: year,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── EventTypeX.displayName ────────────────────────────────────────────────

  group('EventTypeX.displayName', () {
    test('competition → Змагання', () {
      expect(EventType.competition.displayName, 'Змагання');
    });

    test('tournament → Турнір', () {
      expect(EventType.tournament.displayName, 'Турнір');
    });

    test('camp → Збір', () {
      expect(EventType.camp.displayName, 'Збір');
    });

    test('other → Інше', () {
      expect(EventType.other.displayName, 'Інше');
    });
  });

  // ── EventTypeX.fromString ─────────────────────────────────────────────────

  group('EventTypeX.fromString', () {
    test('розпізнає всі валідні значення', () {
      expect(EventTypeX.fromString('competition'), EventType.competition);
      expect(EventTypeX.fromString('tournament'), EventType.tournament);
      expect(EventTypeX.fromString('camp'), EventType.camp);
      expect(EventTypeX.fromString('other'), EventType.other);
    });

    test('невідоме значення → competition (fallback)', () {
      expect(EventTypeX.fromString('unknown'), EventType.competition);
      expect(EventTypeX.fromString(''), EventType.competition);
    });
  });

  // ── EventModel.fromFirestore ──────────────────────────────────────────────

  group('EventModel.fromFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('зчитує всі поля коректно', () async {
      final ref = fakeFirestore.collection('events').doc('ev1');
      await ref.set({
        'title': 'Харківські змагання',
        'type': 'competition',
        'date': Timestamp.fromDate(DateTime(2026, 5, 10)),
        'location': 'Харків',
        'description': 'Опис змагань',
        'coachId': 'coach42',
        'beltLevels': ['green', 'blue'],
        'participantIds': ['child1', 'child2', 'child3'],
        'year': 2026,
      });

      final doc = await ref.get();
      final model = EventModel.fromFirestore(doc);

      expect(model.id, 'ev1');
      expect(model.title, 'Харківські змагання');
      expect(model.type, EventType.competition);
      expect(model.date, DateTime(2026, 5, 10));
      expect(model.location, 'Харків');
      expect(model.description, 'Опис змагань');
      expect(model.coachId, 'coach42');
      expect(model.beltLevels, ['green', 'blue']);
      expect(model.participantIds, ['child1', 'child2', 'child3']);
      expect(model.year, 2026);
    });

    test('description = null коли поле відсутнє', () async {
      final ref = fakeFirestore.collection('events').doc('ev2');
      await ref.set({
        'title': 'Збір',
        'type': 'camp',
        'date': Timestamp.fromDate(DateTime(2026, 7, 1)),
        'location': 'Одеса',
        'coachId': 'c1',
        'beltLevels': <String>[],
        'participantIds': <String>[],
        'year': 2026,
      });

      final model = EventModel.fromFirestore(await ref.get());
      expect(model.description, isNull);
    });

    test('beltLevels та participantIds — пустий список за замовчуванням', () async {
      final ref = fakeFirestore.collection('events').doc('ev3');
      await ref.set({
        'title': 'Тест',
        'type': 'other',
        'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'location': '',
        'coachId': '',
        'year': 2026,
      });

      final model = EventModel.fromFirestore(await ref.get());
      expect(model.beltLevels, isEmpty);
      expect(model.participantIds, isEmpty);
    });
  });

  // ── EventModel.toFirestore ────────────────────────────────────────────────

  group('EventModel.toFirestore', () {
    test('включає всі обов\'язкові поля', () {
      final event = makeEvent();
      final map = event.toFirestore();

      expect(map['title'], 'Київський турнір');
      expect(map['type'], 'tournament');
      expect(map['location'], 'Київ');
      expect(map['coachId'], 'coach1');
      expect(map['beltLevels'], ['yellow', 'orange']);
      expect(map['participantIds'], ['c1', 'c2']);
      expect(map['year'], 2026);
    });

    test('date серіалізується як Timestamp', () {
      final event = makeEvent(date: DateTime(2026, 6, 1));
      final map = event.toFirestore();
      expect(map['date'], isA<Timestamp>());
      expect((map['date'] as Timestamp).toDate(), DateTime(2026, 6, 1));
    });

    test('description включається тільки коли не null', () {
      final withDesc = makeEvent(description: 'Опис').toFirestore();
      expect(withDesc.containsKey('description'), isTrue);
      expect(withDesc['description'], 'Опис');

      final withoutDesc = makeEvent().toFirestore();
      expect(withoutDesc.containsKey('description'), isFalse);
    });

    test('тип enum серіалізується як рядок (name)', () {
      final map = makeEvent(type: EventType.camp).toFirestore();
      expect(map['type'], 'camp');
    });
  });

  // ── EventModel.copyWith ───────────────────────────────────────────────────

  group('EventModel.copyWith', () {
    test('не змінені поля зберігаються', () {
      final original = makeEvent();
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.title, original.title);
      expect(copy.coachId, original.coachId);
      expect(copy.year, original.year);
    });

    test('змінює title', () {
      final copy = makeEvent().copyWith(title: 'Новий турнір');
      expect(copy.title, 'Новий турнір');
    });

    test('змінює тип', () {
      final copy = makeEvent(type: EventType.tournament).copyWith(type: EventType.camp);
      expect(copy.type, EventType.camp);
    });

    test('замінює participantIds', () {
      final copy = makeEvent().copyWith(participantIds: ['c3', 'c4', 'c5']);
      expect(copy.participantIds, ['c3', 'c4', 'c5']);
    });

    test('замінює beltLevels на порожній список', () {
      final copy = makeEvent(beltLevels: ['green']).copyWith(beltLevels: []);
      expect(copy.beltLevels, isEmpty);
    });

    test('зберігає id та coachId (не змінюються через copyWith)', () {
      final original = makeEvent(id: 'fixed-id', coachId: 'fixed-coach');
      final copy = original.copyWith(title: 'Щось нове');
      expect(copy.id, 'fixed-id');
      expect(copy.coachId, 'fixed-coach');
    });
  });

  // ── Round-trip (toFirestore → fromFirestore) ──────────────────────────────

  group('EventModel — round-trip', () {
    test('зберігає і зчитує всі поля без втрат', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final original = makeEvent(
        id: 'rt1',
        title: 'Round Trip',
        type: EventType.competition,
        date: DateTime(2026, 9, 1),
        location: 'Львів',
        description: 'Тест',
        beltLevels: [BeltLevel.green.name, BeltLevel.blue.name],
        participantIds: ['p1', 'p2'],
        year: 2026,
      );

      await fakeFirestore.collection('events').doc('rt1').set(original.toFirestore());
      final doc = await fakeFirestore.collection('events').doc('rt1').get();
      final restored = EventModel.fromFirestore(doc);

      expect(restored.title, original.title);
      expect(restored.type, original.type);
      expect(restored.date, original.date);
      expect(restored.location, original.location);
      expect(restored.description, original.description);
      expect(restored.beltLevels, original.beltLevels);
      expect(restored.participantIds, original.participantIds);
      expect(restored.year, original.year);
    });
  });
}

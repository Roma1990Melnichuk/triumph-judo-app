/// E2E тести для EventsNotifier — повний CRUD подій + участь спортсменів.
/// Покриває: addEvent, updateEvent, deleteEvent, toggleParticipant, full scenario.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/event_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/events/providers/events_provider.dart';

// ── Хелпери ───────────────────────────────────────────────────────────────────

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

ProviderContainer _container(FakeFirebaseFirestore db) => ProviderContainer(
      overrides: [firestoreProvider.overrideWithValue(db)],
    );

EventModel _event({
  String id = '',
  String title = 'Змагання U12',
  EventType type = EventType.competition,
  String coachId = 'coach1',
  List<String> beltLevels = const ['white', 'whiteYellow'],
  List<String> participantIds = const [],
  DateTime? date,
}) =>
    EventModel(
      id: id,
      title: title,
      type: type,
      date: date ?? DateTime(2025, 6, 15),
      location: 'Спортзал "Тріумф"',
      description: 'Обласні змагання',
      coachId: coachId,
      beltLevels: beltLevels,
      participantIds: participantIds,
      year: (date ?? DateTime(2025, 6, 15)).year,
    );

Future<String> _seedEvent(
  FakeFirebaseFirestore db, {
  String title = 'Подія',
  String coachId = 'coach1',
  List<String> participantIds = const [],
}) async {
  final ref = await db.collection('events').add({
    'title': title,
    'type': 'competition',
    'date': Timestamp.fromDate(DateTime(2025, 6, 15)),
    'location': 'Зал',
    'coachId': coachId,
    'beltLevels': <String>[],
    'participantIds': participantIds,
    'year': 2025,
  });
  return ref.id;
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── addEvent ─────────────────────────────────────────────────────────────

  group('EventsNotifier — addEvent', () {
    test('зберігає подію у Firestore', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(eventsNotifierProvider.notifier).addEvent(_event());

      final snap = await db.collection('events').get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first['title'], 'Змагання U12');
      expect(snap.docs.first['coachId'], 'coach1');
      expect(snap.docs.first['type'], 'competition');
    });

    test('рік береться з date.year — не з поля year', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(eventsNotifierProvider.notifier)
          .addEvent(_event(date: DateTime(2027, 3, 10)));

      final doc = (await db.collection('events').get()).docs.first;
      expect(doc['year'], 2027);
    });

    test('кожна подія отримує унікальний ID', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(eventsNotifierProvider.notifier);
      await n.addEvent(_event());
      await n.addEvent(_event(title: 'Турнір U14'));

      final snap = await db.collection('events').get();
      expect(snap.docs, hasLength(2));
      expect(snap.docs[0].id, isNot(snap.docs[1].id));
    });

    test('зберігає beltLevels і participantIds', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(eventsNotifierProvider.notifier).addEvent(
            _event(beltLevels: ['white', 'yellow'], participantIds: ['kid1']),
          );

      final doc = (await db.collection('events').get()).docs.first;
      expect(List<String>.from(doc['beltLevels'] as List),
          containsAll(['white', 'yellow']));
      expect(
          List<String>.from(doc['participantIds'] as List), contains('kid1'));
    });

    test('стан = AsyncData після успішного addEvent', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(eventsNotifierProvider.notifier).addEvent(_event());
      expect(c.read(eventsNotifierProvider), isA<AsyncData<void>>());
    });

    test('різні типи подій зберігаються правильно', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(eventsNotifierProvider.notifier);
      await n.addEvent(_event(type: EventType.tournament, title: 'Турнір'));
      await n.addEvent(_event(type: EventType.camp, title: 'Збір'));
      await n.addEvent(_event(type: EventType.other, title: 'Інше'));

      final docs = (await db.collection('events').get()).docs;
      final types = docs.map((d) => d['type'] as String).toSet();
      expect(types, containsAll(['tournament', 'camp', 'other']));
    });
  });

  // ── updateEvent ───────────────────────────────────────────────────────────

  group('EventsNotifier — updateEvent', () {
    test('оновлює назву і тип', () async {
      final db = _db();
      final id = await _seedEvent(db, title: 'Стара назва');
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(eventsNotifierProvider.notifier).updateEvent(
            _event(id: id, title: 'Нова назва', type: EventType.tournament),
          );

      final doc = await db.collection('events').doc(id).get();
      expect(doc['title'], 'Нова назва');
      expect(doc['type'], 'tournament');
    });

    test('оновлює beltLevels', () async {
      final db = _db();
      final id = await _seedEvent(db);
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(eventsNotifierProvider.notifier).updateEvent(
            _event(id: id, beltLevels: ['green', 'blue']),
          );

      final doc = await db.collection('events').doc(id).get();
      expect(List<String>.from(doc['beltLevels'] as List),
          containsAll(['green', 'blue']));
    });

    test('updateEvent не торкається інших документів', () async {
      final db = _db();
      final id1 = await _seedEvent(db, title: 'Подія 1');
      final id2 = await _seedEvent(db, title: 'Подія 2');
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(eventsNotifierProvider.notifier).updateEvent(
            _event(id: id1, title: 'Оновлена 1'),
          );

      final doc2 = await db.collection('events').doc(id2).get();
      expect(doc2['title'], 'Подія 2');
    });

    test('стан = AsyncData після успішного updateEvent', () async {
      final db = _db();
      final id = await _seedEvent(db);
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(eventsNotifierProvider.notifier).updateEvent(
            _event(id: id, title: 'Оновлено'),
          );
      expect(c.read(eventsNotifierProvider), isA<AsyncData<void>>());
    });
  });

  // ── deleteEvent ───────────────────────────────────────────────────────────

  group('EventsNotifier — deleteEvent', () {
    test('видаляє документ з Firestore', () async {
      final db = _db();
      final id = await _seedEvent(db);
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(eventsNotifierProvider.notifier).deleteEvent(id);

      final doc = await db.collection('events').doc(id).get();
      expect(doc.exists, isFalse);
    });

    test('видаляє тільки потрібну подію — інші залишаються', () async {
      final db = _db();
      final id1 = await _seedEvent(db, title: 'Для видалення');
      final id2 = await _seedEvent(db, title: 'Залишити');
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(eventsNotifierProvider.notifier).deleteEvent(id1);

      final snap = await db.collection('events').get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first.id, id2);
    });

    test('стан = AsyncData після deleteEvent', () async {
      final db = _db();
      final id = await _seedEvent(db);
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(eventsNotifierProvider.notifier).deleteEvent(id);
      expect(c.read(eventsNotifierProvider), isA<AsyncData<void>>());
    });
  });

  // ── toggleParticipant ─────────────────────────────────────────────────────

  group('EventsNotifier — toggleParticipant', () {
    test('додає спортсмена якщо його ще немає', () async {
      final db = _db();
      final id = await _seedEvent(db);
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(eventsNotifierProvider.notifier)
          .toggleParticipant(id, 'kid1');

      final doc = await db.collection('events').doc(id).get();
      expect(
          List<String>.from(doc['participantIds'] as List), contains('kid1'));
    });

    test('видаляє спортсмена якщо вже є в participantIds', () async {
      final db = _db();
      final id = await _seedEvent(db, participantIds: ['kid1', 'kid2']);
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(eventsNotifierProvider.notifier)
          .toggleParticipant(id, 'kid1');

      final participants = List<String>.from(
          (await db.collection('events').doc(id).get())['participantIds']
              as List);
      expect(participants, isNot(contains('kid1')));
      expect(participants, contains('kid2'));
    });

    test('додає трьох різних учасників послідовно', () async {
      final db = _db();
      final id = await _seedEvent(db);
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(eventsNotifierProvider.notifier);
      await n.toggleParticipant(id, 'kid1');
      await n.toggleParticipant(id, 'kid2');
      await n.toggleParticipant(id, 'kid3');

      final participants = List<String>.from(
          (await db.collection('events').doc(id).get())['participantIds']
              as List);
      expect(participants, hasLength(3));
      expect(participants, containsAll(['kid1', 'kid2', 'kid3']));
    });

    test('toggle двічі — повертається до початкового стану', () async {
      final db = _db();
      final id = await _seedEvent(db);
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(eventsNotifierProvider.notifier);
      await n.toggleParticipant(id, 'kid1'); // add
      await n.toggleParticipant(id, 'kid1'); // remove

      final participants = List<String>.from(
          (await db.collection('events').doc(id).get())['participantIds']
              as List);
      expect(participants, isEmpty);
    });
  });

  // ── Повний сценарій тренера ───────────────────────────────────────────────

  group('Events — повний сценарій тренера', () {
    test(
        'тренер: створює → оновлює → реєструє 3 учасники → '
        'знімає одного → видаляє', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);
      final n = c.read(eventsNotifierProvider.notifier);

      // 1. Створити подію
      await n.addEvent(_event());
      final id = (await db.collection('events').get()).docs.first.id;

      // 2. Оновити назву
      await n.updateEvent(_event(id: id, title: 'Оновлені змагання'));
      expect(
          (await db.collection('events').doc(id).get())['title'],
          'Оновлені змагання');

      // 3. Зареєструвати 3 учасників
      await n.toggleParticipant(id, 'kid1');
      await n.toggleParticipant(id, 'kid2');
      await n.toggleParticipant(id, 'kid3');
      var participants = List<String>.from(
          (await db.collection('events').doc(id).get())['participantIds']
              as List);
      expect(participants, hasLength(3));

      // 4. Зняти kid2
      await n.toggleParticipant(id, 'kid2');
      participants = List<String>.from(
          (await db.collection('events').doc(id).get())['participantIds']
              as List);
      expect(participants, hasLength(2));
      expect(participants, isNot(contains('kid2')));

      // 5. Видалити подію
      await n.deleteEvent(id);
      expect(
          (await db.collection('events').doc(id).get()).exists, isFalse);
    });

    test('два тренери — події не перетинаються', () async {
      final db = _db();
      final c1 = _container(db);
      final c2 = _container(db);
      addTearDown(c1.dispose);
      addTearDown(c2.dispose);

      await c1
          .read(eventsNotifierProvider.notifier)
          .addEvent(_event(coachId: 'coach1', title: 'Подія тренера 1'));
      await c2
          .read(eventsNotifierProvider.notifier)
          .addEvent(_event(coachId: 'coach2', title: 'Подія тренера 2'));

      final all = await db.collection('events').get();
      expect(all.docs, hasLength(2));

      final coaches = all.docs.map((d) => d['coachId'] as String).toList();
      expect(coaches, containsAll(['coach1', 'coach2']));
    });
  });
}

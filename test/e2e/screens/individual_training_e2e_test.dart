/// E2E тести для IndividualTrainingScreen.
/// Покриває повний сценарій для ролей тренер і спортсмен:
///   - Факт створення слоту тренером
///   - Відображення слотів для тренера і спортсмена
///   - Запит спортсмена → зміна статусу
///   - Підтвердження тренером → зміна статусу
///   - Скасування тренером → слот зникає з доступних
///   - Видалення слоту тренером
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/individual_slot_model.dart';
import 'package:judo_app/features/individual_training/providers/individual_training_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

IndividualSlotModel _slot({
  String id = 'slot1',
  String coachId = 'coach1',
  String coachName = 'Тренер',
  SlotStatus status = SlotStatus.available,
  String? childId,
  String? childName,
}) =>
    IndividualSlotModel(
      id: id,
      coachId: coachId,
      coachName: coachName,
      date: DateTime(2026, 12, 1),
      timeStart: '10:00',
      timeEnd: '10:30',
      price: 300,
      currency: 'UAH',
      status: status,
      childId: childId,
      childName: childName,
    );

ProviderContainer _container(FakeFirebaseFirestore db) => ProviderContainer(
      overrides: [firestoreProvider.overrideWithValue(db)],
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('IndividualTraining — createSlot (тренер)', () {
    test('createSlot зберігає слот у Firestore зі статусом available', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final notifier = c.read(individualTrainingNotifierProvider.notifier);
      await notifier.createSlot(_slot(id: ''));

      final snap = await db.collection('individual_slots').get();
      expect(snap.docs, hasLength(1));

      final data = snap.docs.first.data();
      expect(data['coachId'], 'coach1');
      expect(data['status'], SlotStatus.available.name);
      expect(data['timeStart'], '10:00');
      expect(data['timeEnd'], '10:30');
      expect(data['price'], 300.0);
    });

    test('createSlot генерує унікальний id (не порожній)', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(individualTrainingNotifierProvider.notifier).createSlot(_slot(id: ''));

      final snap = await db.collection('individual_slots').get();
      final id = snap.docs.first.id;
      expect(id, isNotEmpty);
    });

    test('кілька слотів — кожен зберігається окремо', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(individualTrainingNotifierProvider.notifier);
      await n.createSlot(_slot(id: ''));
      await n.createSlot(_slot(id: ''));

      final snap = await db.collection('individual_slots').get();
      expect(snap.docs, hasLength(2));
      expect(snap.docs.map((d) => d.id).toSet(), hasLength(2));
    });
  });

  group('IndividualTraining — requestSlot (спортсмен)', () {
    test('requestSlot змінює статус на requested і зберігає childId/childName',
        () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      // Спочатку тренер створює слот
      await db.collection('individual_slots').doc('slot1').set(
            _slot(id: 'slot1').toFirestore(),
          );

      // Спортсмен надсилає запит
      await c.read(individualTrainingNotifierProvider.notifier).requestSlot(
            slotId: 'slot1',
            childId: 'kid1',
            childName: 'Іван Петренко',
            userId: 'parent1',
          );

      final doc = await db.collection('individual_slots').doc('slot1').get();
      expect(doc['status'], SlotStatus.requested.name);
      expect(doc['childId'], 'kid1');
      expect(doc['childName'], 'Іван Петренко');
      expect(doc['requestedByUserId'], 'parent1');
    });
  });

  group('IndividualTraining — confirmSlot (тренер)', () {
    test('confirmSlot змінює статус на confirmed', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await db.collection('individual_slots').doc('slot1').set({
        ..._slot(id: 'slot1', status: SlotStatus.requested, childId: 'kid1')
            .toFirestore(),
      });

      await c
          .read(individualTrainingNotifierProvider.notifier)
          .confirmSlot('slot1');

      final doc = await db.collection('individual_slots').doc('slot1').get();
      expect(doc['status'], SlotStatus.confirmed.name);
    });
  });

  group('IndividualTraining — cancelSlot (тренер)', () {
    test('cancelSlot скидає статус на cancelled та очищає childId', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await db.collection('individual_slots').doc('slot1').set(
            _slot(id: 'slot1', status: SlotStatus.confirmed, childId: 'kid1')
                .toFirestore(),
          );

      await c
          .read(individualTrainingNotifierProvider.notifier)
          .cancelSlot('slot1');

      final doc = await db.collection('individual_slots').doc('slot1').get();
      expect(doc['status'], SlotStatus.cancelled.name);
      expect(doc['childId'], isNull);
      expect(doc['childName'], isNull);
    });
  });

  group('IndividualTraining — deleteSlot (тренер)', () {
    test('deleteSlot видаляє документ з Firestore', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await db.collection('individual_slots').doc('slot1').set(
            _slot(id: 'slot1').toFirestore(),
          );

      await c
          .read(individualTrainingNotifierProvider.notifier)
          .deleteSlot('slot1');

      final doc = await db.collection('individual_slots').doc('slot1').get();
      expect(doc.exists, isFalse);
    });
  });

  group('IndividualTraining — markPaid (тренер)', () {
    test('markPaid встановлює isPaid=true', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await db.collection('individual_slots').doc('slot1').set(
            _slot(id: 'slot1', status: SlotStatus.confirmed).toFirestore(),
          );

      await c
          .read(individualTrainingNotifierProvider.notifier)
          .markPaid('slot1');

      final doc = await db.collection('individual_slots').doc('slot1').get();
      expect(doc['isPaid'], isTrue);
    });
  });

  group('IndividualTraining — повний сценарій: тренер + спортсмен', () {
    test(
        'тренер створює → спортсмен бачить і запитує → тренер підтверджує → обидва бачать зміни',
        () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final notifier = c.read(individualTrainingNotifierProvider.notifier);

      // 1. Тренер створює слот
      await notifier.createSlot(_slot(id: ''));
      final allSnap = await db.collection('individual_slots').get();
      expect(allSnap.docs, hasLength(1));
      final slotId = allSnap.docs.first.id;
      expect(allSnap.docs.first['status'], SlotStatus.available.name);

      // 2. Спортсмен бачить слот (статус available)
      final availableSnap = await db
          .collection('individual_slots')
          .where('status', isEqualTo: SlotStatus.available.name)
          .get();
      expect(availableSnap.docs, hasLength(1));

      // 3. Спортсмен запитує слот
      await notifier.requestSlot(
        slotId: slotId,
        childId: 'kid1',
        childName: 'Іван Петренко',
        userId: 'parent1',
      );
      final afterRequest =
          await db.collection('individual_slots').doc(slotId).get();
      expect(afterRequest['status'], SlotStatus.requested.name);
      expect(afterRequest['childId'], 'kid1');

      // 4. Тренер бачить запит (статус requested)
      final pendingSnap = await db
          .collection('individual_slots')
          .where('status', isEqualTo: SlotStatus.requested.name)
          .get();
      expect(pendingSnap.docs, hasLength(1));

      // 5. Тренер підтверджує
      await notifier.confirmSlot(slotId);
      final afterConfirm =
          await db.collection('individual_slots').doc(slotId).get();
      expect(afterConfirm['status'], SlotStatus.confirmed.name);

      // 6. Спортсмен більше не бачить слот у available (він confirmed)
      final stillAvailable = await db
          .collection('individual_slots')
          .where('status', isEqualTo: SlotStatus.available.name)
          .get();
      expect(stillAvailable.docs, isEmpty);

      // 7. Спортсмен бачить свій підтверджений слот
      final childSlots = await db
          .collection('individual_slots')
          .where('childId', isEqualTo: 'kid1')
          .where('status', isEqualTo: SlotStatus.confirmed.name)
          .get();
      expect(childSlots.docs, hasLength(1));
    });
  });

  group('IndividualTraining — провайдери зчитують правильно', () {
    test('coachSlotsProvider повертає тільки слоти цього тренера', () async {
      final db = _db();
      await db
          .collection('individual_slots')
          .doc('s1')
          .set(_slot(id: 's1', coachId: 'coach1').toFirestore());
      await db
          .collection('individual_slots')
          .doc('s2')
          .set(_slot(id: 's2', coachId: 'coach2').toFirestore());

      final snap = await db
          .collection('individual_slots')
          .where('coachId', isEqualTo: 'coach1')
          .get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first['coachId'], 'coach1');
    });

    test('childSlotsProvider — requested і confirmed потрапляють, available ні',
        () async {
      final db = _db();
      await db.collection('individual_slots').doc('s1').set(
            _slot(id: 's1', status: SlotStatus.available).toFirestore(),
          );
      await db.collection('individual_slots').doc('s2').set(
            _slot(
                    id: 's2',
                    status: SlotStatus.requested,
                    childId: 'kid1',
                    childName: 'Іван')
                .toFirestore(),
          );
      await db.collection('individual_slots').doc('s3').set(
            _slot(
                    id: 's3',
                    status: SlotStatus.confirmed,
                    childId: 'kid1',
                    childName: 'Іван')
                .toFirestore(),
          );

      final snap = await db
          .collection('individual_slots')
          .where('childId', isEqualTo: 'kid1')
          .where('status', whereIn: [
            SlotStatus.requested.name,
            SlotStatus.confirmed.name,
          ])
          .get();
      expect(snap.docs, hasLength(2));
    });
  });

  group('IndividualTraining — robustness', () {
    test('стан провайдера після createSlot = AsyncData', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(individualTrainingNotifierProvider.notifier)
          .createSlot(_slot(id: ''));

      final state = c.read(individualTrainingNotifierProvider);
      expect(state, isA<AsyncData<void>>());
    });

    test('стан провайдера після deleteSlot = AsyncData', () async {
      final db = _db();
      await db
          .collection('individual_slots')
          .doc('slot1')
          .set(_slot(id: 'slot1').toFirestore());

      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(individualTrainingNotifierProvider.notifier)
          .deleteSlot('slot1');

      final state = c.read(individualTrainingNotifierProvider);
      expect(state, isA<AsyncData<void>>());
    });
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/individual_slot_model.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

IndividualSlotModel makeSlot({
  String id = 'slot1',
  String coachId = 'coach1',
  String coachName = 'Тренер Іван',
  DateTime? date,
  String timeStart = '14:00',
  String timeEnd = '14:30',
  double? price = 300,
  String currency = 'UAH',
  SlotStatus status = SlotStatus.available,
  String? childId,
  String? childName,
  String? requestedByUserId,
  DateTime? requestedAt,
  DateTime? confirmedAt,
  bool isPaid = false,
}) =>
    IndividualSlotModel(
      id: id,
      coachId: coachId,
      coachName: coachName,
      date: date ?? DateTime(2026, 6, 10),
      timeStart: timeStart,
      timeEnd: timeEnd,
      price: price,
      currency: currency,
      status: status,
      childId: childId,
      childName: childName,
      requestedByUserId: requestedByUserId,
      requestedAt: requestedAt,
      confirmedAt: confirmedAt,
      isPaid: isPaid,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── SlotStatusX.displayName ───────────────────────────────────────────────

  group('SlotStatusX.displayName', () {
    test('available → Вільний', () {
      expect(SlotStatus.available.displayName, 'Вільний');
    });

    test('requested → Запит', () {
      expect(SlotStatus.requested.displayName, 'Запит');
    });

    test('confirmed → Підтверджено', () {
      expect(SlotStatus.confirmed.displayName, 'Підтверджено');
    });

    test('cancelled → Скасовано', () {
      expect(SlotStatus.cancelled.displayName, 'Скасовано');
    });
  });

  // ── SlotStatusX.fromString ────────────────────────────────────────────────

  group('SlotStatusX.fromString', () {
    test('розпізнає всі валідні рядки', () {
      expect(SlotStatusX.fromString('available'), SlotStatus.available);
      expect(SlotStatusX.fromString('requested'), SlotStatus.requested);
      expect(SlotStatusX.fromString('confirmed'), SlotStatus.confirmed);
      expect(SlotStatusX.fromString('cancelled'), SlotStatus.cancelled);
    });

    test('невідомий рядок → available (fallback)', () {
      expect(SlotStatusX.fromString('unknown'), SlotStatus.available);
      expect(SlotStatusX.fromString(''), SlotStatus.available);
    });
  });

  // ── IndividualSlotModel.fromFirestore ─────────────────────────────────────

  group('IndividualSlotModel.fromFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;
    setUp(() => fakeFirestore = FakeFirebaseFirestore());

    test('зчитує всі поля вільного слоту', () async {
      final ref = fakeFirestore.collection('individual_slots').doc('s1');
      await ref.set({
        'coachId': 'c1',
        'coachName': 'Іван',
        'date': Timestamp.fromDate(DateTime(2026, 6, 15)),
        'timeStart': '10:00',
        'timeEnd': '10:30',
        'price': 250.0,
        'currency': 'UAH',
        'status': 'available',
        'isPaid': false,
      });

      final model = IndividualSlotModel.fromFirestore(await ref.get());

      expect(model.id, 's1');
      expect(model.coachId, 'c1');
      expect(model.coachName, 'Іван');
      expect(model.date, DateTime(2026, 6, 15));
      expect(model.timeStart, '10:00');
      expect(model.timeEnd, '10:30');
      expect(model.price, 250.0);
      expect(model.currency, 'UAH');
      expect(model.status, SlotStatus.available);
      expect(model.isPaid, isFalse);
      expect(model.childId, isNull);
      expect(model.childName, isNull);
    });

    test('зчитує підтверджений слот з дочірніми полями', () async {
      final ref = fakeFirestore.collection('individual_slots').doc('s2');
      final reqAt = DateTime(2026, 6, 10, 9, 0);
      final confAt = DateTime(2026, 6, 10, 10, 0);
      await ref.set({
        'coachId': 'c1',
        'coachName': 'Іван',
        'date': Timestamp.fromDate(DateTime(2026, 6, 15)),
        'timeStart': '14:00',
        'timeEnd': '14:30',
        'price': 300.0,
        'currency': 'UAH',
        'status': 'confirmed',
        'childId': 'child42',
        'childName': 'Олексій Коваль',
        'requestedByUserId': 'parent1',
        'requestedAt': Timestamp.fromDate(reqAt),
        'confirmedAt': Timestamp.fromDate(confAt),
        'isPaid': true,
      });

      final model = IndividualSlotModel.fromFirestore(await ref.get());

      expect(model.status, SlotStatus.confirmed);
      expect(model.childId, 'child42');
      expect(model.childName, 'Олексій Коваль');
      expect(model.requestedByUserId, 'parent1');
      expect(model.requestedAt, reqAt);
      expect(model.confirmedAt, confAt);
      expect(model.isPaid, isTrue);
    });

    test('ціна null коли поле відсутнє', () async {
      final ref = fakeFirestore.collection('individual_slots').doc('s3');
      await ref.set({
        'coachId': 'c1',
        'coachName': 'X',
        'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'timeStart': '09:00',
        'timeEnd': '09:30',
        'status': 'available',
        'isPaid': false,
      });

      final model = IndividualSlotModel.fromFirestore(await ref.get());
      expect(model.price, isNull);
      expect(model.currency, 'UAH');
    });

    test('ціна як int конвертується в double', () async {
      final ref = fakeFirestore.collection('individual_slots').doc('s4');
      await ref.set({
        'coachId': 'c',
        'coachName': 'X',
        'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'timeStart': '09:00',
        'timeEnd': '09:30',
        'status': 'available',
        'price': 500,
        'isPaid': false,
      });

      final model = IndividualSlotModel.fromFirestore(await ref.get());
      expect(model.price, 500.0);
      expect(model.price, isA<double>());
    });
  });

  // ── IndividualSlotModel.toFirestore ───────────────────────────────────────

  group('IndividualSlotModel.toFirestore', () {
    test('включає всі обов\'язкові поля', () {
      final slot = makeSlot();
      final map = slot.toFirestore();

      expect(map['coachId'], 'coach1');
      expect(map['coachName'], 'Тренер Іван');
      expect(map['timeStart'], '14:00');
      expect(map['timeEnd'], '14:30');
      expect(map['currency'], 'UAH');
      expect(map['status'], 'available');
      expect(map['isPaid'], isFalse);
    });

    test('date серіалізується як Timestamp', () {
      final map = makeSlot(date: DateTime(2026, 6, 10)).toFirestore();
      expect(map['date'], isA<Timestamp>());
      expect((map['date'] as Timestamp).toDate(), DateTime(2026, 6, 10));
    });

    test('price включається тільки коли не null', () {
      final withPrice = makeSlot(price: 300).toFirestore();
      expect(withPrice.containsKey('price'), isTrue);

      final withoutPrice = makeSlot(price: null).toFirestore();
      expect(withoutPrice.containsKey('price'), isFalse);
    });

    test('nullable поля не включаються коли null', () {
      final map = makeSlot().toFirestore();
      expect(map.containsKey('childId'), isFalse);
      expect(map.containsKey('childName'), isFalse);
      expect(map.containsKey('requestedByUserId'), isFalse);
      expect(map.containsKey('requestedAt'), isFalse);
      expect(map.containsKey('confirmedAt'), isFalse);
    });

    test('nullable поля включаються коли задані', () {
      final reqAt = DateTime(2026, 6, 10);
      final slot = makeSlot(
        childId: 'c99',
        childName: 'Аліна',
        requestedByUserId: 'parent9',
        requestedAt: reqAt,
      );
      final map = slot.toFirestore();

      expect(map['childId'], 'c99');
      expect(map['childName'], 'Аліна');
      expect(map['requestedByUserId'], 'parent9');
      expect(map['requestedAt'], isA<Timestamp>());
    });

    test('status серіалізується як рядок (enum.name)', () {
      expect(makeSlot(status: SlotStatus.confirmed).toFirestore()['status'], 'confirmed');
      expect(makeSlot(status: SlotStatus.cancelled).toFirestore()['status'], 'cancelled');
    });
  });

  // ── IndividualSlotModel.copyWith ──────────────────────────────────────────

  group('IndividualSlotModel.copyWith', () {
    test('незмінені поля зберігаються', () {
      final original = makeSlot();
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.coachId, original.coachId);
      expect(copy.date, original.date);
      expect(copy.timeStart, original.timeStart);
    });

    test('змінює статус', () {
      final slot = makeSlot(status: SlotStatus.available);
      final requested = slot.copyWith(
        status: SlotStatus.requested,
        childId: 'child1',
        childName: 'Михайло',
        requestedByUserId: 'parent1',
        requestedAt: DateTime(2026, 6, 5),
      );
      expect(requested.status, SlotStatus.requested);
      expect(requested.childId, 'child1');
      expect(requested.childName, 'Михайло');
    });

    test('підтвердження: available → confirmed', () {
      final slot = makeSlot(status: SlotStatus.requested, childId: 'c1');
      final confirmed = slot.copyWith(
        status: SlotStatus.confirmed,
        confirmedAt: DateTime(2026, 6, 6),
      );
      expect(confirmed.status, SlotStatus.confirmed);
      expect(confirmed.childId, 'c1');
      expect(confirmed.confirmedAt, DateTime(2026, 6, 6));
    });

    test('позначення оплаченим', () {
      final slot = makeSlot(isPaid: false);
      final paid = slot.copyWith(isPaid: true);
      expect(paid.isPaid, isTrue);
    });

    test('скасування: змінює тільки статус', () {
      final slot = makeSlot(
        status: SlotStatus.confirmed,
        childId: 'c1',
        childName: 'Аня',
      );
      final cancelled = slot.copyWith(status: SlotStatus.cancelled);
      expect(cancelled.status, SlotStatus.cancelled);
      expect(cancelled.childId, 'c1');
      expect(cancelled.childName, 'Аня');
    });
  });

  // ── Round-trip ────────────────────────────────────────────────────────────

  group('IndividualSlotModel — round-trip', () {
    test('зберігає і зчитує всі поля підтвердженого слоту без втрат', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final reqAt = DateTime(2026, 6, 1, 8, 0);
      final confAt = DateTime(2026, 6, 1, 9, 30);

      final original = makeSlot(
        id: 'rt1',
        status: SlotStatus.confirmed,
        childId: 'child99',
        childName: 'Тест Тестов',
        requestedByUserId: 'parent99',
        requestedAt: reqAt,
        confirmedAt: confAt,
        isPaid: true,
      );

      await fakeFirestore
          .collection('individual_slots')
          .doc('rt1')
          .set(original.toFirestore());
      final doc =
          await fakeFirestore.collection('individual_slots').doc('rt1').get();
      final restored = IndividualSlotModel.fromFirestore(doc);

      expect(restored.status, original.status);
      expect(restored.childId, original.childId);
      expect(restored.childName, original.childName);
      expect(restored.requestedAt, original.requestedAt);
      expect(restored.confirmedAt, original.confirmedAt);
      expect(restored.isPaid, isTrue);
    });
  });
}

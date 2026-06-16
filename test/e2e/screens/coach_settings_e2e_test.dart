/// E2E тести для CoachSettingsNotifier — фінансові налаштування тренера.
/// Покриває: updateIndividualPrice, addCard, removeCard, reorderCards.
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/payment_card_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/settings/providers/coach_settings_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

const _kCoachUid = 'coach_001';

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

ProviderContainer _container(FakeFirebaseFirestore db) => ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(db),
        // Підставляємо uid тренера через firebaseAuthProvider — провайдер бере
        // currentUser?.uid із нього.  FakeFirebaseAuth не потрібен, бо нотифаєр
        // просто зчитує uid при створенні.  Перевизначаємо сам нотифаєр:
        coachSettingsNotifierProvider.overrideWith(
          (ref) => CoachSettingsNotifier(db, _kCoachUid),
        ),
      ],
    );

/// Читає document тренера з Firestore і повертає його data map.
Future<Map<String, dynamic>> _coachData(FakeFirebaseFirestore db) async {
  final snap = await db.collection('users').doc(_kCoachUid).get();
  return snap.data() as Map<String, dynamic>? ?? {};
}

PaymentCard _card({
  String id = 'card_1',
  String label = 'Monobank',
  String number = '5375 4141 1234 5678',
  String holder = 'Іван Тренер',
}) =>
    PaymentCard(id: id, label: label, number: number, holder: holder);

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── updateIndividualPrice ────────────────────────────────────────────────────

  group('CoachSettingsNotifier — updateIndividualPrice', () {
    test('зберігає ціну у Firestore', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(coachSettingsNotifierProvider.notifier)
          .updateIndividualPrice(500);

      final data = await _coachData(db);
      expect(data['individualPrice'], 500.0);
    });

    test('перезаписує попередню ціну', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(coachSettingsNotifierProvider.notifier)
          .updateIndividualPrice(300);
      await c
          .read(coachSettingsNotifierProvider.notifier)
          .updateIndividualPrice(450);

      final data = await _coachData(db);
      expect(data['individualPrice'], 450.0);
    });

    test('стан переходить data(null) після успіху', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(coachSettingsNotifierProvider.notifier)
          .updateIndividualPrice(200);

      expect(c.read(coachSettingsNotifierProvider).hasValue, isTrue);
    });
  });

  // ── addCard ──────────────────────────────────────────────────────────────────

  group('CoachSettingsNotifier — addCard', () {
    test('додає картку у Firestore', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(coachSettingsNotifierProvider.notifier)
          .addCard(_card());

      final data = await _coachData(db);
      final cards = data['paymentCards'] as List<dynamic>;
      expect(cards, hasLength(1));
      expect(cards.first['label'], 'Monobank');
      expect(cards.first['number'], '5375 4141 1234 5678');
      expect(cards.first['holder'], 'Іван Тренер');
    });

    test('додає кілька карток — всі зберігаються', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(coachSettingsNotifierProvider.notifier)
          .addCard(_card(id: 'c1', label: 'Monobank'));
      await c
          .read(coachSettingsNotifierProvider.notifier)
          .addCard(_card(id: 'c2', label: 'ПриватБанк'));

      final data = await _coachData(db);
      final cards = data['paymentCards'] as List<dynamic>;
      expect(cards, hasLength(2));
      expect(cards.map((m) => m['label']).toList(),
          containsAll(['Monobank', 'ПриватБанк']));
    });

    test('картка зберігає id', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final card = _card(id: 'fixed_id');
      await c.read(coachSettingsNotifierProvider.notifier).addCard(card);

      final data = await _coachData(db);
      final saved = (data['paymentCards'] as List<dynamic>).first;
      expect(saved['id'], 'fixed_id');
    });
  });

  // ── removeCard ───────────────────────────────────────────────────────────────

  group('CoachSettingsNotifier — removeCard', () {
    test('видаляє картку за id', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(coachSettingsNotifierProvider.notifier)
          .addCard(_card(id: 'c1', label: 'Monobank'));
      await c
          .read(coachSettingsNotifierProvider.notifier)
          .addCard(_card(id: 'c2', label: 'ПриватБанк'));

      await c
          .read(coachSettingsNotifierProvider.notifier)
          .removeCard('c1');

      final data = await _coachData(db);
      final cards = data['paymentCards'] as List<dynamic>;
      expect(cards, hasLength(1));
      expect(cards.first['label'], 'ПриватБанк');
    });

    test('видалення неіснуючого id не змінює список', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(coachSettingsNotifierProvider.notifier)
          .addCard(_card(id: 'c1', label: 'Monobank'));

      await c
          .read(coachSettingsNotifierProvider.notifier)
          .removeCard('nonexistent');

      final data = await _coachData(db);
      final cards = data['paymentCards'] as List<dynamic>;
      expect(cards, hasLength(1));
    });

    test('видалення єдиної картки залишає порожній список', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(coachSettingsNotifierProvider.notifier)
          .addCard(_card(id: 'only'));
      await c
          .read(coachSettingsNotifierProvider.notifier)
          .removeCard('only');

      final data = await _coachData(db);
      final cards = data['paymentCards'] as List<dynamic>;
      expect(cards, isEmpty);
    });
  });

  // ── reorderCards ─────────────────────────────────────────────────────────────

  group('CoachSettingsNotifier — reorderCards', () {
    test('зберігає новий порядок карток', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final c1 = _card(id: 'c1', label: 'Перша');
      final c2 = _card(id: 'c2', label: 'Друга');
      final c3 = _card(id: 'c3', label: 'Третя');

      await c.read(coachSettingsNotifierProvider.notifier).addCard(c1);
      await c.read(coachSettingsNotifierProvider.notifier).addCard(c2);
      await c.read(coachSettingsNotifierProvider.notifier).addCard(c3);

      // Новий порядок: третя → перша → друга
      await c
          .read(coachSettingsNotifierProvider.notifier)
          .reorderCards([c3, c1, c2]);

      final data = await _coachData(db);
      final cards = data['paymentCards'] as List<dynamic>;
      expect(cards[0]['id'], 'c3');
      expect(cards[1]['id'], 'c1');
      expect(cards[2]['id'], 'c2');
    });

    test('перша картка після reorder стає дефолтною (id[0])', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final c1 = _card(id: 'mono', label: 'Monobank');
      final c2 = _card(id: 'privat', label: 'ПриватБанк');

      await c.read(coachSettingsNotifierProvider.notifier).addCard(c1);
      await c.read(coachSettingsNotifierProvider.notifier).addCard(c2);

      // Ставимо ПриватБанк першим — він стає дефолтним
      await c
          .read(coachSettingsNotifierProvider.notifier)
          .reorderCards([c2, c1]);

      final data = await _coachData(db);
      final cards = data['paymentCards'] as List<dynamic>;
      expect(cards.first['id'], 'privat');
    });
  });

  // ── Комплексний сценарій ─────────────────────────────────────────────────────

  group('CoachSettingsNotifier — full scenario', () {
    test('додати 3 картки, видалити середню, переставити, оновити ціну', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final c1 = _card(id: 'c1', label: 'Monobank');
      final c2 = _card(id: 'c2', label: 'ПриватБанк');
      final c3 = _card(id: 'c3', label: 'IBAN ФОП');

      await c.read(coachSettingsNotifierProvider.notifier).addCard(c1);
      await c.read(coachSettingsNotifierProvider.notifier).addCard(c2);
      await c.read(coachSettingsNotifierProvider.notifier).addCard(c3);
      await c.read(coachSettingsNotifierProvider.notifier).removeCard('c2');
      await c
          .read(coachSettingsNotifierProvider.notifier)
          .reorderCards([c3, c1]);
      await c
          .read(coachSettingsNotifierProvider.notifier)
          .updateIndividualPrice(650);

      final data = await _coachData(db);

      final cards = data['paymentCards'] as List<dynamic>;
      expect(cards, hasLength(2));
      expect(cards[0]['id'], 'c3');
      expect(cards[1]['id'], 'c1');
      expect(data['individualPrice'], 650.0);
    });
  });
}

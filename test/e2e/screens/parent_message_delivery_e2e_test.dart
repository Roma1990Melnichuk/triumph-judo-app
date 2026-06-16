/// TC-MSG — Повідомлення від батьків доходить до тренера.
///
/// Ключові правила:
///   1. Після send() повідомлення зберігається в Firestore з readByCoach=false
///   2. markRead() встановлює readByCoach=true
///   3. Кілька повідомлень від одного батька — всі доходять
///   4. Повідомлення до різних тренерів ізольовані (toCoachId)
///   5. Текст повідомлення зберігається точно
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/message_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/notifications/providers/message_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

ProviderContainer _container(FakeFirebaseFirestore db) => ProviderContainer(
      overrides: [firestoreProvider.overrideWithValue(db)],
    );

Future<List<Map<String, dynamic>>> _allMessages(
    FakeFirebaseFirestore db) async {
  final snap = await db.collection('messages').get();
  return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
}

Future<Map<String, dynamic>?> _getMessage(
    FakeFirebaseFirestore db, String id) async {
  final snap = await db.collection('messages').doc(id).get();
  return snap.exists ? snap.data() : null;
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── TC-MSG-001 ───────────────────────────────────────────────────────────────

  group('TC-MSG-001: повідомлення зберігається з readByCoach=false', () {
    test('після send() повідомлення в Firestore, readByCoach=false', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(messageNotifierProvider.notifier).send(
            fromParentId: 'parent1',
            fromParentName: 'Марія Коваль',
            toCoachId: 'coach1',
            body: 'Дитина не прийде в п\'ятницю',
          );

      final messages = await _allMessages(db);
      expect(messages, hasLength(1));

      final msg = messages.first;
      expect(msg['fromParentId'], equals('parent1'));
      expect(msg['fromParentName'], equals('Марія Коваль'));
      expect(msg['toCoachId'], equals('coach1'));
      expect(msg['body'], equals('Дитина не прийде в п\'ятницю'));
      expect(msg['readByCoach'], isFalse);
    });

    test('текст повідомлення зберігається точно (без змін)', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      const text = 'Будь ласка, поставте Олега на змагання у вересні!';
      await c.read(messageNotifierProvider.notifier).send(
            fromParentId: 'parent1',
            fromParentName: 'Іван Петренко',
            toCoachId: 'coach1',
            body: text,
          );

      final messages = await _allMessages(db);
      expect(messages.first['body'], equals(text));
    });

    test('повідомлення отримує непорожній id', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(messageNotifierProvider.notifier).send(
            fromParentId: 'parent1',
            fromParentName: 'Тест',
            toCoachId: 'coach1',
            body: 'Привіт',
          );

      final snap = await db.collection('messages').get();
      expect(snap.docs.first.id, isNotEmpty);
    });
  });

  // ── TC-MSG-002 ───────────────────────────────────────────────────────────────

  group('TC-MSG-002: кілька повідомлень — всі доходять до тренера', () {
    test('3 повідомлення від одного батька — всі 3 в Firestore', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final notifier = c.read(messageNotifierProvider.notifier);
      await notifier.send(
        fromParentId: 'parent1',
        fromParentName: 'Ольга Іваненко',
        toCoachId: 'coach1',
        body: 'Повідомлення 1',
      );
      await notifier.send(
        fromParentId: 'parent1',
        fromParentName: 'Ольга Іваненко',
        toCoachId: 'coach1',
        body: 'Повідомлення 2',
      );
      await notifier.send(
        fromParentId: 'parent1',
        fromParentName: 'Ольга Іваненко',
        toCoachId: 'coach1',
        body: 'Повідомлення 3',
      );

      final messages = await _allMessages(db);
      expect(messages, hasLength(3));

      final bodies = messages.map((m) => m['body'] as String).toSet();
      expect(bodies, containsAll(['Повідомлення 1', 'Повідомлення 2', 'Повідомлення 3']));
    });

    test('всі повідомлення мають readByCoach=false до прочитання', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final notifier = c.read(messageNotifierProvider.notifier);
      for (var i = 1; i <= 5; i++) {
        await notifier.send(
          fromParentId: 'parent1',
          fromParentName: 'Батько',
          toCoachId: 'coach1',
          body: 'Повідомлення $i',
        );
      }

      final messages = await _allMessages(db);
      expect(messages, hasLength(5));
      for (final msg in messages) {
        expect(msg['readByCoach'], isFalse,
            reason: 'Всі нові повідомлення readByCoach=false');
      }
    });
  });

  // ── TC-MSG-003 ───────────────────────────────────────────────────────────────

  group('TC-MSG-003: повідомлення ізольовані за тренером', () {
    test('повідомлення для тренера1 не видно тренеру2', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final notifier = c.read(messageNotifierProvider.notifier);
      await notifier.send(
        fromParentId: 'parent1',
        fromParentName: 'Батько А',
        toCoachId: 'coach1',
        body: 'Для тренера Іванова',
      );
      await notifier.send(
        fromParentId: 'parent2',
        fromParentName: 'Батько Б',
        toCoachId: 'coach2',
        body: 'Для тренера Петренка',
      );

      // Simulate coach1's query
      final coach1Messages = await db
          .collection('messages')
          .where('toCoachId', isEqualTo: 'coach1')
          .get();
      expect(coach1Messages.docs, hasLength(1));
      expect(coach1Messages.docs.first.data()['body'],
          equals('Для тренера Іванова'));

      // Simulate coach2's query
      final coach2Messages = await db
          .collection('messages')
          .where('toCoachId', isEqualTo: 'coach2')
          .get();
      expect(coach2Messages.docs, hasLength(1));
      expect(coach2Messages.docs.first.data()['body'],
          equals('Для тренера Петренка'));
    });
  });

  // ── TC-MSG-004 ───────────────────────────────────────────────────────────────

  group('TC-MSG-004: тренер прочитав → readByCoach=true', () {
    test('markRead встановлює readByCoach=true', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final notifier = c.read(messageNotifierProvider.notifier);
      await notifier.send(
        fromParentId: 'parent1',
        fromParentName: 'Батько',
        toCoachId: 'coach1',
        body: 'Важливе питання',
      );

      final snap = await db.collection('messages').get();
      final msgId = snap.docs.first.id;
      expect(snap.docs.first.data()['readByCoach'], isFalse);

      await notifier.markRead(msgId);

      final updated = await _getMessage(db, msgId);
      expect(updated?['readByCoach'], isTrue);
    });

    test('markRead для одного не змінює статус інших повідомлень', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final notifier = c.read(messageNotifierProvider.notifier);
      await notifier.send(
          fromParentId: 'p1',
          fromParentName: 'Батько',
          toCoachId: 'coach1',
          body: 'Перше');
      await notifier.send(
          fromParentId: 'p1',
          fromParentName: 'Батько',
          toCoachId: 'coach1',
          body: 'Друге');

      final snap = await db.collection('messages').get();
      expect(snap.docs, hasLength(2));

      // Read only the first
      await notifier.markRead(snap.docs.first.id);

      final after = await _allMessages(db);
      final read = after.where((m) => m['readByCoach'] == true).length;
      final unread = after.where((m) => m['readByCoach'] == false).length;

      expect(read, equals(1));
      expect(unread, equals(1));
    });

    test('повторний markRead не кидає помилку і залишається true', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(messageNotifierProvider.notifier).send(
            fromParentId: 'p1',
            fromParentName: 'Батько',
            toCoachId: 'coach1',
            body: 'Тест',
          );

      final snap = await db.collection('messages').get();
      final msgId = snap.docs.first.id;

      final notifier = c.read(messageNotifierProvider.notifier);
      await notifier.markRead(msgId);
      await notifier.markRead(msgId); // Second call — should not throw

      final updated = await _getMessage(db, msgId);
      expect(updated?['readByCoach'], isTrue);
    });
  });

  // ── TC-MSG-005 ───────────────────────────────────────────────────────────────

  group('TC-MSG-005: лічильник непрочитаних повідомлень', () {
    test('кількість непрочитаних = кількість повідомлень без readByCoach=true', () async {
      final db = _db();

      // Add 3 messages
      for (var i = 1; i <= 3; i++) {
        await db.collection('messages').add({
          'fromParentId': 'parent$i',
          'fromParentName': 'Батько $i',
          'toCoachId': 'coach1',
          'body': 'Повідомлення $i',
          'readByCoach': false,
        });
      }

      // Simulate unread count logic (from unreadParentMessagesCountProvider)
      final snap = await db
          .collection('messages')
          .where('toCoachId', isEqualTo: 'coach1')
          .get();
      final messages = snap.docs.map((d) {
        final data = d.data();
        return ParentMessageModel(
          id: d.id,
          fromParentId: data['fromParentId'] as String,
          fromParentName: data['fromParentName'] as String,
          toCoachId: data['toCoachId'] as String,
          body: data['body'] as String,
          sentAt: DateTime.now(),
          readByCoach: data['readByCoach'] as bool,
        );
      }).toList();

      final unread = messages.where((m) => !m.readByCoach).length;
      expect(unread, equals(3));
    });

    test('після прочитання всіх → лічильник непрочитаних = 0', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final notifier = c.read(messageNotifierProvider.notifier);

      // Send 2 messages
      await notifier.send(
          fromParentId: 'p1',
          fromParentName: 'Батько',
          toCoachId: 'coach1',
          body: 'Повідомлення 1');
      await notifier.send(
          fromParentId: 'p1',
          fromParentName: 'Батько',
          toCoachId: 'coach1',
          body: 'Повідомлення 2');

      final snap = await db.collection('messages').get();
      expect(snap.docs, hasLength(2));

      // Mark all as read
      for (final doc in snap.docs) {
        await notifier.markRead(doc.id);
      }

      // All readByCoach=true → 0 unread
      final after = await _allMessages(db);
      final unread = after.where((m) => m['readByCoach'] == false).length;
      expect(unread, equals(0));
    });
  });
}

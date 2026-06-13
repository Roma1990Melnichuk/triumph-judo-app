import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/club_honor_board_model.dart';
import 'package:judo_app/features/news/providers/honor_board_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

ClubHonorBoardItem makeItem({
  String id = 'hb1',
  String athleteId = 'a1',
  String athleteName = 'Максим Іванов',
  HonorBoardType type = HonorBoardType.firstPlace,
  MedalType? medalType = MedalType.gold,
  String title = '1 місце на Кубку Києва',
  bool isPinned = false,
  bool isVisible = true,
}) =>
    ClubHonorBoardItem(
      id: id,
      athleteId: athleteId,
      athleteName: athleteName,
      type: type,
      title: title,
      medalType: medalType,
      isPinned: isPinned,
      isVisible: isVisible,
      publishedAt: DateTime(2026, 6, 1),
      createdAt: DateTime(2026, 6, 1),
    );

Future<void> seedItem(
  FirebaseFirestore db,
  String id, {
  Map<String, dynamic> extra = const {},
}) =>
    db.collection('honor_board').doc(id).set({
      'athleteId': 'a1',
      'athleteName': 'Тест Атлет',
      'type': 'firstPlace',
      'title': 'Тест',
      'isPinned': false,
      'isVisible': true,
      'publishedAt': Timestamp.fromDate(DateTime(2026, 6, 1)),
      'createdAt': Timestamp.fromDate(DateTime(2026, 6, 1)),
      ...extra,
    });

void main() {
  // ── HonorBoardFilter.label ────────────────────────────────────────────────

  group('HonorBoardFilter.label', () {
    final cases = {
      HonorBoardFilter.all:      'Всі',
      HonorBoardFilter.medals:   'Медалі',
      HonorBoardFilter.belts:    'Пояси',
      HonorBoardFilter.progress: 'Прогрес',
    };
    cases.forEach((f, label) {
      test('$f → $label', () => expect(f.label, label));
    });
  });

  // ── HonorBoardNotifier.addItem ────────────────────────────────────────────

  group('HonorBoardNotifier.addItem', () {
    test('створює документ у колекції honor_board', () async {
      final fake = FakeFirebaseFirestore();
      final notifier = HonorBoardNotifier(fake);

      await notifier.addItem(makeItem(athleteName: 'Новий атлет', title: '1 місце'));

      final docs = await fake.collection('honor_board').get();
      expect(docs.docs, hasLength(1));
      expect(docs.docs.first.data()['athleteName'], 'Новий атлет');
      expect(docs.docs.first.data()['title'], '1 місце');
    });

    test('стан переходить в AsyncData після успіху', () async {
      final fake = FakeFirebaseFirestore();
      final notifier = HonorBoardNotifier(fake);

      await notifier.addItem(makeItem());

      expect(notifier.state, isA<AsyncData<void>>());
    });
  });

  // ── HonorBoardNotifier.updateItem ─────────────────────────────────────────

  group('HonorBoardNotifier.updateItem', () {
    test('оновлює поля документа', () async {
      final fake = FakeFirebaseFirestore();
      await seedItem(fake, 'hb1', extra: {'title': 'Старий заголовок'});
      final notifier = HonorBoardNotifier(fake);

      await notifier.updateItem(
        makeItem(id: 'hb1', title: 'Новий заголовок', type: HonorBoardType.newBelt, medalType: null),
      );

      final data = (await fake.collection('honor_board').doc('hb1').get()).data()!;
      expect(data['title'], 'Новий заголовок');
      expect(data['type'], 'newBelt');
    });
  });

  // ── HonorBoardNotifier.deleteItem ─────────────────────────────────────────

  group('HonorBoardNotifier.deleteItem', () {
    test('видаляє документ', () async {
      final fake = FakeFirebaseFirestore();
      await seedItem(fake, 'hb1');
      await HonorBoardNotifier(fake).deleteItem('hb1');

      final doc = await fake.collection('honor_board').doc('hb1').get();
      expect(doc.exists, isFalse);
    });

    test('стан переходить в AsyncData після успіху', () async {
      final fake = FakeFirebaseFirestore();
      await seedItem(fake, 'hb1');
      final notifier = HonorBoardNotifier(fake);

      await notifier.deleteItem('hb1');

      expect(notifier.state, isA<AsyncData<void>>());
    });
  });

  // ── HonorBoardNotifier.toggleVisibility ──────────────────────────────────

  group('HonorBoardNotifier.toggleVisibility', () {
    test('true → false', () async {
      final fake = FakeFirebaseFirestore();
      await seedItem(fake, 'hb1', extra: {'isVisible': true});
      await HonorBoardNotifier(fake).toggleVisibility('hb1', true);

      final data = (await fake.collection('honor_board').doc('hb1').get()).data()!;
      expect(data['isVisible'], isFalse);
    });

    test('false → true', () async {
      final fake = FakeFirebaseFirestore();
      await seedItem(fake, 'hb1', extra: {'isVisible': false});
      await HonorBoardNotifier(fake).toggleVisibility('hb1', false);

      final data = (await fake.collection('honor_board').doc('hb1').get()).data()!;
      expect(data['isVisible'], isTrue);
    });
  });

  // ── HonorBoardNotifier.togglePin ─────────────────────────────────────────

  group('HonorBoardNotifier.togglePin', () {
    test('false → true', () async {
      final fake = FakeFirebaseFirestore();
      await seedItem(fake, 'hb1', extra: {'isPinned': false});
      await HonorBoardNotifier(fake).togglePin('hb1', false);

      final data = (await fake.collection('honor_board').doc('hb1').get()).data()!;
      expect(data['isPinned'], isTrue);
    });

    test('true → false', () async {
      final fake = FakeFirebaseFirestore();
      await seedItem(fake, 'hb1', extra: {'isPinned': true});
      await HonorBoardNotifier(fake).togglePin('hb1', true);

      final data = (await fake.collection('honor_board').doc('hb1').get()).data()!;
      expect(data['isPinned'], isFalse);
    });
  });

  // ── honorBoardFilterProvider ──────────────────────────────────────────────

  group('honorBoardFilterProvider', () {
    test('початковий стан — HonorBoardFilter.all', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(honorBoardFilterProvider), HonorBoardFilter.all);
    });

    test('можна змінити фільтр', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(honorBoardFilterProvider.notifier).state = HonorBoardFilter.medals;
      expect(container.read(honorBoardFilterProvider), HonorBoardFilter.medals);
    });
  });

  // ── filteredHonorBoardProvider ────────────────────────────────────────────

  group('filteredHonorBoardProvider', () {
    final medal1 = makeItem(id: 'i1', type: HonorBoardType.firstPlace, medalType: MedalType.gold);
    final medal2 = makeItem(id: 'i2', type: HonorBoardType.thirdPlace, medalType: MedalType.bronze);
    final belt   = makeItem(id: 'i3', type: HonorBoardType.newBelt, medalType: null);
    final prog1  = makeItem(id: 'i4', type: HonorBoardType.bestProgress, medalType: null);
    final prog2  = makeItem(id: 'i5', type: HonorBoardType.monthAchievement, medalType: null);
    final items  = [medal1, medal2, belt, prog1, prog2];

    ProviderContainer makeContainer() => ProviderContainer(overrides: [
          honorBoardProvider.overrideWith((_) => Stream.value(items)),
        ]);

    test('all — повертає всі елементи', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(honorBoardProvider.future);

      expect(c.read(filteredHonorBoardProvider), hasLength(5));
    });

    test('medals — тільки медальні типи', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(honorBoardProvider.future);
      c.read(honorBoardFilterProvider.notifier).state = HonorBoardFilter.medals;

      final result = c.read(filteredHonorBoardProvider);
      expect(result, hasLength(2));
      expect(result.every((i) => i.type.isMedal), isTrue);
    });

    test('belts — тільки новий пояс', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(honorBoardProvider.future);
      c.read(honorBoardFilterProvider.notifier).state = HonorBoardFilter.belts;

      final result = c.read(filteredHonorBoardProvider);
      expect(result, hasLength(1));
      expect(result.first.type, HonorBoardType.newBelt);
    });

    test('progress — тільки прогресові типи', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(honorBoardProvider.future);
      c.read(honorBoardFilterProvider.notifier).state = HonorBoardFilter.progress;

      final result = c.read(filteredHonorBoardProvider);
      expect(result, hasLength(2));
      expect(result.every((i) => i.type.isProgress), isTrue);
    });

    test('перемикання між фільтрами оновлює результат', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(honorBoardProvider.future);

      c.read(honorBoardFilterProvider.notifier).state = HonorBoardFilter.medals;
      expect(c.read(filteredHonorBoardProvider), hasLength(2));

      c.read(honorBoardFilterProvider.notifier).state = HonorBoardFilter.all;
      expect(c.read(filteredHonorBoardProvider), hasLength(5));
    });
  });
}

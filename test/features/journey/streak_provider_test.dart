import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/constants/journey_messages.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/core/models/training_session_model.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/journey/providers/streak_provider.dart';
import 'package:judo_app/features/schedule/providers/schedule_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';

// ── Фікстури ──────────────────────────────────────────────────────────────────

const _childId = 'child1';
const _coachId = 'coach1';

final _parentUser = UserModel(
  uid: 'parent1',
  email: 'p@test.com',
  name: 'Батько',
  role: 'parent',
  childIds: [_childId],
);

final _coachUser = UserModel(
  uid: _coachId,
  email: 'c@test.com',
  name: 'Тренер',
  role: 'coach',
);

final _child = ChildModel(
  id: _childId,
  firstName: 'Іван',
  lastName: 'Петров',
  birthYear: 2012,
  weightCategory: '-30 кг',
  currentBelt: BeltLevel.white,
  coachId: _coachId,
  coachName: 'Тренер',
  totalPoints: 0,
  createdAt: DateTime(2024),
);

TrainingSessionModel _session(DateTime date, {bool present = true}) =>
    TrainingSessionModel(
      id: 'sess_${date.toIso8601String()}',
      scheduleId: 'sched1',
      coachId: _coachId,
      date: date,
      attendance: {_childId: present},
    );

Future<ProviderContainer> _container(
    List<TrainingSessionModel> sessions) async {
  final c = ProviderContainer(
    overrides: [
      currentUserModelProvider
          .overrideWith((_) => Stream.value(_parentUser)),
      allChildrenProvider.overrideWith((_) => Stream.value([_child])),
      coachSessionsProvider.overrideWith(
        (ref, coachId) => Stream.value(
          coachId == _coachId ? sessions : [],
        ),
      ),
    ],
  );
  // Await all upstream streams so derived providers see resolved values.
  await c.read(currentUserModelProvider.future);
  await c.read(allChildrenProvider.future);
  await c.read(coachSessionsProvider(_coachId).future);
  return c;
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── DateTimeJourney extension ─────────────────────────────────────────────

  group('DateTimeJourney.dayOfYear', () {
    test('1 січня = 1', () {
      expect(DateTime(2025, 1, 1).dayOfYear, 1);
    });

    test('2 січня = 2', () {
      expect(DateTime(2025, 1, 2).dayOfYear, 2);
    });

    test('31 грудня невисокосного = 365', () {
      expect(DateTime(2025, 12, 31).dayOfYear, 365);
    });

    test('31 грудня високосного = 366', () {
      expect(DateTime(2024, 12, 31).dayOfYear, 366);
    });

    test('1 березня невисокосного = 60', () {
      expect(DateTime(2025, 3, 1).dayOfYear, 60);
    });

    test('1 березня високосного = 61', () {
      expect(DateTime(2024, 3, 1).dayOfYear, 61);
    });
  });

  group('DateTimeJourney.isSameDay', () {
    test('однаковий день, різний час → true', () {
      final a = DateTime(2025, 5, 10, 9, 0);
      final b = DateTime(2025, 5, 10, 23, 59);
      expect(a.isSameDay(b), isTrue);
    });

    test('різні дні → false', () {
      final a = DateTime(2025, 5, 10);
      final b = DateTime(2025, 5, 11);
      expect(a.isSameDay(b), isFalse);
    });

    test('різні місяці → false', () {
      expect(DateTime(2025, 4, 30).isSameDay(DateTime(2025, 5, 1)), isFalse);
    });

    test('різні роки → false', () {
      expect(DateTime(2024, 1, 1).isSameDay(DateTime(2025, 1, 1)), isFalse);
    });

    test('симетрія: a.isSameDay(b) == b.isSameDay(a)', () {
      final a = DateTime(2025, 6, 15, 10);
      final b = DateTime(2025, 6, 15, 22);
      expect(a.isSameDay(b), equals(b.isSameDay(a)));
    });
  });

  // ── streakDataProvider ────────────────────────────────────────────────────

  group('streakDataProvider', () {
    test('нуль при відсутності сесій', () async {
      final c = await _container([]);
      final streak = c.read(streakDataProvider);
      expect(streak.current, 0);
      expect(streak.best, 0);
      expect(streak.total, 0);
    });

    test('тренер отримує нулі', () async {
      final c = ProviderContainer(overrides: [
        currentUserModelProvider
            .overrideWith((_) => Stream.value(_coachUser)),
        allChildrenProvider.overrideWith((_) => Stream.value([])),
        coachSessionsProvider
            .overrideWith((_, __) => Stream.value([])),
      ]);
      await c.read(currentUserModelProvider.future);
      await c.read(allChildrenProvider.future);

      final streak = c.read(streakDataProvider);
      expect(streak.current, 0);
    });

    test('3 присутніх сесій поспіль → current = 3', () async {
      final now = DateTime.now();
      final sessions = [
        _session(DateTime(now.year, now.month, now.day)),
        _session(DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1))),
        _session(DateTime(now.year, now.month, now.day).subtract(const Duration(days: 2))),
      ];

      final c = await _container(sessions);
      final streak = c.read(streakDataProvider);
      expect(streak.current, 3);
      expect(streak.total, 3);
    });

    test('пропуск скидає серію', () async {
      final now = DateTime.now();
      // Порядок DESC (як з Firestore): [сьогодні, вчора, позавчора=пропуск, 3 дні тому]
      final sessions = [
        _session(DateTime(now.year, now.month, now.day)),
        _session(DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1))),
        _session(DateTime(now.year, now.month, now.day).subtract(const Duration(days: 2)), present: false),
        _session(DateTime(now.year, now.month, now.day).subtract(const Duration(days: 3))),
      ];

      final c = await _container(sessions);
      final streak = c.read(streakDataProvider);
      // current: лише 2 (до пропуску)
      expect(streak.current, 2);
      // total: 3 присутніх
      expect(streak.total, 3);
    });

    test('одна сесія → current = 1', () async {
      final now = DateTime.now();
      final c = await _container([
        _session(DateTime(now.year, now.month, now.day)),
      ]);
      final streak = c.read(streakDataProvider);
      expect(streak.current, 1);
    });

    test('усі сесії — пропуск → current = 0', () async {
      final now = DateTime.now();
      final sessions = List.generate(
        5,
        (i) => _session(
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i)),
          present: false,
        ),
      );

      final c = await _container(sessions);
      final streak = c.read(streakDataProvider);
      expect(streak.current, 0);
      expect(streak.total, 0);
    });

    test('best == current (немає збереженої попередньої серії)', () async {
      final now = DateTime.now();
      final sessions = [
        _session(DateTime(now.year, now.month, now.day)),
        _session(DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1))),
      ];

      final c = await _container(sessions);
      final streak = c.read(streakDataProvider);
      expect(streak.best, streak.current);
    });

    test('best = попередня серія, коли вона більша за поточну', () async {
      final now = DateTime.now();
      // Розклад: 4 дні поспіль (3–6 днів тому), потім пропуск, потім 1 (вчора)
      final sessions = [
        _session(DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1))),
        // пропуск 2 дні тому (present: false)
        _session(DateTime(now.year, now.month, now.day).subtract(const Duration(days: 2)), present: false),
        _session(DateTime(now.year, now.month, now.day).subtract(const Duration(days: 3))),
        _session(DateTime(now.year, now.month, now.day).subtract(const Duration(days: 4))),
        _session(DateTime(now.year, now.month, now.day).subtract(const Duration(days: 5))),
        _session(DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6))),
      ];

      final c = await _container(sessions);
      final streak = c.read(streakDataProvider);
      // current = 1 (лише вчора), best = 4 (3-6 днів тому)
      expect(streak.current, 1);
      expect(streak.best, 4);
    });

    test('best = current коли ніколи не переривалось', () async {
      final now = DateTime.now();
      final sessions = List.generate(
        5,
        (i) => _session(
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i)),
        ),
      );

      final c = await _container(sessions);
      final streak = c.read(streakDataProvider);
      expect(streak.best, 5);
      expect(streak.current, 5);
    });

    test('дві рівні серії — best відображає максимум', () async {
      final now = DateTime.now();
      // Серія 2, пропуск, серія 2 → best=2
      final sessions = [
        _session(DateTime(now.year, now.month, now.day)),
        _session(DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1))),
        _session(DateTime(now.year, now.month, now.day).subtract(const Duration(days: 2)), present: false),
        _session(DateTime(now.year, now.month, now.day).subtract(const Duration(days: 3))),
        _session(DateTime(now.year, now.month, now.day).subtract(const Duration(days: 4))),
      ];

      final c = await _container(sessions);
      final streak = c.read(streakDataProvider);
      expect(streak.best, 2);
    });
  });

  // ── weekActivityProvider ──────────────────────────────────────────────────

  group('weekActivityProvider', () {
    test('порожній тиждень → 7 false', () async {
      final c = await _container([]);
      final week = c.read(weekActivityProvider);
      expect(week.length, 7);
      expect(week.every((b) => !b), isTrue);
    });

    test('сесія в поточний тиждень відображається', () async {
      final now = DateTime.now();
      // Понеділок поточного тижня
      final monday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final c = await _container([_session(monday)]);
      final week = c.read(weekActivityProvider);
      expect(week[0], isTrue);   // Понеділок
    });

    test('сесія минулого тижня не потрапляє в поточний', () async {
      final now = DateTime.now();
      final lastMonday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1 + 7));
      final c = await _container([_session(lastMonday)]);
      final week = c.read(weekActivityProvider);
      expect(week.every((b) => !b), isTrue);
    });

    test('пропуск у тижні → false для того дня', () async {
      final now = DateTime.now();
      final monday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final c = await _container([_session(monday, present: false)]);
      final week = c.read(weekActivityProvider);
      expect(week[0], isFalse);
    });
  });

  // ── fourWeekActivityProvider ──────────────────────────────────────────────

  group('fourWeekActivityProvider', () {
    test('завжди повертає 28 елементів', () async {
      final c = await _container([]);
      final result = c.read(fourWeekActivityProvider);
      expect(result.length, 28);
    });

    test('майбутні дні мають future = true і trained = false', () async {
      final c = await _container([]);
      final result = c.read(fourWeekActivityProvider);
      final futureDays = result.where((d) => d.future).toList();
      expect(futureDays.every((d) => !d.trained), isTrue);
    });

    test('тренування у вікні → trained = true', () async {
      final now = DateTime.now();
      final twoDaysAgo = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 2));
      final c = await _container([_session(twoDaysAgo)]);
      final result = c.read(fourWeekActivityProvider);
      final entry = result.firstWhere((d) => d.date.isSameDay(twoDaysAgo));
      expect(entry.trained, isTrue);
      expect(entry.future, isFalse);
    });

    test('сесія за межами 3 тижнів назад не враховується', () async {
      final now = DateTime.now();
      // 4 тижні + 1 день тому — поза вікном
      final tooOld = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 29));
      final c = await _container([_session(tooOld)]);
      final result = c.read(fourWeekActivityProvider);
      expect(result.every((d) => !d.trained), isTrue);
    });

    test('список відсортований хронологічно (перший < останній)', () async {
      final c = await _container([]);
      final result = c.read(fourWeekActivityProvider);
      expect(result.first.date.isBefore(result.last.date), isTrue);
    });
  });

  // ── dailyMessageProvider ──────────────────────────────────────────────────

  group('dailyMessageProvider', () {
    test('повертає рядок з kJourneyMessages', () async {
      final c = await _container([]);
      final msg = c.read(dailyMessageProvider);
      expect(kJourneyMessages.contains(msg), isTrue);
    });

    test('індекс = dayOfYear % length — не виходить за межі', () {
      // Перевіряємо що формула не кидає RangeError при будь-якому дні року
      for (var doy = 1; doy <= 366; doy++) {
        final idx = doy % kJourneyMessages.length;
        expect(idx, greaterThanOrEqualTo(0));
        expect(idx, lessThan(kJourneyMessages.length));
      }
    });

    test('kJourneyMessages має 50 повідомлень', () {
      expect(kJourneyMessages.length, 50);
    });

    test('всі повідомлення непорожні', () {
      for (final msg in kJourneyMessages) {
        expect(msg.isNotEmpty, isTrue);
      }
    });
  });
}

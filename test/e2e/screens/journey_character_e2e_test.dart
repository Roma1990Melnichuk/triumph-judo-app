/// TC-CHAR — Персонаж змінюється залежно від відвідуваності.
///
/// Бізнес-правило: чим довший безперервний стрік тренувань,
/// тим потужніший персонаж (pr1..pr8).
///
/// Ключові правила:
///   1. 0 тренувань → pr1 (початківець, без аури)
///   2. 1–6 тренувань підряд → pr2 (помаранчевий)
///   3. 7–14 → pr3 (слабке золото)
///   4. 15–29 → pr4 (золото)
///   5. 30–59 → pr5 (сильне золото)
///   6. 60–89 → pr6 (червоне золото)
///   7. 90–179 → pr7 (Майстер)
///   8. 180+ → pr8 (Легендарний)
///   9. Пропуск тренування обриває поточний стрік
///  10. Найкращий стрік зберігається навіть після обриву
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/training_session_model.dart';

// ── Дублікат логіки з streak_provider.dart ───────────────────────────────────
// Тестуємо саму бізнес-логіку незалежно від Riverpod/Firebase.

typedef _StreakData = ({int current, int best, int total});

_StreakData _computeStreak(
    List<TrainingSessionModel> sessions, String childId) {
  int current = 0;
  int best = 0;
  int running = 0;
  int total = 0;
  bool streakBroken = false;

  // sessions sorted DESC (most recent first) — same as provider
  for (final session in sessions) {
    final present = session.isPresent(childId);
    if (present) {
      total++;
      if (!streakBroken) current++;
      running++;
      if (running > best) best = running;
    } else {
      streakBroken = true;
      running = 0;
    }
  }
  return (current: current, best: best, total: total);
}

// ── Дублікат логіки з journey_screen.dart (_glowForStreak + _assetFor) ────────

String _characterAssetForStreak(int streak) {
  if (streak >= 180) return 'assets/progress/pr8.png'; // Легендарний
  if (streak >= 90) return 'assets/progress/pr7.png';  // Майстер
  if (streak >= 60) return 'assets/progress/pr6.png';  // Червоне золото
  if (streak >= 30) return 'assets/progress/pr5.png';  // Сильне золото
  if (streak >= 15) return 'assets/progress/pr4.png';  // Золото
  if (streak >= 7) return 'assets/progress/pr3.png';   // Слабке золото
  if (streak >= 1) return 'assets/progress/pr2.png';   // Помаранчевий
  return 'assets/progress/pr1.png';                    // Початківець
}

// ── Builders ─────────────────────────────────────────────────────────────────

const _childId = 'child1';
const _coachId = 'coach1';

/// N сесій підряд де дитина ПРИСУТНЯ (не в attendance map = присутня за дефолтом).
List<TrainingSessionModel> _presentSessions(int count) {
  final sessions = <TrainingSessionModel>[];
  var day = DateTime(2026, 1, count); // Починаємо з count-го дня, йдемо назад
  for (var i = 0; i < count; i++) {
    sessions.add(TrainingSessionModel(
      id: 'sess_${day.toIso8601String()}',
      scheduleId: 'sched1',
      coachId: _coachId,
      date: day,
      attendance: {}, // Відсутність в map = присутній
    ));
    day = day.subtract(const Duration(days: 1));
  }
  return sessions; // Вже DESC (найновіші першими)
}

/// N присутніх, потім gap відсутностей, потім older присутніх.
List<TrainingSessionModel> _sessionsWithGap({
  required int recentPresent,
  required int absent,
  required int olderPresent,
}) {
  final sessions = <TrainingSessionModel>[];
  var day = DateTime(2026, 6, 1);

  for (var i = 0; i < recentPresent; i++) {
    sessions.add(TrainingSessionModel(
      id: 'r_${day.toIso8601String()}',
      scheduleId: 's',
      coachId: _coachId,
      date: day,
      attendance: {},
    ));
    day = day.subtract(const Duration(days: 1));
  }

  for (var i = 0; i < absent; i++) {
    sessions.add(TrainingSessionModel(
      id: 'a_${day.toIso8601String()}',
      scheduleId: 's',
      coachId: _coachId,
      date: day,
      attendance: {_childId: false}, // Явна відсутність
    ));
    day = day.subtract(const Duration(days: 1));
  }

  for (var i = 0; i < olderPresent; i++) {
    sessions.add(TrainingSessionModel(
      id: 'o_${day.toIso8601String()}',
      scheduleId: 's',
      coachId: _coachId,
      date: day,
      attendance: {},
    ));
    day = day.subtract(const Duration(days: 1));
  }

  return sessions;
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── TC-CHAR-001 ──────────────────────────────────────────────────────────────

  group('TC-CHAR-001: 0 тренувань → персонаж pr1', () {
    test('порожній список сесій → стрік=0 → pr1', () {
      final streak = _computeStreak([], _childId);
      expect(streak.current, equals(0));
      expect(_characterAssetForStreak(streak.current),
          equals('assets/progress/pr1.png'));
    });

    test('всі сесії — дитина була відсутня → стрік=0 → pr1', () {
      final sessions = [
        TrainingSessionModel(
          id: 's1',
          scheduleId: 'sched',
          coachId: _coachId,
          date: DateTime(2026, 1, 5),
          attendance: {_childId: false},
        ),
        TrainingSessionModel(
          id: 's2',
          scheduleId: 'sched',
          coachId: _coachId,
          date: DateTime(2026, 1, 4),
          attendance: {_childId: false},
        ),
      ];
      final streak = _computeStreak(sessions, _childId);
      expect(streak.current, equals(0));
      expect(_characterAssetForStreak(streak.current),
          equals('assets/progress/pr1.png'));
    });
  });

  // ── TC-CHAR-002 ──────────────────────────────────────────────────────────────

  group('TC-CHAR-002: 1–6 тренувань підряд → pr2 (помаранчевий)', () {
    for (final n in [1, 3, 6]) {
      test('$n тренувань підряд → стрік=$n → pr2', () {
        final streak = _computeStreak(_presentSessions(n), _childId);
        expect(streak.current, equals(n));
        expect(_characterAssetForStreak(streak.current),
            equals('assets/progress/pr2.png'));
      });
    }
  });

  // ── TC-CHAR-003 ──────────────────────────────────────────────────────────────

  group('TC-CHAR-003: 7–14 тренувань підряд → pr3 (слабке золото)', () {
    for (final n in [7, 10, 14]) {
      test('$n тренувань підряд → стрік=$n → pr3', () {
        final streak = _computeStreak(_presentSessions(n), _childId);
        expect(streak.current, equals(n));
        expect(_characterAssetForStreak(streak.current),
            equals('assets/progress/pr3.png'));
      });
    }
  });

  // ── TC-CHAR-004 ──────────────────────────────────────────────────────────────

  group('TC-CHAR-004: 15–29 тренувань підряд → pr4 (золото)', () {
    for (final n in [15, 20, 29]) {
      test('$n тренувань підряд → стрік=$n → pr4', () {
        final streak = _computeStreak(_presentSessions(n), _childId);
        expect(streak.current, equals(n));
        expect(_characterAssetForStreak(streak.current),
            equals('assets/progress/pr4.png'));
      });
    }
  });

  // ── TC-CHAR-005 ──────────────────────────────────────────────────────────────

  group('TC-CHAR-005: 30–59 тренувань підряд → pr5 (сильне золото)', () {
    for (final n in [30, 45, 59]) {
      test('$n тренувань підряд → стрік=$n → pr5', () {
        final streak = _computeStreak(_presentSessions(n), _childId);
        expect(streak.current, equals(n));
        expect(_characterAssetForStreak(streak.current),
            equals('assets/progress/pr5.png'));
      });
    }
  });

  // ── TC-CHAR-006 ──────────────────────────────────────────────────────────────

  group('TC-CHAR-006: 60–89 тренувань підряд → pr6 (червоне золото)', () {
    for (final n in [60, 75, 89]) {
      test('$n тренувань підряд → стрік=$n → pr6', () {
        final streak = _computeStreak(_presentSessions(n), _childId);
        expect(streak.current, equals(n));
        expect(_characterAssetForStreak(streak.current),
            equals('assets/progress/pr6.png'));
      });
    }
  });

  // ── TC-CHAR-007 ──────────────────────────────────────────────────────────────

  group('TC-CHAR-007: 90–179 тренувань підряд → pr7 (Майстер)', () {
    for (final n in [90, 120, 179]) {
      test('$n тренувань підряд → стрік=$n → pr7', () {
        final streak = _computeStreak(_presentSessions(n), _childId);
        expect(streak.current, equals(n));
        expect(_characterAssetForStreak(streak.current),
            equals('assets/progress/pr7.png'));
      });
    }
  });

  // ── TC-CHAR-008 ──────────────────────────────────────────────────────────────

  group('TC-CHAR-008: 180+ тренувань підряд → pr8 (Легендарний)', () {
    for (final n in [180, 250, 365]) {
      test('$n тренувань підряд → стрік=$n → pr8', () {
        final streak = _computeStreak(_presentSessions(n), _childId);
        expect(streak.current, equals(n));
        expect(_characterAssetForStreak(streak.current),
            equals('assets/progress/pr8.png'));
      });
    }
  });

  // ── TC-CHAR-009 ──────────────────────────────────────────────────────────────

  group('TC-CHAR-009: пропуск тренування обриває поточний стрік', () {
    test('10 присутніх, 1 відсутність → поточний стрік=0', () {
      final sessions = _sessionsWithGap(
        recentPresent: 0,
        absent: 1,
        olderPresent: 10,
      );
      final streak = _computeStreak(sessions, _childId);
      expect(streak.current, equals(0));
      expect(streak.total, equals(10));
    });

    test('5 присутніх потім 1 пропуск потім 15 присутніх → current=5, best=15', () {
      final sessions = _sessionsWithGap(
        recentPresent: 5,
        absent: 1,
        olderPresent: 15,
      );
      final streak = _computeStreak(sessions, _childId);
      expect(streak.current, equals(5));
      expect(streak.best, equals(15));
      // Character is based on current streak (5) → pr2
      expect(_characterAssetForStreak(streak.current),
          equals('assets/progress/pr2.png'));
    });

    test('відразу після обриву стріку 7 → character повертається до pr1', () {
      // Was at 7 (pr3), then missed → current=0 → pr1
      final sessions = _sessionsWithGap(
        recentPresent: 0,
        absent: 1,
        olderPresent: 7,
      );
      final streak = _computeStreak(sessions, _childId);
      expect(streak.current, equals(0));
      expect(_characterAssetForStreak(streak.current),
          equals('assets/progress/pr1.png'));
    });
  });

  // ── TC-CHAR-010 ──────────────────────────────────────────────────────────────

  group('TC-CHAR-010: найкращий стрік зберігається після обриву', () {
    test('20 присутніх, 1 пропуск, 3 присутніх → best=20, current=3', () {
      final sessions = _sessionsWithGap(
        recentPresent: 3,
        absent: 1,
        olderPresent: 20,
      );
      final streak = _computeStreak(sessions, _childId);
      expect(streak.current, equals(3));
      expect(streak.best, equals(20));
      expect(streak.total, equals(23));
    });

    test('кілька циклів присутності-відсутності — best = максимальний цикл', () {
      // 5 присутніх → пропуск → 3 присутніх → пропуск → 8 присутніх → пропуск → 2 поточних
      final s1 = _sessionsWithGap(
          recentPresent: 2, absent: 1, olderPresent: 0); // поточний=2
      final s2 = _sessionsWithGap(
          recentPresent: 8, absent: 1, olderPresent: 0); // best candidate=8
      final s3 = _sessionsWithGap(
          recentPresent: 3, absent: 1, olderPresent: 0);
      final s4 = _sessionsWithGap(
          recentPresent: 5, absent: 1, olderPresent: 0);

      // Build one combined list in DESC order: s1 (recent) → s2 → s3 → s4 (oldest)
      // We need to be careful with dates — let's use a simpler approach
      var day = DateTime(2026, 6, 30);
      final sessions = <TrainingSessionModel>[];

      void addPresent(int n) {
        for (var i = 0; i < n; i++) {
          sessions.add(TrainingSessionModel(
            id: 'd_${day.toIso8601String()}',
            scheduleId: 's',
            coachId: _coachId,
            date: day,
            attendance: {},
          ));
          day = day.subtract(const Duration(days: 1));
        }
      }

      void addAbsent() {
        sessions.add(TrainingSessionModel(
          id: 'd_${day.toIso8601String()}',
          scheduleId: 's',
          coachId: _coachId,
          date: day,
          attendance: {_childId: false},
        ));
        day = day.subtract(const Duration(days: 1));
      }

      addPresent(2);  // current = 2
      addAbsent();
      addPresent(8);  // best candidate
      addAbsent();
      addPresent(3);
      addAbsent();
      addPresent(5);

      final streak = _computeStreak(sessions, _childId);
      expect(streak.current, equals(2));
      expect(streak.best, equals(8));
      expect(streak.total, equals(18)); // 2+8+3+5
    });
  });

  // ── TC-CHAR-011 ──────────────────────────────────────────────────────────────

  group('TC-CHAR-011: граничні значення — зміна персонажа на порозі', () {
    test('стрік=6 → pr2; стрік=7 → pr3 (перехід на порозі 7)', () {
      final s6 = _computeStreak(_presentSessions(6), _childId);
      final s7 = _computeStreak(_presentSessions(7), _childId);

      expect(_characterAssetForStreak(s6.current),
          equals('assets/progress/pr2.png'));
      expect(_characterAssetForStreak(s7.current),
          equals('assets/progress/pr3.png'));
    });

    test('стрік=14 → pr3; стрік=15 → pr4 (перехід на порозі 15)', () {
      final s14 = _computeStreak(_presentSessions(14), _childId);
      final s15 = _computeStreak(_presentSessions(15), _childId);

      expect(_characterAssetForStreak(s14.current),
          equals('assets/progress/pr3.png'));
      expect(_characterAssetForStreak(s15.current),
          equals('assets/progress/pr4.png'));
    });

    test('стрік=29 → pr4; стрік=30 → pr5 (перехід на порозі 30)', () {
      final s29 = _computeStreak(_presentSessions(29), _childId);
      final s30 = _computeStreak(_presentSessions(30), _childId);

      expect(_characterAssetForStreak(s29.current),
          equals('assets/progress/pr4.png'));
      expect(_characterAssetForStreak(s30.current),
          equals('assets/progress/pr5.png'));
    });

    test('стрік=179 → pr7; стрік=180 → pr8 (перехід на порозі 180)', () {
      final s179 = _computeStreak(_presentSessions(179), _childId);
      final s180 = _computeStreak(_presentSessions(180), _childId);

      expect(_characterAssetForStreak(s179.current),
          equals('assets/progress/pr7.png'));
      expect(_characterAssetForStreak(s180.current),
          equals('assets/progress/pr8.png'));
    });
  });
}

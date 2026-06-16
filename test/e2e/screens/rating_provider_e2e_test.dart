/// TC-RATING — Бізнес-логіка рейтингу та підрахунку очок.
///
/// Ключові правила:
///   1. yearPointsProvider: підсумовує тільки очки за вказаний рік (seasonYear)
///   2. allRatedSortedProvider: якщо рік задано → сортування за season points
///      інакше → сортування за totalPoints; тай-брейк: lastName ASC
///   3. coachRankingProvider: групує атлетів по coachId,
///      підсумовує totalPoints кожної групи, сортує DESC
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/competition_result_model.dart';
import 'package:judo_app/core/models/child_model.dart';

// ── Чиста логіка рейтингу (дублює провайдери без Riverpod) ──────────────────

/// Розраховує суму очок дитини в конкретному сезоні.
int _yearPoints(String childId, int seasonYear, List<CompetitionResultModel> results) {
  return results
      .where((r) => r.childId == childId && r.seasonYear == seasonYear)
      .fold(0, (sum, r) => sum + r.points);
}

/// Сортує дітей: якщо seasonYear != null → за очками сезону; інакше totalPoints.
/// Тай-брейк: lastName ASC.
List<ChildModel> _sortRated({
  required List<ChildModel> children,
  required List<CompetitionResultModel> results,
  int? seasonYear,
}) {
  final sorted = List<ChildModel>.from(children);
  sorted.sort((a, b) {
    final aPoints = seasonYear != null
        ? _yearPoints(a.id, seasonYear, results)
        : a.totalPoints;
    final bPoints = seasonYear != null
        ? _yearPoints(b.id, seasonYear, results)
        : b.totalPoints;
    final cmp = bPoints.compareTo(aPoints); // DESC
    if (cmp != 0) return cmp;
    return a.lastName.compareTo(b.lastName); // ASC tiebreak
  });
  return sorted;
}

/// Групує атлетів по тренеру, рахує загальні очки групи, сортує DESC.
List<({String coachId, int totalPoints})> _coachRanking(
    List<ChildModel> children) {
  final map = <String, int>{};
  for (final c in children) {
    map[c.coachId] = (map[c.coachId] ?? 0) + c.totalPoints;
  }
  final list = map.entries
      .map((e) => (coachId: e.key, totalPoints: e.value))
      .toList();
  list.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
  return list;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

ChildModel _child({
  required String id,
  required String lastName,
  int totalPoints = 0,
  String coachId = 'coach1',
}) =>
    ChildModel(
      id: id,
      firstName: 'Імʼя',
      lastName: lastName,
      birthYear: 2010,
      weightCategory: '-30 кг',
      currentBelt: BeltLevel.white,
      coachId: coachId,
      coachName: 'Тренер',
      totalPoints: totalPoints,
      createdAt: DateTime(2026, 1, 1),
    );

CompetitionResultModel _result({
  required String childId,
  required int points,
  required int seasonYear,
  String id = 'r1',
}) =>
    CompetitionResultModel(
      id: id,
      childId: childId,
      childName: 'Тест Тест',
      competitionName: 'Змагання',
      level: CompetitionLevel.local,
      place: 1,
      points: points,
      date: DateTime(seasonYear, 10, 1),
      seasonYear: seasonYear,
      addedByCoachId: 'coach1',
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── TC-RATING-001: yearPoints підраховує очки тільки за вказаний рік ──────

  group('TC-RATING-001: yearPoints — тільки вказаний рік', () {
    test('2 результати 2025 + 1 результат 2024 → yearPoints(2025) = 2025-очки', () {
      final results = [
        _result(id: 'r1', childId: 'c1', points: 30, seasonYear: 2025),
        _result(id: 'r2', childId: 'c1', points: 20, seasonYear: 2025),
        _result(id: 'r3', childId: 'c1', points: 100, seasonYear: 2024),
      ];
      expect(_yearPoints('c1', 2025, results), equals(50));
    });

    test('немає результатів за рік → yearPoints = 0', () {
      final results = [
        _result(id: 'r1', childId: 'c1', points: 50, seasonYear: 2024),
      ];
      expect(_yearPoints('c1', 2025, results), equals(0));
    });

    test('yearPoints ізольований: c1 і c2 рахуються окремо', () {
      final results = [
        _result(id: 'r1', childId: 'c1', points: 40, seasonYear: 2025),
        _result(id: 'r2', childId: 'c2', points: 60, seasonYear: 2025),
      ];
      expect(_yearPoints('c1', 2025, results), equals(40));
      expect(_yearPoints('c2', 2025, results), equals(60));
    });

    test('кілька результатів одного року → сума всіх', () {
      final results = [
        _result(id: 'r1', childId: 'c1', points: 10, seasonYear: 2025),
        _result(id: 'r2', childId: 'c1', points: 15, seasonYear: 2025),
        _result(id: 'r3', childId: 'c1', points: 25, seasonYear: 2025),
      ];
      expect(_yearPoints('c1', 2025, results), equals(50));
    });
  });

  // ── TC-RATING-002: сортування — seasonYear задано → по season points ──────

  group('TC-RATING-002: сортування за очками сезону (не totalPoints)', () {
    test('seasonYear → ігнорує totalPoints, сортує за очками сезону DESC', () {
      final children = [
        _child(id: 'c1', lastName: 'Іваненко', totalPoints: 1000),
        _child(id: 'c2', lastName: 'Петренко', totalPoints: 500),
      ];
      final results = [
        _result(id: 'r1', childId: 'c1', points: 10, seasonYear: 2025),
        _result(id: 'r2', childId: 'c2', points: 80, seasonYear: 2025),
      ];

      final sorted = _sortRated(
          children: children, results: results, seasonYear: 2025);

      // c2 має більше сезонних очок (80 > 10), повинен бути першим
      expect(sorted.first.id, equals('c2'));
      expect(sorted.last.id, equals('c1'));
    });

    test('немає seasonYear → сортує за totalPoints DESC', () {
      final children = [
        _child(id: 'c1', lastName: 'Мова', totalPoints: 100),
        _child(id: 'c2', lastName: 'Бить', totalPoints: 300),
        _child(id: 'c3', lastName: 'Грек', totalPoints: 200),
      ];

      final sorted =
          _sortRated(children: children, results: [], seasonYear: null);

      expect(sorted[0].id, equals('c2')); // 300
      expect(sorted[1].id, equals('c3')); // 200
      expect(sorted[2].id, equals('c1')); // 100
    });

    test('тай-брейк: рівні очки → сортується за прізвищем ASC', () {
      final children = [
        _child(id: 'c1', lastName: 'Яценко', totalPoints: 100),
        _child(id: 'c2', lastName: 'Андрієнко', totalPoints: 100),
        _child(id: 'c3', lastName: 'Мовчан', totalPoints: 100),
      ];

      final sorted =
          _sortRated(children: children, results: [], seasonYear: null);

      expect(sorted[0].lastName, equals('Андрієнко'));
      expect(sorted[1].lastName, equals('Мовчан'));
      expect(sorted[2].lastName, equals('Яценко'));
    });

    test('атлет без результатів у сезоні → 0 очок → останній', () {
      final children = [
        _child(id: 'c1', lastName: 'Без_очок', totalPoints: 1000),
        _child(id: 'c2', lastName: 'Переможець', totalPoints: 0),
      ];
      final results = [
        _result(id: 'r1', childId: 'c2', points: 50, seasonYear: 2025),
        // c1 has NO results in 2025
      ];

      final sorted =
          _sortRated(children: children, results: results, seasonYear: 2025);

      // c2 has 50 season points, c1 has 0 → c2 first
      expect(sorted.first.id, equals('c2'));
    });
  });

  // ── TC-RATING-003: coachRankingProvider — групування по тренеру ───────────

  group('TC-RATING-003: coachRanking — сума totalPoints атлетів per coach', () {
    test('2 тренери з різними сумами → більша сума перша', () {
      final children = [
        _child(id: 'c1', lastName: 'A', totalPoints: 100, coachId: 'coach1'),
        _child(id: 'c2', lastName: 'B', totalPoints: 200, coachId: 'coach1'),
        _child(id: 'c3', lastName: 'C', totalPoints: 50, coachId: 'coach2'),
      ];

      final ranking = _coachRanking(children);

      expect(ranking, hasLength(2));
      expect(ranking.first.coachId, equals('coach1')); // 300
      expect(ranking.first.totalPoints, equals(300));
      expect(ranking.last.coachId, equals('coach2'));  // 50
    });

    test('порожній список атлетів → порожній рейтинг тренерів', () {
      final ranking = _coachRanking([]);
      expect(ranking, isEmpty);
    });

    test('всі атлети одного тренера → 1 запис у рейтингу', () {
      final children = [
        _child(id: 'c1', lastName: 'A', totalPoints: 100, coachId: 'coach1'),
        _child(id: 'c2', lastName: 'B', totalPoints: 150, coachId: 'coach1'),
      ];

      final ranking = _coachRanking(children);

      expect(ranking, hasLength(1));
      expect(ranking.first.totalPoints, equals(250));
    });

    test('3 тренери → сортування DESC', () {
      final children = [
        _child(id: 'c1', lastName: 'A', totalPoints: 50, coachId: 'coach3'),
        _child(id: 'c2', lastName: 'B', totalPoints: 300, coachId: 'coach1'),
        _child(id: 'c3', lastName: 'C', totalPoints: 150, coachId: 'coach2'),
      ];

      final ranking = _coachRanking(children);

      expect(ranking[0].coachId, equals('coach1')); // 300
      expect(ranking[1].coachId, equals('coach2')); // 150
      expect(ranking[2].coachId, equals('coach3')); // 50
    });

    test('атлет без очок → 0 до суми свого тренера', () {
      final children = [
        _child(id: 'c1', lastName: 'A', totalPoints: 0, coachId: 'coach1'),
        _child(id: 'c2', lastName: 'B', totalPoints: 0, coachId: 'coach1'),
      ];

      final ranking = _coachRanking(children);

      expect(ranking.first.totalPoints, equals(0));
    });
  });

  // ── TC-RATING-004: yearPoints не включає очки за інший рік ───────────────

  group('TC-RATING-004: фільтрація по року суворо', () {
    test('2024 і 2025 очки → yearPoints(2025) не включає 2024', () {
      final results = [
        _result(id: 'r1', childId: 'c1', points: 1000, seasonYear: 2024),
        _result(id: 'r2', childId: 'c1', points: 5, seasonYear: 2025),
      ];

      expect(_yearPoints('c1', 2025, results), equals(5));
      expect(_yearPoints('c1', 2024, results), equals(1000));
    });

    test('рейтинг за 2025 переставляє дітей порівняно з totalPoints', () {
      final children = [
        // c1 має більше totalPoints, але менше очок за 2025
        _child(id: 'c1', lastName: 'Стронг', totalPoints: 500),
        _child(id: 'c2', lastName: 'Новий', totalPoints: 10),
      ];
      final results = [
        _result(id: 'r1', childId: 'c1', points: 5, seasonYear: 2025),
        _result(id: 'r2', childId: 'c2', points: 100, seasonYear: 2025),
      ];

      final byTotal =
          _sortRated(children: children, results: results, seasonYear: null);
      final bySeason =
          _sortRated(children: children, results: results, seasonYear: 2025);

      // Without season: c1 (500 total) first
      expect(byTotal.first.id, equals('c1'));
      // With season: c2 (100 season) first
      expect(bySeason.first.id, equals('c2'));
    });
  });
}

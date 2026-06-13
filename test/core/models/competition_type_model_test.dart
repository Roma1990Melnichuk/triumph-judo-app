import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/competition_type_model.dart';

void main() {
  group('CompetitionTypeModel', () {
    // ── toFirestore ──────────────────────────────────────────────────────────

    group('toFirestore', () {
      test('містить name та createdByCoachId', () {
        const m = CompetitionTypeModel(
          id: 'ct1', name: 'Міський чемпіонат',
          createdByCoachId: 'coach1',
        );
        final map = m.toFirestore();
        expect(map['name'],             'Міський чемпіонат');
        expect(map['createdByCoachId'], 'coach1');
      });

      test('не включає null clubId', () {
        const m = CompetitionTypeModel(
          id: 'ct2', name: 'Кубок клубу',
          createdByCoachId: 'coach2',
        );
        expect(m.toFirestore().containsKey('clubId'), isFalse);
      });

      test('включає clubId якщо задано', () {
        const m = CompetitionTypeModel(
          id: 'ct3', name: 'Міжнародний',
          createdByCoachId: 'coach3',
          clubId: 'club_triumph',
        );
        expect(m.toFirestore()['clubId'], 'club_triumph');
      });
    });

    // ── fields ───────────────────────────────────────────────────────────────

    test('id та name зберігаються коректно', () {
      const m = CompetitionTypeModel(
        id: 'x', name: 'Обласний', createdByCoachId: 'c',
      );
      expect(m.id,   'x');
      expect(m.name, 'Обласний');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/body_measurement_model.dart';

void main() {
  group('BodyMeasurementModel', () {
    BodyMeasurementModel _m(DateTime dt, {double? kg, double? cm}) =>
        BodyMeasurementModel(
          id: '1', childId: 'c', measuredAt: dt,
          weightKg: kg, heightCm: cm,
        );

    // ── weekKey ─────────────────────────────────────────────────────────────

    group('weekKey', () {
      test('понеділок → той самий день', () {
        // 2025-06-09 is Monday
        final m = _m(DateTime(2025, 6, 9));
        expect(m.weekKey, '2025-06-09');
      });

      test('субота → попередній понеділок', () {
        // 2025-06-14 is Saturday → Monday is 2025-06-09
        final m = _m(DateTime(2025, 6, 14));
        expect(m.weekKey, '2025-06-09');
      });

      test('різні дні тієї самої тижня → однаковий weekKey', () {
        final mon = _m(DateTime(2025, 6, 9));
        final fri = _m(DateTime(2025, 6, 13));
        expect(mon.weekKey, fri.weekKey);
      });

      test('різні тижні → різний weekKey', () {
        final w1 = _m(DateTime(2025, 6, 9));
        final w2 = _m(DateTime(2025, 6, 16));
        expect(w1.weekKey, isNot(w2.weekKey));
      });
    });

    // ── toFirestore ──────────────────────────────────────────────────────────

    group('toFirestore', () {
      test('не включає null weightKg і heightCm', () {
        final m = _m(DateTime(2025), kg: 50.0);
        final map = m.toFirestore();
        expect(map.containsKey('weightKg'), isTrue);
        expect(map.containsKey('heightCm'), isFalse);
        expect(map['weightKg'], 50.0);
      });

      test('включає обидва значення якщо задані', () {
        final m = _m(DateTime(2025), kg: 45.0, cm: 152.0);
        final map = m.toFirestore();
        expect(map['weightKg'], 45.0);
        expect(map['heightCm'], 152.0);
      });
    });

    // ── copyWith ─────────────────────────────────────────────────────────────

    group('copyWith', () {
      test('оновлює тільки вказані поля', () {
        final m = _m(DateTime(2025), kg: 45.0, cm: 150.0);
        final m2 = m.copyWith(weightKg: 46.0);
        expect(m2.weightKg, 46.0);
        expect(m2.heightCm, 150.0); // незмінний
        expect(m.weightKg,  45.0);  // оригінал не змінився
      });
    });
  });
}

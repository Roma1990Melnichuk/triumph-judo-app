import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/water_log_model.dart';

void main() {
  group('WaterLogModel', () {
    WaterLogModel _log(DateTime dt) => WaterLogModel(
      id: '1', childId: 'c', amountMl: 250, loggedAt: dt,
    );

    test('dateKey формат YYYY-MM-DD', () {
      expect(_log(DateTime(2025, 3, 9)).dateKey, '2025-03-09');
    });

    test('однозначні числа доповнюються нулями', () {
      expect(_log(DateTime(2025, 1, 1)).dateKey, '2025-01-01');
    });

    test('різні дні → різний dateKey', () {
      final a = _log(DateTime(2025, 6, 7));
      final b = _log(DateTime(2025, 6, 8));
      expect(a.dateKey, isNot(b.dateKey));
    });

    test('та сама дата, різний час → однаковий dateKey', () {
      final a = _log(DateTime(2025, 6, 7, 8, 0));
      final b = _log(DateTime(2025, 6, 7, 23, 59));
      expect(a.dateKey, b.dateKey);
    });

    test('toFirestore містить childId і amountMl', () {
      final log = WaterLogModel(
        id: '1', childId: 'abc', amountMl: 500, loggedAt: DateTime(2025),
      );
      final map = log.toFirestore();
      expect(map['childId'],  'abc');
      expect(map['amountMl'], 500);
    });
  });
}

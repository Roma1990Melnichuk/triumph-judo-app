import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';

void main() {
  group('BeltLevel.displayName', () {
    test('кожен пояс має непорожній displayName', () {
      for (final b in BeltLevel.values) {
        expect(b.displayName, isNotEmpty,
            reason: '${b.name} має порожній displayName');
      }
    });

    test('white → Білий', () => expect(BeltLevel.white.displayName, 'Білий'));
    test('black → Чорний (Дан)', () => expect(BeltLevel.black.displayName, 'Чорний (Дан)'));
  });

  group('BeltLevel.next', () {
    test('white.next = whiteYellow', () {
      expect(BeltLevel.white.next, BeltLevel.whiteYellow);
    });

    test('brown.next = black', () {
      expect(BeltLevel.brown.next, BeltLevel.black);
    });

    test('black.next = null', () {
      expect(BeltLevel.black.next, isNull);
    });

    test('прогресія послідовна', () {
      final values = BeltLevel.values;
      for (var i = 0; i < values.length - 1; i++) {
        expect(values[i].next, values[i + 1]);
      }
    });
  });

  group('BeltLevel.isLast', () {
    test('тільки black є останнім', () {
      for (final b in BeltLevel.values) {
        expect(b.isLast, b == BeltLevel.black,
            reason: '${b.name}.isLast має бути ${b == BeltLevel.black}');
      }
    });
  });

  group('BeltLevel.color', () {
    test('кожен пояс має колір', () {
      for (final b in BeltLevel.values) {
        expect(b.color.value, isNonZero,
            reason: '${b.name} має нульовий колір');
      }
    });

    test('кольори різних поясів різні', () {
      final colors = BeltLevel.values.map((b) => b.color.value).toSet();
      expect(colors.length, BeltLevel.values.length);
    });
  });

  group('BeltLevel.abbreviation', () {
    test('кожен пояс має непорожнє скорочення', () {
      for (final b in BeltLevel.values) {
        expect(b.abbreviation, isNotEmpty);
      }
    });
  });

  group('BeltLevelX.fromString', () {
    test('парсить коректну назву', () {
      expect(BeltLevelX.fromString('yellow'), BeltLevel.yellow);
      expect(BeltLevelX.fromString('black'), BeltLevel.black);
      expect(BeltLevelX.fromString('white'), BeltLevel.white);
    });

    test('невідомий рядок → white', () {
      expect(BeltLevelX.fromString('unknown'), BeltLevel.white);
      expect(BeltLevelX.fromString(''), BeltLevel.white);
    });

    test('camelCase назви enum-a парсяться', () {
      expect(BeltLevelX.fromString('whiteYellow'), BeltLevel.whiteYellow);
      expect(BeltLevelX.fromString('orangeGreen'), BeltLevel.orangeGreen);
    });
  });

  group('BeltLevel.textColor', () {
    test('білий пояс має темний текст', () {
      expect(BeltLevel.white.textColor.value, isNonZero);
    });

    test('чорний пояс має білий текст', () {
      // black textColor = Colors.white
      expect(BeltLevel.black.textColor.value, 0xFFFFFFFF);
    });
  });
}

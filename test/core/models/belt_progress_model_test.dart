import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/belt_progress_model.dart';

void main() {
  BeltProgressModel makeProgress(Map<String, bool> passed) => BeltProgressModel(
        childId: 'child1',
        belt: BeltLevel.yellow,
        passed: passed,
      );

  group('BeltProgressModel.passedCount', () {
    test('0 коли всі false', () {
      final m = makeProgress({'e1': false, 'e2': false});
      expect(m.passedCount, 0);
    });

    test('рахує тільки true', () {
      final m = makeProgress({'e1': true, 'e2': false, 'e3': true});
      expect(m.passedCount, 2);
    });

    test('0 для порожньої мапи', () {
      expect(makeProgress({}).passedCount, 0);
    });
  });

  group('BeltProgressModel.isFullyPassed', () {
    test('true коли всі виконані', () {
      final m = makeProgress({'e1': true, 'e2': true});
      expect(m.isFullyPassed, isTrue);
    });

    test('false якщо хоча б одна не виконана', () {
      final m = makeProgress({'e1': true, 'e2': false});
      expect(m.isFullyPassed, isFalse);
    });

    test('false для порожньої мапи', () {
      expect(makeProgress({}).isFullyPassed, isFalse);
    });
  });

  group('BeltProgressModel.copyWith', () {
    test('оновлює passed', () {
      final m = makeProgress({'e1': false});
      final updated = m.copyWith(passed: {'e1': true});
      expect(updated.passed['e1'], isTrue);
      expect(updated.childId, m.childId);
      expect(updated.belt, m.belt);
    });

    test('не змінює оригінал', () {
      final m = makeProgress({'e1': false});
      m.copyWith(passed: {'e1': true});
      expect(m.passed['e1'], isFalse);
    });
  });

  group('BeltProgressModel.docId', () {
    test('формує правильний ID', () {
      final m = BeltProgressModel(
        childId: 'abc123',
        belt: BeltLevel.orange,
        passed: {},
      );
      expect(m.docId, 'abc123_orange');
    });
  });
}

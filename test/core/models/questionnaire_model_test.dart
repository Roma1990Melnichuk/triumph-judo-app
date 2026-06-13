import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/questionnaire_model.dart';

void main() {
  // ── QuestionType ──────────────────────────────────────────────────────────

  group('QuestionType', () {
    test('усі типи мають label', () {
      for (final t in QuestionType.values) {
        expect(t.label, isNotEmpty);
      }
    });

    test('fromString невідомий → text', () {
      expect(QuestionType.fromString('???'), QuestionType.text);
    });

    test('fromString "scale"', () {
      expect(QuestionType.fromString('scale'), QuestionType.scale);
    });
  });

  // ── QuestionDef ───────────────────────────────────────────────────────────

  group('QuestionDef', () {
    test('toMap / fromMap round-trip', () {
      const qd = QuestionDef(id: 'q1', text: 'Як справи?', type: QuestionType.yesNo);
      final map = qd.toMap();
      final back = QuestionDef.fromMap(map);
      expect(back.id,   qd.id);
      expect(back.text, qd.text);
      expect(back.type, qd.type);
    });
  });

  // ── QuestionAnswer ────────────────────────────────────────────────────────

  group('QuestionAnswer.displayValue', () {
    test('boolValue=true → "Так"', () {
      const a = QuestionAnswer(questionId: 'q1', boolValue: true);
      expect(a.displayValue, 'Так');
    });

    test('boolValue=false → "Ні"', () {
      const a = QuestionAnswer(questionId: 'q1', boolValue: false);
      expect(a.displayValue, 'Ні');
    });

    test('scaleValue=4 → "4 / 5"', () {
      const a = QuestionAnswer(questionId: 'q1', scaleValue: 4);
      expect(a.displayValue, '4 / 5');
    });

    test('textValue → повертає текст', () {
      const a = QuestionAnswer(questionId: 'q1', textValue: 'Добре');
      expect(a.displayValue, 'Добре');
    });

    test('без значення → "—"', () {
      const a = QuestionAnswer(questionId: 'q1');
      expect(a.displayValue, '—');
    });
  });

  // ── QuestionAnswer toMap ──────────────────────────────────────────────────

  group('QuestionAnswer.toMap', () {
    test('не включає null поля', () {
      const a = QuestionAnswer(questionId: 'q1', scaleValue: 3);
      final m = a.toMap();
      expect(m.containsKey('textValue'),  isFalse);
      expect(m.containsKey('boolValue'),  isFalse);
      expect(m['scaleValue'], 3);
    });
  });

  // ── QuestionnaireModel.copyWith ───────────────────────────────────────────

  group('QuestionnaireModel.copyWith', () {
    final q = QuestionnaireModel(
      id: '1', title: 'Т', description: 'Д',
      questions: const [], createdAt: DateTime(2025),
      coachId: 'c', isActive: true,
    );

    test('copyWith(isActive: false) змінює isActive', () {
      final q2 = q.copyWith(isActive: false);
      expect(q2.isActive,   isFalse);
      expect(q.isActive,    isTrue); // оригінал не змінився
    });
  });
}

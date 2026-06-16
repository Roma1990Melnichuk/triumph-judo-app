/// E2E тести для QuestionnaireNotifier — повний CRUD анкет + cross-role.
/// Покриває: createQuestionnaire, toggleActive, deleteQuestionnaire,
///           submitResponse, hasResponded,
///           cross-role: тренер створює → батько відповідає → тренер бачить відповідь.
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/models/questionnaire_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/questionnaires/providers/questionnaire_provider.dart';

// ── Хелпери ───────────────────────────────────────────────────────────────────

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

ProviderContainer _container(FakeFirebaseFirestore db) => ProviderContainer(
      overrides: [firestoreProvider.overrideWithValue(db)],
    );

const _questions = <QuestionDef>[
  QuestionDef(id: 'q1', text: 'Як самопочуття?', type: QuestionType.scale),
  QuestionDef(id: 'q2', text: 'Готовий тренуватись?', type: QuestionType.yesNo),
  QuestionDef(id: 'q3', text: 'Коментар', type: QuestionType.text),
];

Future<String> _createQ(
  ProviderContainer c, {
  String title = 'Анкета самопочуття',
  bool active = true,
}) =>
    c.read(questionnaireNotifierProvider.notifier).createQuestionnaire(
          title: title,
          description: 'Щотижнева перевірка',
          questions: _questions,
          coachId: 'coach1',
        );

// Seed questionnaire directly in Firestore (bypasses serverTimestamp issues)
Future<String> _seedQ(
  FakeFirebaseFirestore db, {
  String title = 'Анкета',
  bool isActive = true,
}) async {
  final ref = await db.collection('questionnaires').add({
    'title': title,
    'description': 'Тест',
    'questions': _questions.map((q) => q.toMap()).toList(),
    'createdAt': null, // serverTimestamp placeholder
    'coachId': 'coach1',
    'isActive': isActive,
  });
  return ref.id;
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── createQuestionnaire ───────────────────────────────────────────────────

  group('QuestionnaireNotifier — createQuestionnaire', () {
    test('зберігає анкету у Firestore і повертає ID', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final id = await _createQ(c);

      expect(id, isNotEmpty);
      final doc = await db.collection('questionnaires').doc(id).get();
      expect(doc.exists, isTrue);
      expect(doc['title'], 'Анкета самопочуття');
      expect(doc['coachId'], 'coach1');
      expect(doc['isActive'], isTrue);
    });

    test('зберігає всі три питання', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final id = await _createQ(c);
      final doc = await db.collection('questionnaires').doc(id).get();
      final questions = doc['questions'] as List;
      expect(questions, hasLength(3));
      expect(questions[0]['id'], 'q1');
      expect(questions[0]['type'], 'scale');
      expect(questions[1]['type'], 'yesNo');
      expect(questions[2]['type'], 'text');
    });

    test('стан = AsyncData після createQuestionnaire', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      await _createQ(c);
      expect(c.read(questionnaireNotifierProvider), isA<AsyncData<void>>());
    });

    test('дві анкети мають унікальні ID', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final id1 = await _createQ(c, title: 'Анкета 1');
      final id2 = await _createQ(c, title: 'Анкета 2');

      expect(id1, isNot(id2));
      expect((await db.collection('questionnaires').get()).docs, hasLength(2));
    });
  });

  // ── toggleActive ──────────────────────────────────────────────────────────

  group('QuestionnaireNotifier — toggleActive', () {
    test('активна → неактивна (true → false)', () async {
      final db = _db();
      final id = await _seedQ(db, isActive: true);
      final c = _container(db);
      addTearDown(c.dispose);

      final q = QuestionnaireModel(
        id: id,
        title: 'Анкета',
        description: '',
        questions: _questions,
        createdAt: DateTime(2025),
        coachId: 'coach1',
        isActive: true,
      );

      await c.read(questionnaireNotifierProvider.notifier).toggleActive(q);

      final doc = await db.collection('questionnaires').doc(id).get();
      expect(doc['isActive'], isFalse);
    });

    test('неактивна → активна (false → true)', () async {
      final db = _db();
      final id = await _seedQ(db, isActive: false);
      final c = _container(db);
      addTearDown(c.dispose);

      final q = QuestionnaireModel(
        id: id,
        title: 'Анкета',
        description: '',
        questions: _questions,
        createdAt: DateTime(2025),
        coachId: 'coach1',
        isActive: false,
      );

      await c.read(questionnaireNotifierProvider.notifier).toggleActive(q);

      final doc = await db.collection('questionnaires').doc(id).get();
      expect(doc['isActive'], isTrue);
    });

    test('toggleActive не зачіпає інші анкети', () async {
      final db = _db();
      final id1 = await _seedQ(db, title: 'Анкета 1', isActive: true);
      final id2 = await _seedQ(db, title: 'Анкета 2', isActive: true);
      final c = _container(db);
      addTearDown(c.dispose);

      final q1 = QuestionnaireModel(
        id: id1,
        title: 'Анкета 1',
        description: '',
        questions: _questions,
        createdAt: DateTime(2025),
        coachId: 'coach1',
        isActive: true,
      );
      await c.read(questionnaireNotifierProvider.notifier).toggleActive(q1);

      // Анкета 2 залишилась активною
      final doc2 = await db.collection('questionnaires').doc(id2).get();
      expect(doc2['isActive'], isTrue);
    });
  });

  // ── deleteQuestionnaire ───────────────────────────────────────────────────

  group('QuestionnaireNotifier — deleteQuestionnaire', () {
    test('видаляє анкету з Firestore', () async {
      final db = _db();
      final id = await _seedQ(db);
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(questionnaireNotifierProvider.notifier)
          .deleteQuestionnaire(id);

      expect(
          (await db.collection('questionnaires').doc(id).get()).exists,
          isFalse);
    });

    test('видаляє тільки потрібну — інші залишаються', () async {
      final db = _db();
      final id1 = await _seedQ(db, title: 'Видалити');
      final id2 = await _seedQ(db, title: 'Залишити');
      final c = _container(db);
      addTearDown(c.dispose);

      await c
          .read(questionnaireNotifierProvider.notifier)
          .deleteQuestionnaire(id1);

      expect(
          (await db.collection('questionnaires').doc(id1).get()).exists,
          isFalse);
      expect(
          (await db.collection('questionnaires').doc(id2).get()).exists,
          isTrue);
    });
  });

  // ── submitResponse ────────────────────────────────────────────────────────

  group('QuestionnaireNotifier — submitResponse', () {
    test('зберігає відповідь у questionnaire_responses', () async {
      final db = _db();
      final qId = await _seedQ(db);
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(questionnaireNotifierProvider.notifier).submitResponse(
            questionnaireId: qId,
            childId: 'kid1',
            childName: 'Іван Петренко',
            answers: const [
              QuestionAnswer(questionId: 'q1', scaleValue: 4),
              QuestionAnswer(questionId: 'q2', boolValue: true),
              QuestionAnswer(questionId: 'q3', textValue: 'Все добре'),
            ],
          );

      final snap = await db.collection('questionnaire_responses').get();
      expect(snap.docs, hasLength(1));
      final doc = snap.docs.first;
      expect(doc['questionnaireId'], qId);
      expect(doc['childId'], 'kid1');
      expect(doc['childName'], 'Іван Петренко');
      final answers = doc['answers'] as List;
      expect(answers, hasLength(3));
      expect(answers[0]['scaleValue'], 4);
      expect(answers[1]['boolValue'], isTrue);
      expect(answers[2]['textValue'], 'Все добре');
    });

    test('стан = AsyncData після submitResponse', () async {
      final db = _db();
      final qId = await _seedQ(db);
      final c = _container(db);
      addTearDown(c.dispose);

      await c.read(questionnaireNotifierProvider.notifier).submitResponse(
            questionnaireId: qId,
            childId: 'kid1',
            childName: 'Іван',
            answers: const [
              QuestionAnswer(questionId: 'q1', scaleValue: 3),
            ],
          );
      expect(c.read(questionnaireNotifierProvider), isA<AsyncData<void>>());
    });

    test('дві дитини можуть відповісти на одну анкету', () async {
      final db = _db();
      final qId = await _seedQ(db);
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(questionnaireNotifierProvider.notifier);
      await n.submitResponse(
        questionnaireId: qId,
        childId: 'kid1',
        childName: 'Іван',
        answers: const [QuestionAnswer(questionId: 'q1', scaleValue: 5)],
      );
      await n.submitResponse(
        questionnaireId: qId,
        childId: 'kid2',
        childName: 'Марія',
        answers: const [QuestionAnswer(questionId: 'q1', scaleValue: 3)],
      );

      final snap = await db.collection('questionnaire_responses').get();
      expect(snap.docs, hasLength(2));
    });
  });

  // ── hasResponded ──────────────────────────────────────────────────────────

  group('QuestionnaireNotifier — hasResponded', () {
    test('повертає false якщо відповіді немає', () async {
      final db = _db();
      final qId = await _seedQ(db);
      final c = _container(db);
      addTearDown(c.dispose);

      final result = await c
          .read(questionnaireNotifierProvider.notifier)
          .hasResponded(questionnaireId: qId, childId: 'kid1');
      expect(result, isFalse);
    });

    test('повертає true після submitResponse', () async {
      final db = _db();
      final qId = await _seedQ(db);
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(questionnaireNotifierProvider.notifier);
      await n.submitResponse(
        questionnaireId: qId,
        childId: 'kid1',
        childName: 'Іван',
        answers: const [QuestionAnswer(questionId: 'q1', scaleValue: 4)],
      );

      final result = await n.hasResponded(
          questionnaireId: qId, childId: 'kid1');
      expect(result, isTrue);
    });

    test('hasResponded для іншої дитини — false якщо не відповідала', () async {
      final db = _db();
      final qId = await _seedQ(db);
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(questionnaireNotifierProvider.notifier);
      await n.submitResponse(
        questionnaireId: qId,
        childId: 'kid1',
        childName: 'Іван',
        answers: const [QuestionAnswer(questionId: 'q1', scaleValue: 4)],
      );

      // kid2 ще не відповідав
      final result = await n.hasResponded(
          questionnaireId: qId, childId: 'kid2');
      expect(result, isFalse);
    });

    test('hasResponded для іншої анкети — false', () async {
      final db = _db();
      final qId1 = await _seedQ(db, title: 'Анкета 1');
      final qId2 = await _seedQ(db, title: 'Анкета 2');
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(questionnaireNotifierProvider.notifier);
      await n.submitResponse(
        questionnaireId: qId1,
        childId: 'kid1',
        childName: 'Іван',
        answers: const [QuestionAnswer(questionId: 'q1', scaleValue: 4)],
      );

      // kid1 не відповідав на qId2
      final result = await n.hasResponded(
          questionnaireId: qId2, childId: 'kid1');
      expect(result, isFalse);
    });
  });

  // ── Cross-role: тренер створює → батько відповідає → тренер бачить ────────

  group('Questionnaires — cross-role flow', () {
    test(
        'тренер: створює і активує анкету → батько відповідає → '
        'hasResponded=true → в Firestore є відповідь', () async {
      final db = _db();
      final coachC = _container(db);
      final parentC = _container(db);
      addTearDown(coachC.dispose);
      addTearDown(parentC.dispose);

      final cn = coachC.read(questionnaireNotifierProvider.notifier);
      final pn = parentC.read(questionnaireNotifierProvider.notifier);

      // 1. Тренер створює анкету (isActive=true за замовчуванням)
      final qId = await cn.createQuestionnaire(
        title: 'Анкета перед турніром',
        description: 'Готовність до змагань',
        questions: const [
          QuestionDef(id: 'q1', text: 'Самопочуття (1-5)', type: QuestionType.scale),
          QuestionDef(id: 'q2', text: 'Є травми?', type: QuestionType.yesNo),
        ],
        coachId: 'coach1',
      );
      expect(qId, isNotEmpty);

      // 2. Анкета активна — батько бачить її в activeQuestionnaires
      final activeSnap = await db
          .collection('questionnaires')
          .where('isActive', isEqualTo: true)
          .get();
      expect(activeSnap.docs, hasLength(1));
      expect(activeSnap.docs.first.id, qId);

      // 3. Батько перевіряє — ще не відповідав
      final notYet =
          await pn.hasResponded(questionnaireId: qId, childId: 'kid1');
      expect(notYet, isFalse);

      // 4. Батько відповідає
      await pn.submitResponse(
        questionnaireId: qId,
        childId: 'kid1',
        childName: 'Іван Петренко',
        answers: const [
          QuestionAnswer(questionId: 'q1', scaleValue: 5),
          QuestionAnswer(questionId: 'q2', boolValue: false),
        ],
      );

      // 5. hasResponded тепер true
      final alreadyDone =
          await pn.hasResponded(questionnaireId: qId, childId: 'kid1');
      expect(alreadyDone, isTrue);

      // 6. Тренер бачить відповідь у Firestore
      final responses = await db
          .collection('questionnaire_responses')
          .where('questionnaireId', isEqualTo: qId)
          .get();
      expect(responses.docs, hasLength(1));
      expect(responses.docs.first['childId'], 'kid1');
    });

    test('тренер деактивує анкету → вона не входить в активні', () async {
      final db = _db();
      final c = _container(db);
      addTearDown(c.dispose);

      final n = c.read(questionnaireNotifierProvider.notifier);

      // Тренер створює анкету (isActive=true)
      final qId = await n.createQuestionnaire(
        title: 'Анкета',
        description: '',
        questions: _questions,
        coachId: 'coach1',
      );

      // Деактивує
      final q = QuestionnaireModel(
        id: qId,
        title: 'Анкета',
        description: '',
        questions: _questions,
        createdAt: DateTime(2025),
        coachId: 'coach1',
        isActive: true,
      );
      await n.toggleActive(q);

      // Більше немає активних
      final activeSnap = await db
          .collection('questionnaires')
          .where('isActive', isEqualTo: true)
          .get();
      expect(activeSnap.docs, isEmpty);
    });

    test(
        'тренер: дві анкети → батько відповідає на одну → '
        'hasResponded=true тільки для неї', () async {
      final db = _db();
      final coachC = _container(db);
      final parentC = _container(db);
      addTearDown(coachC.dispose);
      addTearDown(parentC.dispose);

      final cn = coachC.read(questionnaireNotifierProvider.notifier);
      final pn = parentC.read(questionnaireNotifierProvider.notifier);

      final qId1 = await cn.createQuestionnaire(
        title: 'Анкета 1',
        description: '',
        questions: _questions,
        coachId: 'coach1',
      );
      final qId2 = await cn.createQuestionnaire(
        title: 'Анкета 2',
        description: '',
        questions: _questions,
        coachId: 'coach1',
      );

      await pn.submitResponse(
        questionnaireId: qId1,
        childId: 'kid1',
        childName: 'Іван',
        answers: const [QuestionAnswer(questionId: 'q1', scaleValue: 3)],
      );

      expect(
          await pn.hasResponded(questionnaireId: qId1, childId: 'kid1'),
          isTrue);
      expect(
          await pn.hasResponded(questionnaireId: qId2, childId: 'kid1'),
          isFalse);
    });
  });
}

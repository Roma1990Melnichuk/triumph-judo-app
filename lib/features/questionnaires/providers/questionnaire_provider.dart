import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/questionnaire_model.dart';

// ── Streams ───────────────────────────────────────────────────────────────────

final questionnairesProvider =
    StreamProvider<List<QuestionnaireModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('questionnaires')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(QuestionnaireModel.fromFirestore).toList());
});

final activeQuestionnairesProvider =
    StreamProvider<List<QuestionnaireModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('questionnaires')
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(QuestionnaireModel.fromFirestore).toList());
});

final questionnaireResponsesProvider =
    StreamProvider.family<List<QuestionnaireResponseModel>, String>(
        (ref, questionnaireId) {
  return FirebaseFirestore.instance
      .collection('questionnaire_responses')
      .where('questionnaireId', isEqualTo: questionnaireId)
      .orderBy('submittedAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map(QuestionnaireResponseModel.fromFirestore).toList());
});

final childResponsesProvider =
    StreamProvider.family<List<QuestionnaireResponseModel>, String>(
        (ref, childId) {
  return FirebaseFirestore.instance
      .collection('questionnaire_responses')
      .where('childId', isEqualTo: childId)
      .snapshots()
      .map((s) =>
          s.docs.map(QuestionnaireResponseModel.fromFirestore).toList());
});

// ── Notifier ──────────────────────────────────────────────────────────────────

final questionnaireNotifierProvider =
    StateNotifierProvider<QuestionnaireNotifier, AsyncValue<void>>(
        (ref) => QuestionnaireNotifier());

class QuestionnaireNotifier extends StateNotifier<AsyncValue<void>> {
  QuestionnaireNotifier() : super(const AsyncValue.data(null));

  final _db = FirebaseFirestore.instance;

  Future<String> createQuestionnaire({
    required String title,
    required String description,
    required List<QuestionDef> questions,
    required String coachId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final ref = await _db.collection('questionnaires').add(
        QuestionnaireModel(
          id: '', title: title, description: description,
          questions: questions, createdAt: DateTime.now(),
          coachId: coachId, isActive: true,
        ).toFirestore(),
      );
      state = const AsyncValue.data(null);
      return ref.id;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      rethrow;
    }
  }

  Future<void> toggleActive(QuestionnaireModel q) async {
    await _db.collection('questionnaires').doc(q.id)
        .update({'isActive': !q.isActive});
    state = const AsyncValue.data(null);
  }

  Future<void> deleteQuestionnaire(String id) async {
    await _db.collection('questionnaires').doc(id).delete();
  }

  Future<void> submitResponse({
    required String questionnaireId,
    required String childId,
    required String childName,
    required List<QuestionAnswer> answers,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _db.collection('questionnaire_responses').add(
        QuestionnaireResponseModel(
          id: '', questionnaireId: questionnaireId,
          childId: childId, childName: childName,
          answers: answers, submittedAt: DateTime.now(),
        ).toFirestore(),
      );
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      rethrow;
    }
  }

  // Check if this child already submitted a response for a questionnaire
  Future<bool> hasResponded({
    required String questionnaireId,
    required String childId,
  }) async {
    final snap = await _db
        .collection('questionnaire_responses')
        .where('questionnaireId', isEqualTo: questionnaireId)
        .where('childId', isEqualTo: childId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }
}

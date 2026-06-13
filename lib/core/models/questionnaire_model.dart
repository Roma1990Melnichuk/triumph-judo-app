import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionType {
  text, yesNo, scale;

  String get label => switch (this) {
    QuestionType.text   => 'Текстова відповідь',
    QuestionType.yesNo  => 'Так / Ні',
    QuestionType.scale  => 'Оцінка 1–5',
  };

  static QuestionType fromString(String v) =>
      QuestionType.values.firstWhere((e) => e.name == v,
          orElse: () => QuestionType.text);
}

class QuestionDef {
  const QuestionDef({
    required this.id,
    required this.text,
    required this.type,
  });

  final String       id;
  final String       text;
  final QuestionType type;

  factory QuestionDef.fromMap(Map<String, dynamic> m) => QuestionDef(
    id:   m['id']   as String? ?? '',
    text: m['text'] as String? ?? '',
    type: QuestionType.fromString(m['type'] as String? ?? ''),
  );

  Map<String, dynamic> toMap() => {
    'id':   id,
    'text': text,
    'type': type.name,
  };
}

class QuestionnaireModel {
  const QuestionnaireModel({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    required this.createdAt,
    required this.coachId,
    required this.isActive,
  });

  final String           id;
  final String           title;
  final String           description;
  final List<QuestionDef> questions;
  final DateTime         createdAt;
  final String           coachId;
  final bool             isActive;

  factory QuestionnaireModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return QuestionnaireModel(
      id:          doc.id,
      title:       d['title']       as String? ?? '',
      description: d['description'] as String? ?? '',
      questions:   (d['questions']  as List? ?? [])
          .map((q) => QuestionDef.fromMap(q as Map<String, dynamic>))
          .toList(),
      createdAt:   (d['createdAt']  as Timestamp?)?.toDate() ?? DateTime.now(),
      coachId:     d['coachId']     as String? ?? '',
      isActive:    d['isActive']    as bool?   ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title':       title,
    'description': description,
    'questions':   questions.map((q) => q.toMap()).toList(),
    'createdAt':   FieldValue.serverTimestamp(),
    'coachId':     coachId,
    'isActive':    isActive,
  };

  QuestionnaireModel copyWith({bool? isActive}) => QuestionnaireModel(
    id: id, title: title, description: description,
    questions: questions, createdAt: createdAt, coachId: coachId,
    isActive: isActive ?? this.isActive,
  );
}

// ── Response ──────────────────────────────────────────────────────────────────

class QuestionAnswer {
  const QuestionAnswer({
    required this.questionId,
    this.textValue,
    this.boolValue,
    this.scaleValue,
  });

  final String  questionId;
  final String? textValue;
  final bool?   boolValue;
  final int?    scaleValue; // 1–5

  factory QuestionAnswer.fromMap(Map<String, dynamic> m) => QuestionAnswer(
    questionId: m['questionId'] as String? ?? '',
    textValue:  m['textValue']  as String?,
    boolValue:  m['boolValue']  as bool?,
    scaleValue: m['scaleValue'] as int?,
  );

  Map<String, dynamic> toMap() => {
    'questionId': questionId,
    if (textValue  != null) 'textValue':  textValue,
    if (boolValue  != null) 'boolValue':  boolValue,
    if (scaleValue != null) 'scaleValue': scaleValue,
  };

  String get displayValue {
    if (textValue  != null) return textValue!;
    if (boolValue  != null) return boolValue! ? 'Так' : 'Ні';
    if (scaleValue != null) return '$scaleValue / 5';
    return '—';
  }
}

class QuestionnaireResponseModel {
  const QuestionnaireResponseModel({
    required this.id,
    required this.questionnaireId,
    required this.childId,
    required this.childName,
    required this.answers,
    required this.submittedAt,
  });

  final String               id;
  final String               questionnaireId;
  final String               childId;
  final String               childName;
  final List<QuestionAnswer> answers;
  final DateTime             submittedAt;

  factory QuestionnaireResponseModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return QuestionnaireResponseModel(
      id:               doc.id,
      questionnaireId:  d['questionnaireId'] as String? ?? '',
      childId:          d['childId']         as String? ?? '',
      childName:        d['childName']       as String? ?? '',
      answers:          (d['answers']        as List? ?? [])
          .map((a) => QuestionAnswer.fromMap(a as Map<String, dynamic>))
          .toList(),
      submittedAt: (d['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'questionnaireId': questionnaireId,
    'childId':         childId,
    'childName':       childName,
    'answers':         answers.map((a) => a.toMap()).toList(),
    'submittedAt':     FieldValue.serverTimestamp(),
  };
}

import 'package:cloud_firestore/cloud_firestore.dart';

enum TipCategory {
  general, preTrain, postTrain, hydration, recovery;

  String get label => switch (this) {
    TipCategory.general   => 'Загальне',
    TipCategory.preTrain  => 'До тренування',
    TipCategory.postTrain => 'Після тренування',
    TipCategory.hydration => 'Гідратація',
    TipCategory.recovery  => 'Відновлення',
  };

  static TipCategory fromString(String v) =>
      TipCategory.values.firstWhere((e) => e.name == v, orElse: () => TipCategory.general);
}

class NutritionTipModel {
  const NutritionTipModel({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    this.imageUrl,
    required this.publishedAt,
    required this.coachId,
    required this.readBy,
  });

  final String       id;
  final String       title;
  final String       body;
  final TipCategory  category;
  final String?      imageUrl;
  final DateTime     publishedAt;
  final String       coachId;
  final List<String> readBy;

  bool isReadBy(String childId) => readBy.contains(childId);

  factory NutritionTipModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NutritionTipModel(
      id:          doc.id,
      title:       d['title']       as String? ?? '',
      body:        d['body']        as String? ?? '',
      category:    TipCategory.fromString(d['category'] as String? ?? ''),
      imageUrl:    d['imageUrl']    as String?,
      publishedAt: (d['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      coachId:     d['coachId']     as String? ?? '',
      readBy:      List<String>.from(d['readBy'] as List? ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title':       title,
    'body':        body,
    'category':    category.name,
    'imageUrl':    imageUrl,
    'publishedAt': Timestamp.fromDate(publishedAt),
    'coachId':     coachId,
    'readBy':      readBy,
  };

  NutritionTipModel copyWithReadBy(List<String> readBy) => NutritionTipModel(
    id: id, title: title, body: body, category: category,
    imageUrl: imageUrl, publishedAt: publishedAt, coachId: coachId,
    readBy: readBy,
  );
}

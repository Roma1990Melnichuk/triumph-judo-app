import 'package:cloud_firestore/cloud_firestore.dart';

enum MealType {
  breakfast, snack, lunch, supper, dinner;

  String get label => switch (this) {
    MealType.breakfast => 'Сніданок',
    MealType.snack     => 'Перекус',
    MealType.lunch     => 'Обід',
    MealType.supper    => 'Полудень',
    MealType.dinner    => 'Вечеря',
  };

  static MealType fromString(String v) =>
      MealType.values.firstWhere((e) => e.name == v, orElse: () => MealType.breakfast);
}

enum MealStatus {
  done, skipped, pending;

  static MealStatus fromString(String v) =>
      MealStatus.values.firstWhere((e) => e.name == v, orElse: () => MealStatus.pending);
}

class MealModel {
  const MealModel({
    required this.id,
    required this.childId,
    required this.type,
    required this.date,
    this.photoUrl,
    required this.mealName,
    required this.hasProtein,
    required this.hasVegetables,
    required this.hasCarbs,
    required this.hasFruits,
    required this.hadWater,
    this.calories,
    required this.comment,
    required this.status,
    required this.createdAt,
  });

  final String     id;
  final String     childId;
  final MealType   type;
  final DateTime   date;
  final String?    photoUrl;
  final String     mealName;
  final bool       hasProtein;
  final bool       hasVegetables;
  final bool       hasCarbs;
  final bool       hasFruits;
  final bool       hadWater;
  final int?       calories;
  final String     comment;
  final MealStatus status;
  final DateTime   createdAt;

  String get dateKey {
    final d = date.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  double get plateScore {
    int score = 0;
    if (hasProtein)    score++;
    if (hasVegetables) score++;
    if (hasCarbs)      score++;
    if (hasFruits)     score++;
    if (hadWater)      score++;
    return score / 5.0;
  }

  factory MealModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MealModel(
      id:            doc.id,
      childId:       d['childId']       as String? ?? '',
      type:          MealType.fromString(d['type'] as String? ?? ''),
      date:          (d['date']         as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl:      d['photoUrl']      as String?,
      mealName:      d['mealName']      as String? ?? '',
      hasProtein:    d['hasProtein']    as bool? ?? false,
      hasVegetables: d['hasVegetables'] as bool? ?? false,
      hasCarbs:      d['hasCarbs']      as bool? ?? false,
      hasFruits:     d['hasFruits']     as bool? ?? false,
      hadWater:      d['hadWater']      as bool? ?? false,
      calories:      d['calories']      as int?,
      comment:       d['comment']       as String? ?? '',
      status:        MealStatus.fromString(d['status'] as String? ?? 'done'),
      createdAt:     (d['createdAt']    as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'childId':       childId,
    'type':          type.name,
    'date':          Timestamp.fromDate(date),
    'photoUrl':      photoUrl,
    'mealName':      mealName,
    'hasProtein':    hasProtein,
    'hasVegetables': hasVegetables,
    'hasCarbs':      hasCarbs,
    'hasFruits':     hasFruits,
    'hadWater':      hadWater,
    'calories':      calories,
    'comment':       comment,
    'status':        status.name,
    'createdAt':     FieldValue.serverTimestamp(),
  };

  MealModel copyWith({
    MealType? type, String? photoUrl, String? mealName,
    bool? hasProtein, bool? hasVegetables, bool? hasCarbs,
    bool? hasFruits, bool? hadWater, int? calories,
    String? comment, MealStatus? status,
  }) =>
      MealModel(
        id: id, childId: childId, date: date, createdAt: createdAt,
        type:          type          ?? this.type,
        photoUrl:      photoUrl      ?? this.photoUrl,
        mealName:      mealName      ?? this.mealName,
        hasProtein:    hasProtein    ?? this.hasProtein,
        hasVegetables: hasVegetables ?? this.hasVegetables,
        hasCarbs:      hasCarbs      ?? this.hasCarbs,
        hasFruits:     hasFruits     ?? this.hasFruits,
        hadWater:      hadWater      ?? this.hadWater,
        calories:      calories      ?? this.calories,
        comment:       comment       ?? this.comment,
        status:        status        ?? this.status,
      );
}

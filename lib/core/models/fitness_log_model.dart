import 'package:cloud_firestore/cloud_firestore.dart';

enum FitnessdifficultY { easy, medium, hard }

extension FitnessDifficultyX on FitnessdifficultY {
  String get label {
    switch (this) {
      case FitnessdifficultY.easy:   return 'Легко';
      case FitnessdifficultY.medium: return 'Середньо';
      case FitnessdifficultY.hard:   return 'Важко';
    }
  }

  static FitnessdifficultY fromInt(int v) {
    switch (v) {
      case 2:  return FitnessdifficultY.medium;
      case 3:  return FitnessdifficultY.hard;
      default: return FitnessdifficultY.easy;
    }
  }

  int get intValue {
    switch (this) {
      case FitnessdifficultY.easy:   return 1;
      case FitnessdifficultY.medium: return 2;
      case FitnessdifficultY.hard:   return 3;
    }
  }
}

class FitnessLog {
  final String id;
  final String childId;
  final String exerciseId;
  final String exerciseName;
  final String exerciseUnit;
  final DateTime date;
  final double value;
  final String comment;
  final int difficulty;

  const FitnessLog({
    required this.id,
    required this.childId,
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseUnit,
    required this.date,
    required this.value,
    required this.comment,
    required this.difficulty,
  });

  factory FitnessLog.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FitnessLog(
      id: doc.id,
      childId: d['childId'] as String? ?? '',
      exerciseId: d['exerciseId'] as String? ?? '',
      exerciseName: d['exerciseName'] as String? ?? '',
      exerciseUnit: d['exerciseUnit'] as String? ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      value: (d['value'] as num?)?.toDouble() ?? 0,
      comment: d['comment'] as String? ?? '',
      difficulty: d['difficulty'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'childId': childId,
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'exerciseUnit': exerciseUnit,
    'date': Timestamp.fromDate(date),
    'value': value,
    'comment': comment,
    'difficulty': difficulty,
  };
}

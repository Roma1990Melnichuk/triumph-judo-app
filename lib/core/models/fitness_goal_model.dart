import 'package:cloud_firestore/cloud_firestore.dart';

class FitnessGoal {
  final String id;
  final String childId;
  final String exerciseId;
  final String exerciseName;
  final String exerciseUnit;
  final double targetValue;
  final DateTime deadline;
  final bool isAchieved;

  const FitnessGoal({
    required this.id,
    required this.childId,
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseUnit,
    required this.targetValue,
    required this.deadline,
    required this.isAchieved,
  });

  factory FitnessGoal.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FitnessGoal(
      id: doc.id,
      childId: d['childId'] as String? ?? '',
      exerciseId: d['exerciseId'] as String? ?? '',
      exerciseName: d['exerciseName'] as String? ?? '',
      exerciseUnit: d['exerciseUnit'] as String? ?? '',
      targetValue: (d['targetValue'] as num?)?.toDouble() ?? 0,
      deadline: (d['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAchieved: d['isAchieved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'childId': childId,
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'exerciseUnit': exerciseUnit,
    'targetValue': targetValue,
    'deadline': Timestamp.fromDate(deadline),
    'isAchieved': isAchieved,
  };
}

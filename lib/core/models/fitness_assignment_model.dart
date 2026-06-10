import 'package:cloud_firestore/cloud_firestore.dart';

enum AssignmentStatus { active, draft, completed }

class FitnessAssignment {
  final String id;
  final String coachId;
  final String title;
  final String exerciseId;
  final String exerciseName;
  final String exerciseUnit;
  final double targetValue;
  final DateTime startDate;
  final DateTime deadline;
  final List<String> assignedChildIds;
  final AssignmentStatus status;
  final String coachComment;
  final bool isCumulative; // FIT-01 Fix: true for reps (sum), false for time/max (peak)

  const FitnessAssignment({
    required this.id,
    required this.coachId,
    required this.title,
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseUnit,
    required this.targetValue,
    required this.startDate,
    required this.deadline,
    required this.assignedChildIds,
    this.status = AssignmentStatus.active,
    this.coachComment = '',
    this.isCumulative = true,
  });

  bool get isActive =>
      status != AssignmentStatus.draft &&
      status != AssignmentStatus.completed &&
      DateTime.now().isBefore(deadline);

  bool get isExpired =>
      status == AssignmentStatus.completed ||
      (status != AssignmentStatus.draft &&
          DateTime.now().isAfter(deadline));

  factory FitnessAssignment.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final statusStr = d['status'] as String? ?? 'active';
    final status = AssignmentStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => AssignmentStatus.active,
    );
    return FitnessAssignment(
      id: doc.id,
      coachId: d['coachId'] as String? ?? '',
      title: d['title'] as String? ?? '',
      exerciseId: d['exerciseId'] as String? ?? '',
      exerciseName: d['exerciseName'] as String? ?? '',
      exerciseUnit: d['exerciseUnit'] as String? ?? 'рази',
      targetValue: (d['targetValue'] as num?)?.toDouble() ?? 0,
      startDate: (d['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deadline: (d['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedChildIds:
          (d['assignedChildIds'] as List<dynamic>? ?? []).cast<String>(),
      status: status,
      coachComment: d['coachComment'] as String? ?? '',
      isCumulative: d['isCumulative'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'coachId': coachId,
        'title': title,
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'exerciseUnit': exerciseUnit,
        'targetValue': targetValue,
        'startDate': Timestamp.fromDate(startDate),
        'deadline': Timestamp.fromDate(deadline),
        'assignedChildIds': assignedChildIds,
        'status': status.name,
        'coachComment': coachComment,
        'isCumulative': isCumulative,
      };
}

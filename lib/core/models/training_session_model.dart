import 'package:cloud_firestore/cloud_firestore.dart';

/// Single training session with per-child attendance.
/// ID format: "scheduleId_YYYY-MM-DD"
class TrainingSessionModel {
  final String id;
  final String scheduleId;
  final String coachId;
  final DateTime date;
  /// childId → present (true=came, false=absent). Missing key = present by default.
  final Map<String, bool> attendance;

  const TrainingSessionModel({
    required this.id,
    required this.scheduleId,
    required this.coachId,
    required this.date,
    required this.attendance,
  });

  static String makeId(String scheduleId, DateTime date) {
    final d = '${date.year.toString().padLeft(4,'0')}-'
        '${date.month.toString().padLeft(2,'0')}-'
        '${date.day.toString().padLeft(2,'0')}';
    return '${scheduleId}_$d';
  }

  /// Returns true when childId is present (default = true when not in map).
  bool isPresent(String childId) => attendance[childId] ?? true;

  factory TrainingSessionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TrainingSessionModel(
      id: doc.id,
      scheduleId: d['scheduleId'] as String? ?? '',
      coachId: d['coachId'] as String? ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attendance: (d['attendance'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v as bool)),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'scheduleId': scheduleId,
    'coachId': coachId,
    'date': Timestamp.fromDate(date),
    'attendance': attendance,
  };
}

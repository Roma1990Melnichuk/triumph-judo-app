import 'package:cloud_firestore/cloud_firestore.dart';

/// Stores ABSENCES only — default is present.
/// Doc ID: "{groupId}_{YYYY-MM-DD}"
class AttendanceModel {
  final String id;
  final String groupId;
  final String coachId;
  final DateTime date;
  final List<String> absentChildIds;

  const AttendanceModel({
    required this.id,
    required this.groupId,
    required this.coachId,
    required this.date,
    required this.absentChildIds,
  });

  bool isPresent(String childId) => !absentChildIds.contains(childId);

  static String makeId(String groupId, DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${groupId}_$y-$m-$d';
  }

  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      groupId: d['groupId'] as String? ?? '',
      coachId: d['coachId'] as String? ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      absentChildIds: (d['absentChildIds'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'groupId': groupId,
        'coachId': coachId,
        'date': Timestamp.fromDate(date),
        'absentChildIds': absentChildIds,
      };
}

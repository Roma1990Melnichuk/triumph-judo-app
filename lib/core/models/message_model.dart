import 'package:cloud_firestore/cloud_firestore.dart';

class ParentMessageModel {
  final String id;
  final String fromParentId;
  final String fromParentName;
  final String toCoachId;
  final String body;
  final DateTime sentAt;
  final bool readByCoach;

  const ParentMessageModel({
    required this.id,
    required this.fromParentId,
    required this.fromParentName,
    required this.toCoachId,
    required this.body,
    required this.sentAt,
    this.readByCoach = false,
  });

  factory ParentMessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ParentMessageModel(
      id: doc.id,
      fromParentId: d['fromParentId'] as String? ?? '',
      fromParentName: d['fromParentName'] as String? ?? '',
      toCoachId: d['toCoachId'] as String? ?? '',
      body: d['body'] as String? ?? '',
      sentAt: (d['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readByCoach: d['readByCoach'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'fromParentId': fromParentId,
        'fromParentName': fromParentName,
        'toCoachId': toCoachId,
        'body': body,
        'sentAt': Timestamp.fromDate(sentAt),
        'readByCoach': readByCoach,
      };
}

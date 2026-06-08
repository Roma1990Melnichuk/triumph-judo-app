import 'package:cloud_firestore/cloud_firestore.dart';

class CompetitionTypeModel {
  final String id;
  final String name;
  final String createdByCoachId;
  final String? clubId;

  const CompetitionTypeModel({
    required this.id,
    required this.name,
    required this.createdByCoachId,
    this.clubId,
  });

  factory CompetitionTypeModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CompetitionTypeModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      createdByCoachId: d['createdByCoachId'] as String? ?? '',
      clubId: d['clubId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'createdByCoachId': createdByCoachId,
        if (clubId != null) 'clubId': clubId,
      };
}

import 'package:cloud_firestore/cloud_firestore.dart';

class WaterLogModel {
  const WaterLogModel({
    required this.id,
    required this.childId,
    required this.amountMl,
    required this.loggedAt,
  });

  final String   id;
  final String   childId;
  final int      amountMl;
  final DateTime loggedAt;

  String get dateKey {
    final d = loggedAt.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  factory WaterLogModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WaterLogModel(
      id:       doc.id,
      childId:  d['childId']  as String? ?? '',
      amountMl: d['amountMl'] as int?    ?? 0,
      loggedAt: (d['loggedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'childId':  childId,
    'amountMl': amountMl,
    'loggedAt': FieldValue.serverTimestamp(),
  };
}

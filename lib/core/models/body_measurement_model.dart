import 'package:cloud_firestore/cloud_firestore.dart';

class BodyMeasurementModel {
  const BodyMeasurementModel({
    required this.id,
    required this.childId,
    required this.measuredAt,
    this.weightKg,
    this.heightCm,
  });

  final String   id;
  final String   childId;
  final DateTime measuredAt;
  final double?  weightKg;
  final double?  heightCm;

  String get weekKey {
    final d = measuredAt.toLocal();
    final monday = d.subtract(Duration(days: d.weekday - 1));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  factory BodyMeasurementModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BodyMeasurementModel(
      id:         doc.id,
      childId:    d['childId']    as String? ?? '',
      measuredAt: (d['measuredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weightKg:   (d['weightKg']  as num?)?.toDouble(),
      heightCm:   (d['heightCm']  as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'childId':    childId,
    'measuredAt': Timestamp.fromDate(measuredAt),
    if (weightKg != null) 'weightKg': weightKg,
    if (heightCm != null) 'heightCm': heightCm,
  };

  BodyMeasurementModel copyWith({double? weightKg, double? heightCm}) =>
      BodyMeasurementModel(
        id: id, childId: childId, measuredAt: measuredAt,
        weightKg: weightKg ?? this.weightKg,
        heightCm: heightCm ?? this.heightCm,
      );
}

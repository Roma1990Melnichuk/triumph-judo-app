import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/belt_levels.dart';

class BeltProgressModel {
  final String childId;
  final BeltLevel belt;
  final Map<String, bool> passed; // exerciseId -> passed
  final DateTime? completedAt;

  const BeltProgressModel({
    required this.childId,
    required this.belt,
    required this.passed,
    this.completedAt,
  });

  String get docId => '${childId}_${belt.name}';

  bool get isFullyPassed =>
      passed.isNotEmpty && passed.values.every((v) => v);

  int get passedCount => passed.values.where((v) => v).length;
  int get totalCount => passed.length;

  factory BeltProgressModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final parts = doc.id.split('_');
    final childId = parts.length > 1 ? parts.sublist(0, parts.length - 1).join('_') : parts[0];
    final beltName = parts.last;
    final passedMap = (d['passed'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v as bool));
    return BeltProgressModel(
      childId: childId,
      belt: BeltLevelX.fromString(beltName),
      passed: passedMap,
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'childId': childId,
        'belt': belt.name,
        'passed': passed,
        if (completedAt != null)
          'completedAt': Timestamp.fromDate(completedAt!),
      };

  BeltProgressModel copyWith({
    Map<String, bool>? passed,
    DateTime? completedAt,
  }) =>
      BeltProgressModel(
        childId: childId,
        belt: belt,
        passed: passed ?? Map.from(this.passed),
        completedAt: completedAt ?? this.completedAt,
      );
}

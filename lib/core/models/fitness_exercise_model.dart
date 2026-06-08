import 'package:cloud_firestore/cloud_firestore.dart';

const _kDefaults = [
  ('pushups',  'Відтискання',  'рази'),
  ('pullups',  'Підтягування', 'рази'),
  ('abs',      'Прес',         'рази'),
  ('plank',    'Планка',       'секунди'),
  ('jumprope', 'Скакалка',     'рази'),
  ('squats',   'Присідання',   'рази'),
  ('burpees',  'Берпі',        'рази'),
  ('sprint',   '100м',         'секунди'),
  ('longrun',  '1000м',        'секунди'),
];

class FitnessExercise {
  final String id;
  final String name;
  final String unit;
  final bool isDefault;

  const FitnessExercise({
    required this.id,
    required this.name,
    required this.unit,
    required this.isDefault,
  });

  factory FitnessExercise.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FitnessExercise(
      id: doc.id,
      name: d['name'] as String? ?? '',
      unit: d['unit'] as String? ?? 'рази',
      isDefault: d['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'unit': unit,
    'isDefault': isDefault,
  };

  static List<FitnessExercise> get defaults => _kDefaults
      .map((t) => FitnessExercise(id: t.$1, name: t.$2, unit: t.$3, isDefault: true))
      .toList();
}

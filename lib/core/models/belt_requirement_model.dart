import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/belt_levels.dart';

// ── Exercise categories ───────────────────────────────────────────────────────

enum ExerciseCategory {
  technique,
  physical,
  theory,
  competition;

  String get displayName {
    switch (this) {
      case ExerciseCategory.technique:    return 'Техніка';
      case ExerciseCategory.physical:     return 'Фізична підготовка';
      case ExerciseCategory.theory:       return 'Теорія';
      case ExerciseCategory.competition:  return 'Змагання';
    }
  }

  static ExerciseCategory fromString(String? s) {
    switch (s) {
      case 'physical':    return ExerciseCategory.physical;
      case 'theory':      return ExerciseCategory.theory;
      case 'competition': return ExerciseCategory.competition;
      default:            return ExerciseCategory.technique;
    }
  }
}

// ── Exercise ──────────────────────────────────────────────────────────────────

class Exercise {
  final String id;
  final String name;
  final String description;
  final ExerciseCategory category;
  final String videoUrl;

  const Exercise({
    required this.id,
    required this.name,
    this.description = '',
    this.category = ExerciseCategory.technique,
    this.videoUrl = '',
  });

  factory Exercise.fromMap(Map<String, dynamic> m) => Exercise(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
        description: m['description'] as String? ?? '',
        category: ExerciseCategory.fromString(m['category'] as String?),
        videoUrl: m['videoUrl'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category.name,
        'videoUrl': videoUrl,
      };

  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    ExerciseCategory? category,
    String? videoUrl,
  }) =>
      Exercise(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        category: category ?? this.category,
        videoUrl: videoUrl ?? this.videoUrl,
      );
}

// ── Belt requirement ──────────────────────────────────────────────────────────

class BeltRequirementModel {
  final BeltLevel belt;
  final List<Exercise> exercises;
  final String description;
  final String level; // e.g. "4 – 2 кю"
  final DateTime updatedAt;
  final String updatedByCoachId;

  const BeltRequirementModel({
    required this.belt,
    required this.exercises,
    this.description = '',
    this.level = '',
    required this.updatedAt,
    required this.updatedByCoachId,
  });

  /// Exercises grouped by category (all 4 categories always present, may be empty)
  Map<ExerciseCategory, List<Exercise>> get byCategory {
    final result = <ExerciseCategory, List<Exercise>>{};
    for (final cat in ExerciseCategory.values) {
      result[cat] = exercises.where((e) => e.category == cat).toList();
    }
    return result;
  }

  factory BeltRequirementModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final exercisesList = (d['exercises'] as List<dynamic>? ?? [])
        .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
        .toList();
    return BeltRequirementModel(
      belt: BeltLevelX.fromString(doc.id),
      exercises: exercisesList,
      description: d['description'] as String? ?? '',
      level: d['level'] as String? ?? '',
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedByCoachId: d['updatedByCoachId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'exercises': exercises.map((e) => e.toMap()).toList(),
        'description': description,
        'level': level,
        'updatedAt': Timestamp.fromDate(updatedAt),
        'updatedByCoachId': updatedByCoachId,
      };

  BeltRequirementModel copyWith({
    List<Exercise>? exercises,
    String? description,
    String? level,
  }) =>
      BeltRequirementModel(
        belt: belt,
        exercises: exercises ?? this.exercises,
        description: description ?? this.description,
        level: level ?? this.level,
        updatedAt: DateTime.now(),
        updatedByCoachId: updatedByCoachId,
      );
}

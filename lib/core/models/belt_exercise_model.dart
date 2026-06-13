import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/belt_levels.dart';

enum ExerciseCategory {
  throws, groundwork, ukemi, conditioning, kata;

  String get label => switch (this) {
    ExerciseCategory.throws      => 'Кидки (Nage-waza)',
    ExerciseCategory.groundwork  => 'Боротьба лежачи (Ne-waza)',
    ExerciseCategory.ukemi       => 'Падіння (Ukemi)',
    ExerciseCategory.conditioning => 'Фізична підготовка',
    ExerciseCategory.kata        => 'Ката',
  };

  String get emoji => switch (this) {
    ExerciseCategory.throws      => '🥋',
    ExerciseCategory.groundwork  => '🤸',
    ExerciseCategory.ukemi       => '🛡️',
    ExerciseCategory.conditioning => '💪',
    ExerciseCategory.kata        => '🎌',
  };

  static ExerciseCategory fromString(String v) =>
      ExerciseCategory.values.firstWhere((e) => e.name == v,
          orElse: () => ExerciseCategory.throws);
}

class BeltExerciseModel {
  const BeltExerciseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.forBelts,
    this.videoUrl,
    required this.isDefault,
  });

  final String            id;
  final String            name;
  final String            description;
  final ExerciseCategory  category;
  final List<BeltLevel>   forBelts;
  final String?           videoUrl;
  final bool              isDefault;

  factory BeltExerciseModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BeltExerciseModel(
      id:          doc.id,
      name:        d['name']        as String? ?? '',
      description: d['description'] as String? ?? '',
      category:    ExerciseCategory.fromString(d['category'] as String? ?? ''),
      forBelts:    (d['forBelts']   as List? ?? [])
          .map((b) => BeltLevel.values.firstWhere(
                (e) => e.name == b,
                orElse: () => BeltLevel.white))
          .toList(),
      videoUrl:    d['videoUrl']    as String?,
      isDefault:   d['isDefault']   as bool?   ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name':        name,
    'description': description,
    'category':    category.name,
    'forBelts':    forBelts.map((b) => b.name).toList(),
    'videoUrl':    videoUrl,
    'isDefault':   isDefault,
  };

  // ── Default exercises seeded on first load ──────────────────────────────────
  static const defaults = <BeltExerciseModel>[
    BeltExerciseModel(
      id: 'mae_ukemi', name: 'Маей-укемі',
      description: 'Падіння вперед на руки з перекатом.',
      category: ExerciseCategory.ukemi,
      forBelts: [BeltLevel.white, BeltLevel.whiteYellow],
      isDefault: true,
    ),
    BeltExerciseModel(
      id: 'ushiro_ukemi', name: 'Усіро-укемі',
      description: 'Падіння назад. Захист голови підборіддям до грудей.',
      category: ExerciseCategory.ukemi,
      forBelts: [BeltLevel.white, BeltLevel.whiteYellow, BeltLevel.yellow],
      isDefault: true,
    ),
    BeltExerciseModel(
      id: 'yoko_ukemi', name: 'Йоко-укемі',
      description: 'Падіння збоку з хлопком рукою по татамі.',
      category: ExerciseCategory.ukemi,
      forBelts: [BeltLevel.white, BeltLevel.whiteYellow],
      isDefault: true,
    ),
    BeltExerciseModel(
      id: 'o_goshi', name: 'О-госі',
      description: 'Велике підсідання під стегно. Базовий кидок.',
      category: ExerciseCategory.throws,
      forBelts: [BeltLevel.whiteYellow, BeltLevel.yellow],
      isDefault: true,
    ),
    BeltExerciseModel(
      id: 'ippon_seoi_nage', name: 'Іппон-сеой-наге',
      description: 'Кидок через плече. Один із найпоширеніших у змаганнях.',
      category: ExerciseCategory.throws,
      forBelts: [BeltLevel.yellow, BeltLevel.yellowOrange, BeltLevel.orange],
      isDefault: true,
    ),
    BeltExerciseModel(
      id: 'osoto_gari', name: 'О-сото-гарі',
      description: 'Велика зовнішня підсічка.',
      category: ExerciseCategory.throws,
      forBelts: [BeltLevel.yellow, BeltLevel.yellowOrange],
      isDefault: true,
    ),
    BeltExerciseModel(
      id: 'tai_otoshi', name: 'Тай-отосі',
      description: 'Кидок з підставленням ноги перед суперником.',
      category: ExerciseCategory.throws,
      forBelts: [BeltLevel.orange, BeltLevel.orangeGreen, BeltLevel.green],
      isDefault: true,
    ),
    BeltExerciseModel(
      id: 'kesa_gatame', name: 'Кеса-гатаме',
      description: 'Утримання збоку (шарф). Базова техніка наземної боротьби.',
      category: ExerciseCategory.groundwork,
      forBelts: [BeltLevel.whiteYellow, BeltLevel.yellow, BeltLevel.yellowOrange],
      isDefault: true,
    ),
    BeltExerciseModel(
      id: 'yoko_shiho_gatame', name: 'Йоко-сіхо-гатаме',
      description: 'Утримання збоку на чотири сторони.',
      category: ExerciseCategory.groundwork,
      forBelts: [BeltLevel.yellow, BeltLevel.yellowOrange, BeltLevel.orange],
      isDefault: true,
    ),
    BeltExerciseModel(
      id: 'uchi_mata', name: 'Учі-мата',
      description: 'Підхоплення зсередини. Ефективний кидок для середнього та вищого рівнів.',
      category: ExerciseCategory.throws,
      forBelts: [BeltLevel.green, BeltLevel.greenBlue, BeltLevel.blue],
      isDefault: true,
    ),
    BeltExerciseModel(
      id: 'juji_gatame', name: 'Джюдзі-гатаме',
      description: 'Важіль ліктя лежачи. Болісний прийом на суглоб.',
      category: ExerciseCategory.groundwork,
      forBelts: [BeltLevel.orangeGreen, BeltLevel.green, BeltLevel.greenBlue],
      isDefault: true,
    ),
    BeltExerciseModel(
      id: 'harai_goshi', name: 'Харай-госі',
      description: 'Кидок з підмахом стегном. Висока ефективність у змаганнях.',
      category: ExerciseCategory.throws,
      forBelts: [BeltLevel.green, BeltLevel.greenBlue, BeltLevel.blue, BeltLevel.blueBrown],
      isDefault: true,
    ),
  ];
}

import 'package:cloud_firestore/cloud_firestore.dart';

enum AchievementCategory {
  belts,
  tournaments,
  training,
  discipline,
  behavior,
  technique,
  theory,
  special,
  seasonal,
}

extension AchievementCategoryX on AchievementCategory {
  String get displayName {
    switch (this) {
      case AchievementCategory.belts:       return 'Пояси';
      case AchievementCategory.tournaments: return 'Турніри';
      case AchievementCategory.training:    return 'Тренування';
      case AchievementCategory.discipline:  return 'Дисципліна';
      case AchievementCategory.behavior:    return 'Поведінка';
      case AchievementCategory.technique:   return 'Техніка';
      case AchievementCategory.theory:      return 'Теорія';
      case AchievementCategory.special:     return 'Особливі';
      case AchievementCategory.seasonal:    return 'Сезонні';
    }
  }
}

enum AchievementRarity { common, rare, epic, legendary, mythic }

extension AchievementRarityX on AchievementRarity {
  String get label {
    switch (this) {
      case AchievementRarity.common:    return 'Звичайне';
      case AchievementRarity.rare:      return 'Рідкісне';
      case AchievementRarity.epic:      return 'Епічне';
      case AchievementRarity.legendary: return 'Легендарне';
      case AchievementRarity.mythic:    return 'Міфічне';
    }
  }
}

enum AchievementType { auto, manual, both }

class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    required this.rarity,
    required this.type,
    this.isHidden = false,
  });

  final String id;
  final String name;
  final String description;
  final String emoji;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final AchievementType type;
  final bool isHidden;

  bool get isManual => type == AchievementType.manual || type == AchievementType.both;
  bool get isAuto   => type == AchievementType.auto   || type == AchievementType.both;
}

class AchievementModel {
  const AchievementModel({
    required this.childId,
    required this.achievementId,
    required this.earnedAt,
    this.grantedByCoachId,
    this.note,
  });

  final String childId;
  final String achievementId;
  final DateTime earnedAt;
  final String? grantedByCoachId; // null = auto
  final String? note;

  bool get isAuto => grantedByCoachId == null;

  factory AchievementModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AchievementModel(
      childId:          d['childId'] as String? ?? '',
      achievementId:    d['achievementId'] as String? ?? '',
      earnedAt:         (d['earnedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      grantedByCoachId: d['grantedByCoachId'] as String?,
      note:             d['note'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'childId':          childId,
    'achievementId':    achievementId,
    'earnedAt':         Timestamp.fromDate(earnedAt),
    if (grantedByCoachId != null) 'grantedByCoachId': grantedByCoachId,
    if (note != null && note!.isNotEmpty) 'note': note,
  };
}

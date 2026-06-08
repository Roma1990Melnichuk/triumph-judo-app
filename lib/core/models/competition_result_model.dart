import 'package:cloud_firestore/cloud_firestore.dart';

enum CompetitionLevel {
  club,
  local,
  district,
  regional,
  national,
  european,
  world,
  international,
}

extension CompetitionLevelX on CompetitionLevel {
  String get displayName {
    switch (this) {
      case CompetitionLevel.club:          return 'Клубний';
      case CompetitionLevel.local:         return 'Міський';
      case CompetitionLevel.district:      return 'Районний';
      case CompetitionLevel.regional:      return 'Обласний';
      case CompetitionLevel.national:      return 'Всеукраїнський';
      case CompetitionLevel.european:      return 'Чемпіонат Європи';
      case CompetitionLevel.world:         return 'Чемпіонат Світу';
      case CompetitionLevel.international: return 'Міжнародний';
    }
  }

  static CompetitionLevel fromString(String v) {
    return CompetitionLevel.values.firstWhere(
      (e) => e.name == v,
      orElse: () => CompetitionLevel.local,
    );
  }
}

class CompetitionResultModel {
  final String id;
  final String childId;
  final String childName;
  final String competitionName;
  final String competitionType;
  final CompetitionLevel level;
  final int place; // 1–6
  final int points;
  final DateTime date;
  final int seasonYear;
  final String addedByCoachId;
  final String? clubId;
  final String? ruleSetVersion; // версія системи нарахування балів

  const CompetitionResultModel({
    required this.id,
    required this.childId,
    required this.childName,
    required this.competitionName,
    this.competitionType = '',
    required this.level,
    required this.place,
    required this.points,
    required this.date,
    required this.seasonYear,
    required this.addedByCoachId,
    this.clubId,
    this.ruleSetVersion,
  });

  factory CompetitionResultModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CompetitionResultModel(
      id: doc.id,
      childId: d['childId'] as String? ?? '',
      childName: d['childName'] as String? ?? '',
      competitionName: d['competitionName'] as String? ?? '',
      competitionType: d['competitionType'] as String? ?? '',
      level: CompetitionLevelX.fromString(d['level'] as String? ?? 'local'),
      place: (d['place'] as num?)?.toInt() ?? 1,
      points: (d['points'] as num?)?.toInt() ?? 0,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      seasonYear: (d['seasonYear'] as num?)?.toInt() ?? DateTime.now().year,
      addedByCoachId: d['addedByCoachId'] as String? ?? '',
      clubId: d['clubId'] as String?,
      ruleSetVersion: d['ruleSetVersion'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'childId': childId,
        'childName': childName,
        'competitionName': competitionName,
        'competitionType': competitionType,
        'level': level.name,
        'place': place,
        'points': points,
        'date': Timestamp.fromDate(date),
        'seasonYear': seasonYear,
        'addedByCoachId': addedByCoachId,
        if (clubId != null) 'clubId': clubId,
        if (ruleSetVersion != null) 'ruleSetVersion': ruleSetVersion,
      };
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show Color;

enum HonorBoardType {
  firstPlace,
  secondPlace,
  thirdPlace,
  newBelt,
  personalRecord,
  monthAchievement,
  disciplineRating,
  bestProgress,
}

extension HonorBoardTypeX on HonorBoardType {
  String get label => switch (this) {
        HonorBoardType.firstPlace        => '1 місце',
        HonorBoardType.secondPlace       => '2 місце',
        HonorBoardType.thirdPlace        => '3 місце',
        HonorBoardType.newBelt           => 'Новий пояс',
        HonorBoardType.personalRecord    => 'Особистий рекорд',
        HonorBoardType.monthAchievement  => 'Досягнення місяця',
        HonorBoardType.disciplineRating  => 'Рейтинг дисципліни',
        HonorBoardType.bestProgress      => 'Кращий прогрес',
      };

  String get emoji => switch (this) {
        HonorBoardType.firstPlace        => '🥇',
        HonorBoardType.secondPlace       => '🥈',
        HonorBoardType.thirdPlace        => '🥉',
        HonorBoardType.newBelt           => '🥋',
        HonorBoardType.personalRecord    => '🏆',
        HonorBoardType.monthAchievement  => '⭐',
        HonorBoardType.disciplineRating  => '📊',
        HonorBoardType.bestProgress      => '📈',
      };

  // For filter groups
  bool get isMedal => this == HonorBoardType.firstPlace ||
      this == HonorBoardType.secondPlace ||
      this == HonorBoardType.thirdPlace;

  bool get isBelt => this == HonorBoardType.newBelt;

  bool get isProgress => !isMedal && !isBelt;

  static HonorBoardType fromString(String? s) =>
      HonorBoardType.values.firstWhere(
        (e) => e.name == s,
        orElse: () => HonorBoardType.monthAchievement,
      );
}

enum MedalType { gold, silver, bronze }

extension MedalTypeX on MedalType {
  String get label => switch (this) {
        MedalType.gold   => 'Золото',
        MedalType.silver => 'Срібло',
        MedalType.bronze => 'Бронза',
      };

  String get emoji => switch (this) {
        MedalType.gold   => '🥇',
        MedalType.silver => '🥈',
        MedalType.bronze => '🥉',
      };

  Color get color => switch (this) {
        MedalType.gold   => const Color(0xFFFFD21A),
        MedalType.silver => const Color(0xFFB0BEC5),
        MedalType.bronze => const Color(0xFFBF8748),
      };

  static MedalType? fromString(String? s) => s == null
      ? null
      : MedalType.values
          .cast<MedalType?>()
          .firstWhere((e) => e?.name == s, orElse: () => null);
}

class ClubHonorBoardItem {
  final String id;
  final String athleteId;
  final String athleteName;
  final int? athleteAge;
  final String? athleteBelt;
  final HonorBoardType type;
  final String title;
  final String? description;
  final String? competitionName;
  final MedalType? medalType;
  final String? imageUrl;
  final String? coachComment;
  final bool isPinned;
  final bool isVisible;
  final DateTime publishedAt;
  final DateTime createdAt;

  const ClubHonorBoardItem({
    required this.id,
    required this.athleteId,
    required this.athleteName,
    this.athleteAge,
    this.athleteBelt,
    required this.type,
    required this.title,
    this.description,
    this.competitionName,
    this.medalType,
    this.imageUrl,
    this.coachComment,
    this.isPinned = false,
    this.isVisible = true,
    required this.publishedAt,
    required this.createdAt,
  });

  factory ClubHonorBoardItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ClubHonorBoardItem(
      id: doc.id,
      athleteId: d['athleteId'] as String? ?? '',
      athleteName: d['athleteName'] as String? ?? '',
      athleteAge: (d['athleteAge'] as num?)?.toInt(),
      athleteBelt: d['athleteBelt'] as String?,
      type: HonorBoardTypeX.fromString(d['type'] as String?),
      title: d['title'] as String? ?? '',
      description: d['description'] as String?,
      competitionName: d['competitionName'] as String?,
      medalType: MedalTypeX.fromString(d['medalType'] as String?),
      imageUrl: d['imageUrl'] as String?,
      coachComment: d['coachComment'] as String?,
      isPinned: d['isPinned'] as bool? ?? false,
      isVisible: d['isVisible'] as bool? ?? true,
      publishedAt:
          (d['publishedAt'] as Timestamp?)?.toDate() ?? DateTime(2026),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2026),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'athleteId': athleteId,
        'athleteName': athleteName,
        if (athleteAge != null) 'athleteAge': athleteAge,
        if (athleteBelt != null) 'athleteBelt': athleteBelt,
        'type': type.name,
        'title': title,
        if (description != null) 'description': description,
        if (competitionName != null) 'competitionName': competitionName,
        if (medalType != null) 'medalType': medalType!.name,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (coachComment != null) 'coachComment': coachComment,
        'isPinned': isPinned,
        'isVisible': isVisible,
        'publishedAt': Timestamp.fromDate(publishedAt),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

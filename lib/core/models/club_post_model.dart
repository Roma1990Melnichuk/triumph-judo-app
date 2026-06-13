import 'package:cloud_firestore/cloud_firestore.dart';

enum ClubPostType { photoReport, competition, achievement, honorBoard, announcement, clubNews }

extension ClubPostTypeX on ClubPostType {
  String get label => switch (this) {
        ClubPostType.photoReport  => 'Фотозвіт',
        ClubPostType.competition  => 'Змагання',
        ClubPostType.achievement  => 'Досягнення',
        ClubPostType.honorBoard   => 'Дошка пошани',
        ClubPostType.announcement => 'Оголошення',
        ClubPostType.clubNews     => 'Новини клубу',
      };

  static ClubPostType fromString(String? s) => ClubPostType.values.firstWhere(
        (e) => e.name == s,
        orElse: () => ClubPostType.clubNews,
      );
}

class ClubPostImage {
  final String id;
  final String postId;
  final String imageUrl;
  final String? thumbnailUrl;
  final String? caption;
  final int sortOrder;
  final DateTime createdAt;

  const ClubPostImage({
    required this.id,
    required this.postId,
    required this.imageUrl,
    this.thumbnailUrl,
    this.caption,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory ClubPostImage.fromMap(Map<String, dynamic> m) => ClubPostImage(
        id: m['id'] as String? ?? '',
        postId: m['postId'] as String? ?? '',
        imageUrl: m['imageUrl'] as String? ?? '',
        thumbnailUrl: m['thumbnailUrl'] as String?,
        caption: m['caption'] as String?,
        sortOrder: m['sortOrder'] as int? ?? 0,
        createdAt: m['createdAt'] is Timestamp
            ? (m['createdAt'] as Timestamp).toDate()
            : DateTime(2026),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'postId': postId,
        'imageUrl': imageUrl,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (caption != null) 'caption': caption,
        'sortOrder': sortOrder,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class ClubPostAthleteMention {
  final String id;
  final String? imageId;
  final String athleteId;
  final String athleteName;
  final double? xPosition;
  final double? yPosition;
  final String? caption;

  const ClubPostAthleteMention({
    required this.id,
    this.imageId,
    required this.athleteId,
    required this.athleteName,
    this.xPosition,
    this.yPosition,
    this.caption,
  });

  factory ClubPostAthleteMention.fromMap(Map<String, dynamic> m) =>
      ClubPostAthleteMention(
        id: m['id'] as String? ?? '',
        imageId: m['imageId'] as String?,
        athleteId: m['athleteId'] as String? ?? '',
        athleteName: m['athleteName'] as String? ?? '',
        xPosition: (m['xPosition'] as num?)?.toDouble(),
        yPosition: (m['yPosition'] as num?)?.toDouble(),
        caption: m['caption'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        if (imageId != null) 'imageId': imageId,
        'athleteId': athleteId,
        'athleteName': athleteName,
        if (xPosition != null) 'xPosition': xPosition,
        if (yPosition != null) 'yPosition': yPosition,
        if (caption != null) 'caption': caption,
      };
}

class ClubPostComment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String text;
  final bool isDeleted;
  final DateTime createdAt;

  const ClubPostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.text,
    this.isDeleted = false,
    required this.createdAt,
  });

  factory ClubPostComment.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ClubPostComment(
      id: doc.id,
      postId: d['postId'] as String? ?? '',
      userId: d['userId'] as String? ?? '',
      userName: d['userName'] as String? ?? '',
      text: d['text'] as String? ?? '',
      isDeleted: d['isDeleted'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2026),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'postId': postId,
        'userId': userId,
        'userName': userName,
        'text': text,
        'isDeleted': isDeleted,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class ClubPost {
  final String id;
  final String authorId;
  final String authorName;
  final ClubPostType type;
  final String title;
  final String description;
  final String content;
  final String? coverImageUrl;
  final bool isPinned;
  final bool isPublished;
  final bool commentsEnabled;
  final int likesCount;
  final int proudCount;
  final int commentsCount;
  final List<ClubPostImage> images;
  final List<ClubPostAthleteMention> mentions;
  final List<String> likedByUserIds;
  final List<String> proudByUserIds;
  final List<String> mentionedAthleteIds;
  // Competition-specific
  final String? competitionName;
  final String? competitionCity;
  final String? competitionVenue;
  final int? goldMedals;
  final int? silverMedals;
  final int? bronzeMedals;
  final DateTime? competitionDate;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClubPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.type,
    required this.title,
    this.description = '',
    this.content = '',
    this.coverImageUrl,
    this.isPinned = false,
    this.isPublished = false,
    this.commentsEnabled = true,
    this.likesCount = 0,
    this.proudCount = 0,
    this.commentsCount = 0,
    this.images = const [],
    this.mentions = const [],
    this.likedByUserIds = const [],
    this.proudByUserIds = const [],
    this.mentionedAthleteIds = const [],
    this.competitionName,
    this.competitionCity,
    this.competitionVenue,
    this.goldMedals,
    this.silverMedals,
    this.bronzeMedals,
    this.competitionDate,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  int get photosCount => images.length;

  bool userLiked(String uid) => likedByUserIds.contains(uid);
  bool userProud(String uid) => proudByUserIds.contains(uid);

  factory ClubPost.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final imagesList = (d['images'] as List<dynamic>? ?? [])
        .map((e) => ClubPostImage.fromMap(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final mentionsList = (d['mentions'] as List<dynamic>? ?? [])
        .map((e) => ClubPostAthleteMention.fromMap(e as Map<String, dynamic>))
        .toList();
    return ClubPost(
      id: doc.id,
      authorId: d['authorId'] as String? ?? '',
      authorName: d['authorName'] as String? ?? '',
      type: ClubPostTypeX.fromString(d['type'] as String?),
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      content: d['content'] as String? ?? '',
      coverImageUrl: d['coverImageUrl'] as String?,
      isPinned: d['isPinned'] as bool? ?? false,
      isPublished: d['isPublished'] as bool? ?? false,
      commentsEnabled: d['commentsEnabled'] as bool? ?? true,
      likesCount: (d['likesCount'] as num?)?.toInt() ?? 0,
      proudCount: (d['proudCount'] as num?)?.toInt() ?? 0,
      commentsCount: (d['commentsCount'] as num?)?.toInt() ?? 0,
      images: imagesList,
      mentions: mentionsList,
      likedByUserIds: List<String>.from(d['likedByUserIds'] as List? ?? []),
      proudByUserIds: List<String>.from(d['proudByUserIds'] as List? ?? []),
      mentionedAthleteIds:
          List<String>.from(d['mentionedAthleteIds'] as List? ?? []),
      competitionName: d['competitionName'] as String?,
      competitionCity: d['competitionCity'] as String?,
      competitionVenue: d['competitionVenue'] as String?,
      goldMedals: (d['goldMedals'] as num?)?.toInt(),
      silverMedals: (d['silverMedals'] as num?)?.toInt(),
      bronzeMedals: (d['bronzeMedals'] as num?)?.toInt(),
      competitionDate:
          (d['competitionDate'] as Timestamp?)?.toDate(),
      publishedAt: (d['publishedAt'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2026),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime(2026),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'authorId': authorId,
        'authorName': authorName,
        'type': type.name,
        'title': title,
        'description': description,
        'content': content,
        if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
        'isPinned': isPinned,
        'isPublished': isPublished,
        'commentsEnabled': commentsEnabled,
        'likesCount': likesCount,
        'proudCount': proudCount,
        'commentsCount': commentsCount,
        'images': images.map((e) => e.toMap()).toList(),
        'mentions': mentions.map((e) => e.toMap()).toList(),
        'likedByUserIds': likedByUserIds,
        'proudByUserIds': proudByUserIds,
        'mentionedAthleteIds': mentionedAthleteIds,
        if (competitionName != null) 'competitionName': competitionName,
        if (competitionCity != null) 'competitionCity': competitionCity,
        if (competitionVenue != null) 'competitionVenue': competitionVenue,
        if (goldMedals != null) 'goldMedals': goldMedals,
        if (silverMedals != null) 'silverMedals': silverMedals,
        if (bronzeMedals != null) 'bronzeMedals': bronzeMedals,
        if (competitionDate != null)
          'competitionDate': Timestamp.fromDate(competitionDate!),
        if (publishedAt != null)
          'publishedAt': Timestamp.fromDate(publishedAt!),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  ClubPost copyWith({
    String? title,
    String? description,
    String? content,
    Object? coverImageUrl = _sentinel,
    ClubPostType? type,
    bool? isPinned,
    bool? isPublished,
    bool? commentsEnabled,
    int? likesCount,
    int? proudCount,
    int? commentsCount,
    List<ClubPostImage>? images,
    List<ClubPostAthleteMention>? mentions,
    List<String>? likedByUserIds,
    List<String>? proudByUserIds,
    List<String>? mentionedAthleteIds,
    Object? competitionName = _sentinel,
    Object? competitionCity = _sentinel,
    Object? competitionVenue = _sentinel,
    Object? goldMedals = _sentinel,
    Object? silverMedals = _sentinel,
    Object? bronzeMedals = _sentinel,
    Object? competitionDate = _sentinel,
    DateTime? updatedAt,
  }) =>
      ClubPost(
        id: id,
        authorId: authorId,
        authorName: authorName,
        type: type ?? this.type,
        title: title ?? this.title,
        description: description ?? this.description,
        content: content ?? this.content,
        coverImageUrl: coverImageUrl == _sentinel
            ? this.coverImageUrl
            : coverImageUrl as String?,
        isPinned: isPinned ?? this.isPinned,
        isPublished: isPublished ?? this.isPublished,
        commentsEnabled: commentsEnabled ?? this.commentsEnabled,
        likesCount: likesCount ?? this.likesCount,
        proudCount: proudCount ?? this.proudCount,
        commentsCount: commentsCount ?? this.commentsCount,
        images: images ?? this.images,
        mentions: mentions ?? this.mentions,
        likedByUserIds: likedByUserIds ?? this.likedByUserIds,
        proudByUserIds: proudByUserIds ?? this.proudByUserIds,
        mentionedAthleteIds: mentionedAthleteIds ?? this.mentionedAthleteIds,
        competitionName: competitionName == _sentinel
            ? this.competitionName
            : competitionName as String?,
        competitionCity: competitionCity == _sentinel
            ? this.competitionCity
            : competitionCity as String?,
        competitionVenue: competitionVenue == _sentinel
            ? this.competitionVenue
            : competitionVenue as String?,
        goldMedals:
            goldMedals == _sentinel ? this.goldMedals : goldMedals as int?,
        silverMedals: silverMedals == _sentinel
            ? this.silverMedals
            : silverMedals as int?,
        bronzeMedals: bronzeMedals == _sentinel
            ? this.bronzeMedals
            : bronzeMedals as int?,
        competitionDate: competitionDate == _sentinel
            ? this.competitionDate
            : competitionDate as DateTime?,
        publishedAt: publishedAt,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}

const Object _sentinel = Object();

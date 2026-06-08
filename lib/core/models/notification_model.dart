import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationTarget { all, ageGroup, belt, top20age, exceptTop20age, personal }

extension NotificationTargetX on NotificationTarget {
  String get displayName {
    switch (this) {
      case NotificationTarget.all:           return 'Всім';
      case NotificationTarget.ageGroup:      return 'За віком';
      case NotificationTarget.belt:          return 'За поясом';
      case NotificationTarget.top20age:      return 'Топ 20 (вік)';
      case NotificationTarget.exceptTop20age: return 'Крім топ 20 (вік)';
      case NotificationTarget.personal:      return 'Особисте';
    }
  }

  static NotificationTarget fromString(String v) =>
      NotificationTarget.values.firstWhere(
        (e) => e.name == v,
        orElse: () => NotificationTarget.all,
      );
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationTarget target;
  /// Meaning depends on [target]:
  /// - ageGroup: list of birthYear strings (e.g. ['2010', '2011'])
  /// - belt:     list of BeltLevel.name strings
  /// - top20age: single-element list with the birthYear string
  /// - all:      empty
  final List<String> targetValues;
  final DateTime sentAt;
  final String coachId;
  final String coachName;
  final List<String> readByUserIds;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.target,
    required this.targetValues,
    required this.sentAt,
    required this.coachId,
    required this.coachName,
    required this.readByUserIds,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      target: NotificationTargetX.fromString(d['target'] as String? ?? 'all'),
      targetValues: (d['targetValues'] as List<dynamic>? ?? []).cast<String>(),
      sentAt: (d['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      coachId: d['coachId'] as String? ?? '',
      coachName: d['coachName'] as String? ?? '',
      readByUserIds: (d['readByUserIds'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'body': body,
        'target': target.name,
        'targetValues': targetValues,
        'sentAt': Timestamp.fromDate(sentAt),
        'coachId': coachId,
        'coachName': coachName,
        'readByUserIds': readByUserIds,
      };
}

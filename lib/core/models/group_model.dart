import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String coachId;
  final String name;
  final List<String> childIds;
  final List<int> daysOfWeek; // 1=Mon … 7=Sun
  final String timeStart;     // "18:00"
  final String timeEnd;       // "19:30"

  const GroupModel({
    required this.id,
    required this.coachId,
    required this.name,
    required this.childIds,
    required this.daysOfWeek,
    required this.timeStart,
    required this.timeEnd,
  });

  static const dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
  String get daysLabel =>
      daysOfWeek.map((d) => dayNames[d - 1]).join(', ');

  /// All training dates from September of [seasonYear] to July of [seasonYear]+1.
  List<DateTime> trainingDates(int seasonYear) {
    final start = DateTime(seasonYear, 9, 1);
    final end = DateTime(seasonYear + 1, 7, 31);
    final dates = <DateTime>[];
    var d = start;
    while (!d.isAfter(end)) {
      if (daysOfWeek.contains(d.weekday)) {
        dates.add(DateTime(d.year, d.month, d.day));
      }
      d = d.add(const Duration(days: 1));
    }
    return dates;
  }

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return GroupModel(
      id: doc.id,
      coachId: d['coachId'] as String? ?? '',
      name: d['name'] as String? ?? '',
      childIds: (d['childIds'] as List<dynamic>? ?? []).cast<String>(),
      daysOfWeek:
          (d['daysOfWeek'] as List<dynamic>? ?? []).map((e) => e as int).toList(),
      timeStart: d['timeStart'] as String? ?? '18:00',
      timeEnd: d['timeEnd'] as String? ?? '19:30',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'coachId': coachId,
        'name': name,
        'childIds': childIds,
        'daysOfWeek': daysOfWeek,
        'timeStart': timeStart,
        'timeEnd': timeEnd,
      };

  GroupModel copyWith({
    String? id,
    String? coachId,
    String? name,
    List<String>? childIds,
    List<int>? daysOfWeek,
    String? timeStart,
    String? timeEnd,
  }) {
    return GroupModel(
      id: id ?? this.id,
      coachId: coachId ?? this.coachId,
      name: name ?? this.name,
      childIds: childIds ?? this.childIds,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      timeStart: timeStart ?? this.timeStart,
      timeEnd: timeEnd ?? this.timeEnd,
    );
  }
}

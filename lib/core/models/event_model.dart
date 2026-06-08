import 'package:cloud_firestore/cloud_firestore.dart';

enum EventType { competition, tournament, camp, other }

extension EventTypeX on EventType {
  String get displayName {
    switch (this) {
      case EventType.competition: return 'Змагання';
      case EventType.tournament:  return 'Турнір';
      case EventType.camp:        return 'Збір';
      case EventType.other:       return 'Інше';
    }
  }

  static EventType fromString(String v) => EventType.values.firstWhere(
        (e) => e.name == v,
        orElse: () => EventType.competition,
      );
}

class EventModel {
  final String id;
  final String title;
  final EventType type;
  final DateTime date;
  final String location;
  final String? description;
  final String coachId;
  final List<String> beltLevels;      // belt names that can participate
  final List<String> participantIds;  // childIds who marked as going
  final int year;                     // event year (for filter)

  const EventModel({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.location,
    this.description,
    required this.coachId,
    required this.beltLevels,
    required this.participantIds,
    required this.year,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: d['title'] as String? ?? '',
      type: EventTypeX.fromString(d['type'] as String? ?? 'competition'),
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: d['location'] as String? ?? '',
      description: d['description'] as String?,
      coachId: d['coachId'] as String? ?? '',
      beltLevels: (d['beltLevels'] as List<dynamic>? ?? []).cast<String>(),
      participantIds: (d['participantIds'] as List<dynamic>? ?? []).cast<String>(),
      year: (d['year'] as num?)?.toInt() ?? DateTime.now().year,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'type': type.name,
        'date': Timestamp.fromDate(date),
        'location': location,
        if (description != null) 'description': description,
        'coachId': coachId,
        'beltLevels': beltLevels,
        'participantIds': participantIds,
        'year': year,
      };

  EventModel copyWith({
    String? title,
    EventType? type,
    DateTime? date,
    String? location,
    String? description,
    List<String>? beltLevels,
    List<String>? participantIds,
  }) {
    return EventModel(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      date: date ?? this.date,
      location: location ?? this.location,
      description: description ?? this.description,
      coachId: coachId,
      beltLevels: beltLevels ?? this.beltLevels,
      participantIds: participantIds ?? this.participantIds,
      year: year,
    );
  }
}

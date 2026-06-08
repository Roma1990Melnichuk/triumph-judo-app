import 'package:cloud_firestore/cloud_firestore.dart';

/// Recurring training schedule (e.g. Mon/Wed/Fri 18:00–19:30)
class TrainingScheduleModel {
  final String id;
  final String coachId;
  final String label;          // "Основне тренування"
  final List<int> daysOfWeek;  // 1=Mon, 2=Tue … 7=Sun
  final String timeStart;      // "18:00"
  final String timeEnd;        // "19:30"

  const TrainingScheduleModel({
    required this.id,
    required this.coachId,
    required this.label,
    required this.daysOfWeek,
    required this.timeStart,
    required this.timeEnd,
  });

  factory TrainingScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TrainingScheduleModel(
      id: doc.id,
      coachId: d['coachId'] as String? ?? '',
      label: d['label'] as String? ?? '',
      daysOfWeek: (d['daysOfWeek'] as List<dynamic>? ?? []).map((e) => e as int).toList(),
      timeStart: d['timeStart'] as String? ?? '18:00',
      timeEnd: d['timeEnd'] as String? ?? '19:30',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'coachId': coachId,
    'label': label,
    'daysOfWeek': daysOfWeek,
    'timeStart': timeStart,
    'timeEnd': timeEnd,
  };

  static const dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
  String get daysLabel => daysOfWeek.map((d) => dayNames[d - 1]).join(', ');
}

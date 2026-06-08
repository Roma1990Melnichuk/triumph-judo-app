import 'package:cloud_firestore/cloud_firestore.dart';

enum SlotStatus { available, requested, confirmed, cancelled }

extension SlotStatusX on SlotStatus {
  String get displayName {
    switch (this) {
      case SlotStatus.available:  return 'Вільний';
      case SlotStatus.requested:  return 'Запит';
      case SlotStatus.confirmed:  return 'Підтверджено';
      case SlotStatus.cancelled:  return 'Скасовано';
    }
  }

  static SlotStatus fromString(String v) => SlotStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => SlotStatus.available,
      );
}

class IndividualSlotModel {
  final String id;
  final String coachId;
  final String coachName;
  final DateTime date;
  final String timeStart;  // "14:00"
  final String timeEnd;    // "14:30"
  final double? price;
  final String currency;
  final SlotStatus status;
  final String? childId;
  final String? childName;
  final String? requestedByUserId;
  final DateTime? requestedAt;
  final DateTime? confirmedAt;
  final bool isPaid;

  const IndividualSlotModel({
    required this.id,
    required this.coachId,
    required this.coachName,
    required this.date,
    required this.timeStart,
    required this.timeEnd,
    this.price,
    this.currency = 'UAH',
    required this.status,
    this.childId,
    this.childName,
    this.requestedByUserId,
    this.requestedAt,
    this.confirmedAt,
    this.isPaid = false,
  });

  factory IndividualSlotModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return IndividualSlotModel(
      id: doc.id,
      coachId: d['coachId'] as String? ?? '',
      coachName: d['coachName'] as String? ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeStart: d['timeStart'] as String? ?? '',
      timeEnd: d['timeEnd'] as String? ?? '',
      price: (d['price'] as num?)?.toDouble(),
      currency: d['currency'] as String? ?? 'UAH',
      status: SlotStatusX.fromString(d['status'] as String? ?? 'available'),
      childId: d['childId'] as String?,
      childName: d['childName'] as String?,
      requestedByUserId: d['requestedByUserId'] as String?,
      requestedAt: (d['requestedAt'] as Timestamp?)?.toDate(),
      confirmedAt: (d['confirmedAt'] as Timestamp?)?.toDate(),
      isPaid: d['isPaid'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'coachId': coachId,
        'coachName': coachName,
        'date': Timestamp.fromDate(date),
        'timeStart': timeStart,
        'timeEnd': timeEnd,
        if (price != null) 'price': price,
        'currency': currency,
        'status': status.name,
        if (childId != null) 'childId': childId,
        if (childName != null) 'childName': childName,
        if (requestedByUserId != null) 'requestedByUserId': requestedByUserId,
        if (requestedAt != null) 'requestedAt': Timestamp.fromDate(requestedAt!),
        if (confirmedAt != null) 'confirmedAt': Timestamp.fromDate(confirmedAt!),
        'isPaid': isPaid,
      };

  IndividualSlotModel copyWith({
    SlotStatus? status,
    String? childId,
    String? childName,
    String? requestedByUserId,
    DateTime? requestedAt,
    DateTime? confirmedAt,
    bool? isPaid,
  }) {
    return IndividualSlotModel(
      id: id,
      coachId: coachId,
      coachName: coachName,
      date: date,
      timeStart: timeStart,
      timeEnd: timeEnd,
      price: price,
      currency: currency,
      status: status ?? this.status,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      requestedByUserId: requestedByUserId ?? this.requestedByUserId,
      requestedAt: requestedAt ?? this.requestedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}

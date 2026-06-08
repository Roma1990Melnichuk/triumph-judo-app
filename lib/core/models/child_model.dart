import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/belt_levels.dart';

enum Gender {
  male,
  female;

  String get displayName => this == Gender.male ? 'Хлопчик' : 'Дівчинка';
  String get icon => this == Gender.male ? '♂' : '♀';

  static Gender? fromString(String? s) {
    if (s == 'male') return Gender.male;
    if (s == 'female') return Gender.female;
    return null;
  }
}

const weightCategories = [
  '-16 кг', '-18 кг', '-20 кг', '-22 кг', '-24 кг',
  '-26 кг', '-28 кг', '-30 кг', '-32 кг', '-34 кг',
  '-36 кг', '-38 кг', '-40 кг', '-42 кг', '-44 кг',
  '-46 кг', '-48 кг', '+48 кг', '-50 кг', '-55 кг',
  '-60 кг', '+60 кг',
];

/// Прибирає знак "-" (до N кг), але зберігає "+" (понад N кг).
/// "-30 кг" → "30 кг", "+48 кг" → "+48 кг"
String displayWeight(String w) =>
    w.startsWith('-') ? w.substring(1) : w;

class ChildModel {
  final String id;
  final String firstName;
  final String lastName;
  final int birthYear;
  final String weightCategory;
  final BeltLevel currentBelt;
  final String? photoUrl;
  final String coachId;
  final String coachName;
  final int totalPoints;
  final DateTime createdAt;
  final String? clubId;
  final Gender? gender;
  final bool beltReady;
  /// Manual coach-added adjustment on top of competition points.
  final int bonusPoints;
  final String? phone;

  const ChildModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthYear,
    required this.weightCategory,
    required this.currentBelt,
    this.photoUrl,
    required this.coachId,
    required this.coachName,
    required this.totalPoints,
    required this.createdAt,
    this.clubId,
    this.gender,
    this.beltReady = false,
    this.bonusPoints = 0,
    this.phone,
  });

  String get fullName => '$lastName $firstName';

  String get ageCategory {
    final age = DateTime.now().year - birthYear;
    if (age <= 8)  return 'Малюки';
    if (age <= 10) return 'Міні';
    if (age <= 12) return 'Юніори мол.';
    if (age <= 14) return 'Кадети';
    if (age <= 17) return 'Юніори';
    if (age <= 20) return 'Молодь';
    return 'Дорослі';
  }

  factory ChildModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChildModel(
      id: doc.id,
      firstName: d['firstName'] as String? ?? '',
      lastName: d['lastName'] as String? ?? '',
      birthYear: (d['birthYear'] as num?)?.toInt() ?? 2010,
      weightCategory: d['weightCategory'] as String? ?? '-30 кг',
      currentBelt: BeltLevelX.fromString(d['currentBelt'] as String? ?? 'white'),
      photoUrl: d['photoUrl'] as String?,
      coachId: d['coachId'] as String? ?? '',
      coachName: d['coachName'] as String? ?? '',
      totalPoints: (d['totalPoints'] as num?)?.toInt() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      clubId: d['clubId'] as String?,
      gender: Gender.fromString(d['gender'] as String?),
      beltReady: (d['beltReady'] as bool?) ?? false,
      bonusPoints: (d['bonusPoints'] as num?)?.toInt() ?? 0,
      phone: d['phone'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'firstName': firstName,
        'lastName': lastName,
        'birthYear': birthYear,
        'weightCategory': weightCategory,
        'currentBelt': currentBelt.name,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'coachId': coachId,
        'coachName': coachName,
        'totalPoints': totalPoints,
        'createdAt': Timestamp.fromDate(createdAt),
        if (clubId != null) 'clubId': clubId,
        if (gender != null) 'gender': gender!.name,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        // beltReady is managed exclusively by belt_provider.toggleExercise
        // and must NOT be overwritten here on profile save
      };

  ChildModel copyWith({
    String? firstName,
    String? lastName,
    int? birthYear,
    String? weightCategory,
    BeltLevel? currentBelt,
    String? photoUrl,
    String? coachId,
    String? coachName,
    int? totalPoints,
    String? clubId,
    Gender? gender,
    bool? beltReady,
    int? bonusPoints,
    String? phone,
    bool clearGender = false,
    bool clearPhone = false,
  }) =>
      ChildModel(
        id: id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        birthYear: birthYear ?? this.birthYear,
        weightCategory: weightCategory ?? this.weightCategory,
        currentBelt: currentBelt ?? this.currentBelt,
        photoUrl: photoUrl ?? this.photoUrl,
        coachId: coachId ?? this.coachId,
        coachName: coachName ?? this.coachName,
        totalPoints: totalPoints ?? this.totalPoints,
        createdAt: createdAt,
        clubId: clubId ?? this.clubId,
        gender: clearGender ? null : (gender ?? this.gender),
        beltReady: beltReady ?? this.beltReady,
        bonusPoints: bonusPoints ?? this.bonusPoints,
        phone: clearPhone ? null : (phone ?? this.phone),
      );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_card_model.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'coach' | 'parent'
  final String? phone;
  final String? photoUrl;
  /// Legacy single-child field — kept for backward compatibility.
  /// Prefer [childIds] for new code.
  final String? childId;
  /// All linked child IDs (parent / guardian view).
  final List<String> childIds;
  final String? clubId;

  // ── Coach financial settings ──────────────────────────────────────────────
  /// Ціна одного індивідуального заняття (грн). 0 = не задано.
  final double individualPrice;
  /// Картки/реквізити для оплати. Перша — дефолтна для клієнта.
  final List<PaymentCard> paymentCards;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.photoUrl,
    this.childId,
    this.childIds = const [],
    this.clubId,
    this.individualPrice = 0,
    this.paymentCards = const [],
  });

  bool get isCoach  => role == 'coach';
  bool get isParent => role == 'parent';

  bool ownsChild(String id) => childIds.contains(id) || childId == id;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final legacyId = data['childId'] as String?;
    final ids = (data['childIds'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        (legacyId != null ? [legacyId] : <String>[]);

    final rawCards = data['paymentCards'] as List<dynamic>? ?? [];
    final cards = rawCards
        .whereType<Map<String, dynamic>>()
        .map(PaymentCard.fromMap)
        .toList();

    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? 'parent',
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
      childId: legacyId,
      childIds: ids,
      clubId: data['clubId'] as String?,
      individualPrice:
          (data['individualPrice'] as num?)?.toDouble() ?? 0,
      paymentCards: cards,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'name': name,
        'role': role,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (photoUrl != null && photoUrl!.isNotEmpty) 'photoUrl': photoUrl,
        'childIds': childIds,
        if (childIds.isNotEmpty) 'childId': childIds.first,
        if (clubId != null) 'clubId': clubId,
        'individualPrice': individualPrice,
        'paymentCards': paymentCards.map((c) => c.toMap()).toList(),
      };

  UserModel copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    String? childId,
    List<String>? childIds,
    String? clubId,
    bool clearPhone = false,
    bool clearPhoto = false,
    double? individualPrice,
    List<PaymentCard>? paymentCards,
  }) =>
      UserModel(
        uid: uid,
        email: email,
        name: name ?? this.name,
        role: role,
        phone: clearPhone ? null : (phone ?? this.phone),
        photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
        childId: childId ?? this.childId,
        childIds: childIds ?? this.childIds,
        clubId: clubId ?? this.clubId,
        individualPrice: individualPrice ?? this.individualPrice,
        paymentCards: paymentCards ?? this.paymentCards,
      );
}

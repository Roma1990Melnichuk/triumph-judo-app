import 'package:cloud_firestore/cloud_firestore.dart';

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
  /// Populated from Firestore `childIds` array; falls back to [childId]
  /// for documents written before multi-child support.
  final List<String> childIds;
  final String? clubId;

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
  });

  bool get isCoach  => role == 'coach';
  bool get isParent => role == 'parent';

  /// Returns true if [id] is among the linked children.
  bool ownsChild(String id) => childIds.contains(id) || childId == id;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final legacyId = data['childId'] as String?;
    final ids = (data['childIds'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        (legacyId != null ? [legacyId] : <String>[]);
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
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'name': name,
        'role': role,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (photoUrl != null && photoUrl!.isNotEmpty) 'photoUrl': photoUrl,
        // Always write the array; keep legacy field for old clients
        'childIds': childIds,
        if (childIds.isNotEmpty) 'childId': childIds.first,
        if (clubId != null) 'clubId': clubId,
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
      );
}

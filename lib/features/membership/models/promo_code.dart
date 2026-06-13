import 'package:cloud_firestore/cloud_firestore.dart';

class PromoCode {
  const PromoCode({
    required this.code,
    required this.discountPct,
    this.validUntil,
    this.isActive = true,
  });

  final String code;
  final int discountPct;
  final DateTime? validUntil;
  final bool isActive;

  bool get isExpired =>
      validUntil != null && validUntil!.isBefore(DateTime.now());
  bool get isValid => isActive && !isExpired;

  Map<String, dynamic> toMap() => {
        'code': code.toUpperCase().trim(),
        'discountPct': discountPct,
        if (validUntil != null) 'validUntil': Timestamp.fromDate(validUntil!),
        'isActive': isActive,
      };

  factory PromoCode.fromMap(Map<String, dynamic> m) => PromoCode(
        code: m['code'] as String,
        discountPct: (m['discountPct'] as num).toInt(),
        validUntil: m['validUntil'] != null
            ? (m['validUntil'] as Timestamp).toDate()
            : null,
        isActive: m['isActive'] as bool? ?? true,
      );
}

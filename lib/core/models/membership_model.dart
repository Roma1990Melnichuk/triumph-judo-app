import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum MembershipStatus { active, expiringSoon, expired }

class MembershipModel {
  const MembershipModel({
    required this.athleteId,
    required this.planName,
    required this.startDate,
    required this.endDate,
    required this.amount,
    this.currency = 'UAH',
    this.totalSessions,
    this.sessionsUsed = 0,
  });

  final String athleteId;
  final String planName;
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final String currency;
  final int? totalSessions; // null = unlimited plan
  final int sessionsUsed;

  bool get isSessionBased => totalSessions != null;

  int? get sessionsRemaining => totalSessions == null
      ? null
      : (totalSessions! - sessionsUsed).clamp(0, totalSessions!);

  int get daysRemaining {
    final d = endDate.difference(DateTime.now()).inDays;
    return d < 0 ? 0 : d;
  }

  int get daysExpiredAgo =>
      isExpired ? DateTime.now().difference(endDate).inDays : 0;

  bool get isActive => !DateTime.now().isAfter(endDate);

  bool get isExpiringSoon {
    if (!isActive) return false;
    if (isSessionBased) return sessionsRemaining! <= 5;
    return daysRemaining <= 7;
  }

  bool get isExpired => DateTime.now().isAfter(endDate);

  MembershipStatus get status {
    if (isExpired) return MembershipStatus.expired;
    if (isExpiringSoon) return MembershipStatus.expiringSoon;
    return MembershipStatus.active;
  }

  double get progressPercent {
    if (isSessionBased && totalSessions! > 0) {
      return (sessionsUsed / totalSessions!).clamp(0.0, 1.0);
    }
    final total = endDate.difference(startDate).inDays;
    if (total <= 0) return 1.0;
    final elapsed = DateTime.now().difference(startDate).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Color get statusColor {
    switch (status) {
      case MembershipStatus.active:
        return const Color(0xFF27AE60);
      case MembershipStatus.expiringSoon:
        return const Color(0xFFFF8A00);
      case MembershipStatus.expired:
        return const Color(0xFFD50000);
    }
  }

  String get statusLabel {
    switch (status) {
      case MembershipStatus.active:
        return 'АКТИВНИЙ';
      case MembershipStatus.expiringSoon:
        return 'ЗАКІНЧУЄТЬСЯ';
      case MembershipStatus.expired:
        return 'ПРОСТРОЧЕНИЙ';
    }
  }

  factory MembershipModel.fromMap(Map<String, dynamic> map, String athleteId) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.parse(v);
      return DateTime.now();
    }

    return MembershipModel(
      athleteId: athleteId,
      planName: map['planName'] as String? ?? '',
      startDate: parseDate(map['startDate']),
      endDate: parseDate(map['endDate']),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'UAH',
      totalSessions: map['totalSessions'] as int?,
      sessionsUsed: (map['sessionsUsed'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'athleteId': athleteId,
        'planName': planName,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'amount': amount,
        'currency': currency,
        if (totalSessions != null) 'totalSessions': totalSessions,
        'sessionsUsed': sessionsUsed,
      };
}
